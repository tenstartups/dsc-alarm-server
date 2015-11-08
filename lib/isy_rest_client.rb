require 'active_support'
require 'active_support/core_ext'
require 'rest-client'

class ISYRestClient
  def initialize(uri, config)
    @isy_uri = uri
    @dsc_status_config = config
  end

  def integer_variables
    return @integer_variables if @integer_variables
    result = get('vars/definitions/1')
    @integer_variables = Hash.from_xml(result)['CList']['e']
  end

  def state_variables
    return @state_variables if @state_variables
    result = get('vars/definitions/2')
    @state_variables = result['CList']['e']
  end

  def set_state(slug, value)
    name = @dsc_status_config[slug]
    return unless (attr = state_variables.find { |a| a['name'] == name })
    puts "Setting #{name}(#{attr['id']}) = #{value}"
    get("vars/set/2/#{attr['id']}/#{value}")
  end

  def get(path)
    result = RestClient.get("#{@isy_uri}/rest/#{path}")
    Hash.from_xml(result)
  end
end
