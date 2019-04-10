# Tasks
################################################################################
schedule_task(:statistics) do
  Storage.calculate_statistics
end
