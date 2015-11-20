require 'singleton'
require 'timeout'

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
    # Start the logger loop
    @threads << Thread.new { DSCLogger.instance.start! }

    # Start the IT-100 event listener loop
    @threads << Thread.new { IT100SocketClient.instance.start! }

    # Start the event handler loops
    @handlers.each { |h| @threads << Thread.new { h.instance.start! } }

    # Start the API REST server if requested
    @threads << Thread.new { IT100RestServer.instance.start! } if ENV['DSC_REST_SERVER_ACTIVE'] == 'true'

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

    # Trigger a full status dump
    begin
      timeout(60) do
        sleep(0.1) until IT100SocketClient.instance.started &&
                         @handlers.all? { |h| h.instance.started } &&
                         IT100RestServer.instance.started &&
                         DSCLogger.instance.started
      end
    rescue Timeout::Error
      STDERR.puts 'Timed out waiting for process threads to start'
      exit(1)
    end
    IT100SocketClient.instance.status

    # Wait on all threads
    @threads.each(&:join)
  end
end
