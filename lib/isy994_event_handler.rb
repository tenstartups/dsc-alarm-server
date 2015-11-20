require 'singleton'

class ISY994EventHandler
  include Singleton
  include LoggingHelper

  attr_reader :started

  def initialize
    isy_action_config = config['actions'].map { |e| e['then'] }.inject([]) { |a, e| a.concat(e) }
    ISY994RestClient.instance.check_programs(
      isy_action_config.map { |e| e['program'] }
                       .compact
                       .map { |e| e['name'] }
                       .uniq.sort
    )
    ISY994RestClient.instance.check_integer_variables(
      isy_action_config.map { |e| e['integer_variable'] }
                       .compact
                       .map { |e| e['name'] }
                       .uniq.sort
    )
    ISY994RestClient.instance.check_state_variables(
      isy_action_config.map { |e| e['state_variable'] }
                       .compact
                       .map { |e| e['name'] }
                       .uniq.sort
    )
  end

  def start!
    debug 'Entering processing loop'
    subscription_id = IT100SocketClient.instance.subscribe_events
    @started = true
    until @loop_exit
      unless (event = IT100SocketClient.instance.next_event(subscription_id)).nil?
        actions = config['actions'].select do |action|
          action['if'] && action['if'].all? { |e| e.any? { |k, v| event.send(k) == v } }
        end
        actions.each do |action|
          action['then'].each do |a|
            action_type = a.keys.first
            action_args = a[action_type]
            case action_type
            when 'program'
              ISY994RestClient.instance.run_program(action_args['name'], action_args['command'])
            when 'integer_variable'
              ISY994RestClient.instance.set_integer_variable(action_args['name'], action_args['value'])
            when 'state_variable'
              ISY994RestClient.instance.set_state_variable(action_args['name'], action_args['value'])
            end
          end
        end
      end
      sleep 0.01
    end
    IT100SocketClient.instance.unsubscribe_events(subscription_id)
    debug 'Exiting processing loop'
  end

  def exit!
    @loop_exit = true
  end

  private

  def config
    return @config unless @config.nil?
    config_template = File.join(File.dirname(__FILE__), 'isy994_event_handler.yml')
    if ENV['ISY994_EVENT_HANDLER_CONFIG'] && !File.exist?(ENV['ISY994_EVENT_HANDLER_CONFIG'])
      warn "Copying configuration template to #{ENV['ISY994_EVENT_HANDLER_CONFIG']}"
      FileUtils.mkdir_p(File.dirname(ENV['ISY994_EVENT_HANDLER_CONFIG']))
      FileUtils.cp(config_template, ENV['ISY994_EVENT_HANDLER_CONFIG'])
    end
    @config = YAML.load_file(ENV['ISY994_EVENT_HANDLER_CONFIG']) if ENV['ISY994_EVENT_HANDLER_CONFIG'] && File.exist?(ENV['ISY994_EVENT_HANDLER_CONFIG'])
    @config ||= YAML.load_file(config_template)
  end
end
