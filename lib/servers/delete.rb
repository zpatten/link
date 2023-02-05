# frozen_string_literal: true

class Servers
  module Delete

################################################################################

    def delete!(params)
      server_name = params[:name]
      if (server = find_by_name(server_name))
        server.stop!
        server.save

        @servers.delete(server_name)
        Config.servers.delete(server_name)
        Config.save

        FileUtils.rm_r(server.path)

        LinkLogger.warn(:servers) { "Deleted server #{server_name}" }
      end
    end

################################################################################

  end
end
