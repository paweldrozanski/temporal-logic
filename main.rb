require 'rubygems'
require 'sinatra'
require 'haml'
load "testy.rb"

set :environment, :development 

get '/' do
  haml :ask
end

post '/formula' do
  @formula = params["formula"]
  rnode = make_and_paint(@formula)
  # @br = add_color_tags(branches(rnode))
  @br = branches(rnode)
  haml :formula
end

post '/notformula' do
	form1 = Formula_Generator.new
	formula = form1.recurse_formula(4)
	rnode = make_and_paint(formula)
	@br = branches(rnode)
  @formula = formula
  haml :notformula
end

get '/tests' do
  haml :tests
end