require 'json'
require 'sinatra/base'
require 'thin'

class RestApiServer < Sinatra::Base
  def dsc_command
    @dsc_command ||= DSCCommand.new(false)
  end

  get '/status' do
    dsc_command.status
    { status: 'ok' }.to_json
  end

  get '/labels' do
    dsc_command.labels
    { status: 'ok' }.to_json
  end

  post '/set_datetime' do
    dsc_command.set_datetime
    { status: 'ok' }.to_json
  end

  post '/arm_away' do
    dsc_command.arm_away(partition: params['partition'])
    { status: 'ok' }.to_json
  end

  post '/arm_stay' do
    dsc_command.arm_stay(partition: params['partition'])
    { status: 'ok' }.to_json
  end

  post '/arm' do
    dsc_command.arm(partition: params['partition'], code: params['code'])
    { status: 'ok' }.to_json
  end

  post '/disarm' do
    dsc_command.disarm(partition: params['partition'], code: params['code'])
    { status: 'ok' }.to_json
  end

  post '/key_press' do
    dsc_command.key_press(key: params['key'])
    { status: 'ok' }.to_json
  end

  post '/acknowledge_trouble' do
    dsc_command.acknowledge_trouble
    { status: 'ok' }.to_json
  end
end
