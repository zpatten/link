# frozen_string_literal: true

def schedule_task_watchdog
  Tasks.schedule(task: :watchdog) do
    Servers.select(&:watch).each do |server|
      if server.unresponsive?
        LinkLogger.warn(server.log_tag(:watchdog)) { "Detected Unresponsive Server" }
        Runner.pool.post { server.restart!(container: true) }
      end
    end
  end
end
