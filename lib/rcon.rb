require 'socket'
require 'securerandom'
require 'ostruct'

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

    @callbacks    = Array.new
    @responses    = Array.new
    @packet_queue = Array.new

    @queue_mutex    = Mutex.new
    @callback_mutex = Mutex.new
    @socket_mutex   = Mutex.new
    @socket_read_mutex   = Mutex.new
    @socket_write_mutex   = Mutex.new
    @response_mutex = Mutex.new

    conn_manager
    poll_send
    poll_recv
  end

################################################################################

  def id
    Zlib::crc32(@name.to_s)
  end

  def rcon_tag
    "#{@name}@#{@host}:#{@port}"
  end

  def shutdown!
    disconnect!
    true
  end

  def available?
    (connected? && authenticated?)
  end

  def unavailable?
    (disconnected? || unauthenticated?)
  end

  def on_exception(e)
    disconnect!
  end

  def conn_manager
    ThreadPool.thread("#{rcon_tag}-connection-manager") do
      loop do
        RescueRetry.attempt(max_attempts: -1, on_exception: method(:on_exception)) do
          connect! if disconnected?
        end
        authenticate if unauthenticated?

        Thread.stop while connected?
      end
    end
  end

  def poll_send
    ThreadPool.thread("#{rcon_tag}-send") do
    RescueRetry.attempt(max_attempts: -1, on_exception: method(:on_exception)) do
      loop do
        queued_packet = nil
        loop do
          queued_packet = get_queued_packet
          break unless queued_packet.nil?
          Thread.stop
        end
        send_packet(queued_packet.packet_fields)
      end
    end
    end
  end

  def receive_packet
    received_packet = recv_packet
    return if received_packet.nil?

    raise "[#{self.id}] Authentication Failed!" if received_packet.id == -1
    tag = "packet-callback-#{received_packet.id}"
    ThreadPool.thread(tag) do
      packet_callback(received_packet)
    end
  end

  def poll_recv
    ThreadPool.thread("#{rcon_tag}-recv") do
    RescueRetry.attempt(max_attempts: -1, on_exception: method(:on_exception)) do
      loop do
        # poll_sleep

        receive_packet
        Thread.stop
      end
    end
    end
  end

end
