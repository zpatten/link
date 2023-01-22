# frozen_string_literal: true

# Link Factorio Server Research Mirroring
################################################################################
class Server
  module Research

    def start_thread_research
      if self.research
        # ThreadPool.schedule_server(:research_current, server: self) do
        Tasks.schedule(:research_current, server: self) do
          command = %(remote.call('link', 'get_current_research'))
          payload = self.rcon_command(command)
          unless payload.nil? || payload.empty?
            current_research = JSON.parse(payload)
            unless current_research.nil? || current_research.empty?
              $logger.debug(:research) { "[#{self.name}] current research: #{current_research.ai}" }
              command = %(remote.call('link', 'set_current_research', '#{current_research.to_json}'))

              Servers.rcon_command_nonblock(:non_research, command)
            end
          end
        end

        # ThreadPool.schedule_server(:research, server: self) do
        Tasks.schedule(:research, server: self) do
          command = %(remote.call('link', 'get_research'))
          payload = self.rcon_command(command)
          unless payload.nil? || payload.empty?
            research = JSON.parse(payload)
            unless research.nil? || research.empty?
              $logger.debug(:research) { "[#{self.name}] research: #{research.ai}" }
              command = %(remote.call('link', 'set_research', '#{research.to_json}'))

              Servers.rcon_command_nonblock(:non_research, command)
            end
          end
        end
      end
    end

  end
end

