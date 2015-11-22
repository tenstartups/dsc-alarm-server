require 'singleton'

module DSCConnect
  class IT100EventHandler
    include Singleton
    include LoggingHelper

    def start!
      @process_thread ||= Thread.new do
        debug 'Starting processing thread'
        subscription_id = IT100SocketClient.instance.subscribe_events
        @thread_ready = true
        until @quit_thread
          unless (event = IT100SocketClient.instance.next_event(subscription_id)).nil?
            log "Event received : #{event.as_json.to_json}"
          end
          sleep 0.01
        end
        IT100SocketClient.instance.unsubscribe_events(subscription_id)
        debug 'Quitting processing thread'
      end
      @process_thread.tap { sleep 0.01 until @thread_ready }
      debug 'Processing thread ready'
    end

    def wait!
      @process_thread.join
    end

    def quit!
      @quit_thread = true
      wait!
    end
  end
end
