require 'curb'
require 'net/sftp'

SERVER = 'localhost'
USERNAME = ''
PASSWORD = ''

puts "Removing execute.txt if it exists on server..."

Net::SFTP.start(SERVER,USERNAME,:password => "#{PASSWORD}") do |sftp|
  sftp.stat!('terminal-codelearn/execute.txt') do |response|
		if response.ok?		
			sftp.remove!('terminal-codelearn/execute.txt')
			puts "execute.txt removed"		
		end	
	end
end

puts "Connection ended"

method = "http://#{SERVER}:3000/terminals/0/execute?command="

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

puts "Starting sftp at #{SERVER} with username '#{USERNAME}' ...."

Net::SFTP.start(SERVER,USERNAME,:password => "#{PASSWORD}") do |sftp|
  sftp.download!('terminal-codelearn/execute.txt', 'initial.txt')
end

puts "sftp connection ended"

demo_times = []
reel_times = []
lines = [[]]
i=0
File.open("initial.txt", 'r').each do |line|
	if line[/^\s*demo-app/i]	
		demo_times << Float(line[/\d*\.\d*$/])
	elsif line[/^\s*reel server/i]
		reel_times << Float(line[/\d*\.\d*$/])
	elsif line[/^url/i]		
		i=i.next	
		lines[i] =[]
	elsif !line[/^\n$/]
		lines[i] << line
	end
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
		file.puts "	Reel server Time: #{'%.4f' % reel_times[i]} s\n"
		lines[i].each do |line|
			file.puts line
		end
		file.puts
		i = i.next
	end
	avg_http =  http_delays.inject{ |sum, el| sum + el } / http_delays.size
	avg_demo =  demo_delays.inject{ |sum, el| sum + el } / demo_delays.size	
	avg_reel =  reel_times.inject{ |sum, el| sum + el } / reel_times.size
	file.puts "Average Http Delay:       #{'%.4f' % avg_http} s\n"
	file.puts "Average Demo-app Delay:   #{'%.2f' % avg_demo} ms\n"
	file.puts "Average Reel server time: #{'%.4f' % avg_reel} s"
end



