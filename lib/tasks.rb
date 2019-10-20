# Tasks
################################################################################
def schedule_task_statistics
  schedule_task(:statistics) do
    Storage.calculate_statistics
  end
end
