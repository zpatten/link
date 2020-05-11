# frozen_string_literal: true

module Link
  module Factorio
    class Server

################################################################################

      attr_reader :client_password
      attr_reader :client_port
      attr_reader :details
      attr_reader :factorio_port
      attr_reader :host
      attr_reader :name
      attr_reader :research
      attr_reader :child_pid
      attr_reader :id
      attr_reader :network_id
      attr_reader :pinged_at

      attr_reader :method_proxy
      attr_reader :rcon

      RECV_MAX_LEN = 64 * 1024

################################################################################

      def initialize(name, details)
        @name                = name.dup
        @id                  = Zlib::crc32(@name.to_s)
        @network_id          = [@id].pack("L").unpack("l").first
        @pinged_at           = 0

        @details             = details
        @active              = details['active']
        @chats               = details['chats']
        @client_password     = details['client_password']
        @client_port         = details['client_port']
        @command_whitelist   = details['command_whitelist']
        @commands            = details['commands']
        @factorio_port       = details['factorio_port']
        @host                = details['host']
        @research            = details['research']

        @rx_signals_initalized = false
        @tx_signals_initalized = false

        @parent_pid          = Process.pid
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

      def rtt
        @rtt
      end

      def rtt=(value)
        if parent?
          @pinged_at = Time.now.to_f unless value.nil?
          @rtt       = value
          update_websocket
          @rtt
        elsif child?
          self.method_proxy.rtt = value
        end
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

      def latest_save_file
        save_files = Dir.glob(File.join(self.saves_path, '*.zip'), File::FNM_CASEFOLD)
        save_files.reject! { |save_file| save_file =~ /tmp\.zip$/ }
        save_files.sort! { |a, b| File.mtime(a) <=> File.mtime(b) }
        save_files.last
      end

################################################################################

      def start_container!
        return true if container_alive?

        FileUtils.cp_r(Servers.factorio_mods, self.path)

        run_command(:server, self.name,
          %(/usr/bin/env),
          %(chcon),
          %(-Rt),
          %(svirt_sandbox_file_t),
          self.path
        )

        run_command(:server, self.name,
          %(docker run),
          %(--rm),
          %(--detach),
          %(--name="#{self.name}"),
          %(--network=host),
          %(-e FACTORIO_PORT="#{self.factorio_port}"),
          %(-e FACTORIO_RCON_PASSWORD="#{self.client_password}"),
          %(-e FACTORIO_RCON_PORT="#{self.client_port}"),
          %(-e PUID="$(id -u)"),
          %(-e PGID="$(id -g)"),
          %(--volume=#{self.path}:/factorio),
          Config.factorio_docker_image
        )

          # %(--volume=#{self.config_path}:/opt/factorio/config),
          # %(--volume=#{self.mods_path}:/opt/factorio/mods),
          # %(--volume=#{self.saves_path}:/opt/factorio/saves),

        true
      end

      def stop_container!
        return true if container_dead?

        run_command(:server, self.name,
          %(docker stop),
          self.name
        )

        true
      end

      def container_alive?
        key = [self.name, 'container-alive'].join('-')
        Link::Cache.fetch(key, expires_in: 10) do
          output = run_command(:server, self.name,
            %(docker inspect),
            %(-f '{{.State.Running}}'),
            self.name
          )
          (output == 'true')
        end
      end

      def container_dead?
        !container_alive?
      end

################################################################################

      def unresponsive?
        ((@pinged_at + PING_TIMEOUT) < Time.now.to_f)
      end

      def responsive?
        !unresponsive?
      end

################################################################################


    end
  end
end
