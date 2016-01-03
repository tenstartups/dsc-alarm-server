module DSCConnect
  class Command
    attr_reader :code, :raw_data, :checksum, :command, :name, :data, :timestamp

    def initialize
      @timestamp = Time.now
    end

    def message
      format("%3s%s%2s\r\n", code, raw_data, checksum)
    end

    def valid_checksum?
      checksum == checksum_verify
    end

    def method_missing(name, *args, &block)
      data.key?(name.to_sym) ? data[name.to_sym].to_i : super
    end

    def respond_to_missing?(name, include_private = false)
      data.key?(name.to_sym) || super
    end

    def as_json
      if command.nil?
        { code: code, message: message }
      else
        { code: code, name: name }.merge(data)
      end
    end

    def to_s
      message
    end

    private

    def checksum_verify
      (format('%3s%s', code, raw_data)).bytes.inject(0) { |a, e| a + e }.to_s(16)[-2..-1].upcase
    end
  end
end
