# frozen_string_literal: true

require_relative 'rcon/authentication'
require_relative 'rcon/callback'
require_relative 'rcon/connection'
require_relative 'rcon/packet'
require_relative 'rcon/queue'
require_relative 'rcon/responses'

class Server
  class RCon

################################################################################

    include Server::RCon::Authentication
    include Server::RCon::Callback
    include Server::RCon::Connection
    include Server::RCon::Packet
    include Server::RCon::Queue
    include Server::RCon::Responses

################################################################################

    attr_reader :name
    attr_reader :id

    def initialize(server:, debug: false)
      @server           = server
      @name             = @server.name
      @host             = @server.host
      @port             = @server.client_port
      @password         = @server.client_password
      @debug            = debug

      @id               = Zlib::crc32(@name.to_s)

      @authenticated    = false

      @manager_thread   = nil
      @manager_mutex    = Mutex.new
      @socket_rx_thread = nil
      @socket_tx_thread = nil

      @callbacks        = Concurrent::Hash.new
      @responses        = Concurrent::Hash.new
      @packet_queue     = ::Queue.new

      @socket           = nil
      @socket_mutex     = Mutex.new

    end

################################################################################

    def tag
      @name
    end

    def cancellation
      $cancellation.join(@server.cancellation).join(@cancellation)
    end

################################################################################

    # RCON Executor
    # Switch between using 'c' or 'silent-command' depending on the debug flag.
    def rcon_executor
      (@debug ? 'c' : 'silent-command')
    end

    def build_command(command)
      if command[0] == '/'
        command
      else
        %(/#{rcon_executor} #{command})
      end
    end

    def command_nonblock(command)
      enqueue_packet(build_command(command))
    end

    def command(command)
      packet_fields = enqueue_packet(build_command(command))
      response = find_response(packet_fields.id)
      response.payload.strip
    end

################################################################################

    def available?
      (connected? && authenticated?)
    end

    def unavailable?
      !available?
    end

################################################################################

    def startup!
      # Tasks.process("#{name}-manager", cancellation: $cancellation.join(@cancellation)) do
      @cancellation, @origin = Concurrent::Cancellation.new
      $pool.post do
        while disconnected? && !self.cancellation.canceled? do
          begin
            connect!
            break if connected?
          rescue Errno::ECONNABORTED, Errno::ECONNREFUSED, Errno::ECONNRESET => e
            $logger.fatal(tag) { "[RCON] Caught Exception: #{e.message}" }
            sleep 3
          end
        end

        # while disconnected? do
        #   begin
        #     connect!
        #     break if connected?
        #   rescue Errno::ECONNABORTED, Errno::ECONNREFUSED, Errno::ECONNRESET => e
        #     $logger.fatal(tag) { "[RCON] Caught Exception: #{e.message}" }
        #     sleep 3
        #   end
        # end
        socket_tx_thread
        socket_rx_thread

        authenticate if connected? && unauthenticated?
        # sleep 1 until disconnected?
      end

      # return if !@manager_thread.nil? && @manager_thread.alive?
      # @manager_mutex.synchronize do
      #   @manager_thread = ThreadPool.thread("#{tag}-connect") do
      #     while disconnected? do
      #       begin
      #         connect!
      #         break if connected?
      #       rescue Errno::ECONNABORTED, Errno::ECONNREFUSED, Errno::ECONNRESET => e
      #         $logger.fatal(tag) { "[RCON] Caught Exception: #{e.message}" }
      #         sleep 3
      #       end
      #     end
      #     socket_tx_thread
      #     socket_rx_thread
      #     authenticate if connected? && unauthenticated?
      #   rescue => e
      #     $logger.fatal(tag) { "[RCON] Caught Exception: #{e.full_message}" }
      #     shutdown!
      #   end
      # end
    end

    def shutdown!
      disconnect!
      @origin and @origin.resolve

      # @manager_thread && @manager_thread.kill
      # @socket_rx_thread && @socket_rx_thread.kill
      # @socket_tx_thread && @socket_tx_thread.kill

      # @manager_thread   = nil
      # @socket_rx_thread = nil
      # @socket_tx_thread = nil

      @authenticated = false

      true
    end

################################################################################

    def socket_tx_thread
      # Tasks.process("#{name}-tx", cancellation: @cancellation) do
      $pool.post do
        begin
          send_packet(get_queued_packet.packet_fields) while connected? && !self.cancellation.canceled?
        rescue Errno::EPIPE
          startup!
        rescue => e
          $logger.fatal(tag) { "[RCON] Caught Exception: #{e.full_message}" }
          shutdown!
        end
      end

      # return if !@socket_tx_thread.nil? && @socket_tx_thread.alive?
      # @socket_tx_thread = ThreadPool.thread("#{tag}-socket-tx") do
      #   send_packet(get_queued_packet.packet_fields) while connected?
      # rescue Errno::EPIPE
      #   startup!
      # rescue => e
      #   $logger.fatal(tag) { "[RCON] Caught Exception: #{e.full_message}" }
      #   shutdown!
      # end
    end

    def socket_rx_thread
      # Tasks.process("#{name}-rx", cancellation: @cancellation) do
      $pool.post do
        begin
          receive_packet while connected? && !self.cancellation.canceled?
        rescue Errno::EPIPE
          startup!
        rescue => e
          $logger.fatal(tag) { "[RCON] Caught Exception: #{e.full_message}" }
          shutdown!
        end
      end

      # return if !@socket_rx_thread.nil? && @socket_rx_thread.alive?
      # @socket_rx_thread = ThreadPool.thread("#{tag}-socket-rx") do
      #   receive_packet while connected?
      # rescue Errno::EPIPE
      #   startup!
      # rescue => e
      #   $logger.fatal(tag) { "[RCON] Caught Exception: #{e.full_message}" }
      #   shutdown!
      # end
    end

################################################################################

  end
end
