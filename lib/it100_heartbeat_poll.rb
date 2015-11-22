require 'singleton'

module DSCConnect
  class IT100HeartbeatPoll
    include Singleton
    include LoggingHelper

    def start!
      @process_thread ||= Thread.new do
        debug 'Starting processing thread'
        @thread_ready = true
        next_heartbeat_at = Time.now.to_i + 30
        until @quit_thread
          if (now = Time.now.to_i) >= next_heartbeat_at
            debug 'Sending heartbeat request'
            IT100SocketClient.instance.poll
            next_heartbeat_at = now + 30
          end
          sleep 0.01
        end
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
