# frozen_string_literal: true

require_relative "server"

class Servers

  module ClassMethods

################################################################################

    @@servers = nil

################################################################################

    def find_by_name(name)
      all.find { |s| s.name == name }
    end

    def find_by_id(id)
      all.find { |s| s.id == id.to_i }
    end

    def find(what)
      what = what.to_sym
      case what
      when :commands, :chats, :ping, :command_whitelist, :logistics, :signals, :id
        all.select { |s| !!Config.server_value(s.name, what) }
      when :research, :current_research
        all.select { |s| s.research }
      when :non_research
        all.select { |s| !s.research }
      else
        nil
      end
    end

################################################################################

    def all
      @@servers ||= Hash.new
      Config.servers.each_pair do |server_name, server_details|
        if @@servers[server_name].nil?
          server = Server.new(server_name, server_details)
          @@servers[server_name] = server
          $logger.info(:servers) { "[#{server.id}] Loaded server #{server.host_tag}" }
        end
      end
      @@servers.values
    end

################################################################################

    def start!
      self.all.each(&:start!)
    end

    def stop!
      self.all.each(&:stop!)
    end

    def restart!
      self.all.each(&:restart!)
    end

    def backup
      self.all.each do |server|
        server.backup(true) if server.available?
      end
    end

################################################################################

    def factorio_mods
      File.expand_path(File.join(LINK_ROOT, 'mods'))
    end

    def factorio_saves
      File.expand_path(File.join(LINK_ROOT, 'saves'))
    end

    def delete!(params)
      server_name = params[:name]
      if (server = find_by_name(server_name))
        server.stop!
        server.backup

        Config.servers.delete(server_name)
        Config.save!
        @@servers.delete(server_name)

        $logger.info(:servers) { "Deleted server #{server_name}" }
      end
    end

    def server_create_types
      types = Array.new
      types += server_types
      types += server_saves
      types
    end

    def server_saves
      begin
        FileUtils.mkdir_p(factorio_saves)
      rescue Errno::ENOENT
      end

      save_files = Dir.glob(File.join(factorio_saves, '*.zip'), File::FNM_CASEFOLD)
      save_files.collect do |save_file|
        {
          file: File.basename(save_file),
          size: File.size(save_file),
          time: File.mtime(save_file)
        }
      end.sort_by { |save_file| save_file[:time] }.reverse
    end

    def server_types
      %w( empty coal stone copper-ore iron-ore uranium-ore crude-oil )
    end

    def create!(params)
      server_name = params[:name]
      server_type = params[:type]
      server_details = {
        'host' => "127.0.0.1",
        'client_port' => generate_port_number,
        'factorio_port' => generate_port_number,
        'client_password' => SecureRandom.hex,
        'research' => (Config.servers.count.zero? ? true : false)
      }
      server = Server.new(server_name, server_details)

      autoplace_off = { frequency: 0, size: 0, richness: 0 }
      autoplace_on  = { frequency: 2, size: 2, richness: 2 }

      FileUtils.mkdir_p(server.config_path)
      FileUtils.mkdir_p(server.mods_path)
      FileUtils.mkdir_p(server.saves_path)

      map_gen_settings_json = {
        water: 0,
        width: 0,
        height: 0,
        starting_area: 2,
        peaceful_mode: false,
        autoplace_controls: {
          coal: (server_type == 'coal' ? autoplace_on : autoplace_off),
          stone: (server_type == 'stone' ? autoplace_on : autoplace_off),
          'copper-ore': (server_type == 'copper-ore' ? autoplace_on : autoplace_off),
          'iron-ore': (server_type == 'iron-ore' ? autoplace_on : autoplace_off),
          'uranium-ore': (server_type == 'uranium-ore' ? autoplace_on : autoplace_off),
          'crude-oil': (server_type == 'crude-oil' ? autoplace_on : autoplace_off),
          trees: autoplace_off,
          'enemy-base': autoplace_on
        },
        cliff_settings: {
          richness: 0
        }
      }
      map_gen_settings_path = File.join(server.config_path, 'map-gen-settings.json')
      IO.write(map_gen_settings_path, JSON.pretty_generate(map_gen_settings_json))

      config_json = {
        'name' => "Link Server: #{server.name}",
        'description' => 'Factorio Link Server',
        'max_players' => 0,
        'tags' => [ 'link' ],
        'visibility' => {
          'public' => false,
          'lan' => true
        },
        'username' => '',
        'password' => '',
        'token' => '',
        'game_password' => '',
        'require_user_verification' => true,
        'max_upload_slots' => 0,
        'allow_commands' => 'admins-only',
        'autosave_interval' => 5,
        'autosave_slots' => 5,
        'afk_autokick_interval' => 0,
        'auto_pause' => false,
        'maximum_segment_size' => 300,
        'maximum_segment_size_peer_count' => 20
      }
      config_json_path = File.join(server.config_path, 'server-settings.json')
      IO.write(config_json_path, JSON.pretty_generate(config_json))

      if server_saves.collect { |save| save[:file] }.include?(server_type)
        factorio_save = File.join(factorio_saves, server_type)
        $logger.info { "factorio_save=#{factorio_save}" }
        $logger.info { "server.save_path=#{server.save_file}" }
        FileUtils.cp(factorio_save, server.save_file)
      end

      server_adminlist_path = File.join(server.config_path, 'server-adminlist.json')
      IO.write(server_adminlist_path, JSON.pretty_generate(Config.server_value(server.name, :admins)))

      FileUtils.cp_r(factorio_mods, server.path)

      Config['servers'] ||= Hash.new
      Config['servers'].merge!(server.to_h)
      Config.save!

      server.start!
      $logger.info(:servers) { "Created server #{server_name}" }
    end

################################################################################

    def shutdown!
      all.each do |server|
        server.shutdown!
        $logger.info(:servers) { "[#{server.id}] Shutdown server #{server.host_tag}" }
      end
    end

################################################################################

    def random
      available_servers = self.available
      random_index = SecureRandom.random_number(available_servers.count)
      available_servers[random_index]
    end

    def available
      all.select { |s| s.available? }
    end

    def available?
      all.map(&:available?).any?(true)
    end

    def unavailable?
      !available?
    end

################################################################################

    def rcon_command_nonblock(command, cserversback, data=nil)
      self.available.each do |server|
        server.rcon_command_nonblock(command, cserversback, data)
      end
    end

################################################################################

  end

  extend ClassMethods
end
