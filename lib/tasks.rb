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

    def metrics_handler(pool:, what:, server_tag:, &block)
      elapsed_time = Benchmark.realtime(&block)
      Metrics::Prometheus[:thread_duration_seconds].observe(elapsed_time,
        labels: { server: server_tag.downcase, task: what.downcase }
      )
      Metrics::Prometheus[:threads].set(Thread.list.count)
      Metrics::Prometheus[:threads_running].set(Thread.list.count { |t| t.status == 'run' })
      Metrics::Prometheus[:threads_queue_length].set(pool.queue_length)
    end

    def timeout_handler(timeout: Config.value(:timeout, :thread), what: nil, tag: nil, &block)
      timeout = Config.value(:timeout, what) || Config.value(:timeout, :thread) if what
      Timeout.timeout(timeout, &block)
    rescue Timeout::Error => e
      LinkLogger.warn(tag) { "Timeout after #{timeout.ai} seconds" }
    end

    def tags(**options)
      server = options[:server]
      what   = options[:what]

      server_tag = (server && server.name) || PROGRAM_NAME
      tag        = [(server && server.name), what].flatten.compact.join('.') || Thread.current.name

      [server_tag.downcase, tag.downcase]
    end

################################################################################

    def onetime(what:, pool: Runner.pool, cancellation: Runner.cancellation, server: nil, metrics: true, **options, &block)
      server_tag, tag = tags(what: what, server: server)

      Concurrent::Promises.future_on(pool) do
        Thread.current.name = tag
        LinkLogger.debug(tag) { "Process Started (onetime)" }
        exception_handler(tag: tag) do
          if metrics
            metrics_handler(pool: pool, what: what, server_tag: server_tag) { block.call(server) }
          else
            block.call(server)
          end
        end
        LinkLogger.debug(tag) { "Process Finished (onetime)" }
      end.run

      true
    end

################################################################################

    def repeat(what:, pool: Runner.pool, cancellation: Runner.cancellation, server: nil, metrics: true, **options, &block)
      server_tag, tag = tags(what: what, server: server)

      task = -> cancellation do
        Thread.current.name = tag
        until cancellation.canceled? do
          LinkLogger.debug(tag) { "Process Started (repeat)" }
          exception_handler(tag: tag) do
            timeout_handler(what: what, tag: tag) do
              if metrics
                metrics_handler(pool: pool, what: what, server_tag: server_tag) { block.call(server) }
              else
                block.call(server)
              end
            end
          end
          LinkLogger.debug(tag) { "Process Finished (repeat)" }
        end
        LinkLogger.warn(tag) { "Process Canceled (repeat)" }
      end

      Concurrent::Promises.future_on(pool, cancellation, &task).run

      LinkLogger.debug(tag) { "Added Process (repeat)" }

      true
    end

################################################################################

    def schedule(what:, pool: Runner.pool, cancellation: Runner.cancellation, server: nil, **options, &block)
      unless !!Config.value(:tasks, what)
        LinkLogger.warn(:tasks) { "Task #{what.ai} not configured!" }
        return false
      end

      server_tag, tag = tags(what: what, server: server)

      repeating_scheduled_task = -> interval, cancellation, task do
        Concurrent::Promises.schedule_on(pool, interval, cancellation, &task).then { repeating_scheduled_task.call(interval, cancellation, task) }
      end

      task = -> cancellation do
        Thread.current.name = tag
        if cancellation.canceled?
          LinkLogger.debug(tag) { "Scheduled Task Canceled" }
          cancellation.check!
        end

        LinkLogger.debug(tag) { "Scheduled Task Started" }
        exception_handler(tag: tag) do
          timeout_handler(what: what, tag: tag) do
            metrics_handler(pool: pool, what: what, server_tag: server_tag)  { block.call(server) }
          end
        end
        LinkLogger.debug(tag) { "Scheduled Task Finished" }

        true
      end

      Concurrent::Promises.future_on(pool,
        Config.value(:scheduler, what),
        cancellation,
        task,
        &repeating_scheduled_task
      ).run

      LinkLogger.info(tag) { "Added Scheduled Task" }

      true
    end

################################################################################

  end

  extend ClassMethods
end


# Tasks
################################################################################

def start_mark
  Tasks.schedule(what: :mark) do
    LinkLogger.info(:mark) { "---MARK--- @ #{Time.now.utc}" }
    GC.start(full_mark: true, immediate_sweep: true) if RUBY_ENGINE == 'ruby'
  end
end

def start_backup
  Tasks.schedule(what: :backup) do
    Servers.backup
    Servers.trim_save_files
  end
end

def start_autosave
  Tasks.schedule(what: :autosave) do
    ItemTypes.save
    Storage.save
  end
end

def start_signals
  Tasks.schedule(what: :signals) do
    Signals.update_inventory_signals
  end
end

def start_prometheus
  Tasks.schedule(what: :prometheus) do
    Storage.metrics_handler

    Metrics::Prometheus.push
  end
end

def start_watchdog
  Tasks.schedule(what: :watchdog) do
    Servers.select(&:watch).each do |server|
      if server.unresponsive?
        LinkLogger.warn(server.log_tag(:watchdog)) { "Detected Unresponsive Server" }
        Runner.pool.post { server.restart!(container: true) }
      end
    end
  end
end
