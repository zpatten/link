# frozen_string_literal: true

# Link Factorio Server ID
################################################################################
class Link
  class Server
    module ID

      def schedule_id
        ThreadPool.schedule_server(:id, server: self) do |server|
          command = %(remote.call('link', 'set_id', '#{self.id}'))
          self.rcon_command(command: command)
        end
      end

    end
  end

end
