require 'rubygems'
require 'bundler/setup'

################################################################################

require "logger"
require "pp"
require "json"
require "zlib"

################################################################################

require_relative "lib/servers"
require_relative "lib/support"

File.truncate("link.log", 0)
File.truncate("combinator.log", 0)

class MultiLogger
  module ClassMethods
    @@loggers ||= Array.new
    def add(logger)
      @@loggers << logger
    end

    def loggers
      @@loggers
    end
  end
  extend ClassMethods

  def method_missing(method_name, *method_args, &block)
    self.class.loggers.each do |logger|
      logger.send(method_name, *method_args, &block)
    end
  end
end

def pp_inline(object)
  PP.singleline_pp(object, "")
end

################################################################################

ENV["DEBUG"] = "1"

SLEEP_TIME = 0.0001

STDOUT.sync = true

################################################################################
$logger = MultiLogger.new
MultiLogger.add(Logger.new(STDOUT))
MultiLogger.add(Logger.new("link.log"))

# $logger = Logger.new(STDOUT)
$logger.datetime_format = '%Y-%m-%d %H:%M:%S.%6N'
# $logger = Logger.new("link.log")
$logger.level = (!!ENV["DEBUG"] ? Logger::DEBUG : Logger::INFO)
Format = "%s [%s] %s: %s %s\n".freeze
$logger.formatter = proc do |severity, datetime, progname, msg|
  progname = "[#{progname.to_s.upcase.gsub("_", "-")}]"
  thread_name = Thread.current.thread_variable_get(:name) || "main"
  datetime = Time.now.utc.strftime('%Y-%m-%d %H:%M:%S.%6N')
  Format % [severity[0..0], datetime, thread_name, progname, msg]
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

require 'sinatra/base'

class WebServer < Sinatra::Application
  set :port, 4242

  get "/" do
    erb :index
  end

  get "/storage" do
    erb :storage, locals: { storage: Storage.clone, statistics: Storage.statistics }
  end

  get "/signals" do
    erb :signals, locals: { signals: Signals }
  end

  ThreadPool.thread("sinatra") do
    run! if app_file == $0
  end
end


################################################################################

ThreadPool.execute

################################################################################
