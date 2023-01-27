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

    def tags(**options)
      server = options[:server]
      what   = options[:what]

      server_tag = (server && server.name) || 'link'
      tag        = [(server && server.name), what].flatten.compact.join('.') || Thread.current.name

      [server_tag, tag]
    end

    def onetime(what:, pool: $pool, cancellation: $cancellation, server: nil, **options, &block)
      server_tag, tag = tags(what: what, server: server)

      Concurrent::Promises.future_on(pool) do
        begin
          $logger.info(tag) { "Process Started (onetime)" }
          metrics_handler(pool: pool, what: what, server_tag: server_tag, &block)
          $logger.info(tag) { "Process Finished (onetime)" }
        rescue Exception => e
          $logger.fatal(tag) { e.message.ai }
          $logger.fatal(tag) { e.backtrace.ai }
        end
      end.run
    end


################################################################################

    def repeat(what:, pool: $pool, cancellation: $cancellation, server: nil, **options, &block)
      server_tag, tag = tags(what: what, server: server)

      task = -> cancellation do
        begin
          $logger.info(tag) { "Process Started (repeat)" }
          until cancellation.canceled? do
            metrics_handler(pool: pool, what: what, server_tag: server_tag, &block)
          end
          $logger.info(tag) { "Process Canceled (repeat)" }
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

    def schedule(what:, pool: $pool, cancellation: $cancellation, server: nil, **options, &block)
      return false unless !!Config.master_value(:scheduler, what)

      server_tag, tag = tags(what: what, server: server)

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
  Tasks.schedule(what: :mark) do
    $logger.info(:mark) { "---MARK--- @ #{Time.now.utc}" }
  end
end

def start_thread_backup(**options)
  Tasks.schedule(what: :backup) do
    Servers.backup
    Servers.trim_save_files
  end
end

def start_thread_autosave(**options)
  Tasks.schedule(what: :autosave) do
    ItemType.save
    Storage.save
  end
end

def start_thread_signals(**options)
  Tasks.schedule(what: :signals) do
    Signals.update_inventory_signals
  end
end

def start_thread_prometheus(**options)
  Tasks.schedule(what: :prometheus) do
    Storage.metrics_handler

    Metrics::Prometheus.push
  end
end

def start_thread_watchdog(**options)
  Tasks.schedule(what: :watchdog) do
    Servers.all.select(&:watch).each do |server|
      # $logger.info(server.log_tag(:watchdog)) { "Checking Server" }
      if server.unresponsive?
        $logger.warn(server.log_tag(:watchdog)) { "Detected Unresponsive Server" }
        server.restart!(container: true)
      end
    end
  end
end
