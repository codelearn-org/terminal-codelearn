require 'reel'
require '../lib/session'
require 'stringio'
require 'json'
require 'cgi'
require 'moped'
require '../lib/code_profiler'
require "ruby-prof"
require '../lib/code_timing'

ANSI_COLOR_CODE = {
	0 => 'black',
	1 => 'red',
	2 => 'green',
	3 => 'yellow',
	4 => 'blue',
	5 => 'purple',
	6 => 'cyan',
	7 => 'white'
}

#### Configurable data points#####

DEFAULT_HOST = '127.0.0.1'
MONGODB_PORT = '27017'
REEL_SERVER_PORT = 3001


$mongodb_session = Moped::Session.new([ DEFAULT_HOST+":"+MONGODB_PORT ])
$mongodb_session.use "terminal_commands"

#making function global as it is needed by both TerminalUser & MyServer
def get_children_process(pid)
	`ps --ppid #{pid} | grep -v PID | awk '{print $1}'`.split("\n")
	#Could not find a Ruby way to do this
end

class TerminalUser < Profiler
	
	def initialize(user)
		@bash = Session::Bash::new({:prog => "su #{user}"})
		@output = ""
		@read_data = StringIO::new(@output)
		@check_data = StringIO::new(@output)
		@bash.outproc = lambda {|out| 
			@output << out
			@status = ( /(\$|>)\s*\z/.match(out) ) ? "complete" : "waiting"
		}
		#commenting out as no STDERR in ruby pty
		#@bash.errproc = lambda {|err| @output << err }
		#@bash.execute "sudo -i -u #{user}"
		@status = "waiting"
		@bash._initialize	
	end
	
	def block_for_output_to_come
		count = 0
		@check_data.read
		loop_count = 0
		until @status == "complete" or loop_count > 4
			sleep 1
			loop_count = loop_count + 1
			puts "inside loop"
		end
	end

	def execute(command)
		@status = "waiting" #changing state so that execution hangs till output appear
		puts @bash.inspect
		puts "Executing command - #{command}"
		@bash.execute(command)
	end

	def respond(request,data_n,status)
		block_for_output_to_come
		puts "output - #{@output}"
		data = @read_data.read
		puts "data - #{data}"
		@output.slice!(0,@read_data.pos)
		@read_data.rewind
		status[0] = @status		
		sanitize_ansi_data(data,data_n)
	end

	def sanitize_ansi_data(data,data_n) 
		data.gsub!(/\033\[1m/,"<b>")
		data.gsub!(/\033\[0m/,"</b></span>")
		
		data.gsub!(/\033\[[\d\;]{2,}m.*?<\/b><\/span>/){ |data|
			span = "<span style='"
			content = ""
			/\033\[([\d\;]{2,})m(.*?)<\/b><\/span>/.match(data) {|m|
				content = m[2]
				m[1].split(";").each do |code|
					#puts code
					if match = /(\d)(\d)/.match(code) 
						case match[1]
						when "3"
							span += "color: #{ANSI_COLOR_CODE[match[2].to_i]}; "
						when "4"
							span += "background-color: #{ANSI_COLOR_CODE[match[2].to_i]}; "
						else
							#do nothing
						end
					else
						span += "font-weight:bold; "
					end
				end
			}
			span += "'>"
			"#{span}#{content}</b></span>"
		}
		data_n[0] = data
	end

	def kill_all_children(interrupt)
		if @parent_pid.nil?
			@parent_pid = get_children_process(@bash.pid)[0] 
		end	
		get_children_process(@parent_pid).each do |p|
			system("kill #{interrupt} #{p}")
			sleep 1
		end
		sleep 1 #let the PS1 appear which was sent prior to the command execution
	end

	def kill_all
		kill_all_children(-9)
		begin
			@bash.close
		rescue Exception => e
			puts e
		end
		sleep 1
	end

	profile(:block_for_output_to_come ,:execute ,:sanitize_ansi_data)
end

class MyServer < Reel::Server
  def initialize(host = DEFAULT_HOST, port = REEL_SERVER_PORT)
   	 super(host, port, &method(:on_connection))
	 $users = Hash.new
  end
  
  def on_connection(connection)
  	start_time = Time.now
  	while request = connection.request
      case request
      when Reel::Request
      	if CodeProfiler::profile_logger_enabled?
	      	CodeProfiler::profile_logger("handle_request", start_time, request.url) do
	       	 	handle_request(request)
	    	end
	    else
	    	handle_request(request)
	    end
   		
      when Reel::WebSocket
        handle_websocket(request)
      end
    end
  end

  def handle_request(request)
  	begin	
  		puts "url - #{request.url}"
		nothing,user,terminal_no,type,command = request.url.split("/")
		
		terminal_no = terminal_no.to_i
		
		if $users[user].nil? 
			puts "#{user} not found. Creating"
			$users[user] = []
			$users[user][terminal_no] = TerminalUser.new(user)
		elsif $users[user][terminal_no].nil?
			$users[user][terminal_no] = TerminalUser.new(user)
		end
		
		terminal_user = $users[user][terminal_no]
		puts terminal_user.inspect
		now = Time.now
		
		#insert into mongo now before any errors that might come
		$mongodb_session[:commands].insert(user: user, terminal_no: terminal_no, command: (command.nil? ? "/#{type}" : CGI::unescape(command)), type: 'input', time: "#{now}")
		
		if type == "execute"
			command = CGI::unescape(command) if command
			puts "command #{command}"
			terminal_user.execute(command)
		end

		if type == "kill"
			terminal_user.kill_all_children(-2)
		end

		if type == "reset"
			handle_error(terminal_user, user, terminal_no, request)			
		end

		data,status = '',''		
		terminal_user.respond(request,data,status)
		puts "status : #{status}" 
		puts "data : #{data}" 

		request.respond :ok, {"Content-type" => "text/html; charset=utf-8"},  JSON.generate({:content => data, :status => status})
  
		if !data.empty? #logging only non-empty output to keep the clutter less 
			$mongodb_session[:commands].insert(user: user, terminal_no: terminal_no, command: data.gsub(%r{</?[^>]+?>}, ''), type: 'output', time: "#{now}") 
		end
		
	rescue Exception => e
		#there might be a problem with broken pipe as the user might have typed 'exit'. Just send error & expect for a new request
		puts "---- Inside Exception ----\n#{e}"
		handle_error(terminal_user, user, terminal_no, request)
	end
	
  end

  def handle_error(terminal_user, user, terminal_no, request)
  	terminal_user.kill_all
		
		$users[user][terminal_no] = nil
		#hopefully garbage collector kicks in here & picks up the object that is made nil
		$users[user][terminal_no] = TerminalUser.new(user)
		
		request.respond :ok, {"Content-type" => "text/html; charset=utf-8"}, JSON.generate({:status => "error", :content => ""})
		return
  end

  def self.exit_system #cleanup all the users
	puts "Cleaning up all users. This may take sometime. Please wait ...."
	$users.each do |user, terminals|
	   terminals.each_with_index.map do |terminal_user,i|
			terminal_user.kill_all
			terminals[i] = nil
	   end
	   $users[user] = nil
	end

	#kill any remaining child process that are active
	puts "Process pid #{Process.pid}"
	get_children_process(Process.pid).each do |p| #recursively kill  
		MyServer.kill_children_and_self(p)
	end
		
	puts "All is well"
	return
  end

  def self.kill_children_and_self(pid)
  	  # RubyProf.start	
	  get_children_process(pid).each do |p|
		  kill_children_and_self(p)
	  end
	  puts "Killing pid #{pid}"
	  system("kill -9 #{pid}")
	  # profile_result = RubyProf.stop # end profiling
	  # print_profile_logs(profile_result,"reel_server_profiler", "MyServer -> kill_children_and_self")
  end

  def handle_websocket(sock)
  	# RubyProf.start
    sock << "Hello everyone out there in WebSocket land!"
    sock.close
    # profile_result = RubyProf.stop # end profiling
	# print_profile_logs(profile_result,"reel_server_profiler", "MyServer -> handle_websocket")
  end
end

begin
	 MyServer.run
rescue SystemExit, Interrupt
	MyServer.exit_system
	
end
