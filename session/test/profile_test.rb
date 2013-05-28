class Profiler
  
 def self.profile(*names)
    names.each do |name|
			puts name      
			m = instance_method(name)
			puts m
      define_method(name) do |*args, &block|  
	  	puts "profile start"
        m.bind(self).(*args, &block)
		puts "profile end"
      end
    end
  end


end

class SomeArbitClass < Profiler #Every class need to be made subclass of Profiler. So this is 1 line change per class definition

	def some_function
		return "some execution here"
	end
		
	def another_function
		return puts "another execution here"
	end
  	
	profile(*(instance_methods - Class.instance_methods)) #or give names of the functions that need to be profiled . Only this line need to be added to all the classes
end

a = SomeArbitClass.new
puts a.some_function

