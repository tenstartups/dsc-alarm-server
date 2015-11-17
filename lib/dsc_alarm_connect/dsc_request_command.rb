class DSCRequestCommand
  attr_reader :command, :raw_data, :checksum, :slug, :name, :data

  REQUEST_COMMANDS ||= YAML.load_file(File.join(File.dirname(__FILE__), 'dsc_commands.yml'))['request']

  def initialize(message)
    @command = message[0..2].to_i
    @raw_data = message[3..-1]
    REQUEST_COMMANDS.each do |slug, attr|
      next unless attr['command'] == command
      @slug = slug
      @name = attr['name']
      @data = {}
      break
    end
  end

  def checksum
    ('%03d%s' % [command, raw_data]).bytes.inject(0) { |a, e| a + e }.to_s(16)[-2..-1].upcase
  end

  def message
    "%03d%s%2s\r\n" % [command, raw_data, checksum]
  end
end
