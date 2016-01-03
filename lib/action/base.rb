require 'singleton'

module DSCConnect
  module Action
    class Base
      include Singleton
      include LoggingHelper

      def source_event
        Thread.current.thread_variable_get(:event)
      end
    end
  end
end
