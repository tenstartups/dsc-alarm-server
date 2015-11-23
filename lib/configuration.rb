require 'singleton'

module DSCConnect
  class Configuration
    include Singleton

    attr_reader :config

    def initialize
      default_config = File.join(File.dirname(__FILE__), 'config.yml')
      if ENV['DSC_CONNECT_CONFIG'] && !File.exist?(ENV['DSC_CONNECT_CONFIG'])
        warn "Copying configuration template to #{ENV['DSC_CONNECT_CONFIG']}"
        FileUtils.mkdir_p(File.dirname(ENV['DSC_CONNECT_CONFIG']))
        FileUtils.cp(default_config, ENV['DSC_CONNECT_CONFIG'])
      end
      @config = YAML.load_file(ENV['DSC_CONNECT_CONFIG']) if ENV['DSC_CONNECT_CONFIG'] && File.exist?(ENV['DSC_CONNECT_CONFIG'])
      @config ||= YAML.load_file(default_config)
    end
  end
end
