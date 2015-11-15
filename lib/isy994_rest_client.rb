require 'active_support'
require 'active_support/core_ext'
require 'rest-client'
require 'singleton'

class ISY994RestClient
  include Singleton

  def check_missing_variables(required_vars)
    isy_vars = state_variables.map { |e| e['name'] }
    missing_vars = required_vars - isy_vars
    missing_vars.each { |v| STDERR.puts("[ISY994RestClient] Missing state variable - #{v}".colorize(:yellow)) }
  end

  def state_variables
    return @state_variables if @state_variables
    result = get('vars/definitions/2')
    @state_variables = result['CList']['e']
  end

  def set_state(name, value)
    return unless (attr = state_variables.find { |a| a['name'] == name })
    puts "[ISY994RestClient] Setting state variable - #{name}(#{attr['id']}) = #{value}".colorize(:yellow)
    get("vars/set/2/#{attr['id']}/#{value}")
  end

  def get(path)
    result = RestClient.get("#{isy994_uri}/rest/#{path}")
    Hash.from_xml(result)
  end

  private

  def isy994_uri
    @isy994_uri ||= (ENV['ISY994_URI'] && ENV['ISY994_URI'].length > 0 ? ENV['ISY994_URI'] : 'http://admin:admin@isy994-ems')
  end
end
