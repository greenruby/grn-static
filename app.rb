$LOAD_PATH << File.expand_path('../lib',__FILE__)

require 'sinatra/base'
class App < Sinatra::Base

  get '/' do
    '{ "status": "ok"}'
  end

end