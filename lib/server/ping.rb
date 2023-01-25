# frozen_string_literal: true

class Server
  module Ping

    def start_thread_ping
      # ThreadPool.schedule_server(:ping, server: self) do |server|
      Tasks.schedule(:ping, server: self) do
        # Calculate round-trip time to RCON
        command = %(remote.call('link', 'ping'))
        started_at = Time.now.to_f
        self.rcon_command(command)
        response_time = (Time.now.to_f - started_at)

        # Update Factorio Server with our current RTT
        command = %(remote.call('link', 'rtt', '#{response_time}'))
        self.rcon_command(command)

        # Update Link Server with our current RTT
        rtt_ms = (response_time * 1000.0).round(0)
        self.rtt = rtt_ms

        # Update Prometheus with our current RTT
        Metrics::Prometheus[:server_rtt].set(rtt_ms, labels: { server: self.name })

        $logger.debug(self.name) { "[PING] rtt: #{rtt_ms}ms" }
      end
    end

  end
end
