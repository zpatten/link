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
      # RescueRetry.attempt(max_attempts: -1) do
        $logger.info { "[#{self.id}] Attempting connection to #{host_tag}" }

        $socket_write_mutex.synchronize do
          $socket_read_mutex.synchronize do
            @socket = ::TCPSocket.new(@host, @port)
          end
        end
        # @socket_mutex.synchronize {  }

        unless @socket.nil?
          @connected = true
          $logger.info { "[#{self.id}] Connected to #{host_tag}" }
          true
        else
          false
        end
      # end
    end

    def disconnect!
      if !@socket.nil?
        # puts "a"
        # $socket_write_mutex.lock
        # puts "b"
        # $socket_read_mutex.lock
        # puts "c"
        @socket.shutdown

        # $socket_write_mutex.unlock
        # $socket_read_mutex.unlock
        # @socket_mutex.synchronize { @socket.close }
        $logger.info { "[#{self.id}] Disconnected from #{host_tag}" }
      end
      @connected     = false
      @authenticated = false
    end

  end
end
