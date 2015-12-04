require 'yaml'

module DSCConnect
  class IT100ResponseCommand < IT100Command
    RESPONSE_COMMANDS ||= YAML.load_file(File.join(File.dirname(__FILE__), 'it100_commands.yml'))['response']

    def initialize(message)
      @command = message.strip[0..2] || ''
      @raw_data = message.strip[3..-3] || ''
      @checksum = (message.strip[-2..-1] || '').upcase
      RESPONSE_COMMANDS.each do |slug, attr|
        next unless attr['command'] == command
        next unless raw_data.length == 0 && attr['data_pattern'].nil? ||
                    (match = Regexp.new(attr['data_pattern'] || '').match(raw_data))
        @slug = slug
        @name = attr['name']
        @data = match.nil? ? {} : match.names.reduce({}) { |a, e| a[e.to_sym] = match[e.to_sym]; a }
        break
      end
    end
  end
end
