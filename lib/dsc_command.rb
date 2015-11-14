class DSCCommand
  def initialize(*commands)
    @commands = commands
  end

  def message
    @commands.map do |command|
      checksum = command.bytes.inject(0) { |a, e| a + e }.to_s(16)[-2..-1].upcase
      "#{command}#{checksum}\r\n"
    end.join
  end
end
