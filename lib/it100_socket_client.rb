require 'securerandom'
require 'singleton'
require 'socket'
require 'timeout'

class IT100SocketClient
  include Singleton
  include LoggingHelper

  attr_reader :started

  def initialize
    @subscribers = {}
  end

  %i[ poll status labels ].each do |method_name|
    define_method method_name do
      send_command method_name
    end
  end

  def set_datetime(datetime: nil)
    datetime = Time.now if datetime.nil? || datetime.length == 0
    send_command __method__, datetime: datetime.strftime('%H%M%m%d%y')
  end

  def output_control(partition: nil, program: nil)
    partition = 1 if partition.nil? || partition.length == 0
    program = 1 if program.nil? || program.length == 0
    send_command __method__, partition: partition, program: program
  end

  def arm_away(partition: nil, no_entry_delay: false)
    partition = 1 if partition.nil? || partition.length == 0
    send_command __method__, partition: partition
  end

  def arm_stay(partition: nil)
    partition = 1 if partition.nil? || partition.length == 0
    send_command __method__, partition: partition
  end

  def arm(partition: nil, code:)
    partition = 1 if partition.nil? || partition.length == 0
    send_command __method__, partition: partition, code: ('%-6s' % code)[0..5].tr(' ', '0')
  end

  def disarm(partition: nil, code:)
    partition = 1 if partition.nil? || partition.length == 0
    send_command __method__, partition: partition, code: ('%-6s' % code)[0..5].tr(' ', '0')
  end

  def timestamp_control(on: false)
    send_command __method__, on_off: on ? 1 : 0
  end

  def datetime_broadcast(on: false)
    send_command __method__, on_off: on ? 1 : 0
  end

  def code_send(code:)
    send_command __method__, code: ('%-6s' % code)[0..5].tr(' ', '0')
  end

  def key_press(keys:)
    keys.chars.map do |ch|
      send_command __method__, key: ch
    end
  end

  # Complex commands
  def acknowledge_trouble
    key_press keys: '*2#'
  end

  def start!
    debug 'Entering processing loop'
    @started = true
    until @loop_exit
      while (line = it100_socket.readline_nonblock).length > 0
        event = DSCResponseCommand.new(line)
        @subscribers.values.each { |q| q.push(event) } if event.valid_checksum?
      end
      sleep 0.01
    end
    debug 'Exiting processing loop'
  end

  def exit!
    @loop_exit = true
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
    return @it100_uri unless @it100_uri.nil?
    uri = ENV['IT100_URI'] && ENV['IT100_URI'].length > 0 ? ENV['IT100_URI'] : 'tcp://localhost:3000'
    uri = "tcp://#{uri}" unless uri =~ /^[A-Za-z]+:\/\//
    @it100_uri ||= URI(uri)
  end

  def send_command(slug, **data)
    command = DSCRequestCommand.new(slug, data)
    result = { request: command.as_json }
    sub_id = subscribe_events
    log "Sending command : #{command.as_json.to_json}"
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
    result
  ensure
    unsubscribe_events(sub_id)
  end
end
