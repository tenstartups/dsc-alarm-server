require 'json'
require 'sinatra/base'

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
      ENV['IT100_REST_SERVER_BIND_ADDRESS'] || '0.0.0.0'
    end

    def bind_port
      ENV['IT100_REST_SERVER_PORT'] || 8080
    end

    private

    def thread_ready
      JSON.parse(RestClient.get("http://#{bind_address}:#{bind_port}/start_check"))['status'] == 'ok'
    rescue Exception => e
      false
    end
  end

  class SinatraApp < Sinatra::Base
    set :server, :thin

    configure do
      set :environment, 'production'
      set :bind, IT100RestServer.instance.bind_address
      set :port, IT100RestServer.instance.bind_port
      set :run, true
      set :threaded, false
      set :traps, false
    end

    get '/start_check' do
      { status: 'ok' }.to_json
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
end
