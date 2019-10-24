# frozen_string_literal: true

require_relative "rcon/authentication"
require_relative "rcon/callback"
require_relative "rcon/connection"
require_relative "rcon/packet"
require_relative "rcon/queue"
require_relative "rcon/responses"

class RCon
  include RCon::Authentication
  include RCon::Callback
  include RCon::Connection
  include RCon::Packet
  include RCon::Queue
  include RCon::Responses

  attr_reader :thread

  def initialize(name, host, port, password)
    @name     = name
    @host     = host
    @port     = port
    @password = password

    @connected     = false
    @authenticated = false
    @started       = false
    @shutdown      = false

    @callbacks    = Hash.new
    @responses    = Hash.new
    # @packet_queue = Array.new
    @packet_queue = ::Queue.new

    # @queue_mutex    = Mutex.new
    # @callback_mutex = Mutex.new
    # @response_mutex = Mutex.new

    @socket = nil
    @socket_mutex       = Mutex.new
    # @socket_read_mutex  = Mutex.new
    # @socket_write_mutex = Mutex.new
  end

################################################################################

  def id
    Zlib::crc32(@name.to_s)
  end

  def rcon_tag
    # "#{@name}@#{@host}:#{@port}"
    @name
  end

  def started?
    @started
  end

  def startup!
    unless started?
      @started = true
      conn_manager
      poll_send
      poll_recv
    end
  end

  def shutdown!
    @shutdown = true
    disconnect!
    true
  end

  def shutdown?
    @shutdown
  end

  def available?
    (connected? && authenticated?)
  end

  def unavailable?
    (disconnected? || unauthenticated?)
  end

  def on_exception(e)
    $logger.fatal(:rcon) { "Caught Exception #{e}; will disconnect if connected!" }
    disconnect! if connected?

    true
  rescue
    false
  end

  def conn_manager
    ThreadPool.thread("#{rcon_tag}-manager") do
      RescueRetry.attempt(max_attempts: -1, on_exception: method(:on_exception)) do
        loop do
          connect! if disconnected? && !shutdown?
          authenticate if connected? && unauthenticated? && !shutdown?

          break if shutdown?
          Thread.stop while connected?
        end
      end
    end
  end

  def poll_send
    ThreadPool.thread("#{rcon_tag}-send", priority: 1) do
      RescueRetry.attempt(max_attempts: -1, on_exception: method(:on_exception)) do
        loop do
          send_packet(get_queued_packet.packet_fields) while connected? && !shutdown?

          break if shutdown?
          Thread.stop
        end
      end
    end
  end

  def poll_recv
    ThreadPool.thread("#{rcon_tag}-recv", priority: 1) do
      RescueRetry.attempt(max_attempts: -1, on_exception: method(:on_exception)) do
        loop do
          receive_packet while connected? && !shutdown?

          break if shutdown?
          Thread.stop
        end
      end
    end
  end

end
