# frozen_string_literal: true

# Link Server List
################################################################################
class Server
  module Task
    module GUI

      def schedule_task_gui
        Tasks.schedule(
          task: :gui,
          pool: @pool,
          cancellation: @cancellation,
          server: self
        ) do
          def hash_sort(hash)
            hash = hash.clone
            hash.delete_if { |key,value| value.nil? || value == 0 }
            hash = hash.transform_values { |value| countvalue(value) }
            Hash[hash.sort_by { |key,value| key }]
          end

          command = %(remote.call('link', 'set_gui_server_list', '#{Servers.to_json}'))
          rcon_command_nonblock(command)

          storage = hash_sort(Factorio::Storage.to_h)
          command = %(remote.call('link', 'set_gui_storage', '#{storage.to_json}'))
          rcon_command_nonblock(command)

          @metrics.keys.each do |key|
            command = %(remote.call('link', 'set_gui_logistics_#{key}', '#{hash_sort(@metrics[key]).to_json}'))
            rcon_command_nonblock(command)
          end
        end
      end

    end
  end
end
