require 'singleton'

class IT100EventHandler
  include Singleton
  include LoggingHelper

  def start!
    subscription_id = IT100SocketClient.instance.subscribe_events
    loop do
      unless (event = IT100SocketClient.instance.next_event(subscription_id)).nil?
        log "Event received : #{event.as_json.to_json}"
      end
      sleep 0.01
    end
    IT100SocketClient.instance.unsubscribe_events(subscription_id)
  end
end
