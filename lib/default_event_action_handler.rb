module DSCConnect
  class ActionError < StandardError; end

  class DefaultEventHandler
    include WorkerThreadBase

    def initialize
      @action_handlers = (Configuration.instance.action_handlers.try(:to_h) || {}).reduce({}) do |hash, (_slug, attrs)|
        attrs = attrs.symbolize_keys
        attrs[:actions].each { |k, v| hash[k.to_sym] = [ActiveSupport::Inflector.constantize(attrs[:class_name]), v.to_sym] }
        hash
      end
    end

    def prepare_work
      @subscription_id = IT100SocketClient.instance.subscribe_events
    end

    def do_work
      unless (event = IT100SocketClient.instance.next_event(@subscription_id)).nil?
        event_action_defns = (Configuration.instance.default_event_handler || []).select do |ea_defn|
          ea_defn['if'] && ea_defn['if'].all? { |e| e.any? { |k, v| event.send(k.to_sym) == v } }
        end
        event_action_defns.map { |e| e['then'] || [] }.each do |action_defns|
          action_defns.each do |action_defn|
            action_defn.each do |(action, attrs)|
              action_class = @action_handlers[action.to_sym][0]
              action_method = @action_handlers[action.to_sym][1]
              action_retry(5) do
                action_class.instance.send(action_method, **(attrs.symbolize_keys))
              end
            end
          end
        end
      end
    end

    def cleanup_work
      IT100SocketClient.instance.unsubscribe_events(@subscription_id)
    end

    private

    def action_retry(max_num_retries, &block)
      result = nil
      num_failures = 0
      next_retry_at = Time.now.to_i
      loop do
        sleep 0.01
        break if quit_thread?
        next unless Time.now.to_i >= next_retry_at
        begin
          result = block.call(num_failures)
          break # success
        rescue ActionError => e
          error "Action failure : #{e.message}"
          break if max_num_retries && num_failures >= max_num_retries
          num_failures += 1
          next_retry_at = Time.now.to_i + (retry_wait = [num_failures * 2, 30].min)
          warn "Waiting #{retry_wait} seconds before trying again"
        end
      end
      result
    end
  end
end
