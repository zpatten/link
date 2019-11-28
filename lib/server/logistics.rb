# frozen_string_literal: true

class Server
  module Logistics

    def schedule_logistics
      ThreadPool.schedule_server(:logistics, server: self) do

        command = %(remote.call('link', 'get_providables'))
        payload = self.rcon_command(command: command)
        unless payload.nil? || payload.empty?
          providables = JSON.parse(payload)
          unless providables.nil? || providables.empty?
            $logger.debug(:logistics) { "[#{self.name}] providables: #{providables.ai}" }
            providables.transform_keys! do |item_name|
              if item_name =~ /link-fluid-(?!.*(provider|requester)).*/
                item_name.gsub('link-fluid-', '')
              else
                item_name
              end
            end
            self.method_proxy.Storage(:bulk_add, providables)
          end
        end

        command = %(remote.call('link', 'get_requests'))
        payload = self.rcon_command(command: command)
        unless payload.nil? || payload.empty?
          requests = JSON.parse(payload)
          unless requests.nil? || requests.empty?
            $logger.debug(:logistics) { "[#{self.name}] requests: #{requests.ai}" }
            logistics = ::Logistics.new(self, requests)
            fulfillments = logistics.fulfill
            command = %(remote.call('link', 'set_fulfillments', '#{fulfillments.to_json}'))
            self.rcon_command(command: command)
            $logger.debug(:logistics) { "[#{self.name}] fulfillments: #{fulfillments.ai}" }
          end
        end

      end
    end

  end
end
