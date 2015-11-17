require 'awesome_print'

# Require all library files
Dir[File.join(File.dirname(__FILE__), 'helpers', '*.rb')].each { |f| require f }
require File.join(File.dirname(__FILE__), 'dsc_alarm_connect', 'dsc_command.rb')
Dir[File.join(File.dirname(__FILE__), 'dsc_alarm_connect', '*.rb')].each { |f| require f }

Thread.abort_on_exception = true
$stdout.sync = true

case
when ARGV[0] == 'server'
  DSCEventServer.instance.start!
else
  DSCCommandServer.instance.run!(ARGV[0], *ARGV[1..-1].select { |a| a.start_with?('--') })
end
