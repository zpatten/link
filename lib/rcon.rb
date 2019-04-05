require 'socket'
require 'securerandom'
require 'ostruct'

require_relative "rcon/authentication"
require_relative "rcon/callback"
require_relative "rcon/connection"
require_relative "rcon/packet"
require_relative "rcon/queue"

class RCon
  include RCon::Authentication
  include RCon::Callback
  include RCon::Connection
  include RCon::Packet
  include RCon::Queue

  attr_reader :thread

  def initialize(name, host, port, password)
    @name     = name
    @host     = host
    @port     = port
    @password = password

    @connected     = false
    @authenticated = false

    @callbacks    = Array.new
    @packet_queue = Array.new

    @queue_mutex    = Mutex.new
    @callback_mutex = Mutex.new
    @socket_mutex   = Mutex.new

    @threads = Array.new

    @threads << Thread.new do
      conn_manager
    end

    @threads << Thread.new do
      poll_send
    end
    @threads << Thread.new do
      poll_recv
    end
  end

  def shutdown!
    disconnect!
    @threads.map(&:exit)
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
    RescueRetry.attempt(max_attempts: -1, on_exception: method(:on_exception)) do
      loop do
        connect! if disconnected?
        authenticate if unauthenticated?

        conn_sleep
      end
    end
  end

  def conn_sleep
    sleep 1 while connected?
  end

  def poll_sleep
    sleep 1 while disconnected?
  end

  def poll_send
    RescueRetry.attempt(max_attempts: -1, on_exception: method(:on_exception)) do
      queued_packet = nil
      loop do
        poll_sleep

        loop do
          queued_packet = get_queued_packet
          break unless queued_packet.nil?
          sleep SLEEP_TIME
        end

        send_packet(queued_packet.packet_fields)
      end
    end
  end

  def poll_recv
    RescueRetry.attempt(max_attempts: -1, on_exception: method(:on_exception)) do
      loop do
        poll_sleep

        received_packet = recv_packet
        next if received_packet.nil?

        raise "Authentication Failed!" if received_packet.id == -1
        packet_callback(received_packet)
      end
    end
  end

end
