#!/usr/bin/env ruby

require 'dsc_isy_bridge'

Thread.abort_on_exception = true
$stdout.sync = true

# Call the appropriate command
dsc_isy_bridge = DSCISYBridge.new
case ARGV[0]
when 'server'
  dsc_isy_bridge.start
else
  dsc_isy_bridge.run_command(*ARGV)
end
