require 'active_support'
require 'active_support/core_ext'
require 'awesome_print'
require 'colorize'
require 'dsc_command'
require 'dsc_event'
require 'isy_rest_client'
require 'json'
require 'nokogiri'
require 'socket'
require 'yaml'

class DSCISYBridge
  def start
    load_config
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
    @isy_rest_client ||= ISYRestClient.new(isy994_uri)
  end

  def event_queue
    @event_queue ||= Queue.new
  end

  def wait_on_threads
    @event_listen_thread.join
    @event_process_thread.join
  end

  private

  def load_config
    @config = YAML.load_file(ENV['DSC_ISY_BRIDGE_CONFIG'])
  end

  def listen_events
    dsc_command.set_datetime
    dsc_command.request_status
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
            isy_rest_client.set_state_variable(@config['dsc_status']["zone_#{event.data.to_i}"], 1)
          when '610' # Zone restored
            isy_rest_client.set_state_variable(@config['dsc_status']["zone_#{event.data.to_i}"], 0)
          when '626' # System is ready
            isy_rest_client.set_state_variable(@config['dsc_status']['system_ready'], 1)
          when '651' # System is not ready
            isy_rest_client.set_state_variable(@config['dsc_status']['system_ready'], 0)
          when '652' # System armed (stay or away)
            isy_rest_client.set_state_variable(@config['dsc_status']['system_ready'], 0)
            isy_rest_client.set_state_variable(@config['dsc_status']['system_disarmed'], 0)
            isy_rest_client.set_state_variable(@config['dsc_status']['armed_stay'], event.data =~ /[1-8](1|3)/ ? 1 : 0)
            isy_rest_client.set_state_variable(@config['dsc_status']['armed_away'], event.data =~ /[1-8](2|4)/ ? 1 : 0)
          when '655' # System disarmed
            isy_rest_client.set_state_variable(@config['dsc_status']['armed_stay'], 0)
            isy_rest_client.set_state_variable(@config['dsc_status']['armed_away'], 0)
            isy_rest_client.set_state_variable(@config['dsc_status']['system_disarmed'], 1)
            isy_rest_client.set_state_variable(@config['dsc_status']['entry_delay'], 0)
            isy_rest_client.set_state_variable(@config['dsc_status']['exit_delay'], 0)
          when '656' # Exit delay started
            isy_rest_client.set_state_variable(@config['dsc_status']['exit_delay'], 1)
          when '657' # Entry delay started
            isy_rest_client.set_state_variable(@config['dsc_status']['entry_delay'], 1)
          when '700', '701' # Exit delay ended (armed)
            isy_rest_client.set_state_variable(@config['dsc_status']['exit_delay'], 0)
          when '840' # Panel trouble started
            isy_rest_client.set_state_variable(@config['dsc_status']['panel_trouble'], 1)
          when '841' # Panel trouble ended
            isy_rest_client.set_state_variable(@config['dsc_status']['panel_trouble'], 0)
          end
        end
        sleep 0.1
      end
    end
  end
end
