# frozen_string_literal: true

# Link Factorio Server Game Save Management
################################################################################
class Server
  module Task
    module Save

      def schedule_task_save
        unless (task_schedule = Tasks.task_schedule(:save)).nil?
          Tasks.repeat(
            task: :save,
            pool: @pool,
            cancellation: @cancellation,
            metrics: false,
            server: self
          ) do |server|
            sleep_for = SecureRandom.random_number(task_schedule) + 1
            sleep_until = Time.now + sleep_for

            while Time.now < sleep_until do
              sleep 1
              break if @cancellation.canceled?
            end

            server.save unless @cancellation.canceled?
          end
        end
      end

    end
  end
end
