module DSCConnect
  class ActionError < StandardError; end

  class EventActionHandler
    include WorkerThreadBase

    def initialize
      defns = Configuration.instance.action_handlers.try(:to_h) || {}
      @action_handlers = defns.each_with_object({}) do |(slug, attrs), hash|
        attrs = attrs.symbolize_keys
        attrs[:actions].each do |action|
          hash[:"#{slug}_#{action}"] = {
            class: ActiveSupport::Inflector.constantize(attrs[:class_name]),
            method: action.to_sym
          }
        end
      end
    end

    def prepare_work
      @subscription_id = SocketClient.instance.subscribe_events
    end

    def do_work
      unless (event = SocketClient.instance.next_event(@subscription_id)).nil?
        matching_actions = (Configuration.instance.event_actions || []).select do |defn|
          defn['conditions'] &&
          defn['conditions'].all? { |e| e.any? { |k, v| event.send(k.to_sym) == v } }
        end
        matching_actions.map { |e| e['actions'] || [] }.each do |defns|
          defns.each do |defn|
            defn.each do |(action, attrs)|
              action_class = @action_handlers[action.to_sym].try(:[], :class)
              action_method = @action_handlers[action.to_sym].try(:[], :method)
              next unless action_class && action_method
              action_retry(5) do
                action_class.instance.send(action_method, **(attrs.symbolize_keys))
              end
            end
          end
        end
      end
    end

    def cleanup_work
      SocketClient.instance.unsubscribe_events(@subscription_id)
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