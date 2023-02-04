# frozen_string_literal: true

# Link Factorio Server ID
################################################################################
class Server
  module ID

    def schedule_task_id
      Tasks.schedule(what: :id, pool: @pool, cancellation: @cancellation, server: self) do
        command = %(remote.call('link', 'set_id', '#{self.id}'))
        rcon_command_nonblock(command)
      end
    end

  end
end

