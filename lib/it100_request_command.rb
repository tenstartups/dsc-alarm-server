module DSCConnect
  class IT100RequestCommand < IT100Command
    attr_reader :command, :raw_data, :checksum, :slug, :name, :data

    REQUEST_COMMANDS ||= YAML.load_file(File.join(File.dirname(__FILE__), 'it100_commands.yml'))['request']

    def initialize(slug, **data)
      @slug = slug.to_s
      @data = data
      fail "Unknown command slug [@slug]" unless REQUEST_COMMANDS[@slug]
      @name = REQUEST_COMMANDS[@slug]['name']
      @command = REQUEST_COMMANDS[@slug]['command']
      @raw_data = (REQUEST_COMMANDS[@slug]['data_pattern'] || '') % @data
      @checksum = checksum_verify
    end
  end
end
