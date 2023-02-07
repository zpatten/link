# frozen_string_literal: true

class Server
  module Task
    module Providables

      def schedule_task_providables
        Tasks.schedule(task: :providables, pool: @pool, cancellation: @cancellation, server: self) do
          command = %(remote.call('link', 'get_providables'))
          rcon_handler(task: :get_providables, command: command) do |providables|
            LinkLogger.debug(log_tag(:logistics)) { "Providables: #{providables.ai}" }
            Factorio::Storage.bulk_add(providables)
            providables.each do |item_name, item_count|
              Metrics::Prometheus[:providable_items_total].observe(item_count,
                labels: { server: self.name, item_name: item_name, item_type: Factorio::ItemTypes[item_name] })
            end
            @metrics[:provided] = providables
            # providables = Hash[providables.delete_if { |key,value| value == 0 }.transform_values { |value| countvalue(value) }.sort_by { |key,value| key }]
            # command = %(remote.call('link', 'set_logistics_provided', '#{providables.to_json}'))
            # rcon_command_nonblock(command)
          end
        end

      end

    end
  end
end
