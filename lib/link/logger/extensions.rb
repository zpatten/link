# frozen_string_literal: true

module Link
  class Logger

################################################################################

    module Extensions

      def logger(loglevel=::Logger::DEBUG)
        $logger ||= Link::Logger::Engine.new(loglevel)
      end

    end

    Object.include(Link::Logger::Extensions)

################################################################################

  end
end
