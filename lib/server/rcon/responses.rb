# frozen_string_literal: true

class Server
  class RCon

    module Responses

      RESPONSE_QUEUE_LENGTH = 64

      def register_response(packet_fields)
        unless @responses[packet_fields.id].nil?
          @responses[packet_fields.id].fulfill(packet_fields)
          $logger.debug(tag) { "Fulfilled Response (#{packet_fields.id})" }
        end

        true
      end

      def find_response(packet_id)
        packet_fields = @responses[packet_id].value
        $logger.debug(tag) { "Resolved Response(#{packet_id})" }
        packet_fields

      ensure
        @responses.delete(packet_id)
      end

    end

  end
end
