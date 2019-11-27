# frozen_string_literal: true

class ThreadPool

  module ClassMethods

    @@thread_group ||= ThreadGroup.new
    # @@thread_group_2 ||= ThreadGroup.new
    @@thread_schedules ||= Concurrent::Array.new #ThreadSafeArray.new

    def thread_group
      @@thread_group
    end

    def thread_schedules
      @@thread_schedules
    end

    def thread(name, options={}, &block)
      schedule_log(:thread, :starting, name)

      thread = Thread.new do
        Thread.current[:started_at] = Time.now.to_f

        trap_signals
        block.call
        Thread.exit
      end
      thread.name     = name
      thread.priority = options.fetch(:priority, 0)
      # @@thread_group_2.add(thread)

      Metrics[:thread_count].set(
        @@thread_group.list.count,
        labels: { name: Thread.current.name }
      )

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

      return false if @@thread_group.list.map(&:name).compact.include?(thread_name)

      thread = Thread.new do
        Thread.current.name = thread_name
        Thread.current.priority = schedule.options.fetch(:priority, 0)

        thread_instrumentation(thread_name) do
          trap_signals
          expires_in                  = [(schedule.frequency * 2), 10.0].max
          expires_at                  = Time.now.to_f + THREAD_TIMEOUT
          Thread.current[:expires_at] = expires_at
          Thread.current[:started_at] = Time.now.to_f

          schedule_log(:thread, :starting, schedule, Thread.current)
          schedule.block.call #(server)
          schedule_log(:thread, :stopping, schedule, Thread.current)
        end

        Thread.exit
      end
      @@thread_group.add(thread)

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
        @@thread_group.list.count,
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
      @@thread_schedules = Array.new
      Thread.list.each do |thread|
        thread.exit unless thread == Thread.main
      end
    end

    def running?
      @@thread_group.list.size > 0
    end

    def wait_on_server_threads(server_name)
      sleep 1
      sleep SLEEP_TIME while server_thread_running?(server_name)
    end

    def server_thread_running?(server_name)
      @@thread_group.list.each do |thread|
        return true if thread.name =~ /server_name/i
      end

      false
    end

    def execute

      trap_signals

      # at_exit do
      #   $logger.fatal(:at_exit) { 'Shutting down!' }
      #   shutdown!
      # end

      if master?
        $logger.info { "In main process #{Process.pid}" }

        thread = ThreadPool.thread("sinatra") do
          # require_relative '../web_server'
          ::WebServer.run! do |server|
          end
        end
        ::Servers.all.each do |s|
          if s.running?
            s.start_process!
            s.start_rcon!
          end
        end

        schedule_task_backup
        schedule_task_statistics
      else
      end
      schedule_task_prometheus

      last_checked_threads_at = Time.now.to_f
      next_run_at = Array.new

      loop do
        @@thread_group.list.each do |thread|
          unless thread[:expires_at].nil? || Time.now.to_f < thread[:expires_at]
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
        sleep_for = (next_run_at.min - Time.now.to_f)
        sleep sleep_for if sleep_for > 0.0

        Metrics[:thread_count].set(
          @@thread_group.list.count,
          labels: { name: Thread.current.name }
        )
      end

    end

  end

  extend ClassMethods
end
