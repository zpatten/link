# frozen_string_literal: true

# Link Server List
################################################################################
class Link
  class Server
    module List

      def schedule_server_list
        ThreadPool.schedule_server(:server_list, server: self) do
          server_list = self.method_proxy.Servers(:list)
          command = %(remote.call('link', 'set_server_list', '#{server_list.to_json}'))
          payload = self.rcon_command(command: command)
        end
      end

    end
  end

end
