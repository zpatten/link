class ThreadPool

  module ClassMethods

    @@metric ||= $thread_pool_metric
#Metric.new(:uniform_histogram, "threads")
    @@thread_pool ||= Array.new
    @@thread_pool_mutex ||= Mutex.new

    @@thread_schedules ||= Array.new


    def synchronize(&block)
      @@thread_pool_mutex.synchronize(&block)
    end

    def thread_pool
      @@thread_pool
    end

    # def thread_pool<<(value)
    #   @@thread_pool << value
    # end

    def thread_schedules
      @@thread_schedules
    end

    def metric
      @@metric
    end

    def thread(name, &block)
      schedule_log(:thread, :starting, name)
      result = nil

      @@thread_pool << Thread.new do
        Thread.current.thread_variable_set(:name, name)
        result = block.call
        # schedule_log(:thread, :stopped, name)
        Thread.exit
      end

      #self.metric.update(@@thread_pool.count) unless (self.metric.values.first == @@thread_pool.count)
      self.metric.set(@@thread_pool.count)

      result
    end

    def register(what, parallel=false, &block)
      schedule = OpenStruct.new(
        what: what,
        frequency: Config.master_value(:scheduler, what),
        parallel: parallel,
        block: block,
        next_run_at: Time.now.to_f
      )
      @@thread_schedules << schedule
      schedule_log(:scheduler, :added, schedule)

      true
    end

    def run_thread(schedule, *args)
      Thread.new do
        schedule_log(:thread, :started, schedule, Thread.current)

        thread_name = [
          server_names(*args),
          schedule.what.to_s
        ].compact.join(":")
        Thread.current.thread_variable_set(:name, thread_name)

        schedule.block.call(*args)

        schedule_log(:thread, :stopping, schedule, Thread.current)
        Thread.exit
      end
    end

    def run(schedule)
      schedule_log(:thread, :starting, schedule)

      parallel = schedule.parallel
      what     = schedule.what

      servers  = Servers.find(what)

      if parallel
        servers.each do |server|
          next if server.unavailable?
          @@thread_pool << run_thread(schedule, server)
        end
      else
        @@thread_pool << run_thread(schedule, servers)
      end

      #self.metric.update(@@thread_pool.count) unless (self.metric.values.first == @@thread_pool.count)
      self.metric.set(@@thread_pool.count)

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

    def log
      $logger.info { ("=" * 80) }
      @@thread_pool.each do |thread|
        name = (thread.thread_variable_get(:name) || "<starting>")
        $logger.debug { "[THREAD] #{name}: #{thread.status}" }
      end
      $logger.info { ("=" * 80) }
    end

    def display
      puts "\e[H"
      puts "\e[2J"
      @@thread_pool.each do |thread|
        name = (thread.thread_variable_get(:name) || "<starting>")
        puts "[THREAD] #{name}: #{thread.status}"
      end
    end

    def shutdown!
      # disable schedules
      @@thread_schedules = Array.new
      # stop threads
      @@thread_pool.each { |t| t.terminate }
    end

    def threads
      @@thread_pool
    end

    def execute
      loop do
        @@thread_schedules.each do |schedule|
          if schedule.next_run_at <= Time.now.to_f
            run(schedule)
            schedule_next_run(schedule)
            # if schedule.server.nil?
            #    unless Servers.unavailable?
            # else
            #   unless [schedule.server].flatten.map(&:unavailable?).all?(true)
            #     run(schedule)
            #   end
            # end

          end
        end

        @@thread_pool.each do |thread|
          case thread.status
          when "aborting"
            # $logger.debug { ("=" * 80) }
            # $logger.debug { "[THREAD] Thread Aborting: #{thread}" }
            # $logger.debug { ("=" * 80) }
            thread.terminate
            @@thread_pool -= [thread]

          when "sleep"
            # $logger.debug { ("=" * 80) }
            # $logger.debug { "[THREAD] Thread Sleeping: #{thread.thread_variable_get(:name)}" }
            # $logger.debug { ("=" * 80) }
            #sleep SLEEP_TIME
            Thread.pass
            thread.wakeup if thread.status == "sleep"

          when false
            name = thread.thread_variable_get(:name) || "<dead>"
            @@thread_pool -= [thread]
            schedule_log(:thread, :exit, name)
            #self.metric.update(@@thread_pool.count) unless (self.metric.values.first == @@thread_pool.count)
            self.metric.set(@@thread_pool.count)
          end
        end
      end
      sleep SLEEP_TIME
    end
  end

  extend ClassMethods
end
