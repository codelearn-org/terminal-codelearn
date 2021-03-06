require 'selenium-webdriver'
require 'test/unit'

class TerminalTests < Test::Unit::TestCase
    def setup
      # create selenium objects
		@driver = Selenium::WebDriver.for :firefox
		@driver.navigate.to 'http://localhost:1134/test_client.html'
		@wait = Selenium::WebDriver::Wait.new :timeout => 4

		#output pre element and input Box		
		@output = @driver.find_element(:id, 'output')
		@input = @driver.find_element(:name, 'command')

		#buttons
		@execute = @driver.find_element(:id, 'execute')
		@reset = @driver.find_element(:id, 'reset')
		@kill = @driver.find_element(:id, 'kill')
		
		@wait.until {@execute.enabled?}		
	end
		
	#clear the pre element
	def clear_output
		@driver.execute_script("document.getElementById('output').innerHTML = ''")
	end

	def test_whoami

		@input.send_keys("whoami")
		@execute.click

		@wait.until {@execute.enabled?}		
		user = `whoami`.strip	

		result = @output.text.split("\n")[1]
		assert(result[/#{user}/],"Output does not contain '#{user}' when command 'whoami' is executed")
	end

	def test_kill_process

		command = "sleep 100"

		@input.send_keys("#{command}")
		@execute.click
		
		sleep 0.1

		#check if sleep 100 has been started		
		result = `ps -ef | grep 'sleep 100' | awk '{print $8"\s"$9}'`
		result = result.split("\n")[0]

		assert(result[/#{command}/],"Sleep 100 did not start")

		@kill.click
		
		@wait.until {@execute.enabled?}

		#check if sleep 100 has been killed	
		result = `ps -ef | grep 'sleep 100' | awk '{print $8"\s"$9}'`
		result = result.split("\n")[0]

		assert(!result[/#{command}/],"Sleep 100 was not killed")
	end

	def test_reset

		@input.send_keys("echo $$")
		@execute.click
		
		@wait.until {@execute.enabled?}
		result = @output.text

		#find the process id first time		
		pid1 = result.split("\n")[1]

		@reset.click

		@wait.until {@execute.enabled?}		

		@input.send_keys("echo $$")
		@execute.click

		@wait.until {@execute.enabled?}
		result = @output.text

		#find the process id second time
		pid2 = result.split("\n")[1]

		assert(pid2 != pid1,"Process after reset is same")
	end

	def teardown
		@driver.quit  
	end

end
