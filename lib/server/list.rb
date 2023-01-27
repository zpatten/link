# frozen_string_literal: true

# Link Server List
################################################################################
class Server
  module List

    def start_thread_server_list
      Tasks.schedule(what: :server_list, pool: @pool, cancellation: @cancellation, server: self) do
        server_list = Servers.list
        command = %(remote.call('link', 'set_server_list', '#{server_list.to_json}'))
        rcon_command(command)
      end
    end

  end
end

