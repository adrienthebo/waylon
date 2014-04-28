require 'sinatra'

class Waylon < Sinatra::Application
  get '/' do
    erb :index
  end
end
