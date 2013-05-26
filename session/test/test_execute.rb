require 'curb'
require 'net/sftp'

server = 'www.codelearn.org'

method = "http://#{server}:3000/terminals/0/execute?command="
commands = ["ps","cd+..","ls","pwd","cal","df","id","uptime"]
times = []

commands.each do |command|
	url = method + command
	puts url
	start_time = Time.now
		Curl.get(url)
	end_time = Time.now

 	times << end_time - start_time
end

username = 'ubuntu'

puts "Starting sftp at #{server} with username '#{username}' ...."

Net::SFTP.start(server,username,:password => 'founders@codelearn') do |sftp|
  sftp.download!('terminal-codelearn/execute.txt', 'initial.txt')
	sftp.remove!('terminal-codelearn/execute.txt')
end

puts "sftp connection ended"

demo_times = []
reel_times = []
i=1
File.open("initial.txt", 'r').each do |line|
	if(i%4==2)	
		demo_times << Float(line[/\d*\.\d*$/])
	elsif (i%4==3)
		reel_times << Float(line[/\d*\.\d*$/])
	end
	i = i.next
end

http_delays = []
demo_delays = []

File.open("final.txt", 'w') do |file|
	i=0
	while(i < times.length)	
		http_delays << times[i]-demo_times[i]
		demo_delays << (demo_times[i]-reel_times[i]) * 1000
		file.puts "URL:  #{method}#{commands[i]}\n"		
		file.puts "	Http Delay:       #{'%.4f' % (times[i]-demo_times[i])} s\n"
		file.puts "	Demo-app Delay:   #{'%.2f' % ((demo_times[i]-reel_times[i])*1000)} ms\n"
		file.puts "	Reel server Time: #{'%.4f' % reel_times[i]} s\n\n"
		i = i.next
	end
	avg_http =  http_delays.inject{ |sum, el| sum + el } / http_delays.size
	avg_demo =  demo_delays.inject{ |sum, el| sum + el } / demo_delays.size	
	avg_reel =  reel_times.inject{ |sum, el| sum + el } / reel_times.size
	file.puts "Average Http Delay:       #{'%.4f' % avg_http} s\n"
	file.puts "Average Demo-app Delay:   #{'%.2f' % avg_demo} ms\n"
	file.puts "Average Reel server time: #{'%.4f' % avg_reel} s"
end



