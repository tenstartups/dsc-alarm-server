require 'singleton'

class DSCEventServer
  include Singleton
  include LoggingHelper

  def initialize
    ENV['DSC_EVENT_HANDLER_DEFAULT'] = 'IT100EventHandler'
    @threads = []
    @handlers = ENV.keys.grep(/^DSC_EVENT_HANDLER_([_A-Z0-9]+)/)
                .map { |e| ENV[e] }.uniq
                .map { |h| ActiveSupport::Inflector.constantize(h) }
  end

  def start!
    warn 'Press CTRL-C at any time to stop all threads and exit'

    # Trap CTRL-C
    trap('INT') do
      warn 'CTRL-C detected, waiting for all threads to exit gracefully...'
      IT100SocketClient.instance.exit!
      @handlers.each { |h| h.instance.exit! }
      IT100RestServer.instance.exit!
      sleep(1)
      DSCLogger.instance.exit!
      @threads.each(&:join)
    end

    # Trap SIGTERM
    trap('TERM') do
      error 'Kill detected, waiting for all threads to exit gracefully...'
      @threads.each(&:kill)
      @threads.each(&:join)
    end

    # Start the logger loop
    @threads << Thread.new { DSCLogger.instance.start! }

    # Start the IT-100 event listener loop
    @threads << Thread.new do
      IT100SocketClient.instance.status
      IT100SocketClient.instance.start!
    end

    # Start the event handler loops
    @handlers.each { |h| @threads << Thread.new { h.instance.start! } }

    # Start the API REST server if requested
    @threads << Thread.new { IT100RestServer.instance.start! } if ENV['DSC_REST_SERVER_ACTIVE'] == 'true'

    # Wait on all threads
    @threads.each(&:join)
  end
end
