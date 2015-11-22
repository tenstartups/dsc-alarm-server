require 'securerandom'
require 'singleton'
require 'socket'
require 'timeout'

module DSCConnect
  class IT100SocketClient
    include Singleton
    include LoggingHelper

    def initialize
      @subscribers = {}
    end

    %i[ poll status labels ].each do |method_name|
      define_method method_name do
        send_command IT100RequestCommand.new(method_name)
      end
    end

    def set_datetime(datetime: nil)
      datetime = Time.now if datetime.nil? || datetime.length == 0
      send_command IT100RequestCommand.new(__method__, datetime: datetime.strftime('%H%M%m%d%y'))
    end

    def output_control(partition: nil, program: nil)
      partition = 1 if partition.nil? || partition.length == 0
      program = 1 if program.nil? || program.length == 0
      send_command IT100RequestCommand.new(__method__, partition: partition, program: program)
    end

    def arm_away(partition: nil, no_entry_delay: false)
      partition = 1 if partition.nil? || partition.length == 0
      send_command IT100RequestCommand.new(__method__, partition: partition)
    end

    def arm_stay(partition: nil)
      partition = 1 if partition.nil? || partition.length == 0
      send_command IT100RequestCommand.new(__method__, partition: partition)
    end

    def arm(partition: nil, code:)
      partition = 1 if partition.nil? || partition.length == 0
      send_command IT100RequestCommand.new(__method__,
                                           partition: partition,
                                           code: ('%-6s' % code)[0..5].tr(' ', '0'))
    end

    def disarm(partition: nil, code:)
      partition = 1 if partition.nil? || partition.length == 0
      send_command IT100RequestCommand.new(__method__,
                                           partition: partition,
                                           code: ('%-6s' % code)[0..5].tr(' ', '0'))
    end

    def timestamp_control(on: false)
      send_command IT100RequestCommand.new(__method__, on_off: on ? 1 : 0)
    end

    def datetime_broadcast(on: false)
      send_command IT100RequestCommand.new(__method__, on_off: on ? 1 : 0)
    end

    def code_send(code:)
      send_command IT100RequestCommand.new(__method__, code: ('%-6s' % code)[0..5].tr(' ', '0'))
    end

    def key_press(keys:)
      keys.chars.map do |ch|
        send_command IT100RequestCommand.new(__method__, key: ch)
      end
    end

    # Complex commands
    def acknowledge_trouble
      key_press keys: '*2#'
    end

    def start!
      @process_thread ||= Thread.new do
        debug 'Starting processing thread'
        @thread_ready = true
        until @quit_thread
          with_socket_retry do
            while (line = it100_socket.readline_nonblock).length > 0
              event = IT100ResponseCommand.new(line)
              @subscribers.values.each { |q| q.push(event) } if event.valid_checksum?
            end
          end
          sleep 0.01
        end
        debug 'Quitting processing thread'
      end
      @process_thread.tap { sleep 0.01 until @thread_ready }
      debug 'Processing thread ready'
    end

    def wait!
      @process_thread.join
    end

    def quit!
      @quit_thread = true
      wait!
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
      @it100_socket ||= TCPSocket.open(it100_uri.host, it100_uri.port)
    end

    def it100_uri
      return @it100_uri unless @it100_uri.nil?
      uri = ENV['IT100_URI'] && ENV['IT100_URI'].length > 0 ? ENV['IT100_URI'] : 'tcp://localhost:3000'
      uri = "tcp://#{uri}" unless uri =~ /^[A-Za-z]+:\/\//
      @it100_uri ||= URI(uri)
    end

    def send_command(command)
      result = { request: command.as_json }
      sub_id = subscribe_events
      with_socket_retry(0) do
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
      end
      result
    ensure
      unsubscribe_events(sub_id)
    end

    def with_socket_retry(max_num_failures = nil, &block)
      num_failures = 0
      next_retry_at = Time.now.to_i
      success = false
      until @quit_thread || success || (max_num_failures && num_failures > max_num_failures)
        if Time.now.to_i >= next_retry_at
          begin
            block.call(num_failures)
            success = true
          rescue Errno::EINVAL, Errno::ECONNREFUSED, Errno::ECONNRESET,
                 EOFError, Timeout::Error, Net::HTTPBadResponse,
                 Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
            error "Socket failure : #{e.message}"
            @it100_socket = nil
            num_failures += 1
            retry_wait = [num_failures * 2, 30].min
            warn "Waiting #{retry_wait} seconds before trying again"
            next_retry_at = Time.now.to_i + retry_wait
          end
        end
        sleep 0.01
      end
    end
  end
end
