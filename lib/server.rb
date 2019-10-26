# frozen_string_literal: true

require_relative "rcon"

class Server

################################################################################

  attr_accessor :rtt
  attr_reader :client_password
  attr_reader :client_port
  attr_reader :details
  attr_reader :factorio_port
  attr_reader :host
  attr_reader :name
  attr_reader :rcon

################################################################################

  def initialize(name, details)
    @name              = name
    @details           = details
    @active            = details['active']
    @chats             = details['chats']
    @client_password   = details['client_password']
    @client_port       = details['client_port']
    @command_whitelist = details['command_whitelist']
    @commands          = details['commands']
    @factorio_port     = details['factorio_port']
    @host              = details['host']
    @research          = details['research']

    @rcon = RCon.new(@name, @host, @client_port, @client_password)
  end

################################################################################

  def id
    Zlib::crc32(@name.to_s)
  end

  def network_id
    [self.id].pack("L").unpack("l").first
  end

  def update_websocket
    WebServer.settings.server_sockets.each do |s|
      s.send({
        name: @name,
        connected: connected?,
        authenticated: authenticated?,
        available: available?,
        rtt: @rtt.nil? ? '-' : "#{@rtt} ms"
      }.to_json)
    end
  end

  def rtt
    @rtt
  end

  def rtt=(value)
    @rtt = value
    update_websocket
    @rtt
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

  def running!(running=false)
    unless Config.servers[@name].nil?
      Config.servers[@name]['running'] = running
      Config.save!
    end
    running
  end

  def running?
    !!Config.servers[@name]['running']
  end

################################################################################

  def to_h
    { self.name => self.details }
  end

  def path
    File.expand_path(File.join(LINK_ROOT, 'servers', self.name))
  end

  def config_path
    File.join(self.path, 'config')
  end

  def mods_path
    File.join(self.path, 'mods')
  end

  def saves_path
    File.join(self.path, 'saves')
  end

  def save_file
    File.join(self.saves_path, "save.zip")
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
    command << %(-e FACTORIO_PORT="#{self.factorio_port}")
    command << %(-e FACTORIO_RCON_PASSWORD="#{self.client_password}")
    command << %(-e FACTORIO_RCON_PORT="#{self.client_port}")
    command << %(-e PGID="$(id -g)")
    command << %(-e PUID="$(id -u)")
    command << %(-e RUN_CHOWN="false")
    command << %(--volume=#{self.config_path}:/opt/factorio/config)
    command << %(--volume=#{self.mods_path}:/opt/factorio/mods)
    command << %(--volume=#{self.saves_path}:/opt/factorio/saves)
    command << Config['factorio_docker_image']
    command = command.flatten.compact.join(' ')

    # $logger.info {%(chcon -Rt svirt_sandbox_file_t #{self.server_path})}
    system %(/usr/bin/env chcon -Rt svirt_sandbox_file_t #{self.path})
    puts "command=#{command}"
    system command

    running!(true)
  end

  def stop!
    running!(false)

    shutdown!
    command = Array.new
    command << %(sudo)
    command << %(docker stop)
    command << self.name
    command = command.flatten.compact.join(' ')

    $logger.info(:server) { "command=#{command}" }
    system command
  end

################################################################################

  def startup!
    @rcon.startup!
  end

  def shutdown!
    @rcon.shutdown!
    self.rtt = nil
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

  def rcon_command_nonblock(command, callback, data=nil)
    return if unavailable?
    data = self if data.nil?
    @rcon.enqueue_packet(command, callback, data)
  end

  def rcon_command(command)
    return if unavailable?
    packet_fields = @rcon.enqueue_packet(command)
    response = @rcon.find_response(packet_fields.id)
    response.payload.strip
  end

################################################################################

end
