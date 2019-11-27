# frozen_string_literal: true

# Tasks
################################################################################
def schedule_task_statistics
  ThreadPool.schedule_task(:statistics) do
    Storage.calculate_delta
  end
end

def schedule_task_backup
  ThreadPool.schedule_task(:backup) do
    $logger.info(:backup) { "Backing up servers..." }
    Servers.backup
    Servers.trim_save_files
  end
end

def schedule_task_prometheus
  ThreadPool.schedule_task(:prometheus) do
    Metrics.push
  end
end
