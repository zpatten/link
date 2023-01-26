# frozen_string_literal: true

class Server
  module Logistics

    def start_thread_logistics
      Tasks.schedule(:fulfillments, pool: @pool, cancellation: @cancellation, server: self) do
        command = %(remote.call('link', 'get_requests'))
        rcon_handler(command) do |requests|
          logistics = ::Logistics.new(self, requests)
          fulfillments = logistics.fulfill
          unless fulfillments.nil? || fulfillments.empty?
            command = %(remote.call('link', 'set_fulfillments', '#{fulfillments.to_json}'))
            self.rcon_command(command)
          end
        end
      end

      Tasks.schedule(:providables, pool: @pool, cancellation: @cancellation, server: self) do
        command = %(remote.call('link', 'get_providables'))
        rcon_handler(command) do |providables|
          $logger.debug(self.name) { "[LOGISTICS] providables: #{providables.ai}" }
          ::Storage.bulk_add(providables)
          providables.each do |item_name, item_count|
            Metrics::Prometheus[:providable_items_total].observe(item_count,
              labels: { server: self.name, item_name: item_name, item_type: ItemType[item_name] })
          end
        end
      end

    end

  end
end
