# frozen_string_literal: true

class Tasks
  module Scheduling
    def schedule(what, server: nil, &block)
      return false unless !!Config.master_value(:scheduler, what)
      repeating_scheduled_task = -> interval, cancellation, task do
        Concurrent::Promises.
          schedule(interval, cancellation, &task).
          then { repeating_scheduled_task.call(interval, cancellation, task) }
      end

      task = -> cancellation do
        if cancellation.canceled?
          $logger.debug(tag) { "[#{what}] Task Canceled" }
          cancellation.check!
        end
        tag = (server and server.name) || Thread.current.name
        $logger.debug(tag) { "[#{what}] Task Started" }
        begin
          block.call(server)
        rescue Exception => e
          $logger.fatal(tag) { "[#{what}] #{e.ai}\n#{e.backtrace.ai}" }
          puts e.ai
          puts e.backtrace.ai
          # raise e
        end
        $logger.debug(tag) { "[#{what}] Task Finished" }
        true
      end

      cancellation = (server ? $cancellation.join(server.cancellation) : $cancellation)

      result = Concurrent::Promises.future(
        Config.master_value(:scheduler, what) || 120,
        cancellation,
        task,
        &repeating_scheduled_task
      ).run

      # schedule = OpenStruct.new(
      #   block: block,
      #   frequency: Config.master_value(:scheduler, what) || 120,
      #   next_run_at: Time.now.to_f,
      #   options: options,
      #   task: task,
      #   server: server,
      #   what: what
      # )
      # @@thread_schedules << schedule
      tag = (server and server.name) || Thread.current.name
      $logger.debug(tag) { "[#{what}] Added to task scheduler" }

      true
    end
  end

  extend Scheduling
end
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

def start_thread_signals
  Tasks.schedule(:signals) do
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
