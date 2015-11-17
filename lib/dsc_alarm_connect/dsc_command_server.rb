require 'optparse'

class DSCCommandServer
  include Singleton

  def run!(command, *args)
    options = {}
    OptionParser.new do |opts|
      args.each do |arg|
        opt_name = arg[/^--([^=]+)(?:=(.*))?$/, 1]
        opt_value = arg[/^--([^=]+)(?:=(.*))?$/, 2]
        if opt_value
          opts.on("--#{opt_name}=VALUE") do |v|
            options[opt_name.tr('-', '_').to_sym] = v
          end
        else
          opts.on("--#{opt_name}") do
            options[opt_name.tr('-', '_').to_sym] = true
          end
        end
      end
    end.parse!

    threads = []

    # Start the IT-100 event listener loop
    threads << Thread.new { IT100SocketClient.instance.start! }

    # Start default and optional event handlers
    threads << Thread.new { IT100EventHandler.instance.start! }

    # Execute the command
    if options.size > 0
      IT100SocketClient.instance.send(ARGV[0], **options)
    else
      IT100SocketClient.instance.send(ARGV[0])
    end
  end
end
