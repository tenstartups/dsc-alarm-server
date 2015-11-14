require 'io'
require 'singleton'
require 'socket'
require 'stringio'

class IT100SocketClient
  include Singleton

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

  def arm_away(partition: 1, no_entry_delay: false)
    partition = 1 if partition.nil? || partition.length == 0
    send_command "#{no_entry_delay ? '032' : '030'}#{partition}"
  end

  def arm_stay(partition: 1)
    partition = 1 if partition.nil? || partition.length == 0
    send_command "031#{partition}"
  end

  def arm(partition: 1, code:)
    partition = 1 if partition.nil? || partition.length == 0
    send_command "033#{partition}#{('%-6s' % code)[0..5].tr(' ', '0')}"
  end

  def disarm(partition: 1, code:)
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

  def event_loop!
    while (line = it100_socket.gets)
      event = DSCEvent.new(line.chop)
      event_subscriptions.each { |s| s.push(event) } if event.valid_checksum?
    end
  end

  def subscribe_events(queue)
    event_subscriptions << queue
  end

  private

  def it100_socket
    @it100_socket ||= TCPSocket.new(it100_uri.host, it100_uri.port)
  end

  def it100_uri
    @it100_uri ||= URI(ENV['IT100_URI'] && ENV['IT100_URI'].length > 0 ? ENV['IT100_URI'] : 'tcp://localhost:3000')
  end

  def event_subscriptions
    @event_subscriptions ||= []
  end

  def send_command(*commands)
    command = DSCCommand.new(*commands)
    result = { command: command.message }
    puts "Sending DSC command - #{command.message.inspect}"
    it100_socket.write(command.message)
    # while (line = it100_socket.readline_nonblock).length > 0
    #   event = DSCEvent.new(line)
    #   (result[:response] ||= []) << event.as_json
    #   puts "Response received - #{event.as_json.to_json}" if event.valid_checksum?
    # end
    result.to_json
  end
end
