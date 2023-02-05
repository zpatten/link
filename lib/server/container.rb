# frozen_string_literal: true

class Server
  module Container

################################################################################

    def start_container!
      return false if container_alive?

      LinkLogger.info(log_tag(:container)) { "Syncing Factorio Mods for Server" }

      filepath  = File.expand_path(File.join(self.mods_path, '*.zip'))
      mod_files = Dir.glob(filepath, File::FNM_CASEFOLD)
      mod_files.each do |mod_file|
        FileUtils.rm_f(mod_file)
      end
      FileUtils.cp_r(Servers.factorio_mods, self.path)

      run_command(@name,
        %(/usr/bin/env),
        %(chcon),
        %(-Rt),
        %(svirt_sandbox_file_t),
        self.path
      )

      run_command(@name,
        %(docker run),
        %(--rm),
        %(--detach),
        %(--name="#{@name}"),
        %(--network=host),
        %(-e FACTORIO_PORT="#{self.factorio_port}"),
        %(-e FACTORIO_RCON_PASSWORD="#{self.client_password}"),
        %(-e FACTORIO_RCON_PORT="#{self.client_port}"),
        %(-e PUID="$(id -u)"),
        %(-e PGID="$(id -g)"),
        %(-e DEBUG=true),
        %(--volume=#{self.path}:/factorio),
        Config.factorio_docker_image
      )

      true
    end

    def stop_container!
      return false if container_dead?

      run_command(@name,
        %(docker stop),
        @name
      )

      true
    end

################################################################################

    def container_alive?
      # key = [@name, 'container-alive'].join('-')
      states = Cache.fetch('container-alive', expires_in: 1) do
        ids = run_command(@name, %(docker ps -aq)).split("\n").map(&:strip)
        states = run_command(@name,
          %(docker inspect),
          %(-f '{{.Name}} {{.State.Running}}'),
          ids
        ).split("\n").map(&:strip)
        states.collect { |state| state.split(' ') }.to_h
      end
      states["/#{@name}"] == 'true'
    end

    def container_dead?
      !container_alive?
    end

################################################################################

  end
end
