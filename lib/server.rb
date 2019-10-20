require_relative "rcon"

class Server

################################################################################

  attr_reader :name, :host, :factorio_port, :client_port, :client_password, :rcon, :details
  attr_accessor :rtt

################################################################################

  def initialize(name, details)
    @name = name
    @details = details
    @host = details["host"]
    @factorio_port = details["factorio_port"]
    @client_port = details["client_port"]
    @client_password = details["client_password"]
    @research = details["research"]
    @chats = details["chats"]
    @commands = details["commands"]
    @command_whitelist = details["command_whitelist"]

    @rcon = RCon.new(name, host, client_port, client_password)
  end

################################################################################

  def id
    Zlib::crc32(@name.to_s)
  end

################################################################################

  def host_tag
    "#{@name}@#{@host}:#{@client_port}"
  end

################################################################################

  def method_missing(method_name, *method_args, &block)
    @details[method_name.to_s]
  end

################################################################################

  def to_h
    { self.name => self.details }
  end

  def server_path
    File.expand_path(File.join(LINK_ROOT, 'servers', self.name))
  end

  def save_path
    File.join(self.server_path, 'saves', "#{self.name}.zip")
  end

################################################################################

  def start!
    factorio_bin = File.join(Servers.factorio_path, 'bin', 'x64', 'factorio.exe')
    config_path = File.join(self.server_path, 'config.ini')
    settings_path = File.join(self.server_path, 'server-settings.json')
    map_gen_path = File.join(self.server_path, 'map-gen-settings.json')

    FileUtils.cp_r(Servers.factorio_mods, self.server_path)

    command = Array.new
    command << factorio_bin
    command << %(--config #{config_path})
    command << %(--port #{self.factorio_port})
    command << %(--rcon-password #{self.client_password})
    command << %(--rcon-port #{self.client_port})
    command << %(--server-settings #{settings_path})
    if File.exists?(self.save_path)
      command << %(--start-server #{self.save_path})
    else
      command << %(--create #{self.save_path})
      command << %(--map-gen-settings #{map_gen_path})
    end
    command = command.flatten.compact.join(' ')

    Kernel.exec(command)
  end

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
    @rcon.startup! unless @rcon.started?
    @rcon.unavailable?
  end

################################################################################

  def rcon
    @rcon
  end

  def rcon_command_nonblock(command, callback, data=nil)
    return if unavailable?
    data = self if data.nil?
    @rcon.enqueue_packet(command, callback, data)
  end

  def rcon_command(command)
    return if unavailable?
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
