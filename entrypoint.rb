#!/usr/bin/env ruby

require 'dsc_isy_bridge'

Thread.abort_on_exception = true
$stdout.sync = true

dsc_isy_bridge = DSCISYBridge.new
dsc_isy_bridge.start
