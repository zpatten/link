# frozen_string_literal: true

class RCon
  module Packet

    PACKET_TYPE_LOGIN    = 3
    PACKET_TYPE_COMMAND  = 2
    PACKET_TYPE_RESPONSE = 0

    BASE_PACKET_LENGTH = 10

    def build_packet(payload, type=PACKET_TYPE_COMMAND)
      packet_fields = OpenStruct.new(
        length: (BASE_PACKET_LENGTH + payload.bytesize),
        id: SecureRandom.random_number((2**32) - 1),
        type: type,
        payload: payload
      )
      $logger.debug(:rcon) { "[#{rcon_tag}] Built Packet ID #{packet_fields.id}" }
      packet_fields
    end

    def recv_packet_data(length)
      return nil if disconnected?

      buffer = StringIO.new
      while buffer.length < length do
        data = socket.recv_nonblock(length, 0, nil, exception: false)
        if data == :wait_readable
          IO.select([socket])
          next
        end
        buffer.write(data)
      end
      buffer.rewind
      buffer.read
    rescue Errno::ECONNABORTED, Errno::ESHUTDOWN
      # server is shutting down
    end

    def recv_packet
      return nil if disconnected?

      buffer = StringIO.new
      length = recv_packet_data(4)
      return nil if length.nil?
      buffer.write(length)

      length = length.unpack("L<").first
      data = recv_packet_data(length)
      buffer.write(data)

      buffer.rewind
      packet_fields = decode_packet(buffer.read)
      $logger.debug(:rcon) { %([#{rcon_tag}:#{packet_fields.id}] RCON< #{packet_fields.payload.to_s.strip}) }
      register_response(packet_fields)
      packet_fields
    end

    def receive_packet
      received_packet = recv_packet
      return if received_packet.nil?

      raise "[#{rcon_tag}] Authentication Failed!" if received_packet.id == -1
      packet_callback(received_packet)
    end

    def send_packet(packet_fields)
      return nil if disconnected?

      encoded_packet = encode_packet(packet_fields)

      buffer = StringIO.new
      buffer.write(encoded_packet)

      total_sent = 0
      begin
        buffer.seek(total_sent)
        total_sent += socket.send(buffer.read, 0)
      end while total_sent < buffer.length

      $logger.debug(:rcon) { %([#{rcon_tag}:#{packet_fields.id}] RCON> #{packet_fields.payload.to_s.strip}) }

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
