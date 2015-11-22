require 'active_support'
require 'active_support/core_ext'
require 'rest-client'
require 'singleton'

module DSCConnect
  class ISY994RestClient
    include Singleton
    include LoggingHelper

    def check_programs(action_progs)
      missing_progs = action_progs - programs.map { |e| e['name'] }
      missing_progs.each { |n| warn "Missing program : #{n}" }
    end

    def check_integer_variables(action_vars)
      missing_vars = action_vars - integer_variables.map { |e| e['name'] }
      missing_vars.each { |n| warn "Missing integer variable : #{n}" }
    end

    def check_state_variables(action_vars)
      missing_vars = action_vars - state_variables.map { |e| e['name'] }
      missing_vars.each { |n| warn "Missing state variable : #{n}" }
    end

    def programs
      @programs ||= get('programs?subfolders=true')['programs']['program'].select { |e| e['folder'] == 'false' }
    end

    def integer_variables
      @integer_variables ||= get('vars/definitions/1')['CList']['e']
    end

    def state_variables
      @state_variables ||= get('vars/definitions/2')['CList']['e']
    end

    def run_program(name, command = :if)
      command = command.to_s.downcase.to_sym
      command = :if unless %i[ if then else ].include?(command)
      cmd = case command
      when :if
        'runIf'
      when :then
        'runThen'
      when :else
        'runElse'
      else
        'runIf'
      end
      if (attr = programs.find { |a| a['name'] == name })
        log "Running program : #{name} [#{attr['id']}] -> #{command}"
        result = get("programs/#{attr['id']}/#{cmd}")
        log "REST response : #{result['RestResponse'].to_json}"
      else
        warn "NOT running missing program : #{name} -> #{command}"
      end
    end

    def set_integer_variable(name, value)
      if (attr = integer_variables.find { |a| a['name'] == name })
        log "Setting integer variable : #{name} [#{attr['id']}] = #{value}"
        result = get("vars/set/1/#{attr['id']}/#{value}")
        log "REST response : #{result['RestResponse'].to_json}"
      else
        warn "NOT setting missing integer variable : #{name} = #{value}"
      end
    end

    def set_state_variable(name, value)
      if (attr = state_variables.find { |a| a['name'] == name })
        log "Setting state variable : #{name} [#{attr['id']}] = #{value}"
        result = get("vars/set/2/#{attr['id']}/#{value}")
        log "REST response : #{result['RestResponse'].to_json}"
      else
        warn "NOT setting missing state variable : #{name} = #{value}"
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
end
