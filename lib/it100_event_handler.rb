require 'singleton'

class IT100EventHandler
  include Singleton
  include LoggingHelper

  attr_reader :started

  def start!
    debug 'Entering processing loop'
    subscription_id = IT100SocketClient.instance.subscribe_events
    @started = true
    until @loop_exit
      unless (event = IT100SocketClient.instance.next_event(subscription_id)).nil?
        log "Event received : #{event.as_json.to_json}"
      end
      sleep 0.01
    end
    IT100SocketClient.instance.unsubscribe_events(subscription_id)
    debug 'Exiting processing loop'
  end

  def exit!
    @loop_exit = true
  end
end
