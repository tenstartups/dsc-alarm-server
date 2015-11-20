require 'colorize'
require 'singleton'

class DSCLogger
  include Singleton

  attr_reader :started

  def initialize
    @available_colors = []
    @log_colors = {}
    @log_queue = Queue.new
  end

  %i[ debug info warn error ].each do |severity|
    define_method :"log_#{severity}" do |source_id, message|
      log severity: severity.to_sym, source_id: source_id, message: message
    end
  end

  def start!
    log!(source_id: self.class.name, severity: :debug, message: 'Entering processing loop')
    @started = true
    until @loop_exit
      log!(**@log_queue.pop) until @log_queue.empty?
      sleep 0.01
    end
    log!(source_id: self.class.name, severity: :debug, message: 'Exiting processing loop')
  end

  def exit!
    @loop_exit = true
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

  def log(source_id:, severity: :info, message:)
    @log_queue.push source_id: source_id, severity: severity, message: message
  end

  def log!(source_id:, severity: :info, message:)
    stream, message = case severity
                      when :debug
                        [:stdout, message.colorize(:purple)]
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
