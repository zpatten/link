# Tasks
################################################################################
def schedule_task_statistics
  schedule_task(:statistics) do
    Storage.calculate_statistics
  end
end

def schedule_task_prometheus
  schedule_task(:prometheus) do
    Prometheus::Client::Push.new('link', 'master', 'http://127.0.0.1:9091').add($prometheus)
  end
end
