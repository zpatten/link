# frozen_string_literal: true

class Tasks
  module ClassMethods

################################################################################

    def exception_handler(tag:, &block)
      begin
        yield
      rescue Exception => e
        LinkLogger.fatal(tag) { "CAUGHT EXCEPTION: #{e.ai} - #{e.message.ai}\n#{e.backtrace.ai}" }
      end
    end

    def metrics_handler(pool:, task:, server_tag:, &block)
      elapsed_time = Benchmark.realtime(&block)
      Metrics::Prometheus[:thread_duration_seconds].observe(elapsed_time,
        labels: { server: server_tag.downcase, task: task.downcase }
      )
      Metrics::Prometheus[:threads].set(Thread.list.count)
      Metrics::Prometheus[:threads_running].set(Thread.list.count { |t| t.status == 'run' })
      Metrics::Prometheus[:threads_queue_length].set(pool.queue_length)
    end

    def timeout_handler(timeout: Config.value(:timeout, :thread), task: nil, tag: nil, server: nil, &block)
      timeout = Config.value(:timeout, task) || Config.value(:timeout, :thread) if task
      Timeout.timeout(timeout, &block)
      true
    rescue Timeout::Error => e
      message = "Timeout after #{timeout.ai} seconds"
      unless server.nil?
        server.timeouts += 1
        message += " (Timeouts: #{server.timeouts.ai})"
      end
      LinkLogger.warn(tag) { message }
      false
    end

    def tags(**options)
      server = options[:server]
      task   = options[:task]

      server_tag = (server && server.name) || PROGRAM_NAME
      tag        = [(server && server.name), task].flatten.compact.join('.') || Thread.current.name

      [server_tag.downcase, tag.downcase]
    end

################################################################################

    def onetime(task:, pool: Runner.pool, cancellation: Runner.cancellation, server: nil, metrics: false, **options, &block)
      server_tag, tag = tags(task: task, server: server)

      Concurrent::Promises.future_on(pool) do
        Thread.current.name = server_tag
        LinkLogger.debug(tag) { "Process Started (onetime)" }
        exception_handler(tag: tag) do
          if metrics
            metrics_handler(pool: pool, task: task, server_tag: server_tag) { block.call(server) }
          else
            block.call(server)
          end
        end
        LinkLogger.debug(tag) { "Process Finished (onetime)" }
        Thread.current.name = "stopped-#{tag}"
      end.run

      true
    end

################################################################################

    def repeat(task:, pool: Runner.pool, cancellation: Runner.cancellation, server: nil, metrics: true, **options, &block)
      server_tag, tag = tags(task: task, server: server)

      repeat_task = -> cancellation do
        Thread.current.name = server_tag
        until cancellation.canceled? do
          LinkLogger.debug(tag) { "Process Started (repeat)" }
          exception_handler(tag: tag) do
            timeout_handler(task: task, tag: tag, server: server) do
              if metrics
                metrics_handler(pool: pool, task: task, server_tag: server_tag) { block.call(server) }
              else
                block.call(server)
              end
            end
          end
          LinkLogger.debug(tag) { "Process Finished (repeat)" }
        end
        LinkLogger.warn(tag) { "Process Canceled (repeat)" }
        Thread.current.name = "stopped-#{tag}"
      end

      Concurrent::Promises.future_on(pool, cancellation, &repeat_task).run

      LinkLogger.debug(tag) { "Added Process (repeat)" }

      true
    end

################################################################################

    def schedule(task:, pool: Runner.pool, cancellation: Runner.cancellation, server: nil, **options, &block)
      return false if task_schedule(task).nil?

      server_tag, tag = tags(task: task, server: server)

      repeating_scheduled_task = -> interval, cancellation, task do
        Concurrent::Promises.schedule_on(pool, interval, cancellation, &task).then { repeating_scheduled_task.call(interval, cancellation, task) }
      end

      scheduled_task = -> cancellation do
        Thread.current.name = server_tag
        if cancellation.canceled?
          LinkLogger.debug(tag) { "Scheduled Task Canceled" }
          cancellation.check!
        end

        LinkLogger.debug(tag) { "Scheduled Task Started" }
        exception_handler(tag: tag) do
          timeout_handler(task: task, tag: tag, server: server) do
            metrics_handler(pool: pool, task: task, server_tag: server_tag)  { block.call(server) }
          end
        end
        LinkLogger.debug(tag) { "Scheduled Task Finished" }
        Thread.current.name = "stopped-#{tag}"

        true
      end

      Concurrent::Promises.future_on(pool,
        Config.value(:scheduler, task),
        cancellation,
        scheduled_task,
        &repeating_scheduled_task
      ).run

      LinkLogger.info(tag) { "Added Scheduled Task" }

      true
    end

################################################################################

    def task_enabled?(task)
      !!Config.value(:tasks, task)
    end

    def task_disabled?(task)
      !task_enabled?(task)
    end

################################################################################

    def task_schedule(task)
      return Config.value(:scheduler, task) unless task_disabled?(task)
      LinkLogger.warn(:tasks) { "Task #{task.ai} not configured!" }
      nil
    end

################################################################################

  end

  extend ClassMethods
end


# Tasks
################################################################################

def schedule_task_mark
  Tasks.schedule(task: :mark) do
    LinkLogger.info(:mark) { "---MARK--- @ #{Time.now.utc}" }
    GC.start(full_mark: true, immediate_sweep: true) if RUBY_ENGINE == 'ruby'
  end
end

def schedule_task_trim
  Tasks.schedule(task: :trim) do
    Servers.trim_saves
  end
end

def schedule_task_backup
  Tasks.schedule(task: :backup) do
    Factorio::ItemTypes.save
    Factorio::Storage.save
    Servers.backup
  end
end

def schedule_task_signals
  Tasks.schedule(task: :signals) do
    Factorio::Signals.update_inventory_signals
  end
end

def schedule_task_prometheus
  Tasks.schedule(task: :prometheus) do
    Factorio::Storage.metrics_handler

    Metrics::Prometheus.push
  end
end

def schedule_task_watchdog
  Tasks.schedule(task: :watchdog) do
    Servers.select(&:watch).each do |server|
      if server.unresponsive?
        LinkLogger.warn(server.log_tag(:watchdog)) { "Detected Unresponsive Server" }
        Runner.pool.post { server.restart!(container: true) }
      end
    end
  end
end
