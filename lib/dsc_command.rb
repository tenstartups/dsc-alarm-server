require 'stringio'
require 'timeout'
require 'it100_socket'

class IO
  def readline_nonblock
    StringIO.new.tap do |buffer|
      begin
        timeout(1) do
          while (ch = recv(1))
            buffer << ch
            break if ch == "\n"
          end
        end
      rescue Timeout::Error
        # We timed out waiting therefore continue
      end
    end.string.strip
  end
end

class DSCCommand
  def initialize(read_response = false)
    @read_response = read_response
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

  def set_datetime(datetime: Time.now)
    send_command "010#{datetime.strftime('%H%M%m%d%y')}"
  end

  def output_control(partition: 1, program: 1)
    send_command "020#{partition}#{program}"
  end

  def arm_away(partition: 1, no_entry_delay: false)
    send_command "#{no_entry_delay ? '032' : '030'}#{partition}"
  end

  def arm_stay(partition: 1)
    send_command "031#{partition}"
  end

  def arm(partition: 1, code:)
    send_command "033#{partition}#{('%-6s' % code)[0..5].tr(' ', '0')}"
  end

  def disarm(partition: 1, code:)
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

  def key_press(key:)
    send_command "070#{key}"
  end

  # Complex commands
  def acknowledge_trouble
    key_press key: '*'
    key_press key: '2'
    key_press key: '#'
  end

  private

  def send_command(command)
    checksum = command.bytes.inject(0) { |a, e| a + e }.to_s(16)[-2..-1].upcase
    message = "#{command}#{checksum}\r\n"
    puts "Sending DSC command - #{message}"
    IT100Socket.instance.write(message)
    return unless @read_response
    while (line = IT100Socket.instance.readline_nonblock).length > 0
      event = DSCEvent.new(line)
      puts "Response received - #{event.as_json.to_json}" if event.valid_checksum?
    end
  end
end
