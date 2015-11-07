class DSCEvent
  attr_accessor :raw_message

  def initialize(message)
    self.raw_message = message
  end

  def command
    raw_message[0..2]
  end

  def data
    raw_message[3..-3]
  end

  def checksum
    raw_message[-2..-1]
  end

  def checksum_verify
    raw_message[0..-3].bytes.inject(0) { |a, e| a + e }.to_s(16)[-2..-1].upcase
  end

  def valid?
    checksum == checksum_verify
  end

  def to_s
    raw_message
  end
end
