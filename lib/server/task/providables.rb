# frozen_string_literal: true

class Server
  module Task
    module Providables

      def schedule_task_providables
        Tasks.schedule(task: :providables, pool: @pool, cancellation: @cancellation, server: self) do
          command = %(remote.call('link', 'get_providables'))
          rcon_handler(task: :get_providables, command: command) do |providables|
            # LinkLogger.debug(@name) { "[LOGISTICS] providables: #{providables.ai}" }
            Factorio::Storage.bulk_add(providables)
            providables.each do |item_name, item_count|
              Metrics::Prometheus[:providable_items_total].observe(item_count,
                labels: { server: self.name, item_name: item_name, item_type: Factorio::ItemTypes[item_name] })
            end
          end
        end

      end

    end
  end
end
