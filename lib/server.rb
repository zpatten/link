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

  def path
    File.expand_path(File.join(LINK_ROOT, 'servers', self.name))
  end

  def config_path
    File.expand_path(File.join(self.path, 'config'))
  end

  def mods_path
    File.expand_path(File.join(self.path, 'mods'))
  end

  def saves_path
    File.expand_path(File.join(self.path, 'saves'))
  end

  def save_file
    File.expand_path(File.join(self.server_saves_path, "#{self.name}.zip"))
  end

################################################################################

  def start!
    FileUtils.cp_r(Servers.factorio_mods, self.path)

    command = Array.new
    command << %(sudo)
    command << %(docker run)
    command << %(--rm)
    command << %(--detach)
    command << %(--name="#{self.name}")
    command << %(--network=host)
    command << %(-e PUID="$(id -u)")
    command << %(-e PGID="$(id -g)")
    command << %(-e RUN_CHOWN="false")
    command << %(-e FACTORIO_PORT="#{self.factorio_port}")
    command << %(-e FACTORIO_RCON_PORT="#{self.client_port}")
    command << %(-e FACTORIO_RCON_PASSWORD="#{self.client_password}")
    command << %(--volume=#{self.config_path}:/opt/factorio/config)
    command << %(--volume=#{self.mods_path}:/opt/factorio/mods)
    command << %(--volume=#{self.saves_path}:/opt/factorio/saves)
    command << Config['factorio_docker_image']
    command = command.flatten.compact.join(' ')

    # $logger.info {%(chcon -Rt svirt_sandbox_file_t #{self.server_path})}
    system %(/usr/bin/env chcon -Rt svirt_sandbox_file_t #{self.path})
    puts "command=#{command}"
    system command
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
