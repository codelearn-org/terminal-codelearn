require 'curb'
require 'net/ftp'

method = "http://localhost:3000/terminals/0/execute?command="
commands = ["ps","cd+..","ls","pwd","cal","df","id","uptime"]
times = []

commands.each do |command|
	url = method + command

	start_time = Time.now
		Curl.get(url)
	end_time = Time.now

 	times << end_time - start_time
end

Net::FTP.open('localhost','saasbook','saasbook') do |ftp|
	ftp.chdir('terminal-codelearn')
  ftp.gettextfile('execute.txt', 'initial.txt')
end

i=1
File.open("final.txt", 'a+') do |file|
	File.open("initial.txt", 'r').each do |line|
		if((i-2)%4==0)
				file.puts "	Script Time: #{times[(i-2)/4]}\n"
		end
		file.puts line		
		i = i.next
	end
end
