require 'yaml'

module DSCConnect
  class ResponseCommand < Command
    RESPONSE_COMMANDS ||= YAML.load_file(File.join(File.dirname(__FILE__), 'commands.yml'))['response']

    def initialize(message)
      super()
      @code = message.strip[0..2] || ''
      @raw_data = message.strip[3..-3] || ''
      @checksum = (message.strip[-2..-1] || '').upcase
      RESPONSE_COMMANDS.each do |command, attr|
        next unless attr['code'] == code
        next unless raw_data.length == 0 &&
                    attr['data_pattern'].nil? ||
                    (match = Regexp.new(attr['data_pattern'] || '').match(raw_data))
        @command = command
        @name = attr['name']
        @data = if match.nil?
                  {}
                else
                  match.names.each_with_object({}) do |e, a|
                    a[e.to_sym] = match[e.to_sym]
                  end
                end
        break
      end
    end
  end
end
