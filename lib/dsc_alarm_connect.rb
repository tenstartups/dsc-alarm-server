require 'awesome_print'

# Require all library files
%w( logging_helper dsc_command ).each do |file_name|
  require File.join(File.dirname(__FILE__), file_name)
end
Dir[File.join(File.dirname(__FILE__), '*.rb')].each { |f| require f }

Thread.abort_on_exception = true
$stdout.sync = true

case
when ARGV[0] == 'server'
  DSCEventServer.instance.start!
else
  DSCCommandServer.instance.run!(ARGV[0], *ARGV[1..-1].select { |a| a.start_with?('--') })
end
