# frozen_string_literal: true

class Server
  class RCon

    module Queue

      def enqueue_packet(payload, callback: nil, type: RCon::PACKET_TYPE_COMMAND)
        packet_fields = build_packet(payload, type)
        unless callback.nil?
          register_packet_callback(packet_fields.id, callback)
        end
        @responses[packet_fields.id] = Concurrent::Promises.resolvable_future
        @packet_queue << OpenStruct.new(packet_fields: packet_fields)
        packet_fields
      end

      def get_queued_packet
        @packet_queue.shift
      end

    end

  end
end
