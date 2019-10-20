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
      when :commands, :chats, :ping, :command_whitelist, :providables, :requests, :tx_signals, :rx_signals, :id
        all.select { |s| !!Config.server_value(s.name, what) }
      when :research, :current_research
        all.select { |s| !!Config.server_value(s.name, :research) }
      when :non_research
        all.select { |s| !(!!Config.server_value(s.name, :research)) }
      else
        raise "INVALID FIND: #{what.inspect}"
      end
    end

################################################################################

    def all
      @@servers ||= begin
        servers = Array.new
        Config.servers.each_pair do |server_name, server_details|
          server = Server.new(server_name, server_details)
          servers << server
          $logger.info { "[#{server.id}] Loaded server #{server.host_tag}" }
        end
        servers
      end
    end

################################################################################

    def factorio_path
      File.expand_path(File.join(LINK_ROOT, 'factorio'))
    end

    def factorio_mods
      File.expand_path(File.join(LINK_ROOT, 'mods'))
    end

    def server_path(name)
      File.expand_path(File.join(LINK_ROOT, 'servers', name))
    end

    def factorio_zip
      File.expand_path(File.join(LINK_ROOT, Config['factorio_zip']))
    end

    def factorio_save
      File.expand_path(File.join(LINK_ROOT, Config['factorio_save']))
    end

    def create(params)
      require 'zip'

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

      Config['servers'] ||= Hash.new
      Config['servers'].merge!(server.to_h)

      Zip.on_exists_proc = true
      Zip::File.open(factorio_zip) do |zip_file|
        zip_file.each do |entry|
          trimmed_path = File.join(factorio_path, entry.name.split(File::SEPARATOR)[1..-1])
          next if File.exists?(trimmed_path)
          puts "Extract: #{trimmed_path}"
          FileUtils.mkdir_p(File.dirname(trimmed_path))
          entry.extract(trimmed_path)
        end
      end

      autoplace_off = { frequency: 0, size: 0, richness: 0 }
      autoplace_on  = { frequency: 2, size: 2, richness: 2 }

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
      map_gen_settings_path = File.join(server.server_path, 'map-gen-settings.json')
      FileUtils.mkdir_p(File.dirname(map_gen_settings_path))
      IO.write(map_gen_settings_path, JSON.pretty_generate(map_gen_settings_json))

      config_json = {
        'name' => "Link Server #{server.name}",
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
      config_json_path = File.join(server.server_path, 'server-settings.json')
      FileUtils.mkdir_p(File.dirname(config_json_path))
      IO.write(config_json_path, JSON.pretty_generate(config_json))

      config_ini = <<-CONFIG_INI
[path]
read-data=#{File.join(factorio_path, 'data')}
write-data=#{server.server_path}
CONFIG_INI
      config_ini_path = File.join(server.server_path, 'config.ini')
      FileUtils.mkdir_p(File.dirname(config_ini_path))
      IO.write(config_ini_path, config_ini)

      if server_type.nil?
        FileUtils.mkdir_p(File.dirname(server.save_path))
        FileUtils.cp(factorio_save, server.save_path)
      end

      server_adminlist_path = File.join(server.server_path, 'server-adminlist.json')
      FileUtils.mkdir_p(File.dirname(server_adminlist_path))
      IO.write(server_adminlist_path, JSON.pretty_generate(Config.server_value(server.name, :admins)))

      FileUtils.cp_r(factorio_mods, server.server_path)

      Config.save!
      $logger.info(:servers) { "Created server #{server_name}" }

      unless server_type.nil?
        server.start!
      end
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
