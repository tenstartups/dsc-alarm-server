module DSCConnect
  class RequestCommand < Command
    attr_reader :code, :raw_data, :checksum, :command, :name, :data

    REQUEST_COMMANDS ||= YAML.load_file(File.join(File.dirname(__FILE__), 'commands.yml'))['request']

    def initialize(command, **data)
      super()
      @command = command.to_s
      @data = data
      fail "Unknown command [#{@command}]" unless REQUEST_COMMANDS[@command]
      @name = REQUEST_COMMANDS[@command]['name']
      @code = REQUEST_COMMANDS[@command]['code']
      @raw_data = format((REQUEST_COMMANDS[@command]['data_pattern'] || ''), @data)
      @checksum = checksum_verify
    end
  end
end
