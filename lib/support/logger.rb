# frozen_string_literal: true

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

################################################################################

class LinkLogger < Logger

  DebugFormat = "%s [%s] %s %s - %s\n".freeze
  InfoFormat  = "%s [%s] %s %s\n".freeze

################################################################################

  def initialize(device)
    super(device)

    self.datetime_format = '%Y-%m-%d %H:%M:%S.%6N'
    self.level           = Logger::INFO
    self.formatter       = Proc.new do |severity, datetime, progname, msg|
      progname    = "[#{progname.to_s.upcase.gsub("_", "-")}]"
      thread_name = Thread.current.name || "main"
      loc         = caller_locations(4,1).first
      caller_name = "(#{thread_name}:#{File.basename(loc.path)}:#{loc.lineno}:#{loc.label})"
      datetime    = Time.now.strftime('%Y-%m-%d %H:%M:%S.%6N')

      message = if LinkLogger.level == Logger::DEBUG
        DebugFormat % [severity[0..0], datetime, progname, msg, caller_name]
      else
        DebugFormat % [severity[0..0], datetime, progname, msg, caller_name]
        # InfoFormat % [severity[0..0], datetime, progname, msg]
      end

      if RUBY_ENGINE == 'ruby' && defined?(WebServer)
        WebServer.settings.sockets.each do |s|
          s.send(message)
        end
      end

      message
    end
  end

################################################################################

  module ClassMethods
    LOGFILE = File.join(LINK_ROOT, 'link.log')

    FileUtils.touch(LOGFILE)
    File.truncate(LOGFILE, 0)

    # @@logger ||= begin
    #   multi_logger = MultiLogger.new
    #   multi_logger.add(LinkLogger.new(STDOUT))
    #   multi_logger.add(LinkLogger.new(LOGFILE))
    #   multi_logger
    # end

    @@logger ||= LinkLogger.new(LOGFILE)

    def method_missing(method_name, *method_args, &block)
      @@logger.send(method_name, *method_args, &block)
    end
  end

  extend ClassMethods

################################################################################

end
