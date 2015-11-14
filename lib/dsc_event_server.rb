require 'awesome_print'
require 'colorize'
require 'dsc_command'
require 'dsc_event'
require 'isy_rest_client'
require 'it100_socket'
require 'json'
require 'nokogiri'
require 'rest_api_server'
require 'yaml'

class DSCEventServer
  def self.start!
    DSCEventServer.new.start!
  end

  def start!
    start_event_listener
    start_event_processor
    start_api_server
  end

  def dsc_command
    @dsc_command ||= DSCCommand.new
  end

  def isy994_uri
    @isy994_uri ||= ENV['ISY994_URI']
  end

  def isy_rest_client
    @isy_rest_client ||= ISYRestClient.new(isy994_uri, config['dsc_event'] || {})
  end

  def event_queue
    @event_queue ||= Queue.new
  end

  private

  def initialize
  end

  def config
    return @config unless @config.nil?
    @config = File.exist?(ENV['DSC_ISY_CONFIG'] || '') ? YAML.load_file(ENV['DSC_ISY_CONFIG']) : {}
    @config.tap do |conf|
      if (dsc_event_conf = conf['dsc_event']).keys
        dsc_event_conf.keys.each do |event|
          dsc_event_conf[event] = [dsc_event_conf[event]] unless dsc_event_conf[event].is_a?(Array)
        end
      end
    end
  end

  def start_event_listener
    dsc_command.status
    Thread.new do
      while (line = IT100Socket.instance.gets)
        event = DSCEvent.new(line.chop)
        event_queue.push(event) if event.valid_checksum?
      end
    end
  end

  def start_event_processor
    Thread.new do
      loop do
        until event_queue.empty?
          event = event_queue.pop
          puts "Event received - #{event.as_json.to_json}"
          event.set_isy_state(isy_rest_client)
        end
        sleep 0.1
      end
    end
  end

  def start_api_server
    RestApiServer.run!
  end
end
