#!/usr/bin/env ruby

require 'optparse'
require 'dsc_isy_connect'
require 'it100_socket_client'

Thread.abort_on_exception = true
$stdout.sync = true

# Call the appropriate command
if ARGV.size > 0
  if ARGV[0] == 'server'
    DSCISYConnect.instance.start_server!
  elsif IT100SocketClient.instance.respond_to?(ARGV[0])
    cli_options = ARGV[1..-1].select { |a| a.start_with?('--') }
    options = nil
    OptionParser.new do |opts|
      cli_options.each do |cli_option|
        opt_name = cli_option[/^--([^=]+)(?:=(.*))?$/, 1]
        opt_value = cli_option[/^--([^=]+)(?:=(.*))?$/, 2]
        if opt_value
          opts.on("--#{opt_name}=VALUE") do |v|
            (options ||= {})[opt_name.tr('-', '_').to_sym] = v
          end
        else
          opts.on("--#{opt_name}") do
            (options ||= {})[opt_name.tr('-', '_').to_sym] = true
          end
        end
      end
    end.parse!
    if options
      IT100SocketClient.instance.send(ARGV[0], **options)
    else
      IT100SocketClient.instance.send(ARGV[0])
    end
  else
    # Execute the passed in command if provided
    exec(*ARGV)
  end
end
