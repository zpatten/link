# frozen_string_literal: true

class ThreadPool

  module ClassMethods

    @@thread_group = ThreadGroup.new
    @@metric ||= $thread_pool_metric
    @@thread_schedules ||= ThreadSafeArray.new

    def thread_group
      @@thread_group
    end

    def thread_schedules
      @@thread_schedules
    end

    def metric
      @@metric
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

      self.metric.set(@@thread_group.list.count)

      thread
    end

    def register(what, parallel: false, **options, &block)
      schedule = OpenStruct.new(
        block: block,
        frequency: Config.master_value(:scheduler, what),
        next_run_at: Time.now.to_f,
        options: options,
        parallel: parallel,
        what: what
      )
      @@thread_schedules << schedule
      schedule_log(:scheduler, :added, schedule)

      true
    end

    def run_thread(schedule, *args)
      thread = Thread.new do
        trap_signals
        schedule_log(:thread, :started, schedule, Thread.current)

        schedule.block.call(*args)

        schedule_log(:thread, :stopping, schedule, Thread.current)
      end
        thread_name = [
          server_names(*args),
          schedule.what.to_s
        ].compact.join(":")
      thread.name = thread_name
      thread.priority = schedule.options.fetch(:priority, 0)
      @@thread_group.add(thread)
    end

    def run(schedule)
      schedule_log(:thread, :starting, schedule)

      parallel = schedule.parallel
      what     = schedule.what

      servers  = Servers.find(what)
      # [servers].flatten.compact.map(&:startup!)
      servers.delete_if { |server| server.unavailable? } unless servers.nil?

      if parallel
        servers.each do |server|
          # next if server.unavailable?
          run_thread(schedule, server)
        end
      else
        run_thread(schedule, servers)
      end

      self.metric.set(@@thread_group.list.count)

      true
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
      now         = Time.now.to_f
      frequency   = schedule.frequency
      next_run_at = (now + (frequency - (now % frequency)))
      schedule.next_run_at = next_run_at
      schedule_log(:thread, :scheduled, schedule)
    end

    def shutdown!
      @@thread_schedules = Array.new
      @@thread_group.list.map(&:exit)
    end

    def execute
      loop do
        @@thread_schedules.each do |schedule|
          if schedule.next_run_at <= Time.now.to_f
            run(schedule)
            schedule_next_run(schedule)
          end
          Thread.pass
        end

        sleep SLEEP_TIME

        self.metric.set(@@thread_group.list.count)
      end
    end

  end

  extend ClassMethods
end
