class RCon
  module Connection

    attr_reader :socket

    def host_tag
      "#{@name}@#{@host}:#{@port}"
    end

    def connected?
      !!@connected && !!@socket && !@socket.closed?
    end

    def disconnected?
      !connected?
    end

    def connect!
      # RescueRetry.attempt(max_attempts: -1) do
        $logger.info(:rcon) { "[#{self.id}] Attempting connection to #{host_tag}" }

        @socket = @socket_mutex.synchronize { TCPSocket.new(@host, @port) }

        unless @socket.nil? || @socket.closed?
          @connected = true
          @authenticated = false
          $logger.info(:rcon) { "[#{self.id}] Connected to #{host_tag}" }
          true
        else
          false
        end
      # end
    end

    def disconnect!
      @connected     = false
      @authenticated = false

      if !!@socket && !@socket.closed?
        @socket_mutex.synchronize { @socket.shutdown }
        $logger.info(:rcon) { "[#{self.id}] Disconnected from #{host_tag}" }
      end
    end

  end
end
