begin
  File.truncate("link.log", 0)
rescue Errno::EACCES, Errno::ENOENT
end

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

$logger = Logger.new(STDOUT)

# $logger = Logger.new(STDOUT)
$logger.datetime_format = '%Y-%m-%d %H:%M:%S.%6N'

# $logger = Logger.new("link.log")
Format = "%s [%s] %s: %s %s\n".freeze

$logger.formatter = proc do |severity, datetime, progname, msg|
  progname = "[#{progname.to_s.upcase.gsub("_", "-")}]"
  thread_name = Thread.current.thread_variable_get(:name) || "main"
  datetime = Time.now.utc.strftime('%Y-%m-%d %H:%M:%S.%6N')
  message = Format % [severity[0..0], datetime, thread_name, progname, msg]
  # if defined?(WebServer)
  #   # EM.next_tick do
  #     WebServer.settings.sockets.each do |s|
  #       s.send(message)
  #     end
  #   # end
  # end
  message
  # "#{datetime}: #{msg}\n"
end
