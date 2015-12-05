require 'json'
require 'sinatra/base'
require 'configuration'

module DSCConnect
  class IT100RestServer
    include WorkerThreadBase

    def do_work
      SinatraApp.run!
    end

    def quit!
      SinatraApp.quit!
      super
    end

    def bind_address
      Configuration.instance.rest_server.try(:bind_address) || '0.0.0.0'
    end

    def bind_port
      Configuration.instance.rest_server.try(:bind_port) || 8080
    end

    private

    def thread_ready
      JSON.parse(RestClient.get("http://#{bind_address}:#{bind_port}/start_check"))['status'] == 'ok'
    rescue Exception => e
      false
    end
  end

  class SinatraApp < Sinatra::Base
    set :server, :puma

    configure do
      set :environment, 'production'
      set :bind, IT100RestServer.instance.bind_address
      set :port, IT100RestServer.instance.bind_port
      set :run, true
      set :threaded, false
      set :traps, false
    end

    get '/start_check' do
      content_type :json
      { status: 'ok' }.to_json
    end

    get '/poll' do
      content_type :json
      run_command :poll, pretty: params['pretty']
    end

    get '/status' do
      content_type :json
      run_command :status, pretty: params['pretty']
    end

    get '/labels' do
      content_type :json
      run_command :labels, pretty: params['pretty']
    end

    post '/set_datetime' do
      content_type :json
      run_command :set_datetime, pretty: params['pretty']
    end

    post '/arm_away' do
      content_type :json
      run_command :arm_away, partition: params['partition'], pretty: params['pretty']
    end

    post '/arm_stay' do
      content_type :json
      run_command :arm_stay, partition: params['partition'], pretty: params['pretty']
    end

    post '/arm' do
      content_type :json
      run_command :arm, partition: params['partition'], code: params['code'], pretty: params['pretty']
    end

    post '/disarm' do
      content_type :json
      run_command :disarm, partition: params['partition'], code: params['code'], pretty: params['pretty']
    end

    post '/key_press' do
      content_type :json
      run_command :key_press, key: params['keys'], pretty: params['pretty']
    end

    post '/acknowledge_trouble' do
      content_type :json
      run_command :acknowledge_trouble, pretty: params['pretty']
    end

    private

    def run_command(slug, **params)
      pretty = (params.delete(:pretty) || 'false').downcase == 'true'
      result = if params.keys.empty?
                 IT100SocketClient.instance.send(slug)
               else
                 IT100SocketClient.instance.send(slug, **params)
               end
      pretty ? JSON.pretty_generate(result) : result.to_json
    end
  end
end
