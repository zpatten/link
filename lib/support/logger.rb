# frozen_string_literal: true

FileUtils.touch('link.log')
File.truncate("link.log", 0)

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

  def mutex(logger)
    @logger_mutex ||= Hash.new
    @logger_mutex[logger] ||= Mutex.new
  end

  def method_missing(method_name, *method_args, &block)
    self.class.loggers.each do |logger|
      # mutex(logger.to_s).synchronize do
        logger.send(method_name, *method_args, &block)
      # end
    end
  end
end

# $logger = MultiLogger.new
# MultiLogger.add(Logger.new(STDOUT))
# MultiLogger.add(Logger.new("link.log"))

# $logger = Logger.new(STDOUT)
$logger = Logger.new("link.log")

$logger.level = Logger::INFO

$logger.datetime_format = '%Y-%m-%d %H:%M:%S.%6N'

DebugFormat = "%s [%s] %d %s %s - %s\n".freeze
InfoFormat = "%s [%s] %d %s %s\n".freeze

$logger.formatter = proc do |severity, datetime, progname, msg|
  progname = "[#{progname.to_s.upcase.gsub("_", "-")}]"
  thread_name = Thread.current.name || "main"
  loc = caller_locations(4,1).first
  caller_name = "(#{thread_name}:#{File.basename(loc.path)}:#{loc.lineno}:#{loc.label})"
  datetime = Time.now.strftime('%Y-%m-%d %H:%M:%S.%6N')

  message = if $logger.level == Logger::DEBUG
    DebugFormat % [severity[0..0], datetime, Process.pid, progname, msg, caller_name]
  else
    DebugFormat % [severity[0..0], datetime, Process.pid, progname, msg, caller_name]
    # InfoFormat % [severity[0..0], datetime, Process.pid, progname, msg]
  end

  if defined?(WebServer)
    WebServer.settings.sockets.each do |s|
      s.send(message)
    end
  end

  message
end
