require_relative "server"

class Servers

  module ClassMethods

################################################################################

    @@servers = nil
    @@server_mutex = Mutex.new

################################################################################

    def find_by_name(name)
      all.select { |s| s.name == name }.first
    end

    def find(what)
      what = what.to_sym
      case what
      when :commands, :chats, :ping, :command_whitelist, :providables, :requests, :combinators
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
        @@server_mutex.synchronize do
          return @@servers unless @@servers.nil?

          server_list = Array.new
          Config.servers.each_pair do |server_name, server_details|
            server = Server.new(server_name, server_details)
            server_list << server
            $logger.info { "Registered server #{server.host_tag}" }
          end
          server_list
        end
      end
      @@servers
    end

################################################################################

    def shutdown!
      all.each do |server|
        server.shutdown!
        $logger.info { "Shutdown server #{server.host_tag}" }
      end
    end

################################################################################

    def available
      all.select { |s| s.available? }
    end

    def available?
      all.map(&:available?).all?(true)
    end

    def unavailable?
      !available?
    end

################################################################################

    def rcon_command(command, cserversback, data=nil)
      self.available.each do |server|
        server.rcon_command(command, cserversback, data)
      end
    end

################################################################################

  end

  extend ClassMethods
end
