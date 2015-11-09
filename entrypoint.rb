#!/usr/bin/env ruby

require 'dsc_isy_event_server'
require 'dsc_command'
require 'optparse'

Thread.abort_on_exception = true
$stdout.sync = true

# Call the appropriate command
case ARGV[0]
when 'server'
  DSCISYEventServer.new.start
else
  cli_options = ARGV[1..-1]
                .select { |a| a.start_with?('--') }
                .map { |a| a.split('=').first }
                .each { |a| a.slice!('--') }
  options = {}
  OptionParser.new do |opts|
    cli_options.each do |cli_option|
      opts.on("--#{cli_option}=VALUE") do |v|
        options[cli_option.to_sym] = v
      end
    end
  end.parse!
  DSCCommand.new(read_response: true).send(ARGV[0], **options)
end
