require 'rubygems'
require 'bundler/setup'

################################################################################

require "logger"
require "pp"
require "json"
require "zlib"

require "active_support/core_ext"

################################################################################

ENV["DEBUG"] = "1"

SLEEP_TIME = 0.0001

STDOUT.sync = true
Thread.abort_on_exception = true

################################################################################

require_relative "lib/options"

################################################################################


require_relative "lib/support"

Config.load

require_relative "lib/servers"
require_relative "lib/tasks"
require_relative "lib/factorio"
require_relative "lib/web_server"

Config.servers.present? and Config.servers.each_pair do |server_name, server_details|
  Servers.register(server_name, server_details)
end



################################################################################

Requests.reset

################################################################################

%w( INT ).each do |signal|
  Signal.trap(signal) do
    $stderr.puts "Caught Signal: #{signal}"
    exit
  end
end

################################################################################

at_exit do
  $stderr.puts "Shutting down!"
  Servers.shutdown!
  ThreadPool.shutdown!
  Storage.save
  $logger.close
end

################################################################################

ThreadPool.execute

################################################################################
