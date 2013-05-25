class TerminalsController < ApplicationController
	
  def current_user
	  `echo $USER`.strip
  end

  def index
  end

  def get
	  http = Curl.get("http://localhost:3001/#{current_user}/#{params[:terminal_id]}/get")
	  render :json => http.body_str
  end

  def execute
		beginning = Time.now

			url = "http://localhost:3001/#{current_user}/#{params[:terminal_id]}/execute/#{params[:command].nil? ? "" : CGI::escape(params[:command])}" 
			puts url
			http = Curl.get(url)
			render :json => http.body_str
		
		end_time = Time.now

		File.open "../execute.txt", 'a+' do |file|
			file.puts "URL: #{url}\n	Demo-app: 	 #{end_time - beginning}\n"
		end

	end

  def kill
	  http = Curl.get("http://localhost:3001/#{current_user}/#{params[:terminal_id]}/kill")
	  render :json => http.body_str
  end

  def reset
	  http = Curl.get("http://localhost:3001/#{current_user}/#{params[:terminal_id]}/reset")
	  render :json => http.body_str
  end

end
