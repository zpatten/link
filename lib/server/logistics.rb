# frozen_string_literal: true

class Server
  module Logistics

    def schedule_requests
      ThreadPool.schedule_task(:requests, server: self) do |server|

        command = %(/#{rcon_executor} remote.call('link', 'get_requests'))
        payload = self.rcon_command(command: command)
        unless payload.nil? || payload.empty?
          requests = JSON.parse(payload)
          unless requests.nil? || requests.empty?
            $logger.debug(:logistics) { "[#{self.name}] requests: #{requests.ai}" }
            logistics = ::Logistics.new(self, requests)
            fulfillments = logistics.fulfill
            command = %(/#{rcon_executor} remote.call('link', 'set_fulfillments', '#{fulfillments.to_json}'))
            self.rcon_command(command: command)
            $logger.debug(:logistics) { "[#{self.name}] fulfillments: #{fulfillments.ai}" }
          end
        end

      end
    end

  end
end
