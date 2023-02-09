# frozen_string_literal: true

# Link Factorio Server ID
################################################################################
class Server
  module Task
    module ID

      def schedule_task_id
        Tasks.onetime(task: :id, pool: @pool, cancellation: @cancellation, metrics: true, server: self) do
          command = %(remote.call('link', 'set_id', '#{self.id}'))
          rcon_command_nonblock(command)
        end
      end

    end
  end
end
