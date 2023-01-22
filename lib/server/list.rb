# frozen_string_literal: true

# Link Server List
################################################################################
class Server
  module List

    def schedule_server_list
      ThreadPool.schedule_server(:server_list, server: self) do
        server_list = Servers.list
        command = %(remote.call('link', 'set_server_list', '#{server_list.to_json}'))
        payload = self.rcon_command(command)
      end
    end

  end
end

