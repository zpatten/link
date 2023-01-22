# frozen_string_literal: true

# Tasks
################################################################################
# repeating_scheduled_task = -> interval, cancellation, task do
#   Concurrent::Promises.
#     schedule(interval, cancellation, &task).
#     then { repeating_scheduled_task.call(interval, cancellation, task) }
# end

# task_statistics = -> cancellation do
#   cancellation.check!
#   puts "Running task: statistics"
#   Storage.calculate_delta
# end

# result = Concurrent::Promises.future(
#   Config.master_value(:scheduler, :statistics) || 120,
#   $cancellation,
#   task_statistics,
#   &repeating_scheduled_task
# ).run


def schedule_task_statistics
  ThreadPool.schedule_task(:statistics) do
    Storage.calculate_delta
  end
end

def schedule_task_backup
  ThreadPool.schedule_task(:backup) do
    Servers.backup
    Servers.trim_save_files
  end
end

def schedule_task_prometheus
  ThreadPool.schedule_task(:prometheus) do
    Metrics.push
  end
end

def schedule_task_autosave
  ThreadPool.schedule_task(:autosave) do
    ItemType.save
    Storage.save
  end
end

def schedule_task_signals
  ThreadPool.schedule_task(:signals) do
    Signals.update_inventory_signals
  end
end

def schedule_task_watchdog
  ThreadPool.schedule_task(:watchdog, timeout: 300) do
    Servers.all.each do |server|
      if server.process_alive? && server.unresponsive?
        $logger.warn(:servers) {
          "[#{server.name}] Detected Unresponsive Server - Restarting"
        }
        server.restart!
      end
    end
  end
end
