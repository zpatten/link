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
$logger.datetime_format = '%Y-%m-%d %H:%M:%S.%6N'
# $logger = Logger.new("link.log")
$logger.level = (!!ENV["DEBUG"] ? Logger::DEBUG : Logger::INFO)
Format = "%s [%s] %s: %s\n".freeze
$logger.formatter = proc do |severity, datetime, progname, msg|
  progname = Thread.current.thread_variable_get(:name) || "main"
  datetime = Time.now.utc.strftime('%Y-%m-%d %H:%M:%S.%6N')
  Format % [severity[0..0], datetime, progname,
        msg]
  # "#{datetime}: #{msg}\n"
end

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
  ThreadPool.shutdown!
  Storage.save
  $logger.close
end

################################################################################

require_relative "lib/tasks"
require_relative "lib/factorio"

################################################################################

ThreadPool.execute

################################################################################
