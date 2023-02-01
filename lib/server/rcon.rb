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

class Server

  class RConPool
    SEND_TO_ALL_CONNECTIONS = %i( start! stop! connected? disconnected? authenticated? unauthenticated? available? unavailable? )

    def initialize(pool_size: 3, server:)
      @server      = server
      @connections = Concurrent::Array.new

      pool_size.times { @connections << RCon.new(server: @server) }
    end

    def method_missing(method_name, *args, **options, &block)
      if SEND_TO_ALL_CONNECTIONS.include?(method_name)
        @connections.all? { |connection| connection.send(method_name, *args, &block) }
      else
        Thread.pass while (connection = @connections.shift).nil?
        results = connection.send(method_name, *args, &block)
        @connections.push(connection)
        results
      end
    end
  end

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
      "#{@name}.RCON"
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
        what: 'RCON',
        pool: @pool,
        server: @server
      ) do
        until connected? || @cancellation.canceled? do
          begin
            connect!
            break if connected? || @cancellation.canceled?
          rescue Errno::ECONNABORTED, Errno::ECONNREFUSED, Errno::ECONNRESET => e
            $logger.fatal(tag) { "Caught Exception: #{e.message}" }
            sleep 3
          end
        end

        unless @cancellation.canceled?
          Tasks.repeat(
            what: 'RCON.RX',
            pool: @pool,
            cancellation: @cancellation,
            server: @server
          ) { receive_packet }

          Tasks.repeat(
            what: 'RCON.TX',
            pool: @pool,
            cancellation: @cancellation,
            server: @server
          ) { send_packet(get_queued_packet.packet_fields) }

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
