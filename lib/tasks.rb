# frozen_string_literal: true

class Tasks
  module ClassMethods

################################################################################

    def metrics_handler(pool:, what:, server_tag:, &block)
      elapsed_time = Benchmark.realtime(&block)
      Metrics::Prometheus[:thread_duration_seconds].observe(elapsed_time,
        labels: { server: server_tag.downcase, task: what.downcase }
      )
      Metrics::Prometheus[:threads].set(Thread.list.count)
      Metrics::Prometheus[:threads_running].set(Thread.list.count { |t| t.status == 'run' })
      Metrics::Prometheus[:threads_queue_length].set(pool.queue_length)
    end

    def timeout_handler(&block)
      Timeout.timeout(THREAD_TIMEOUT, &block)
    end

################################################################################

    def repeat(pool: $pool, cancellation: $cancellation, what: nil, server: nil, **options, &block)
      # pool         = options.delete(:pool) || $pool
      # cancellation = options.delete(:cancellation) || $cancellation
      # server       = options.delete(:server)

      server_tag = (server && server.name) || 'link'
      tag        = [(server && server.name), what].flatten.compact.join('.') || Thread.current.name

      task = -> cancellation do
        begin
          $logger.info(tag) { "Process Started" }
          until cancellation.canceled? do
            metrics_handler(pool: pool, what: what, server_tag: server_tag, &block)
          end
          $logger.info(tag) { "Process Canceled" }
        rescue Exception => e
          $logger.fatal(tag) { e.message.ai }
          $logger.fatal(tag) { e.backtrace.ai }
        end
      end

      result = Concurrent::Promises.future_on(pool,
        cancellation,
        &task
      ).run

    rescue Exception => e
      $logger.fatal(tag) { "EXCEPTION: #{e.message.ai}\n#{e.backtrace.ai}" }
      # raise e
    end

################################################################################

    def schedule(what, **options, &block)
      return false unless !!Config.master_value(:scheduler, what)

      pool         = options.delete(:pool) || $pool
      cancellation = options.delete(:cancellation) || $cancellation
      server       = options.delete(:server)

      server_tag = (server && server.name) || 'link'
      tag        = [(server && server.name), what].flatten.compact.join('.') || Thread.current.name

      repeating_scheduled_task = -> interval, cancellation, task do
        Concurrent::Promises.
          schedule_on(pool, interval, cancellation, &task).
          then { repeating_scheduled_task.call(interval, cancellation, task) }
      end

      task = -> cancellation do
        if cancellation.canceled?
          $logger.debug(tag) { "Scheduled Task Canceled" }
          cancellation.check!
        end
        $logger.debug(tag) { "Scheduled Task Started" }
        begin
          metrics_handler(pool: pool, what: what, server_tag: server_tag) { block.call(server) }
          # elapsed_time = Benchmark.realtime do
          #   block.call(server)
          # end
          # Metrics::Prometheus[:thread_duration_seconds].observe(elapsed_time,
          #   labels: { server: server_tag.downcase, task: what.downcase }
          # )
          # Metrics::Prometheus[:threads].set(Thread.list.count)
          # Metrics::Prometheus[:threads_running].set(Thread.list.count { |t| t.status == 'run' })
          # Metrics::Prometheus[:threads_queue_length].set(pool.queue_length)
        rescue Exception => e
          $logger.fatal(tag) { "EXCEPTION: #{e.message.ai}\n#{e.backtrace.ai}" }
          # raise e
        end
        $logger.debug(tag) { "Scheduled Task Finished" }
        true
      end

      result = Concurrent::Promises.future_on(pool,
        Config.master_value(:scheduler, what) || 120,
        cancellation,
        task,
        &repeating_scheduled_task
      ).run

      $logger.info(tag) { "Added Scheduled Task" }

      true
      rescue Exception => e
        $logger.fatal(tag) { e.message.ai }
        $logger.fatal(tag) { e.backtrace.ai }

        raise e
    end

################################################################################

  end

  extend ClassMethods
end


# Tasks
################################################################################

def start_thread_mark(**options)
  Tasks.schedule(:mark) do
    $logger.info(:mark) { "---MARK--- @ #{Time.now.utc}" }
  end
end

def start_thread_backup(**options)
  Tasks.schedule(:backup) do
    Servers.backup
    Servers.trim_save_files
  end
end

def start_thread_autosave(**options)
  Tasks.schedule(:autosave) do
    ItemType.save
    Storage.save
  end
end

def start_thread_signals(**options)
  Tasks.schedule(:signals) do
    Signals.update_inventory_signals
  end
end

def start_thread_prometheus(**options)
  Tasks.schedule(:prometheus) do
    Storage.metrics_handler

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
