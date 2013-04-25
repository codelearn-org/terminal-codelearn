require "benchmark"
require "curb"

user = `echo $USER`.strip
port = "3000"
url_base = "http://localhost:#{port}/#{user}/0/"
commands_to_test = ["ls", "whoami", "grep my.cnf -r .", "rails new test_app"]
supported_urls = ["get", "execute", "kill", "reset"]
no_of_calls_to_make = 15

urls_to_execute = commands_to_test.inject([]) {|array, cmd| array << url_base + "execute/" + cmd }
get_url = url_base + "get"
kill_url = url_base + "kill"
reset_url = url_base + "reset"

#lets call apis in this order get,execute,reset,kill
order_of_execution = [get_url, urls_to_execute, reset_url, kill_url]

Benchmark.benchmark do |x|
  no_of_calls_to_make.times do |i|
    #take i % 4 and execute that perticular command in order_of_execution list 
    url_to_fetch = order_of_execution[i%4]
    #shift the urls in urls_to_execute list one by one
    url_to_fetch = url_to_fetch.is_a?(Array) ? url_to_fetch.shift : url_to_fetch
    x.report { Curl.get(url_to_fetch) }
  end
end
