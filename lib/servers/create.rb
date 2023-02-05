# frozen_string_literal: true

class Servers
  module Create

################################################################################

    def server_types
      %w( empty coal stone copper-ore iron-ore uranium-ore crude-oil )
    end

    def server_create_types
      types = Array.new
      types += server_types
      types += saves
      types
    end

    def create!(params)
      server_name = params[:name]
      server_type = params[:type]
      server_enemy_base = params[:biters]
      server_details = {
        'host' => "127.0.0.1",
        'client_port' => generate_port_number,
        'factorio_port' => generate_port_number,
        'client_password' => SecureRandom.hex,
        'research' => (Config.servers.count.zero? ? true : false)
      }
      server = Server.new(server_name, server_details)

      autoplace_off = { frequency: 0, size: 0, richness: 0 }
      autoplace_on  = { frequency: 6, size: 6, richness: 6 }

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
          'enemy-base': (server_enemy_base == 'true' ? autoplace_on : autoplace_off)
        },
        cliff_settings: {
          richness: 0
        }
      }
      map_gen_settings_path = File.join(server.config_path, 'map-gen-settings.json')
      IO.write(map_gen_settings_path, JSON.pretty_generate(map_gen_settings_json))

      config_json = {
        'name' => "Link Server: #{server.name}",
        'description' => "Factorio Link Server #{server.name}",
        'max_players' => 0,
        'tags' => [ PROGRAM_NAME ],
        'visibility' => {
          'public' => false,
          'steam' => false,
          'lan' => true
        },
        'username' => '',
        'password' => '',
        'token' => '',
        'game_password' => '',
        'require_user_verification' => true,
        'max_upload_slots' => 0,
        'allow_commands' => 'admins-only',
        'autosave_interval' => 0,
        'autosave_slots' => 0,
        'afk_autokick_interval' => 0,
        'auto_pause' => false,
        'non_blocking_saving' => true,
        'maximum_segment_size' => 300,
        'maximum_segment_size_peer_count' => 20
      }
      config_json_path = File.join(server.config_path, 'server-settings.json')
      IO.write(config_json_path, JSON.pretty_generate(config_json))

      if saves.collect { |save| save[:file] }.include?(server_type)
        factorio_save = File.join(save_path, server_type)
        LinkLogger.info { "factorio_save=#{factorio_save}" }
        LinkLogger.info { "server.save_path=#{server.save_file}" }
        FileUtils.cp(factorio_save, server.save_file)
      end

      server_adminlist_path = File.join(server.config_path, 'server-adminlist.json')
      IO.write(server_adminlist_path, JSON.pretty_generate(Config.server(server.name, :admins)))

      Config.servers ||= Hash.new
      Config.servers.merge!(server.to_h)
      Config.save

      @servers[server_name] = server

      LinkLogger.info(:servers) { "Created server #{server_name}" }

      true
    end

################################################################################



################################################################################

  end
end
