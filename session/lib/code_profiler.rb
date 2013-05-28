require 'ruby-prof'

module CodeProfiler
	
	# config variable for enabling/disabling log. To disable profile logger, set PROFILE_LOGGER_STATUS = false
	PROFILE_LOGGER_STATUS = true

	def self.profile_logger_enabled?
		PROFILE_LOGGER_STATUS
	end

	
	# profile logger. As of now, it will log the records inside performance/hande-request-graph.txt file
	def self.profile_logger(file_name, start_time,request_url)
		RubyProf.measure_mode = RubyProf::WALL_TIME		
		RubyProf.start
			yield
		results = RubyProf.stop

		end_time = Time.now

		profile_type = "flat"

		File.open "../performance/#{file_name}-#{profile_type}.txt", 'w+' do |file|
			RubyProf::FlatPrinterWithLineNumbers.new(results).print(file)
		end

		record_time_and_url(file_name,"flat",start_time, end_time, request_url)
	end	

	# Method for recording the time and url
	def self.record_time_and_url(file_name,profile_type,start_time,end_time, request_url)		
		File.open "../../execute.txt", 'a+' do |file|
			file.puts "	Reel Server: #{end_time - start_time}\nURL: #{request_url}\n\n"
		end
	end
	

end
