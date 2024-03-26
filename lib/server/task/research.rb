# frozen_string_literal: true

# Link: Factorio Server Research Mirroring
################################################################################
class Server
  module Task
    module Research

      def schedule_task_research_current
        if @research
          Tasks.schedule(task: :research_current, pool: @pool, cancellation: @cancellation, server: self) do
            command = %(remote.call('link', 'get_current_research'))
            rcon_handler(task: :get_current_research, command: command) do |current_research|
              LinkLogger.debug(log_tag(:research_current)) { "Current Research: #{current_research.ai}" }
              command = %(remote.call('link', 'set_current_research', '#{current_research.to_json}'))

              Servers.rcon_command_nonblock(:non_research, command)
            end
          end
        end
      end

      def schedule_task_research
        if @research
          Tasks.schedule(task: :research, pool: @pool, cancellation: @cancellation, server: self) do
            command = %(remote.call('link', 'get_research'))
            rcon_handler(task: :get_research, command: command) do |research|
              LinkLogger.debug(log_tag(:research)) { "Research: #{research.ai}" }
              command = %(remote.call('link', 'set_research', '#{research.to_json}'))

              Servers.rcon_command_nonblock(:non_research, command)
            end
          end
        end
      end

    end
  end
end

