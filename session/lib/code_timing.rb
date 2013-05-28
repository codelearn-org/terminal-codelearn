class Profiler
  
	def self.profile(*names)
		names.each do |name|
			m = instance_method(name)
			define_method(name) do |*args, &block|
				start = Time.now
				m.bind(self).(*args, &block)
				end_time = Time.now
				File.open "../../execute.txt", 'a+' do |file|
					file.puts "		#{name} : #{end_time - start}"
				end
			end
		end
	end

end
