require 'yaml'

class DSCResponseCommand
  attr_reader :command, :raw_data, :checksum, :slug, :name, :data

  RESPONSE_COMMANDS ||= YAML.load_file(File.join(File.dirname(__FILE__), 'dsc_commands.yml'))['response']

  def initialize(message)
    @command = message.strip[0..2].to_i
    @raw_data = message.strip[3..-3]
    @checksum = message.strip[-2..-1].upcase
    RESPONSE_COMMANDS.each do |slug, attr|
      next unless attr['command'] == command
      next unless raw_data.length == 0 && attr['data_pattern'].nil? ||
                  (match = Regexp.new(attr['data_pattern']).match(raw_data))
      @slug = slug
      @name = attr['name']
      @data = match.nil? ? {} : match.names.reduce({}) { |a, e| a[e.to_sym] = match[e.to_sym]; a }
      break
    end
  end

  def message
    "%03d%s%2s\r\n" % [command, raw_data, checksum]
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
    ('%03d%s' % [command, raw_data]).bytes.inject(0) { |a, e| a + e }.to_s(16)[-2..-1].upcase
  end
end
