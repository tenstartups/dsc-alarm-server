require 'yaml'

class DSCEvent
  attr_accessor :raw_message
  attr_reader :slug, :name, :data

  EVENT_DEFINITIONS ||= YAML.load_file(File.join(File.dirname(__FILE__), 'dsc_event.yml'))

  def initialize(message)
    self.raw_message = message
    EVENT_DEFINITIONS.each do |slug, attr|
      next unless attr['command'] == command
      next unless raw_data.length == 0 && attr['data_pattern'].nil? ||
                  (match = Regexp.new(attr['data_pattern']).match(raw_data))
      @slug = slug
      @name = attr['name']
      @data = match.nil? ? {} : match.names.reduce({}) { |a, e| a[e.to_sym] = match[e.to_sym]; a }
      break
    end
  end

  def command
    raw_message[0..2].to_i
  end

  def raw_data
    raw_message[3..-3]
  end

  def checksum
    raw_message[-2..-1]
  end

  def valid_checksum?
    checksum == checksum_verify
  end

  def method_missing(name, *args, &block)
    super unless data.key?(name.to_sym)
    data[name.to_sym].to_i
  end

  def respond_to_missing?(name, include_private = false)
    data.key?(name.to_sym) || super
  end

  def as_json
    if slug.nil?
      { command: command, raw_message: raw_message }
    else
      { command: command, name: name }.merge(data)
    end
  end

  def to_s
    raw_message
  end

  private

  def checksum_verify
    raw_message[0..-3].bytes.inject(0) { |a, e| a + e }.to_s(16)[-2..-1].upcase
  end
end
