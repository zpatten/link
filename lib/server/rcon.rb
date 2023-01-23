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
      $logger.info(tag) { "[RCON] Startup" }
      @cancellation, @origin = Concurrent::Cancellation.new
      $pool.post do
        begin
          until connected? || self.cancellation.canceled? do
            begin
              connect!
              break if connected?
            rescue Errno::ECONNABORTED, Errno::ECONNREFUSED, Errno::ECONNRESET => e
              $logger.fatal(tag) { "[RCON] Caught Exception: #{e.message}" }
              sleep 3
            end
          end

          if connected? && !self.cancellation.canceled?
            start_tx_thread
            start_rx_thread

            authenticate if unauthenticated?
          end

          sleep 1 until self.cancellation.canceled?
          disconnect!

        rescue => e
          $logger.fatal(tag) { "[RCON] Caught Exception: #{e.full_message}" }
          shutdown!
        end
      end
    end

    def shutdown!
      $logger.warn(tag) { "[RCON] Shutdown" }
      @origin and @origin.resolve

      disconnect!

      true
    end

################################################################################

    def start_tx_thread
      $pool.post do
        begin
          send_packet(get_queued_packet.packet_fields) until disconnected? || self.cancellation.canceled?
        rescue => e
          $logger.fatal(tag) { "[RCON] Caught Exception: #{e.full_message}" }
          shutdown!
        end
        $logger.warn(tag) { "[RCON] TX Shutdown" }
      end
    end

    def start_rx_thread
      $pool.post do
        begin
          receive_packet until disconnected? || self.cancellation.canceled?
        rescue => e
          $logger.fatal(tag) { "[RCON] Caught Exception: #{e.full_message}" }
          shutdown!
        end
        $logger.warn(tag) { "[RCON] RX Shutdown" }
      end
    end

################################################################################

  end
end
