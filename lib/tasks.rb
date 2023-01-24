# frozen_string_literal: true

class Tasks
  module Process
    def process(what, cancellation: nil, &block)
      cancellation = cancellation || $cancellation
      # task = -> cancellation do
      #   begin
      #     block.call until cancellation.canceled?
      #   rescue Exception => e
      #     $logger.fatal(tag) { "[#{what}] #{e.ai}\n#{e.backtrace.ai}" }
      #     puts e.ai
      #     puts e.backtrace.ai
      #     # raise e
      #   end
      # end
      # result = Concurrent::Promises.future(
      #   cancellation,
      #   task
      # ).run

      task = -> cancellation do
        begin
          $logger.debug(tag) { "[#{what}] Process Started" }
          block.call until cancellation.canceled?
        rescue Exception => e
          $logger.fatal(tag) { "[#{what}] #{e.ai}\n#{e.backtrace.ai}" }
          puts e.ai
          puts e.backtrace.ai
          # raise e
        end
      end

      #Concurrent::Promises.future(cancellation) do |cancellation|
      result = Concurrent::Promises.future_on($pool,
        Config.master_value(:scheduler, what) || 120,
        cancellation,
        &task
      ).run

      # $pool.post do
      #   begin
      #     $logger.debug(tag) { "[#{what}] Process Started" }
      #     block.call until cancellation.canceled?
      #   rescue Exception => e
      #     $logger.fatal(tag) { "[#{what}] #{e.ai}\n#{e.backtrace.ai}" }
      #     puts e.ai
      #     puts e.backtrace.ai
      #     # raise e
      #   end
      # end
    end
  end

  module Scheduling
    def schedule(what, server: nil, &block)
      return false unless !!Config.master_value(:scheduler, what)
      repeating_scheduled_task = -> interval, cancellation, task do
        Concurrent::Promises.
          schedule_on($pool, interval, cancellation, &task).
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

      result = Concurrent::Promises.future_on($pool,
        Config.master_value(:scheduler, what) || 120,
        cancellation,
        task,
        &repeating_scheduled_task
      ).run

      tag = (server and server.name) || Thread.current.name
      $logger.debug(tag) { "[#{what}] Added to task scheduler" }

      true
    end
  end

  extend Scheduling
  extend Process
end


# Tasks
################################################################################

def start_thread_statistics
  Tasks.schedule(:statistics) do
    Storage.calculate_delta
  end
end

def start_thread_backup
  Tasks.schedule(:backup) do
    Servers.backup
    Servers.trim_save_files
  end
end

def start_thread_autosave
  Tasks.schedule(:autosave) do
    ItemType.save
    Storage.save
  end
end

def start_thread_signals
  Tasks.schedule(:signals) do
    Signals.update_inventory_signals
  end
end

def start_thread_prometheus
  Tasks.schedule(:prometheus) do
    Metrics::Prometheus[:threads_total].set(Thread.list.count, labels: { name: 'total' })
    Metrics::Prometheus[:threads_running].set(Thread.list.select { |t| t.status == 'run' }.count, labels: { name: 'running' })
    Metrics::Prometheus[:threads_queue_length].set($pool.queue_length, labels: { name: 'queue_length' })

    Metrics::Prometheus.push
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
