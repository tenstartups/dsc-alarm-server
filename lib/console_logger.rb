require 'colorize'
require 'singleton'

module DSCConnect
  class ConsoleLogger
    include Singleton

    def initialize
      @available_colors = []
      @log_colors = {}
      @log_queue = Queue.new
    end

    def log(source_id:, severity: :info, message:)
      @log_queue.push source_id: source_id, severity: severity, message: message
    end

    %i[ debug info warn error ].each do |severity|
      define_method :"log_#{severity}" do |source_id, message|
        log severity: severity.to_sym, source_id: source_id, message: message
      end
    end

    def start!
      @process_thread ||= Thread.new do
        log!(source_id: self.class.name.split('::').last, severity: :debug, message: 'Starting processing thread')
        @thread_ready = true
        until @quit_thread && @log_queue.empty?
          log!(**@log_queue.pop) until @log_queue.empty?
          sleep 0.01
        end
        log!(source_id: self.class.name.split('::').last, severity: :debug, message: 'Quitting processing thread')
      end
      @process_thread.tap { sleep 0.01 until @thread_ready }
      log!(source_id: self.class.name.split('::').last, severity: :debug, message: 'Processing thread ready')
    end

    def wait!
      @process_thread.join
    end

    def quit!
      @quit_thread = true
      wait!
    end

    private

    def next_available_color
      @available_colors = (String.colors.shuffle - %i( yellow red black white )) if @available_colors.empty?
      @available_colors.slice!(0)
    end

    def log_prefix(source_id)
      log_color = (@log_colors[source_id] ||= next_available_color)
      "#{source_id.ljust(20)} | ".colorize(log_color)
    end

    def log!(source_id:, severity: :info, message:)
      stream, message = case severity
                        when :debug
                          [:stdout, message.colorize(:light_magenta)]
                        when :info
                          [:stdout, message]
                        when :warn
                          [:stderr, message.colorize(:yellow)]
                        when :error
                          [:stderr, message.colorize(:red)]
                        else
                          [:stdout, message]
                        end
      message = "#{log_prefix(source_id)} #{message}"
      case stream
      when :stdout
        STDOUT.puts message
      when :stderr
        STDERR.puts message
      else
        puts message
      end
    end
  end
end
