module DSCConnect
  module LoggingHelper
    %i(debug info warn error).each do |severity|
      define_method severity do |message|
        ConsoleLogger.instance.send(:"log_#{severity}", self.class.name.split('::').last, message)
      end
    end

    def log(severity, message)
      ConsoleLogger.instance.send(:log, source_id: self.class.name.split('::').last, severity: severity, message: message)
    end
  end
end
