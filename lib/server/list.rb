# frozen_string_literal: true

# Link Server List
################################################################################
class Server
  module List

    def start_thread_server_list
      Tasks.schedule(what: :server_list, pool: @pool, cancellation: @cancellation, server: self) do
        command = %(remote.call('link', 'set_server_list', '#{Servers.to_json}'))
        rcon_command_nonblock(command)
      end
    end

  end
end
