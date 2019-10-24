# frozen_string_literal: true

class RCon
  module Responses

    RESPONSE_QUEUE_LENGTH = 64

    def register_response(packet_fields)
      $logger.debug(:rcon) { "Registered Response for Packet ID #{packet_fields.id}" }
      @responses[packet_fields.id] = packet_fields
      $logger.debug(:rcon) { "Registered Response Count is #{@responses.count}" }

      true
    end

    def find_response(packet_id)
      Thread.stop while (response = @responses.delete(pc.id)).nil?
      $logger.debug(:rcon) { "Find Response(#{packet_id}): #{response}" }
      response
    end

  end
end
