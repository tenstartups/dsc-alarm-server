require 'sinatra/base'
require 'thin'

class IT100RestServer
  include Singleton

  def start!
    Thin::Server.start SinatraApp,
                       ENV['IT100_REST_SERVER_BIND_ADDRESS'] || '0.0.0.0',
                       ENV['IT100_REST_SERVER_PORT'] || 4567
  end
end

class SinatraApp < Sinatra::Base
  configure do
    set :threaded, false
  end

  get '/status' do
    IT100SocketClient.instance.status
  end

  get '/labels' do
    IT100SocketClient.instance.labels
  end

  post '/set_datetime' do
    IT100SocketClient.instance.set_datetime
  end

  post '/arm_away' do
    IT100SocketClient.instance.arm_away(partition: params['partition'])
  end

  post '/arm_stay' do
    IT100SocketClient.instance.arm_stay(partition: params['partition'])
  end

  post '/arm' do
    IT100SocketClient.instance.arm(partition: params['partition'], code: params['code'])
  end

  post '/disarm' do
    IT100SocketClient.instance.disarm(partition: params['partition'], code: params['code'])
  end

  post '/key_press' do
    IT100SocketClient.instance.key_press(key: params['keys'])
  end

  post '/acknowledge_trouble' do
    IT100SocketClient.instance.acknowledge_trouble
  end
end
