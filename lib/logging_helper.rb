module LoggingHelper
  %i[ debug info warn error ].each do |severity|
    define_method severity do |message|
      DSCLogger.instance.send(:"log_#{severity}", self.class.name, message)
    end
  end
  alias_method :log, :info
end
