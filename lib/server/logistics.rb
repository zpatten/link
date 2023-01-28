# frozen_string_literal: true

class Server
  module Logistics

    def start_thread_logistics
      Tasks.schedule(what: :fulfillments, pool: @pool, cancellation: @cancellation, server: self) do
        command = %(remote.call('link', 'get_requests'))
        rcon_handler(what: :get_requests, command: command) do |requests|
          logistics = ::Logistics.new(self, requests)
          fulfillments = logistics.fulfill
          unless fulfillments.nil? || fulfillments.empty?
            command = %(remote.call('link', 'set_fulfillments', '#{fulfillments.to_json}'))
            rcon_command_nonblock(command)
          end
        end
      end

      Tasks.schedule(what: :providables, pool: @pool, cancellation: @cancellation, server: self) do
        command = %(remote.call('link', 'get_providables'))
        rcon_handler(what: :get_providables, command: command) do |providables|
          # $logger.debug(@name) { "[LOGISTICS] providables: #{providables.ai}" }
          $storage.bulk_add(providables)
          providables.each do |item_name, item_count|
            Metrics::Prometheus[:providable_items_total].observe(item_count,
              labels: { server: self.name, item_name: item_name, item_type: ItemType[item_name] })
          end
        end
      end

    end

  end
end
