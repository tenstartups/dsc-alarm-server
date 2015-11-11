require 'active_support'
require 'active_support/core_ext'
require 'rest-client'

class ISYRestClient
  attr_reader :config

  def initialize(uri, config)
    @isy_uri = uri
    @config = config
    check_variables
  end

  def state_variables
    return @state_variables if @state_variables
    result = get('vars/definitions/2')
    @state_variables = result['CList']['e']
  end

  def set_state(name, value)
    return unless (attr = state_variables.find { |a| a['name'] == name })
    puts "Setting ISY state variable - #{name}(#{attr['id']}) = #{value}"
    get("vars/set/2/#{attr['id']}/#{value}")
  end

  def get(path)
    result = RestClient.get("#{@isy_uri}/rest/#{path}")
    Hash.from_xml(result)
  end

  private

  def check_variables
    isy_vars = state_variables.map { |e| e['name'] }
    config_vars = @config.values.reduce([]) { |a, e| a.concat(e) }.map { |e| e['isy_state'] }.reduce([]) { |a, e| a.concat(e.keys) }.uniq.sort
    missing_vars = config_vars - isy_vars
    missing_vars.each { |v| STDERR.puts("Missing ISY state variable - #{v}") }
  end
end
