require_relative "server"

class Servers

  module ClassMethods

################################################################################

    @@servers = Array.new
    @@server_mutex = Mutex.new

################################################################################

    def find_by_name(name)
      all.select { |s| s.name == name }.first
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
      @@servers
    end


  # "servers": {
  #   "core": {
  #     "host": "127.0.0.1",
  #     "port": "28923",
  #     "password": "bdnvhswv",
  #     "research": true,
  #     "scheduler": {
  #       "ping": 5.0
  #     }
  #   },
  #   "provinggrounds": {
  #     "host": "127.0.0.1",
  #     "port": "743",
  #     "password": "yxkxvfr",
  #     "command_whitelist": [
  #       "admins",
  #       "version"
  #     ]
  #   }
  # }

    def register(server_name, server_details)
      @@server_mutex.synchronize do
        server = Server.new(server_name, server_details)
        @@servers ||= Array.new
        @@servers << server
        server.schedule
        $logger.info { "[#{server.id}] Registered server #{server.host_tag}" }
      end
    end

    def create(params)
      Config['servers'] ||= Hash.new

      server_name = params[:name]
      server_details = {
        'host' => "127.0.0.1",
        'port' => generate_port_number,
        'password' => "thing",
        'research' => (Config.servers.count.zero? ? true : false)
      }
      Config['servers'][server_name] = server_details
      pp Config['servers']
      $logger.info(:servers) { "Created server #{server_name}" }
      register(server_name, server_details)
      Config.save!
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
