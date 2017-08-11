module DSCConnect
  class EventServer
    include Singleton
    include LoggingHelper

    def initialize
      @process_threads = []
    end

    def start!
      # Start the logger loop
      @process_threads << ConsoleLogger.instance.tap(&:start!)

      # Start the IT-100 event listener loop
      @process_threads << SocketClient.instance.tap(&:start!)

      # Start the event handler loop
      @process_threads << EventActionHandler.instance.tap(&:start!)

      # Start the heatbeat poll loop
      @process_threads << HeartbeatPoll.instance.tap(&:start!)

      # Start the API REST server if requested
      @process_threads << RestServer.instance.tap(&:start!)

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
      SocketClient.instance.status

      # Wait on threads
      @process_threads.each(&:wait!)
    end
  end
end
