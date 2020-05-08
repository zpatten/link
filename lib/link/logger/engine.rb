# frozen_string_literal: true

module Link
  class Logger

################################################################################

    class Engine
      include Concurrent::Async

      MESSAGE_FORMAT  = "%s [%s] %d/%s(%s): %s\n".freeze
      DATETIME_FORMAT = "%Y-%m-%d %H:%M:%S.%6N".freeze

      def initialize(level)
        super()
        @logger = ::Logger.new(STDOUT)
        @logger.level = level
        @logger.datetime_format = DATETIME_FORMAT
        @logger.formatter = proc do |severity, datetime, progname, msg|
          caller = caller_locations[4]
          message = MESSAGE_FORMAT % [
            severity[0..0],
            Time.now.strftime(DATETIME_FORMAT),
            Process.pid,
            Thread.current.name ||Thread.current.object_id.to_s,
            "#{File.basename(caller.path)}:#{caller.lineno}:#{caller.label}",
            msg
          ]
          # stream to web server websocket here
          message
        end

      end

      def method_missing(method_name, *method_args, &method_block)
        @logger.send(method_name, *method_args, &method_block)
      end
    end

################################################################################

  end
end
