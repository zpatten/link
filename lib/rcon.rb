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

  def initialize(name, host, port, password)
    @name           = name
    @host           = host
    @port           = port
    @password       = password

    @authenticated  = false

    @manager_thread = nil
    @manager_mutex = Mutex.new
    @socket_rx_thread    = nil
    @socket_tx_thread    = nil

    @callbacks      = Hash.new
    @responses      = Hash.new
    @packet_queue   = ::Queue.new

    @socket         = nil
    @socket_mutex   = Mutex.new
  end

################################################################################

  def id
    Zlib::crc32(@name.to_s)
  end

  def rcon_tag
    # "#{@name}@#{@host}:#{@port}"
    @name
  end

################################################################################

  def available?
    (connected? && authenticated?)
  end

  def unavailable?
    (disconnected? || unauthenticated?)
  end

################################################################################

  def startup!
    return if !@manager_thread.nil? && @manager_thread.alive?
    @manager_mutex.synchronize do
      @manager_thread = ThreadPool.thread("#{rcon_tag}-connect") do
        while disconnected? do
          begin
            connect!
            break if connected?
          rescue Errno::ECONNABORTED, Errno::ECONNREFUSED, Errno::ECONNRESET => e
            $logger.fatal(:rcon) { "[#{rcon_tag}] Caught Exception: #{e.message}" }
            sleep 3
          end
        end
        socket_tx_thread
        socket_rx_thread
        authenticate if connected? && unauthenticated?
      rescue => e
        $logger.fatal(:rcon) { "[#{rcon_tag}] Caught Exception: #{e.full_message}" }
        shutdown!
      end
    end
  end

  def shutdown!
    disconnect!

    @manager_thread && @manager_thread.kill
    @socket_rx_thread && @socket_rx_thread.kill
    @socket_tx_thread && @socket_tx_thread.kill

    @manager_thread = nil
    @socket_rx_thread    = nil
    @socket_tx_thread    = nil

    @authenticated = false

    true
  end

################################################################################

  def socket_tx_thread
    return if !@socket_tx_thread.nil? && @socket_tx_thread.alive?
    @socket_tx_thread = ThreadPool.thread("#{rcon_tag}-socket-tx", priority: 1) do
      send_packet(get_queued_packet.packet_fields) while connected?
    rescue Errno::EPIPE
      startup!
    rescue => e
      $logger.fatal(:rcon) { "[#{rcon_tag}] Caught Exception: #{e.full_message}" }
      shutdown!
    end
  end

  def socket_rx_thread
    return if !@socket_rx_thread.nil? && @socket_rx_thread.alive?
    @socket_rx_thread = ThreadPool.thread("#{rcon_tag}-socket-rx", priority: 1) do
      receive_packet while connected?
    rescue Errno::EPIPE
      startup!
    rescue => e
      $logger.fatal(:rcon) { "[#{rcon_tag}] Caught Exception: #{e.full_message}" }
      shutdown!
    end
  end

################################################################################

end
