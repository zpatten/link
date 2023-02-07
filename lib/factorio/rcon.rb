# frozen_string_literal: true

# [
#   Errno::ECONNABORTED,
#   Errno::ECONNREFUSED,
#   Errno::ECONNRESET,
#   Errno::ENOTSOCK,
#   Errno::EPIPE,
#   IOError,
#   Net::OpenTimeout,
#   RuntimeError
# ]

require_relative 'rcon/authentication'
require_relative 'rcon/callback'
require_relative 'rcon/connection'
require_relative 'rcon/packet'
require_relative 'rcon/queue'
require_relative 'rcon/responses'

module Factorio
  class RCon

################################################################################

    include Factorio::RCon::Authentication
    include Factorio::RCon::Callback
    include Factorio::RCon::Connection
    include Factorio::RCon::Packet
    include Factorio::RCon::Queue
    include Factorio::RCon::Responses

################################################################################

    attr_reader :name
    attr_reader :id

    def initialize(server:, debug: false)
      @server        = server
      @cancellation  = @server.cancellation
      @pool          = @server.pool
      @name          = @server.name
      @host          = @server.host
      @port          = @server.client_port
      @password      = @server.client_password
      @debug         = debug

      @id            = Zlib::crc32(@name.to_s)

      @authenticated = false

      @callbacks     = Concurrent::Map.new
      @responses     = Concurrent::Map.new
      @packet_queue  = ::Queue.new

      @socket        = nil
      @socket_mutex  = Mutex.new
    end

################################################################################

    def tag
      @server.log_tag("RCON")
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
      response.payload.strip unless response.nil?
    end

################################################################################

    def available?
      (connected? && authenticated?)
    end

    def unavailable?
      !available?
    end

################################################################################

    def start!
      Tasks.onetime(
        task: 'RCON',
        pool: @pool,
        server: @server,
        metrics: false
      ) do
        until connected? || @cancellation.canceled? do
          begin
            connect!
            break if connected? || @cancellation.canceled?
          rescue Errno::ECONNABORTED, Errno::ECONNREFUSED, Errno::ECONNRESET => e
            LinkLogger.fatal(tag) { "Caught Exception: #{e.message}" }
            sleep 3
          end
        end

        unless disconnected? || @cancellation.canceled?
          Tasks.repeat(
            task: 'RCON.RX',
            pool: @pool,
            cancellation: @cancellation,
            server: @server,
            metrics: false
          ) { receive_packet }

          Tasks.repeat(
            task: 'RCON.TX',
            pool: @pool,
            cancellation: @cancellation,
            server: @server,
            metrics: false
          ) { send_packet }

          authenticate
        end
      end
    end

    def stop!
      disconnect!
    end

################################################################################

  end
end
