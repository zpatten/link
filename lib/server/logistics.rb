# frozen_string_literal: true

class Server
  module Logistics

    def start_thread_logistics
      Tasks.schedule(:fulfillments, server: self) do
        command = %(remote.call('link', 'get_requests'))
        rcon_handler(command) do |requests|
          logistics = ::Logistics.new(self, requests)
          fulfillments = logistics.fulfill
          unless fulfillments.nil? || fulfillments.empty?
            command = %(remote.call('link', 'set_fulfillments', '#{fulfillments.to_json}'))
            self.rcon_command(command)
          end
        end

        # payload = self.rcon_command(command)
        # unless payload.nil? || payload.empty?
        #   requests = JSON.parse(payload)
        #   unless requests.nil? || requests.empty?
        #     logistics = ::Logistics.new(self, requests)
        #     fulfillments = logistics.fulfill
        #     unless fulfillments.nil? || fulfillments.empty?
        #       command = %(remote.call('link', 'set_fulfillments', '#{fulfillments.to_json}'))
        #       self.rcon_command(command)
        #     end
        #   end
        # end
      end

      Tasks.schedule(:providables, server: self) do
        command = %(remote.call('link', 'get_providables'))
        rcon_handler(command) do |providables|
          $logger.debug(self.name) { "[LOGISTICS] providables: #{providables.ai}" }
          ::Storage.bulk_add(providables)
        end

        # payload = self.rcon_command(command)
        # unless payload.nil? || payload.empty?
        #   providables = JSON.parse(payload)
        #   unless providables.nil? || providables.empty?
        #     $logger.debug(self.name) { "[LOGISTICS] providables: #{providables.ai}" }
        #     ::Storage.bulk_add(providables)
        #   end
        # end
      end

    end

  end
end
