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

  def rcon_command(command, callback, data=nil)
    sleep 1 while disconnected?
    $logger.debug { "RCON[#{@name}]> #{command}" }
    @rcon.enqueue_packet(command, callback, data)
  end

################################################################################

end
