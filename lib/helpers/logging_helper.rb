require 'colorize'

module LoggingHelper
  def output_color
    @output_color ||= (String.colors - %i( yellow red black white )).sample
  end

  def log(message)
    puts "#{self.class.name.ljust(20)} | ".colorize(output_color) + message
  end

  def warn(message)
    puts "#{self.class.name.ljust(20)} | ".colorize(output_color) + message.colorize(:yellow)
  end
end
