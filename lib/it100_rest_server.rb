require 'singleton'
require 'sinatra/base'

class IT100RestServer
  include Singleton
  include LoggingHelper

  attr_reader :started

  def start!
    debug 'Entering processing loop'
    @started = true
    SinatraApp.run!
    debug 'Exiting processing loop'
  end

  def exit!
    SinatraApp.quit!
  end
end

class SinatraApp < Sinatra::Base
  configure do
    set :environment, 'production'
    set :bind, ENV['IT100_REST_SERVER_BIND_ADDRESS'] || '0.0.0.0'
    set :port, ENV['IT100_REST_SERVER_PORT'] || 4567
    set :run, true
    set :threaded, false
    set :traps, false
  end

  get '/poll' do
    IT100SocketClient.instance.poll.to_json
  end

  get '/status' do
    IT100SocketClient.instance.status.to_json
  end

  get '/labels' do
    IT100SocketClient.instance.labels.to_json
  end

  post '/set_datetime' do
    IT100SocketClient.instance.set_datetime.to_json
  end

  post '/arm_away' do
    IT100SocketClient.instance.arm_away(partition: params['partition']).to_json
  end

  post '/arm_stay' do
    IT100SocketClient.instance.arm_stay(partition: params['partition']).to_json
  end

  post '/arm' do
    IT100SocketClient.instance.arm(partition: params['partition'], code: params['code']).to_json
  end

  post '/disarm' do
    IT100SocketClient.instance.disarm(partition: params['partition'], code: params['code']).to_json
  end

  post '/key_press' do
    IT100SocketClient.instance.key_press(key: params['keys']).to_json
  end

  post '/acknowledge_trouble' do
    IT100SocketClient.instance.acknowledge_trouble.to_json
  end
end
