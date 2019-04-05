class RCon
  module Callback

    def register_packet_callback(packet_id, callback, data=nil)
      @callback_mutex.synchronize { @callbacks << OpenStruct.new(id: packet_id, callback: callback, data: data) }
    end

    def packet_callback(packet_fields)
      pc = @callback_mutex.synchronize { @callbacks.select { |cb| cb.id == packet_fields.id }.first }
      unless pc.nil?
        pc.callback.call(@name, packet_fields, pc.data)
        @callback_mutex.synchronize { @callbacks.delete(pc) }
      end
    end

  end
end
