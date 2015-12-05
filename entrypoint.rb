#!/usr/bin/env ruby
require 'active_support'
require 'active_support/core_ext'
require 'awesome_print'
require 'pry'

# Require all library files
%w( logging_helper it100_command worker_thread_base ).each do |file_name|
  require "#{ENV['RUBYLIB']}/#{file_name}.rb"
end
Dir[File.join(ENV['RUBYLIB'], '*.rb')].each { |f| require f }

Thread.abort_on_exception = true
$stdout.sync = true

socket_commands = %w(
  poll
  status
  labels
  set_datetime
  arm_away
  arm_stay
  arm
  disarm
  timestamp_control
  datetime_broadcast
  code_send
  key_press
  acknowledge_trouble
)
case ARGV[0]
when 'server'
  DSCConnect::IT100EventServer.instance.start!
when *socket_commands
  DSCConnect::IT100CommandExec.instance.run!(ARGV[0], *ARGV[1..-1].select { |a| a.start_with?('--') })
when 'pry'
  binding.pry
else
  exec(*ARGV) if ARGV.size > 0
end
