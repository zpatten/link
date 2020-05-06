# frozen_string_literal: true

class Link
  class Server
    module Logistics

      def schedule_logistics
        ThreadPool.schedule_server(:logistics, server: self) do

          command = %(remote.call('link', 'get_requests'))
          payload = self.rcon_command(command: command)
          unless payload.nil? || payload.empty?
            requests = JSON.parse(payload)
            unless requests.nil? || requests.empty?
              logistics = ::Logistics.new(self, requests)
              fulfillments = logistics.fulfill
              unless fulfillments.nil? || fulfillments.empty?
                command = %(remote.call('link', 'set_fulfillments', '#{fulfillments.to_json}'))
                self.rcon_command(command: command)
              end
            end
          end

          command = %(remote.call('link', 'get_providables'))
          payload = self.rcon_command(command: command)
          unless payload.nil? || payload.empty?
            providables = JSON.parse(payload)
            unless providables.nil? || providables.empty?
              $logger.debug(:logistics) {
                "[#{self.name}] providables: #{providables.ai}"
              }
              self.method_proxy.Storage(:bulk_add, providables)
            end
          end

        end
      end

    end
  end
end
