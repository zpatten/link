# frozen_string_literal: true

class Server
  class RCon

    module Callback

      def register_packet_callback(packet_id, callback)
        @callbacks[packet_id] = OpenStruct.new(
          id: packet_id,
          callback: callback
        )
      end

      def packet_callback(packet_fields)
        unless (pc = @callbacks.delete(packet_fields.id)).nil?
          @responses.delete(pc.id)
          tag = [rcon_tag, 'callback', pc.what, pc.id].compact.join('-')
          ThreadPool.thread(tag, priority: 3) do
            pc.callback.call(@name, packet_fields)
          end
        end
      end

    end

  end
end
