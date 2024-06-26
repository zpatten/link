# frozen_string_literal: true

class Server
  module Task
    module Ping

      def schedule_task_ping
        Tasks.schedule(task: :ping, pool: @pool, cancellation: @cancellation, server: self) do
          # Calculate round-trip time to RCON
          command = %(remote.call('link', 'ping'))
          started_at = Time.now.to_f
          rcon_command(command)
          response_time = (Time.now.to_f - started_at)

          # Update Factorio Server with our current RTT
          command = %(remote.call('link', 'rtt', '#{response_time}'))
          rcon_command(command)

          # Update Link Server with our current RTT
          rtt_ms = (response_time * 1000.0).round(0)
          update_rtt(rtt_ms)

          # Update Prometheus with our current RTT
          Metrics::Prometheus[:server_rtt].set(rtt_ms, labels: { server: @name })

          LinkLogger.debug(log_tag(:ping)) { "RTT: #{rtt_ms}ms" }
        end
      end

    end
  end
end
