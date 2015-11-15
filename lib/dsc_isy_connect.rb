require 'awesome_print'
require 'colorize'
require 'json'
require 'nokogiri'
require 'yaml'

require 'dsc_command'
require 'dsc_event'
require 'isy994_rest_client'
require 'it100_rest_server'
require 'it100_socket_client'

class DSCISYConnect
  include Singleton

  def start_server!
    ISY994RestClient.instance.check_missing_variables(
      config['dsc_event'].values
            .reduce([]) { |a, e| a.concat(e) }
            .map { |e| e['isy_state'] }
            .reduce([]) { |a, e| a.concat(e.keys) }
            .uniq
            .sort
    )

    puts 'Starting individual processing threads'.colorize(:yellow)
    @threads = []
    @threads << start_rest_server
    @threads << start_event_processor
    @threads << start_event_listener

    # Wait for every thread to initialize
    sleep(5)

    # Trap CTRL-C
    Signal.trap('INT') do
      puts "\nCTRL-C detected, waiting for all threads to exit gracefully...".colorize(:yellow)
      @threads.each(&:kill)
      exit 0
    end

    # Trap SIGTERM
    Signal.trap('TERM') do
      puts "\nKill detected, waiting for all threads to exit gracefully...".colorize(:yellow)
      @threads.each(&:kill)
      exit 1
    end

    puts 'Finished starting individual threads'.colorize(:green)
    @threads.each(&:join)
  end

  def event_queue
    @event_queue ||= Queue.new
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

  def start_rest_server
    Thread.new { IT100RestServer.run! }
  end

  def start_event_listener
    Thread.new do
      IT100SocketClient.instance.status
      IT100SocketClient.instance.event_loop!
    end
  end

  def start_event_processor
    Thread.new do
      IT100SocketClient.instance.subscribe_events(event_queue)
      loop do
        until (event = event_queue.pop).nil?
          (config['dsc_event'][event.slug] || []).each do |defn|
            if defn['condition'].nil? || defn['condition'].all? { |k, v| event.send(k) == v }
              defn['isy_state'].each do |var, val|
                ISY994RestClient.instance.set_state(var, val)
              end
            end
          end
        end
        sleep 0.1
      end
    end
  end
end
