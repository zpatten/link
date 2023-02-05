# frozen_string_literal: true

class Server
  module Task
    module Fulfillments

      def schedule_task_fulfillments
        Tasks.schedule(what: :fulfillments, pool: @pool, cancellation: @cancellation, server: self) do
          command = %(remote.call('link', 'get_requests'))
          rcon_handler(what: :get_requests, command: command) do |requests|
            logistics = Factorio::Logistics.new(self, requests)
            fulfillments = logistics.fulfill
            unless fulfillments.nil? || fulfillments.empty?
              command = %(remote.call('link', 'set_fulfillments', '#{fulfillments.to_json}'))
              rcon_command_nonblock(command)
            end
          end
        end
      end

    end
  end
end
