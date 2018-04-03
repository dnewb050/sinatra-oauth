require 'sinatra/base'
require 'sinatra/activerecord'
require 'dotenv'
Dotenv.load

class Application < Sinatra::Base
  get '/' do
    'Hello World!'
  end
end
