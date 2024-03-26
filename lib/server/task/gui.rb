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

          metric_keys = Servers.collect { |server| server.metrics.keys }.flatten.compact.uniq
          metric_keys.each do |key|
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
          Factorio::Signals.get_network_ids.sort_by { |nid| nid.to_s }.each do |network_id|
            signal_networks[network_id] = Factorio::Signals.calculate_signals(network_id).delete_if { |s| s['count'] == 0 }.sort_by { |s| s['count'] }.reverse
          end
          # puts "signal_networks=#{signal_networks.ai}"
          command = %(remote.call('link', 'set_gui_signals', '#{signal_networks.to_json}'))
          rcon_command_nonblock(command)
        end
      end

    end
  end
end
