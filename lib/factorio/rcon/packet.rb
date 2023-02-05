# frozen_string_literal: true
require 'stringio'

module Factorio
  class RCon

    module Packet

      PACKET_TYPE_LOGIN    = 3
      PACKET_TYPE_COMMAND  = 2
      PACKET_TYPE_RESPONSE = 0

      BASE_PACKET_LENGTH = 10

      def build_packet(payload, type=PACKET_TYPE_COMMAND)
        packet_fields = OpenStruct.new(
          length: (BASE_PACKET_LENGTH + payload.bytesize),
          id: SecureRandom.random_number(2**32),
          type: type,
          payload: payload
        )
        LinkLogger.debug(tag) { "Built Packet ID #{packet_fields.id}" }
        packet_fields
      end

      def recv_packet_data(length)
        return nil if disconnected?

        buffer = ''
        while buffer.length < length do
          break if disconnected? || @cancellation.canceled?
          len = (length - buffer.length)
          data = nil
          data = @socket.recv(len) unless disconnected? || @cancellation.canceled? || IO.select([@socket], nil, nil, 1).nil?
          buffer += data unless data.nil?
          # data = socket.recvmsg_nonblock(len, exception: false)
          # if data == :wait_readable
          #   IO.select([socket])
          # else
          #   buffer += data.first
          # end
        end
        buffer
        # IO.select([@socket])
        # buffer = @socket.recv(length)
      rescue Errno::ECONNABORTED, Errno::ESHUTDOWN, IOError
        # server is shutting down
      end

      def recv_packet
        return nil if disconnected?

        buffer = StringIO.new
        length = recv_packet_data(4)
        return nil if length.nil?
        buffer.write(length)

        length = length.unpack("L<").first
        return nil if length.nil?
        data = recv_packet_data(length)
        buffer.write(data)

        buffer.rewind
        return nil if buffer.length != (length + 4)

        packet_fields = decode_packet(buffer.read)
        if packet_fields.payload.to_s =~ /error/i then
          LinkLogger.error(tag) { %([RCON:#{packet_fields.id}] RCON< #{packet_fields.payload.to_s.strip}) }
        else
          LinkLogger.debug(tag) { %([RCON:#{packet_fields.id}] RCON< #{packet_fields.payload.to_s.strip}) }
        end
        register_response(packet_fields)
        packet_fields
      end

      def receive_packet
        received_packet = recv_packet
        return if received_packet.nil?

        raise "[#{tag}] Authentication Failed!" if received_packet.id == -1
        packet_callback(received_packet)
      end

      def send_packet
        # loop do
        #   return nil if disconnected? || @cancellation.canceled?
        #   break if get_queue_count > 0
        #   Thread.pass
        # end
        # return nil if disconnected?

        # return nil if get_queue_count == 0
        packet         = get_queued_packet
        packet_fields  = packet.packet_fields
        encoded_packet = encode_packet(packet_fields)

        buffer = StringIO.new
        buffer.write(encoded_packet)
        buffer.rewind

        # total_sent = 0
        # while total_sent < buffer.length
        #   buffer.seek(total_sent)
        #   # IO.select(nil, [@socket])
        #   bytes_sent = @socket.send(buffer.read, 0)
        #   total_sent += bytes_sent unless bytes_sent.nil?

        #   # data = socket.sendmsg_nonblock(buffer.read)
        #   # if data == :wait_writeable
        #   #   IO.select(nil, [socket])
        #   # else
        #   #   total_sent += data
        #   # end
        # end

        total_sent = 0
        total_sent = @socket.send(buffer.read, 0) unless disconnected? || @cancellation.canceled? || IO.select(nil, [@socket], nil, 1).nil?

        LinkLogger.debug(tag) { %([RCON:#{packet_fields.id}] RCON> #{packet_fields.payload.to_s.strip}) }

        total_sent
      rescue Errno::ECONNABORTED, Errno::ESHUTDOWN
        # server is shutting down
      end

      def encode_packet(packet_fields)
        len = [packet_fields.length].pack("L<")
        id = [packet_fields.id].pack("L<")
        type = [packet_fields.type].pack("L<")
        payload = [packet_fields.payload].pack("Z*x")

        (len + id + type + payload)
      end

      def decode_packet(packet)
        packet_fields = packet.unpack("L<L<L<Z*x")

        OpenStruct.new(
          length: packet_fields[0],
          id: packet_fields[1],
          type: packet_fields[2],
          payload: packet_fields[3]
        )
      end

    end

  end
end
