require 'singleton'

class ISY994EventHandler
  include Singleton

  def initialize
    ISY994RestClient.instance.check_missing_variables(
      config['dsc_response_commands'].values
            .reduce([]) { |a, e| a.concat(e) }
            .map { |e| e['state_variables'] }
            .reduce([]) { |a, e| a.concat(e.keys) }
            .uniq
            .sort
    )
  end

  def start!
    subscription_id = IT100SocketClient.instance.subscribe_events
    loop do
      unless (event = IT100SocketClient.instance.next_event(subscription_id)).nil?
        (config['dsc_response_commands'][event.slug] || []).each do |defn|
          next unless defn['conditions'].nil? || defn['conditions'].all? { |k, v| event.send(k) == v }
          defn['state_variables'].each do |var, val|
            ISY994RestClient.instance.set_state(var, val)
          end
        end
      end
      sleep 0.01
    end
    IT100SocketClient.instance.unsubscribe_events(subscription_id)
  end

  private

  def config
    return @config unless @config.nil?
    @config = YAML.load_file(ENV['ISY994_EVENT_HANDLER_CONFIG']) if ENV['ISY994_EVENT_HANDLER_CONFIG'] && File.exist?(ENV['ISY994_EVENT_HANDLER_CONFIG'])
    @config ||= YAML.load_file(File.join(File.dirname(__FILE__), 'isy994_event_handler.yml'))
    @config.tap do |conf|
      if (command_config = conf['dsc_response_commands']).keys
        command_config.keys.each do |event|
          command_config[event] = [command_config[event]] unless command_config[event].is_a?(Array)
        end
      end
    end
  end
end
