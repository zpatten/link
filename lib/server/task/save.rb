# frozen_string_literal: true

# Link Factorio Server Game Save Management
################################################################################
class Server
  module Task
    module Save

      def schedule_task_save
        Tasks.schedule(what: :save, pool: @pool, cancellation: @cancellation, server: self) do |server|
          server.backup(timestamp: true)
        end
      end

    end
  end
end