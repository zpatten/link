# frozen_string_literal: true

module Factorio
  class RCon

    module Responses

      RESPONSE_QUEUE_LENGTH = 64

      def register_response(packet_fields)
        unless @responses[packet_fields.id].nil?
          @responses[packet_fields.id].fulfill(packet_fields)
          LinkLogger.debug(tag) { "Fulfilled Response (#{packet_fields.id.ai})" }
        end

        true
      end

      def find_response(packet_id)
        packet_fields = @responses[packet_id].value
        LinkLogger.debug(tag) { "Resolved Response (#{packet_id.ai})" }
        packet_fields

      ensure
        @responses.delete(packet_id)
      end

    end

  end
end
