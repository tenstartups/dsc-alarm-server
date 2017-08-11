require 'singleton'

module DSCConnect
  module Action
    class Error < StandardError; end

    class Base
      include Singleton
      include LoggingHelper

      attr_accessor :config

      def config
        @config ||= {}
      end

      private

      def source_event
        Thread.current.thread_variable_get(:event)
      end
    end
  end
end
