class RCon
  module Connection

    attr_reader :socket

    def host_tag
      "#{@name}@#{@host}:#{@port}"
    end

    def connected?
      !!@connected
    end

    def disconnected?
      !connected?
    end

    def connect!
      RescueRetry.attempt(max_attempts: -1) do
        $logger.info { "Attempting connection to #{host_tag}" }

        @socket_mutex.synchronize { @socket = ::TCPSocket.new(@host, @port) }

        unless @socket.nil?
          @connected = true
          $logger.info { "Connected to #{host_tag}" }
          true
        else
          false
        end
      end
    end

    def disconnect!
      if !@socket.nil?
        @socket_mutex.synchronize { @socket.close }
        $logger.info { "Disconnected from #{host_tag}" }
      end
      @connected     = false
      @authenticated = false
    end

  end
end
