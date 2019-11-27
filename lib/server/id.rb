# frozen_string_literal: true

# Link Factorio Server ID
################################################################################
class Server
  module ID

    def schedule_id
      ThreadPool.schedule_task(:id, server: self) do |server|
        command = %(/#{rcon_executor} remote.call('link', 'set_id', '#{self.id}'))
        self.rcon_command(command: command)
      end
    end

  end
end

