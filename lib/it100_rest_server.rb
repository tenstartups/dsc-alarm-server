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
      JSON.pretty_generate(status: 'ok')
    end

    get '/poll' do
      run_command :poll, pretty: params['pretty']
    end

    get '/status' do
      run_command :status, pretty: params['pretty']
    end

    get '/labels' do
      run_command :labels, pretty: params['pretty']
    end

    post '/set_datetime' do
      run_command :set_datetime, pretty: params['pretty']
    end

    post '/arm_away' do
      run_command :arm_away, partition: params['partition'], pretty: params['pretty']
    end

    post '/arm_stay' do
      run_command :arm_stay, partition: params['partition'], pretty: params['pretty']
    end

    post '/arm' do
      run_command :arm, partition: params['partition'], code: params['code'], pretty: params['pretty']
    end

    post '/disarm' do
      run_command :disarm, partition: params['partition'], code: params['code'], pretty: params['pretty']
    end

    post '/key_press' do
      run_command :key_press, key: params['keys'], pretty: params['pretty']
    end

    post '/acknowledge_trouble' do
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
