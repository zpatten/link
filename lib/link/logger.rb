# frozen_string_literal: true

require 'link/logger/engine'
require 'link/logger/extensions'

module Link
  class Logger

################################################################################

    def initialize(level)
      @logger = Link::Logger::Engine.new(level)
      # Concurrent.use_simple_logger(level)
      Concurrent.configuration.logger = @logger.method(:add)
    end

    def method_missing(method_name, *method_args, &method_block)
      @logger.async.send(method_name, *method_args, &method_block)
    end

################################################################################

  end
end
