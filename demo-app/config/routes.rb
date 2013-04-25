TerminalCodelearn::Application.routes.draw do
  root :to => "terminals#index" 
  match "terminals/:terminal_id/get" => "terminals#get"
  match "terminals/:terminal_id/execute" => "terminals#execute"
  match "terminals/:terminal_id/kill" => "terminals#kill"
  match "terminals/:terminal_id/reset" => "terminals#reset"
end
