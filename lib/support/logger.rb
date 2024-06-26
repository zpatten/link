# frozen_string_literal: true

require 'logger'

################################################################################

class MultiLogger
  def method_missing(method_name, *method_args, &block)
    self.class.loggers.each do |logger|
      logger.send(method_name, *method_args, &block)
    end
  end

  def respond_to?(method_name, include_private=false)
    unless (logger = self.class.loggers.first).nil?
      logger.public_methods.include?(method_name) || super
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private=false)
    unless (logger = self.class.loggers.first).nil?
      logger.public_methods.include?(method_name) || super
    else
      super
    end
  end

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
      loc         = caller_locations(5,1).first
      caller_name = "(#{thread_name}:#{File.basename(loc.path)}:#{loc.lineno}:#{loc.label})"
      datetime    = Time.now.strftime('%Y-%m-%d %H:%M:%S.%6N')

      message = if self.level == Logger::DEBUG
        DebugFormat % [severity[0..0], datetime, progname, msg, caller_name]
      else
        InfoFormat % [severity[0..0], datetime, progname, msg]
      end

      message
    end

    self.info(:logger) { "---START--- @ #{Time.now.utc}" }
  end

################################################################################

  module ClassMethods
    LOGFILE = STDOUT

    # LOGFILE = File.join(LINK_ROOT, 'link.log')
    # FileUtils.touch(LOGFILE)
    # File.truncate(LOGFILE, 0)

    # @@logger ||= begin
    #   multi_logger = MultiLogger.new
    #   multi_logger.add(LinkLogger.new(STDOUT))
    #   multi_logger.add(LinkLogger.new(LOGFILE))
    #   multi_logger
    # end

    @@logger ||= LinkLogger.new(LOGFILE)
    @@logger_methods ||= (@@logger.public_methods + LinkLogger.instance_methods).flatten
    @@mutex ||= Mutex.new

    def method_missing(method_name, *method_args, &block)
      if @@logger_methods.include?(method_name)
        @@mutex.synchronize do
          @@logger.send(method_name, *method_args, &block)
        end
      else
        super
      end
    end

    def respond_to?(method_name, include_private=false)
      @@logger_methods.include?(method_name) || super
    end

    def respond_to_missing?(method_name, include_private=false)
      @@logger_methods.include?(method_name) || super
    end

  end

  extend ClassMethods

################################################################################

end
