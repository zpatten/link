# frozen_string_literal: true

# Link: Factorio Server Research Mirroring
################################################################################
class Server
  module Research

    def start_thread_research
      if @research
        Tasks.schedule(what: :research_current, pool: @pool, cancellation: @cancellation, server: self) do
          command = %(remote.call('link', 'get_current_research'))
          rcon_handler(what: :get_current_research, command: command) do |current_research|
            $logger.debug(log_tag(:research_current)) { "[RESEARCH] current research: #{current_research.ai}" }
            command = %(remote.call('link', 'set_current_research', '#{current_research.to_json}'))

            Servers.rcon_command_nonblock(:non_research, command)
          end
        end

        Tasks.schedule(what: :research, pool: @pool, cancellation: @cancellation, server: self) do
          command = %(remote.call('link', 'get_research'))
          rcon_handler(what: :get_research, command: command) do |research|
            $logger.debug(log_tag(:research)) { "[RESEARCH] research: #{research.ai}" }
            command = %(remote.call('link', 'set_research', '#{research.to_json}'))

            Servers.rcon_command_nonblock(:non_research, command)
          end
        end
      end
    end

  end
end

