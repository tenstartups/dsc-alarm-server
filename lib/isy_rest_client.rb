require 'rest-client'

class ISYRestClient
  def initialize(uri)
    @isy_uri = uri
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

  def set_state_variable(name, value)
    if (attr = state_variables.find { |a| a['name'] == name })
      puts "Setting #{name}(#{attr['id']}) = #{value}"
      get("vars/set/2/#{attr['id']}/#{value}")
    end
  end

  def get(path)
    result = RestClient.get("#{@isy_uri}/rest/#{path}")
    Hash.from_xml(result)
  end
end
