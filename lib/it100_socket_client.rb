require 'securerandom'
require 'socket'
require 'thread'
require 'timeout'

module DSCConnect
  class IT100SocketError < StandardError; end

  class IT100SocketClient
    include WorkerThreadBase

    def initialize
      @subscribers = {}
      @socket_mutex = Mutex.new
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

    def do_work
      socket_retry do
        while (line = socket_readline).length > 0
          event = IT100ResponseCommand.new(line)
          log "Event received : #{event.as_json.to_json}"
          @subscribers.values.each { |q| q.push(event) } if event.valid_checksum?
        end
      end
    end

    def subscribe_events(&block)
      id = SecureRandom.hex
      @subscribers[id] = Queue.new
      if block_given?
        begin
          block.call(id)
        ensure
          unsubscribe_events(id)
        end
      else
        id
      end
    end

    def unsubscribe_events(id)
      @subscribers.delete(id)
      id
    end

    def next_event(id)
      @subscribers[id].pop if @subscribers[id].length > 0
    end

    private

    def it100_uri
      uri = ENV['IT100_URI'] if ENV['IT100_URI'] && ENV['IT100_URI'].length > 0
      uri ||= Configuration.instance.config['it100_uri']
      uri ||= 'tcp://localhost:3000'
      uri = "tcp://#{uri}" unless uri =~ /^[A-Za-z]+:\/\//
      URI(uri)
    end

    def socket_readline
      with_socket { |s| s.readline_nonblock(timeout: 0.5, line_end: "\r\n") }
      rescue Errno::EINVAL, Errno::ECONNREFUSED, Errno::ECONNRESET,
             EOFError, SocketError, Timeout::Error, Net::HTTPBadResponse,
             Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
        raise IT100SocketError, e.message
    end

    def socket_writeline(line)
      with_socket { |s| s.write(line) }
      rescue Errno::EINVAL, Errno::ECONNREFUSED, Errno::ECONNRESET,
             EOFError, SocketError, Timeout::Error, Net::HTTPBadResponse,
             Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
        raise IT100SocketError, e.message
    end

    def send_command(command)
      result = { request: command.as_json }
      socket_retry(1) do
        log "Sending command : #{command.as_json.to_json}"
        subscribe_events do |sub_id|
          socket_writeline(command.message)
          loop do
            begin
              timeout(2) do
                sleep 0.01 while (event = IT100SocketClient.instance.next_event(sub_id)).nil?
                (result[:response] ||= []) << event.as_json
              end
            rescue Timeout::Error
              raise IT100SocketError, 'No response received in time' if result[:response].nil?
              break
            end
          end
        end
      end
      result
    end

    def socket_retry(max_num_retries = nil, &block)
      result = nil
      num_failures = 0
      next_retry_at = Time.now.to_i
      loop do
        sleep 0.01
        break if quit_thread?
        next unless Time.now.to_i >= next_retry_at
        begin
          result = block.call(num_failures)
          break # success
        rescue IT100SocketError => e
          error "Socket failure : #{e.message}"
          reset_socket
          break if max_num_retries && num_failures >= max_num_retries
          num_failures += 1
          next_retry_at = Time.now.to_i + (retry_wait = [num_failures * 2, 30].min)
          warn "Waiting #{retry_wait} seconds before trying again"
        end
      end
      result
    end

    def reset_socket
      @socket_mutex.synchronize do
        return if @it100_socket.nil?
        debug "Closing socket at #{it100_uri}"
        begin
          @it100_socket.close
        rescue StandardError => e
          error "Socket failure : #{e.message}"
        end
        @it100_socket = nil
      end
    end

    def with_socket(&block)
      @socket_mutex.synchronize do
        if @it100_socket.nil?
          debug "Opening socket at #{it100_uri}"
          @it100_socket = TCPSocket.open(it100_uri.host, it100_uri.port)
        end
        block.call(@it100_socket)
      end
    end
  end
end
