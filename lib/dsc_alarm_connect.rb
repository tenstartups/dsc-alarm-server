require 'awesome_print'

# Require all library files
Dir[File.join(File.dirname(__FILE__), 'helpers', '*.rb')].reverse.each { |f| require f }
Dir[File.join(File.dirname(__FILE__), 'dsc_alarm_connect', '*.rb')].reverse.each { |f| require f }

Thread.abort_on_exception = true
$stdout.sync = true

case
when ARGV[0] == 'server'
  DSCEventServer.instance.start!
else
  DSCCommandServer.instance.run!(ARGV[0], *ARGV[1..-1].select { |a| a.start_with?('--') })
end
