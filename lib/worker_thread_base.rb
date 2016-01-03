require 'singleton'

module DSCConnect
  module WorkerThreadBase
    def self.included(base)
      base.class_eval do
        include Singleton
        include LoggingHelper

        attr_reader :process_thread, :thread_ready, :quit_thread
        alias_method :thread_ready?, :thread_ready
        alias_method :quit_thread?, :quit_thread
      end
    end

    def start!
      raise 'Worker already started' if process_thread
      @process_thread = Thread.new do
        begin
          debug 'Starting processing thread'
          prepare_work if respond_to?(:prepare_work)
          @thread_ready = true
          until quit_thread
            do_work
            sleep(0.05)
          end
        ensure
          cleanup_work if respond_to?(:cleanup_work)
          debug 'Quitting processing thread'
        end
      end
      process_thread.tap { sleep 0.05 until thread_ready }
      debug 'Processing thread ready'
    end

    def do_work
      fail 'You need to implement a concrete do_work method'
    end

    def wait!
      process_thread.join
    end

    def quit!
      @quit_thread = true
      wait!
    end
  end
end
