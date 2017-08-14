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
      if ENV['DSC_ALARM_CONFIG'] && !File.exist?(ENV['DSC_ALARM_CONFIG'])
        warn "Copying configuration template to #{ENV['DSC_ALARM_CONFIG']}"
        FileUtils.mkdir_p(File.dirname(ENV['DSC_ALARM_CONFIG']))
        FileUtils.cp(default_config, ENV['DSC_ALARM_CONFIG'])
      end
      config = YAML.load_file(ENV['DSC_ALARM_CONFIG']) if ENV['DSC_ALARM_CONFIG'] && File.exist?(ENV['DSC_ALARM_CONFIG'])
      config ||= YAML.load_file(default_config)
      @config = RecursiveOpenStruct.new(config)
      super(@config)
    end
  end
end
