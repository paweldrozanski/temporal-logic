require 'sinatra'
require 'haml'

get '/' do
  erb :index
end

get '/hello/:name' do |n|
  "Hello #{n}!"
end

get '/my_template' do
  @weather = "sunny"
  @temperature = 80
  haml :weather
end
