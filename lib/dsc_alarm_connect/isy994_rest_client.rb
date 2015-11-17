require 'active_support'
require 'active_support/core_ext'
require 'rest-client'
require 'singleton'

class ISY994RestClient
  include Singleton
  include LoggingHelper

  def check_missing_variables(required_vars)
    isy_vars = state_variables.map { |e| e['name'] }
    missing_vars = required_vars - isy_vars
    missing_vars.each { |v| warn "Missing state variable : #{v}" }
  end

  def state_variables
    return @state_variables if @state_variables
    result = get('vars/definitions/2')
    @state_variables = result['CList']['e']
  end

  def set_state(name, value)
    if (attr = state_variables.find { |a| a['name'] == name })
      log "Setting state variable : #{name} [#{attr['id']}] = #{value}"
      result = get("vars/set/2/#{attr['id']}/#{value}")
      log "REST response : #{result['RestResponse'].to_json}"
    else
      warn "Skipping missing state variable : #{name} = #{value}"
    end
  end

  def get(path)
    result = RestClient.get("#{isy994_uri}/rest/#{path}")
    Hash.from_xml(result)
  end

  private

  def isy994_uri
    @isy994_uri ||= ENV['ISY994_URI'] if ENV['ISY994_URI'] && ENV['ISY994_URI'].length > 0
    @isy994_uri ||= YAML.load_file(ENV['ISY994_EVENT_HANDLER_CONFIG'])['isy994_uri'] if ENV['ISY994_EVENT_HANDLER_CONFIG'] && File.exist?(ENV['ISY994_EVENT_HANDLER_CONFIG'])
    @isy994_uri ||= 'http://admin:admin@isy994-ems'
  end
end
