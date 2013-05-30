# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
require 'faye'
require ::File.expand_path("../lib/terminal_users.rb",  __FILE__)
require ::File.expand_path("../lib/process_incoming.rb",  __FILE__)

faye_server = Faye::RackAdapter.new(:mount => "/faye", :timeout => 5)
faye_server.add_extension(ProcessIncoming.new)

# TODO send pull request to faye to get this fixed
# by adding a rack_prefix option
# which should then make the faye server object available
# via the get_client() method on the server

FAYE_CLIENT = faye_server.get_client

#faye_server.bind(:unsubscribe) do |client_id|
#  ActiveUsers.remove_by_client_id(client_id)
#end

run Rack::URLMap.new({
    "/remote"  => faye_server,
    "/"      => TerminalCodelearn::Application
  })

# run Kandan::Application
