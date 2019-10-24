class RCon
  module Callback

    def register_packet_callback(packet_id, callback, data=nil)
      # @callback_mutex.synchronize { @callbacks[packet_id] = OpenStruct.new(id: packet_id, callback: callback, data: data) }
      @callbacks[packet_id] = OpenStruct.new(id: packet_id, callback: callback, data: data)
    end

    def packet_callback(packet_fields)
      # pc = @callback_mutex.synchronize { @callbacks[packet_fields.id] }
      unless (pc = @callbacks[packet_fields.id]).nil?
        tag = "#{rcon_tag}-callback-#{pc.id}"
        ThreadPool.thread(tag) do
          pc.callback.call(@name, packet_fields, pc.data)
        end
        @callbacks.delete(pc.id)
      end
    end

  end
end
