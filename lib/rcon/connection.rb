# frozen_string_literal: true

class RCon
  module Connection

    attr_reader :socket

    def host_tag
      "#{@name}@#{@host}:#{@port}"
    end

    def connected?
      return false if @socket.nil?

      @socket.remote_address
      true
    rescue Errno::ENOTCONN
      false
    end

    def disconnected?
      !connected?
    end

    def connect!
      $logger.info(:rcon) { "[#{self.id}] Attempting connection to #{host_tag}" }

      @socket = @socket_mutex.synchronize { TCPSocket.new(@host, @port) }

      if connected?
        $logger.info(:rcon) { "[#{self.id}] Connected to #{host_tag}" }

        true
      else
        false
      end
    end

    def disconnect!
      if connected?
        @socket_mutex.synchronize { @socket.shutdown }
        $logger.info(:rcon) { "[#{self.id}] Disconnected from #{host_tag}" }
      end

      @authenticated = false
    end

  end
end
