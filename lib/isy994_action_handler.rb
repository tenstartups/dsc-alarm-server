require 'rest-client'
require 'singleton'

module DSCConnect
  class ISY994ActionHandler
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

    def run_program(name:, command: :if)
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
        log "Running program #{name} [#{attr['id']}] #{command} command"
        result = get("programs/#{attr['id']}/#{cmd}")
        log "REST response : #{result['RestResponse'].to_json}"
      else
        warn "Missing program #{name}, NOT running command #{command}"
      end
    end

    def set_integer(name:, value:)
      if (attr = integer_variables.find { |a| a['name'] == name })
        log "Setting integer variable #{name} [#{attr['id']}] to #{value}"
        result = get("vars/set/1/#{attr['id']}/#{value}")
        log "REST response : #{result['RestResponse'].to_json}"
      else
        warn "Missing integer variable #{name}, NOT setting value to #{value}"
      end
    end

    def set_state(name:, value:)
      if (attr = state_variables.find { |a| a['name'] == name })
        log "Setting state variable #{name} [#{attr['id']}] to #{value}"
        result = get("vars/set/2/#{attr['id']}/#{value}")
        log "REST response : #{result['RestResponse'].to_json}"
      else
        warn "Missing state variable #{name}, NOT setting value to #{value}"
      end
    end

    def get(path)
      result = RestClient.get("#{isy994_uri}/rest/#{path}")
      Hash.from_xml(result)
    rescue Errno::EINVAL, Errno::ECONNREFUSED, Errno::ECONNRESET,
           EOFError, SocketError, Timeout::Error, Net::HTTPBadResponse,
           Net::HTTPHeaderSyntaxError, Net::ProtocolError, RestClient::Unauthorized => e
      raise ActionError, e.message
    end

    private

    def isy994_uri
      @isy994_uri ||= ENV['ISY994_URI'] if ENV['ISY994_URI'] && ENV['ISY994_URI'].length > 0
      @isy994_uri ||= Configuration.instance.action_handlers.try(:isy994).try(:uri)
      @isy994_uri ||= 'http://admin:admin@isy994-ems'
    end
  end
end
