class RCon
  module Responses

    RESPONSE_QUEUE_LENGTH = 64

    def register_response(packet_fields)
      $logger.debug { "Registered Response: #{packet_fields.id}" }
      @response_mutex.synchronize do
        @responses << packet_fields

        if @responses.count > RESPONSE_QUEUE_LENGTH
          @responses = @responses[-RESPONSE_QUEUE_LENGTH, RESPONSE_QUEUE_LENGTH]
        end
      end

      true
    end

    def find_response(packet_id)
      results = @response_mutex.synchronize do
        @responses.select { |r| r.id == packet_id }.first
      end

      unless results.nil?
        $logger.debug { "Find Response(#{packet_id}): #{results}" }
      end

      results
    end

  end
end
