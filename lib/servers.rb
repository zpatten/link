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

################################################################################

    def backup
      self.all.each do |server|
        server.backup(true) if server.available?
      end
    end

    def time_index
      %i( year month day hour min )
    end

    def build_date_hash(timestamp, h, v, modifier=0)
      return false if modifier >= time_index.size

      x = timestamp.send(time_index[modifier])
      h[x] ||= Hash.new
      h[x] = v if !build_date_hash(timestamp, h[x], v, modifier + 1)

      true
    end

    def save_files_to_trim(save_files)
      save_files.sort! { |a, b| a <=> b }
      save_files[0..-2]
    end

    def trim_save_files
      save_file_hash = Hash.new
      save_files = Dir.glob(File.join(factorio_saves, "*.zip"), File::FNM_CASEFOLD)
      save_files.each do |save_file|
        basename = File.basename(save_file, '.*')
        separator = basename.rindex('-')
        next if separator.nil?

        server_name = basename[0, separator]
        timestamp = basename[separator+1..-1]
        next if server_name.nil? || timestamp.nil?

        save_file_hash[server_name] ||= Array.new
        save_file_hash[server_name] << [timestamp, save_file]
      end

      now = Time.now
      save_file_hash.each do |server_name, save_files|
        next if save_files.size <= 1
        save_files.sort! { |(atime,afile),(btime,bfile)| atime <=> btime }
        h = Hash.new
        save_files.each do |save_file|
          build_date_hash(Time.at(save_file[0].to_i), h, save_file[1])
        end
        delete_save_files = Array.new
        h.each_pair do |year, months|
          months.each_pair do |month, days|
            if now.month != month
              file_pairs = days.values.map(&:values).flatten.map(&:values).flatten
              delete_save_files << save_files_to_trim(file_pairs)
            end
            days.each_pair do |day, hours|
              if now.day != day
                file_pairs = hours.values.map(&:values).flatten
                delete_save_files << save_files_to_trim(file_pairs)
              end
              hours.each_pair do |hour, minutes|
                if now.day == day && now.hour != hour
                  delete_save_files << save_files_to_trim(minutes.values.flatten)
                end
              end
            end
          end
        end

        next if delete_save_files.nil? || delete_save_files.empty?

        delete_save_files.flatten!.uniq!
        delete_save_files.each do |delete_save_file|
          $logger.warn(:backup) { "Trimming save file #{File.basename(delete_save_file).inspect}" }
        end
        FileUtils.rm(delete_save_files, force: true)
      end

      true
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

        @@servers.delete(server_name)
        Config.servers.delete(server_name)
        Config.save!

        FileUtils.rm_r(server.path)

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
        'description' => 'Factorio Link Server',
        'max_players' => 0,
        'tags' => [ 'link' ],
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

      $logger.info(:servers) { "Created server #{server_name}" }

      server.start!

      true
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
