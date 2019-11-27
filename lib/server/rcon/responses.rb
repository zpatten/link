# frozen_string_literal: true

class Server
  class RCon

    module Responses

      RESPONSE_QUEUE_LENGTH = 64

      def register_response(packet_fields)
        $logger.debug(:rcon) { "[#{rcon_tag}:#{packet_fields.id}] Registered Response for Packet" }
        @responses[packet_fields.id] = packet_fields
        $logger.debug(:rcon) { "[#{rcon_tag}] Registered Response Count is #{@responses.count}" }

        true
      end

      def find_response(packet_id)
        sleep SLEEP_TIME while (response = @responses.delete(packet_id)).nil?
        $logger.debug(:rcon) { "[#{rcon_tag}] Find Response(#{packet_id}): #{response}" }
        response
      end

    end

  end
end
