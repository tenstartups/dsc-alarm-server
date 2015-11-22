require 'singleton'
require 'timeout'

module DSCConnect
  class IT100EventServer
    include Singleton
    include LoggingHelper

    def initialize
      @process_threads = []
      @extra_event_handlers = ENV.keys.grep(/^DSC_EVENT_HANDLER_([_A-Z0-9]+)/)
                              .map { |e| ENV[e] }.uniq
                              .map { |h| ActiveSupport::Inflector.constantize(h) }
    end

    def start!
      # Start the logger loop
      @process_threads << Logger.instance.tap(&:start!)

      # Start the IT-100 event listener loop
      @process_threads << IT100SocketClient.instance.tap(&:start!)

      # Start the default event handler
      @process_threads << LogEventHandler.instance.tap(&:start!)

      # Start the event handler loops
      @extra_event_handlers.each { |h| @process_threads << h.instance.tap(&:start!) }

      # Start the heatbeat poll loop
      @process_threads << IT100HeartbeatPoll.instance.tap(&:start!)

      # Start the API REST server if requested
      @process_threads << IT100RestServer.instance.tap(&:start!) if ENV['DSC_REST_SERVER_ACTIVE'] == 'true'

      # Trap CTRL-C and SIGTERM
      trap('INT') do
        warn 'CTRL-C detected, waiting for all threads to exit gracefully...'
        @process_threads.reverse_each(&:quit!)
        exit(0)
      end
      trap('TERM') do
        error 'Kill detected, waiting for all threads to exit gracefully...'
        @process_threads.reverse_each(&:quit!)
        exit(1)
      end

      warn 'Press CTRL-C at any time to stop all threads and exit'

      # Trigger a full status dump
      IT100SocketClient.instance.status

      # Wait on threads
      @process_threads.each(&:wait!)
    end
  end
end
