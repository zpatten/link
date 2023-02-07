# frozen_string_literal: true

# Link Server List
################################################################################
class Server
  module Task
    module ServerList

      def schedule_task_server_list
        Tasks.schedule(
          task: :server_list,
          pool: @pool,
          cancellation: @cancellation,
          server: self
        ) do
          command = %(remote.call('link', 'set_server_list', '#{Servers.to_json}'))
          rcon_command_nonblock(command)

          def hash_sort(hash)
            puts "hash: #{hash.ai}"
            hash.each do |key,value|
              puts "value: #{countsize(value).ai}"
            end
            h = Hash[hash.delete_if { |key,value| value.nil? || value == 0 }.transform_values { |key,value| puts value.ai; countsize(value) }.sort_by { |key,value| key }]
            puts "h:#{h.ai}"
            h
          end

          @metrics.keys.each do |key|
            command = %(remote.call('link', 'set_logistics_#{key}', '#{hash_sort(@metrics[key]).to_json}'))
            rcon_command_nonblock(command)
          end
          # @server.metrics[:requested] = @requested_item_counts
          # @requested_item_counts = hash_sort(@requested_item_counts)

          # command = %(remote.call('link', 'set_logistics_requested', '#{@server.metrics[:requested].to_json}'))
          # @server.rcon_command_nonblock(command)

        end
      end

    end
  end
end
