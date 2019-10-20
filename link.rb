#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

################################################################################

require "logger"
require "pp"
require "json"
require "zlib"

# require "active_support/core_ext"

################################################################################

SLEEP_TIME = 0.0001
LINK_ROOT = Dir.pwd

STDOUT.sync = true
Thread.abort_on_exception = true

################################################################################

require_relative "lib/support/config"
Config.load

################################################################################

require_relative "lib/support"
require_relative "lib/servers"
require_relative "lib/tasks"
require_relative "lib/factorio"
require_relative "lib/web_server"

$logger.level = Logger::INFO

################################################################################

%w( INT ).each do |signal|
  Signal.trap(signal) do
    $stderr.puts "Caught Signal: #{signal}"
    exit
  end
end

require_relative "lib/options"

################################################################################

at_exit do
  $stderr.puts "Shutting down!"
  Servers.shutdown!
  ThreadPool.shutdown!
  Storage.save
  $logger.close
end

################################################################################

Requests.reset

schedule_server_chats
schedule_server_command_whitelist
schedule_server_commands
schedule_server_current_research
schedule_server_id
schedule_server_ping
schedule_server_providables
schedule_server_research
schedule_server_rx_signals
schedule_server_tx_signals
schedule_servers_requests
schedule_task_statistics

ThreadPool.execute

################################################################################

