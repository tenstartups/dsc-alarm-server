require 'securerandom'
require 'singleton'
require 'socket'
require 'timeout'

class IT100SocketClient
  include Singleton
  include LoggingHelper

  def initialize
    @subscribers = {}
  end

  def poll
    send_command '000'
  end

  def status
    send_command '001'
  end

  def labels
    send_command '002'
  end

  def set_datetime(datetime: nil)
    datetime = Time.now if datetime.nil? || datetime.length == 0
    send_command "010#{datetime.strftime('%H%M%m%d%y')}"
  end

  def output_control(partition: nil, program: nil)
    partition = 1 if partition.nil? || partition.length == 0
    program = 1 if program.nil? || program.length == 0
    send_command "020#{partition}#{program}"
  end

  def arm_away(partition: nil, no_entry_delay: false)
    partition = 1 if partition.nil? || partition.length == 0
    send_command "#{no_entry_delay ? '032' : '030'}#{partition}"
  end

  def arm_stay(partition: nil)
    partition = 1 if partition.nil? || partition.length == 0
    send_command "031#{partition}"
  end

  def arm(partition: nil, code:)
    partition = 1 if partition.nil? || partition.length == 0
    send_command "033#{partition}#{('%-6s' % code)[0..5].tr(' ', '0')}"
  end

  def disarm(partition: nil, code:)
    partition = 1 if partition.nil? || partition.length == 0
    send_command "040#{partition}#{('%-6s' % code)[0..5].tr(' ', '0')}"
  end

  def timestamp_control(on: false)
    send_command "055#{on ? 1 : 0}"
  end

  def datetime_broadcast(on: false)
    send_command "056#{on ? 1 : 0}"
  end

  def code_send(code:)
    send_command "200#{('%-6s' % code)[0..5].tr(' ', '0')}"
  end

  def key_press(keys:)
    send_command(*keys.chars.map { |k| "070#{k}" })
  end

  # Complex commands
  def acknowledge_trouble
    key_press keys: '*2#'
  end

  def start!
    loop do
      while (line = it100_socket.readline_nonblock).length > 0
        event = DSCResponseCommand.new(line)
        @subscribers.values.each { |q| q.push(event) } if event.valid_checksum?
      end
      sleep 0.01
    end
  end

  def subscribe_events
    id = SecureRandom.hex
    @subscribers[id] = Queue.new
    id
  end

  def unsubscribe_events(id)
    @subscribers.delete(id)
    id
  end

  def next_event(id)
    @subscribers[id].pop if @subscribers[id].length > 0
  end

  private

  def it100_socket
    @it100_socket ||= TCPSocket.new(it100_uri.host, it100_uri.port)
  end

  def it100_uri
    @it100_uri ||= URI(ENV['IT100_URI'] && ENV['IT100_URI'].length > 0 ? ENV['IT100_URI'] : 'tcp://localhost:3000')
  end

  def send_command(*commands)
    command = DSCRequestCommand.new(*commands)
    result = { command: command.message }
    sub_id = subscribe_events
    log "Sending command : #{command.message.inspect}"
    it100_socket.write(command.message)
    loop do
      begin
        timeout(2) do
          sleep 0.01 while (event = IT100SocketClient.instance.next_event(sub_id)).nil?
          (result[:response] ||= []) << event.as_json
        end
      rescue Timeout::Error
        break
      end
    end
    result.to_json
  ensure
    unsubscribe_events(sub_id)
  end
end
