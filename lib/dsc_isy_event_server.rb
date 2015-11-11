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
    @dsc_command ||= DSCCommand.new(socket: it100_socket)
  end

  def isy994_uri
    @isy994_uri ||= ENV['ISY994_URI']
  end

  def isy_rest_client
    @isy_rest_client ||= ISYRestClient.new(isy994_uri, config['dsc_status'])
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
    @config ||= YAML.load_file(ENV['DSC_ISY_CONFIG'])
  end

  def listen_events
    dsc_command.status_request
    @event_listen_thread = Thread.new do
      while (line = it100_socket.gets)
        event = DSCEvent.new(line.chop)
        event_queue.push(event) if event.valid?
      end
    end
  end

  def process_events
    @event_process_thread = Thread.new do
      loop do
        until event_queue.empty?
          event = event_queue.pop
          puts event
          case event.command
          when '609' # Zone opened
            isy_rest_client.set_state("zone_#{event.data.to_i}", 1)
          when '610' # Zone restored
            isy_rest_client.set_state("zone_#{event.data.to_i}", 0)
          when '625' # Panic alarm
            isy_rest_client.set_state('panic_alarm', 1)
          when '626'
            if event.data[0] == 0 # Panic alarm restored
              isy_rest_client.set_state('panic_alarm', 0)
            else # System ready
              isy_rest_client.set_state('sytem_ready', 1)
            end
          when '631' # Auxiliary alarm
            isy_rest_client.set_state('aux_alarm', 1)
          when '632' # Auxiliary alarm restored
            isy_rest_client.set_state('aux_alarm', 0)
          when '651' # System is not ready
            isy_rest_client.set_state('system_ready', 0)
          when '652' # System armed (stay or away)
            isy_rest_client.set_state('system_ready', 0)
            isy_rest_client.set_state('system_disarmed', 0)
            isy_rest_client.set_state('armed_away', event.data =~ /[1-8](0|2)/ ? 1 : 0)
            isy_rest_client.set_state('armed_stay', event.data =~ /[1-8](1|3)/ ? 1 : 0)
          when '654' # System alarmed
            isy_rest_client.set_state('system_alarmed', 1)
          when '655' # System disarmed
            isy_rest_client.set_state('armed_stay', 0)
            isy_rest_client.set_state('armed_away', 0)
            isy_rest_client.set_state('system_disarmed', 1)
            isy_rest_client.set_state('entry_delay', 0)
            isy_rest_client.set_state('exit_delay', 0)
          when '656' # Exit delay started
            isy_rest_client.set_state('exit_delay', 1)
          when '657' # Entry delay started
            isy_rest_client.set_state('entry_delay', 1)
          when '700', '701' # Exit delay ended (armed)
            isy_rest_client.set_state('exit_delay', 0)
          when '840' # Panel trouble started
            isy_rest_client.set_state('panel_trouble', 1)
          when '841' # Panel trouble ended
            isy_rest_client.set_state('panel_trouble', 0)
          when '842' # Fire alarm
            isy_rest_client.set_state('fire_alarm', 1)
          when '843' # Fire alarm restored
            isy_rest_client.set_state('fire_alarm', 0)
          end
        end
        sleep 0.1
      end
    end
  end
end
