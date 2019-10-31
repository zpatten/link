# frozen_string_literal: true

class ThreadPool

  module ClassMethods

    @@thread_group = ThreadGroup.new
    @@thread_schedules ||= ThreadSafeArray.new

    def thread_group
      @@thread_group
    end

    def thread_schedules
      @@thread_schedules
    end

    def thread(name, options={}, &block)
      schedule_log(:thread, :starting, name)

      thread = Thread.new do
        trap_signals
        block.call
      end
      thread.name     = name
      thread.priority = options.fetch(:priority, 0)
      @@thread_group.add(thread)

      $metric_thread_count.set(@@thread_group.list.count)

      thread
    end

    def register(what, parallel: false, task: false, **options, &block)
      schedule = OpenStruct.new(
        block: block,
        frequency: Config.master_value(:scheduler, what),
        next_run_at: Time.now.to_f,
        options: options,
        parallel: parallel,
        task: task,
        what: what
      )
      @@thread_schedules << schedule
      schedule_log(:scheduler, :added, schedule)

      true
    end

    def thread_instrumentation(schedule, &block)
      if $thread_execution && $thread_timing
        elapsed_time = Benchmark.realtime(&block)
        $thread_execution.observe(elapsed_time, labels: { name: schedule.what.to_s })
        $thread_timing.set(elapsed_time, labels: { name: schedule.what.to_s })
      else
        block.call
      end
    end

    def run_thread(schedule, *args)
      thread_name = [
        server_names(*args),
        schedule.what.to_s
      ].compact.join(":")
      return if @@thread_group.list.map(&:name).compact.include?(thread_name)

      thread = Thread.new do
        thread_instrumentation(schedule) do
          trap_signals
          expires_in = [(schedule.frequency * 2), 10.0].max
          expires_at = Time.now.to_f + expires_in
          # Thread.current[:started_at] = Time.now.to_f
          # Thread.current[:expires_in] = [(schedule.frequency * 2), 10.0].max
          Thread.current[:expires_at] = expires_at
          schedule_log(:thread, :started, schedule, Thread.current)

          schedule.block.call(*args)

          schedule_log(:thread, :stopping, schedule, Thread.current)
        end
      end
      thread.name = thread_name
      thread.priority = schedule.options.fetch(:priority, 0)
      @@thread_group.add(thread)
    end

    def run(schedule)
      parallel = schedule.parallel
      what     = schedule.what
      task     = schedule.task

      servers  = Servers.find(what)
      servers.delete_if { |server| server.unavailable? } unless servers.nil?
      return if !task && (servers.nil? || servers.count == 0)

      if parallel
        servers.each do |server|
          run_thread(schedule, server)
        end
      else
        run_thread(schedule, servers)
      end

      $metric_thread_count.set(@@thread_group.list.count)

      true
    end

    def schedule_task(what, parallel: false, **options, &block)
      $logger.info(:scheduler) { "Scheduling task #{what.to_s.inspect}" }
      register(what, parallel: parallel, task: true, **options, &block)
    end

    def schedule_servers(what, parallel: true, **options, &block)
      $logger.info(:scheduler) { "Scheduling servers #{what.to_s.inspect}" }
      register(what, parallel: parallel, priority: 2, **options, &block)
    end

    def server_names(*args)
      return nil if args.nil? || args.empty?
      args = [args].flatten.compact
      if args.count == 0
        nil
      else
        args.collect { |s| s.name }.join(",")
      end
    end

    def schedule_log(action, who, schedule, thread=nil)
      unless schedule.is_a?(String)
        who = who.to_s.capitalize
        action = action.to_s.downcase
        what = schedule.what.to_s.downcase
        next_run_at = schedule.next_run_at
        frequency = schedule.frequency
        parallel = schedule.parallel
        block = schedule.block

        log_fields = [
          (thread.nil? ? nil : "thread_id:#{thread.object_id}"),
          "next_run_at:#{next_run_at}",
          "frequency:#{frequency}",
          "parallel:#{parallel}",
          "block:#{block}"
        ].compact.join(", ")

        $logger.debug(:thread) { "#{who} #{action} #{what}: #{log_fields}" }
      else
        $logger.debug(:thread) { "#{who} #{action} #{schedule.to_s.downcase}" }
      end
    end

    def schedule_next_run(schedule)
      now                  = Time.now.to_f
      frequency            = schedule.frequency
      next_run_at          = (now + (frequency - (now % frequency)))
      schedule.next_run_at = next_run_at
      schedule_log(:thread, :scheduled, schedule)
    end

    def shutdown!
      @@thread_schedules = Array.new
      @@thread_group.list.map(&:exit)
    end

    def execute
      last_checked_threads_at = Time.now.to_f
      loop do
        @@thread_schedules.each do |schedule|
          if schedule.next_run_at <= Time.now.to_f
            run(schedule)
            schedule_next_run(schedule)
          end
          # Thread.pass
        end

        if last_checked_threads_at < (Time.now.to_f - 10.0)
          last_checked_threads_at = Time.now.to_f
          $logger.info(:thread) { "Checking for stale threads" }
          @@thread_group.list.each do |thread|
            if thread.key?(:expires_at) && (Time.now.to_f > thread[:expires_at])
              $logger.fatal(:thread) { "Thread #{thread.name.inspect} expired!" }
              thread.exit
            end
          end
        end

        sleep SLEEP_TIME

        $metric_thread_count.set(@@thread_group.list.count)
      end
    end

  end

  extend ClassMethods
end
