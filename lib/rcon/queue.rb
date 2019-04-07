class RCon
  module Queue

    def enqueue_packet(payload, callback=nil, data=nil, type=RCon::PACKET_TYPE_COMMAND)
      packet_fields = build_packet(payload, type)
      unless callback.nil?
        register_packet_callback(packet_fields.id, callback, data)
      end
      @queue_mutex.synchronize { @packet_queue << OpenStruct.new(packet_fields: packet_fields) }
      packet_fields
    end

    def get_queued_packet
      @queue_mutex.synchronize { @packet_queue.shift }
    end

    def packet_queue_count
      @queue_mutex.synchronize { @packet_queue.count }
    end

  end
end
