require_relative "rcon"

class Server

################################################################################

  attr_reader :name, :host, :port, :password, :rcon

################################################################################

  def initialize(name, details)
    @name = name
    @details = details
    @host = details["host"]
    @port = details["port"]
    @password = details["password"]
    @research = details["research"]
    @chats = details["chats"]
    @commands = details["commands"]
    @command_whitelist = details["command_whitelist"]

    @rcon = RCon.new(name, host, port, password)
  end

################################################################################

  def id
    Zlib::crc32(@name.to_s)
  end

################################################################################

  def host_tag
    "#{@name}@#{@host}:#{@port}"
  end

################################################################################

  def method_missing(method_name, *method_args, &block)
    @details.send(method_name, *method_args, &block)
  end

################################################################################

  def shutdown!
    @rcon.shutdown!
  end

################################################################################

  def connected?
    @rcon.connected?
  end

  def disconnected?
    @rcon.disconnected?
  end

################################################################################

  def authenticated?
    @rcon.authenticated?
  end

  def unauthenticated?
    @rcon.unauthenticated?
  end

################################################################################

  def available?
    @rcon.available?
  end

  def unavailable?
    @rcon.unavailable?
  end

################################################################################

  def rcon
    @rcon
  end

  def rcon_command_nonblock(command, callback, data=nil)
    Thread.stop while unavailable?
    data = self if data.nil?
    @rcon.enqueue_packet(command, callback, data)
  end

  def rcon_command(command)
    Thread.stop while unavailable?
    packet_fields = @rcon.enqueue_packet(command)
    response = nil
    loop do
      Thread.stop if (response = @rcon.find_response(packet_fields.id)).nil?
      break unless response.nil?
    end
    response.payload.strip
  end

################################################################################

end
