# frozen_string_literal: true

class RCon
  module Callback

    def register_packet_callback(packet_id, callback, data=nil)
      @callbacks[packet_id] = OpenStruct.new(id: packet_id, callback: callback, data: data)
    end

    def packet_callback(packet_fields)
      unless (pc = @callbacks.delete(packet_fields.id)).nil?
        @responses.delete(pc.id)
        tag = "#{rcon_tag}-callback-#{pc.id}"
        ThreadPool.thread(tag, priority: 3) do
          pc.callback.call(@name, packet_fields, pc.data)
        end
      end
    end

  end
end
