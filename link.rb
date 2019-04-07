################################################################################

require "logger"
require "pp"
require "json"
require "zlib"

################################################################################

require_relative "lib/servers"
require_relative "lib/support"

################################################################################

ENV["DEBUG"] = "1"

SLEEP_TIME = 0.0001

################################################################################

$logger = Logger.new(STDOUT)
# $logger = Logger.new("link.log")
$logger.level = (!!ENV["DEBUG"] ? Logger::DEBUG : Logger::INFO)

$threads = Array.new

################################################################################

Thread.abort_on_exception = true

################################################################################

Config.load("config.json")
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
  $threads.map(&:exit)
  Storage.save
end

################################################################################

require_relative "lib/tasks"
require_relative "lib/factorio"

################################################################################

ThreadPool.execute
$threads.map(&:join)

################################################################################
