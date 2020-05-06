# frozen_string_literal: true

class Link
  class ThreadPool

    module ClassMethods

      @@thread_group_persistent ||= ThreadGroup.new
      @@thread_group_scheduled ||= ThreadGroup.new
      @@thread_schedules ||= Concurrent::Array.new

      def thread_group_scheduled
        @@thread_group_scheduled
      end

      def reset
        @@thread_group_persistent = ThreadGroup.new
        @@thread_group_scheduled = ThreadGroup.new
        @@thread_schedules = Concurrent::Array.new
      end

      def thread_schedules
        @@thread_schedules
      end

      def update_thread_count_metric
        thread_list = Thread.list.dup.delete_if { |t| t.nil? || t.name.nil? }

        Metrics[:thread_count].set(
          thread_list.count,
          labels: { name: Thread.current.name }
        )

        true
      end

      def thread(name, options={}, &block)
        schedule_log(:thread, :starting, name)

        thread = Thread.new do
          Link.trap_signals

          Thread.current.name         = name
          Thread.current.priority     = options.fetch(:priority, 0)
          Thread.current[:started_at] = Time.now.to_f

          block.call
        end
        @@thread_group_persistent.add(thread)

        thread
      end

      def register(what, task: false, server: nil, **options, &block)
        schedule = OpenStruct.new(
          block: block,
          frequency: Config.master_value(:scheduler, what),
          next_run_at: Time.now.to_f,
          options: options,
          task: task,
          server: server,
          what: what
        )
        @@thread_schedules << schedule
        schedule_log(:scheduler, :added, schedule)

        true
      end

      def thread_instrumentation(thread_name, &block)
        elapsed_time = Benchmark.realtime(&block)
        Metrics[:thread_timing].set(elapsed_time, labels: { name: thread_name })

        # if Metrics[:thread_execution] && Metrics[:thread_timing]
        #   elapsed_time = Benchmark.realtime(&block)
        #   Metrics[:thread_execution].observe(elapsed_time, labels: { name: thread_name })
        #   Metrics[:thread_timing].set(elapsed_time, labels: { name: thread_name })
        # else
        #   block.call
        # end

        true
      end

      def run_thread(schedule, server)
        thread_name = Array.new
        thread_name << if server.nil?
          Thread.current.name
        else
          server.name
        end
        thread_name << schedule.what.to_s
        thread_name = thread_name.compact.join(':')

        return false if @@thread_group_scheduled.list.map(&:name).compact.include?(thread_name)

        thread = Thread.new do
          # trap_signals

          Thread.current.name = thread_name
          Thread.current.priority = schedule.options.fetch(:priority, 0)

          thread_instrumentation(thread_name) do
            # expires_in                  = [(schedule.frequency * 2), 10.0].max
            thread_timeout = schedule.options.fetch(:timeout, THREAD_TIMEOUT)
            expires_at                  = Time.now.to_f + thread_timeout
            Thread.current[:expires_at] = expires_at
            Thread.current[:started_at] = Time.now.to_f

            schedule_log(:thread, :starting, schedule, Thread.current)
            schedule.block.call #(server)
            schedule_log(:thread, :stopping, schedule, Thread.current)
          end
        end
        @@thread_group_scheduled.add(thread)

        true
      end

      def run(schedule)
        parallel = schedule.parallel
        what     = schedule.what
        task     = schedule.task
        server   = schedule.server

        return if !server.nil? && server.unavailable?

        run_thread(schedule, server)

        Metrics[:thread_count].set(
          @@thread_group_scheduled.list.count,
          labels: { name: Thread.current.name }
        )

        true
      end

      def schedule_task(what, **options, &block)
        $logger.info(:scheduler) { "Scheduling task #{what.to_s.inspect}" }
        register(what, task: true, **options, &block)
      end

      def schedule_server(what, **options, &block)
        $logger.info(:scheduler) { "Scheduling server #{what.to_s.inspect}" }
        register(what, **options, &block)
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
          # parallel = schedule.parallel
          block = schedule.block

          log_fields = [
            # (thread.nil? ? nil : "thread:#{thread.name}"),
            "next_run_at:#{next_run_at}",
            "frequency:#{frequency}",
            # "parallel:#{parallel}",
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
        reset
        while running?
          $logger.fatal(:thread) { "Waiting for threads to exit..." }
          sleep 1
        end
      end

      def running?
        @@thread_group_scheduled.list.size > 0
      end

      def execute
        Link.trap_signals

        reset

        if Link.master?
          $logger.info(:thread) { "Master Startup" }

          thread = ThreadPool.thread("sinatra") do
            WebServer.run! do |server|
              # NOOP
            end
          end

          Servers.all.each do |server|
            if server.container_alive?
              server.start!(false)
            end
          end
        end

        Link.schedule_task_prometheus
        if Link.master?
          Link.schedule_task_autosave
          Link.schedule_task_backup
          Link.schedule_task_signals
          Link.schedule_task_statistics
          Link.schedule_task_watchdog
        end
        yield if block_given?

        loop do
          @@thread_group_scheduled.list.each do |thread|
            unless thread[:expires_at].nil? || Time.now.to_f <= thread[:expires_at]
              $logger.fatal(:thread) { "Thread Expired: #{thread.name}" }
              thread.exit
            end
          end

          next_run_at = []
          @@thread_schedules.each do |schedule|
            if schedule.next_run_at <= Time.now.to_f
              run(schedule)
              schedule_next_run(schedule)
            end
            next_run_at << schedule.next_run_at
          end

          update_thread_count_metric

          sleep_for = (next_run_at.min - Time.now.to_f)
          sleep sleep_for if sleep_for > 0.0
        end

      end

    end

    extend ClassMethods
  end

end
