require 'awesome_print'
require 'colorize'
require 'dsc_command'
require 'dsc_event'
require 'isy_rest_client'
require 'json'
require 'nokogiri'
require 'socket'
require 'yaml'

class DSCISYEventServer
  def start
    listen_events
    process_events
    wait_on_threads
  end

  def it100_uri
    @it100_uri ||= URI(ENV['IT100_URI'])
  end

  def it100_socket
    @it100_socket ||= TCPSocket.open(it100_uri.host, it100_uri.port)
  end

  def dsc_command
    @dsc_command ||= DSCCommand.new(it100_socket)
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

  def wait_on_threads
    @event_listen_thread.join
    @event_process_thread.join
  end

  private

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

  def listen_events
    dsc_command.status
    @event_listen_thread = Thread.new do
      while (line = it100_socket.gets)
        event = DSCEvent.new(line.chop)
        event_queue.push(event) if event.valid_checksum?
      end
    end
  end

  def process_events
    @event_process_thread = Thread.new do
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
end
