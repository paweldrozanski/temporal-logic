require 'rubygems'
require 'sinatra'
require 'haml'
 
# Handle GET-request (Show the upload form)
get "/upload" do
  haml :upload
end      
 
# Handle POST-request (Receive and save the uploaded file)
post "/upload" do
  File.open('uploads/' + params['myfile'][:filename], "w") do |f|
    f.write(params['myfile'][:tempfile].read)
  end
  return "The file was successfully uploaded!"
end