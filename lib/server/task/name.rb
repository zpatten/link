# frozen_string_literal: true

# Link Factorio Server Name
################################################################################
class Server
  module Task
    module Name

      def schedule_task_name
        puts "HERE"
        Tasks.onetime(task: :name, pool: @pool, cancellation: @cancellation, metrics: true, server: self) do
          puts "HERE1"
          command = %(remote.call('link', 'set_name', '#{self.name}'))
          LinkLogger.info(:name) {"command=#{command.ai}"}
          rcon_command_nonblock(command)
        end
      end

    end
  end
end
