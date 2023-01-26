# frozen_string_literal: true

# Link Factorio Server ID
################################################################################
class Server
  module ID

    def start_thread_id
      # ThreadPool.schedule_server(:id, server: self) do |server|
      Tasks.schedule(:id, pool: @pool, cancellation: @cancellation, server: self) do
        command = %(remote.call('link', 'set_id', '#{self.id}'))
        self.rcon_command(command)
      end
    end

  end
end

