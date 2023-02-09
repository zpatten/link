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
            hash.delete_if { |key, value| value.nil? || value == 0 }
            Hash[hash.sort_by { |key, value| value }.reverse]
          end

          command = %(remote.call('link', 'set_gui_servers', '#{Servers.to_json}'))
          rcon_command_nonblock(command)

          storage = hash_sort(Factorio::Storage.to_h)
          command = %(remote.call('link', 'set_gui_logistics_storage', '#{storage.to_json}'))
          rcon_command_nonblock(command)

          @metrics.keys.each do |key|
            all_metrics = Servers.collect { |server| server.metrics[key] }.flatten.compact.map(&:clone)
            totals = Hash.new(0)
            all_metrics.each do |metric|
              totals.merge!(metric) do |k,o,n|
                o + n
              end
            end

            command = %(remote.call('link', 'set_gui_logistics_#{key}', '#{hash_sort(@metrics[key]).to_json}', '#{hash_sort(totals).to_json}'))
            rcon_command_nonblock(command)
          end

          signal_networks = Hash.new
          Signals.get_network_ids.each do |network_id|
            signal_networks[network_id] = Signals.copy(network_id)
          end

          command = %(remote.call('link', 'set_gui_signals', '#{signal_networks.to_json}'))
          rcon_command_nonblock(command)
        end
      end

    end
  end
end
