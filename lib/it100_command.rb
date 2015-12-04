module DSCConnect
  class IT100Command
    attr_reader :command, :raw_data, :checksum, :slug, :name, :data

    def message
      "%3s%s%2s\r\n" % [command, raw_data, checksum]
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
      if slug.nil?
        { command: command, message: message }
      else
        { command: command, name: name }.merge(data)
      end
    end

    def to_s
      message
    end

    private

    def checksum_verify
      ('%3s%s' % [command, raw_data]).bytes.inject(0) { |a, e| a + e }.to_s(16)[-2..-1].upcase
    end
  end
end
