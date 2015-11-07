class DSCCommand
  def initialize(socket)
    @socket = socket
  end

  def request_status
    send_command '001'
  end

  def set_datetime
    send_command('010' + Time.now.strftime('%H%M%m%d%y'))
  end

  private

  def send_command(command)
    checksum = command.bytes.inject(0) { |a, e| a + e }.to_s(16)[-2..-1].upcase
    message = "#{command}#{checksum}\r\n"
    puts "Sending command - #{message}"
    @socket.write(message)
  end
end
