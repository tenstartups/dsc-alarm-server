require 'delegate'
require 'fileutils'
require 'json'
require 'recursive-open-struct'
require 'singleton'
require 'yaml'

module DSCConnect
  class Configuration < SimpleDelegator
    include Singleton

    def initialize
      default_config = File.join(File.dirname(__FILE__), 'config_template.yml')
      if ENV['CONFIG_FILE'] && !File.exist?(ENV['CONFIG_FILE'])
        warn "Copying configuration template to #{ENV['CONFIG_FILE']}"
        FileUtils.mkdir_p(File.dirname(ENV['CONFIG_FILE']))
        FileUtils.cp(default_config, ENV['CONFIG_FILE'])
      end
      config = YAML.load_file(ENV['CONFIG_FILE']) if ENV['CONFIG_FILE'] && File.exist?(ENV['CONFIG_FILE'])
      config ||= YAML.load_file(default_config)
      @config = RecursiveOpenStruct.new(config)
      super(@config)
    end
  end
end
