class DSCEventServer
  include Singleton

  def start!
    threads = []

    # Start the IT-100 event listener loop
    threads << Thread.new { IT100SocketClient.instance.start! }

    # Start default and optional event handlers
    ENV['DSC_EVENT_HANDLER_DEFAULT'] = 'IT100EventHandler'
    handlers = ENV.keys.grep(/^DSC_EVENT_HANDLER_([_A-Z0-9]+)/).map { |e| ENV[e] }
    handlers.each do |handler|
      threads << Thread.new { ActiveSupport::Inflector.constantize(handler).instance.start! }
    end

    # Trigger a status dump
    IT100SocketClient.instance.status

    # Start the API REST server if requested
    threads << Thread.new { IT100RestServer.instance.start! } if ENV['DSC_REST_SERVER_ACTIVE'] == 'true'

    # Wait on all threads
    threads.each(&:join)
  end
end
