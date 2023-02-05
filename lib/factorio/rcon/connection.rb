# frozen_string_literal: true

module Factorio
  class RCon

    module Connection

      attr_reader :socket

      def host_tag
        "#{@name}@#{@host}:#{@port}"
      end

      def connected?
        return false if @socket.nil?

        @socket_mutex.synchronize { @socket.remote_address }
        true
      rescue Errno::ENOTCONN
        false
      end

      def disconnected?
        !connected?
      end

      def connect!
        LinkLogger.info(tag) { "Attempting connection to #{host_tag.ai}" }

        @socket = @socket_mutex.synchronize { TCPSocket.new(@host, @port) }

        if connected?
          LinkLogger.info(tag) { "Connected to #{host_tag.ai}" }

          true
        else
          false
        end
      end

      def disconnect!
        if connected?
          @socket_mutex.synchronize { @socket.shutdown }
          LinkLogger.info(tag) { "Disconnected from #{host_tag.ai}" }
        end

        @authenticated = false
      end

    end

  end
end
