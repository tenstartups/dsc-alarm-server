require 'timeout'

class IO
  def readline_nonblock
    rlnb_buffer = ''
    begin
      timeout(0.5) do
        while (ch = recv(1))
          rlnb_buffer << ch
          break if ch == "\n"
        end
      end
    rescue Timeout::Error
    end
    rlnb_buffer = nil if rlnb_buffer.length == 0
    rlnb_buffer
  end
end

class DSCCommand
  def initialize(socket: nil, read_response: false)
    @it100_socket = socket
    @read_response = read_response
  end

  def poll
    send_command '000'
  end

  def status_request
    send_command '001'
  end

  def labels_request
    send_command '002'
  end

  def set_time_and_date(datetime: Time.now)
    send_command "010#{datetime.strftime('%H%M%m%d%y')}"
  end

  def command_output_control(partition: 1, program: 1)
    send_command "020#{partition}#{program}"
  end

  def partition_arm_control_away(partition: 1)
    send_command "030#{partition}"
  end

  def partition_arm_control_stay(partition: 1)
    send_command "031#{partition}"
  end

  def partition_arm_control_armed_no_entry_delay(partition: 1)
    send_command "032#{partition}"
  end

  def partition_arm_control_with_code(partition: 1, code:)
    send_command "033#{partition}#{('%-6s' % code)[0..5].tr(' ', '0')}"
  end

  def partition_disarm_control_with_code(partition: 1, code:)
    send_command "040#{partition}#{('%-6s' % code)[0..5].tr(' ', '0')}"
  end

  private

  def it100_uri
    @it100_uri ||= URI(ENV['IT100_URI'])
  end

  def it100_socket
    @it100_socket ||= TCPSocket.open(it100_uri.host, it100_uri.port)
  end

  def send_command(command)
    checksum = command.bytes.inject(0) { |a, e| a + e }.to_s(16)[-2..-1].upcase
    message = "#{command}#{checksum}\r\n"
    puts "Sending command - #{message}"
    it100_socket.write(message)
    return unless @read_response
    while (line = it100_socket.readline_nonblock)
      event = DSCEvent.new(line.chop)
      puts event if event.valid?
    end
  end
end
