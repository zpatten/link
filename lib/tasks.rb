# frozen_string_literal: true

# Tasks
################################################################################
def schedule_task_statistics
  schedule_task(:statistics) do
    $logger.info(:statistics) { ("=" * 80) }
    Storage.calculate_delta
  end
end

def schedule_task_prometheus
  schedule_task(:prometheus) do
    RescueRetry.attempt do
      Prometheus::Client::Push.new('link', 'master', 'http://127.0.0.1:9091').add($prometheus)
    end
  end
end
