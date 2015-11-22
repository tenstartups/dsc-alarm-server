module DSCConnect
  module LoggingHelper
    %i[ debug info warn error ].each do |severity|
      define_method severity do |message|
        Logger.instance.send(:"log_#{severity}", self.class.name.split('::').last, message)
      end
    end
    alias_method :log, :info
  end
end
