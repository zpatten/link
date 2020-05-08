# frozen_string_literal: true

module Link
  module Factorio
    class Servers

################################################################################

      module ClassMethods
        @@servers ||= Concurrent::Hash.new

        def all
          Link::Data::Config.servers.each_pair do |server_name, server_details|
            if @@servers[server_name].nil?
              server = Server.new(server_name, server_details)
              @@servers[server_name] = server

              logger.info { "[#{server.id}] Loaded Server #{server.host_tag}" }
            end
          end
          @@servers.values
        end

      end

      extend ClassMethods

################################################################################

    end
  end
end
