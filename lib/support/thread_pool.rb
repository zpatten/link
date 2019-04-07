class ThreadPool

  module ClassMethods

    @@thread_pool = Array.new
    @@thread_pool_mutex = Mutex.new

    @@thread_schedules = Array.new

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

    def thread(name, &block)
      schedule_log(:thread, :starting, name)

      @@thread_pool << Thread.new do
        Thread.current.thread_variable_set(:name, name)
        block.call
        schedule_log(:thread, :stopped, name)
        Thread.exit
      end
    end

    def register(what, frequency=nil, server=nil, &block)
      schedule = OpenStruct.new(
        what: what,
        frequency: frequency,
        server: server,
        block: block,
        next_run_at: (Time.now.to_f)
      )
      @@thread_schedules << schedule
      schedule_log(:schedule, :added, schedule)
      # pp @@thread_schedules
    end

    def run(schedule)
      schedule_log(:thread, :starting, schedule)

      server = schedule.server
      block  = schedule.block
      args   = [server].compact

      @@thread_pool << Thread.new do
        Thread.current.thread_variable_set(:name, schedule.what)
        block.call(*args)
        schedule_log(:thread, :stopped, schedule)
        Thread.exit
      end

      true
    end

    def schedule_log(action, who, schedule)
      unless schedule.is_a?(String)
        who = who.to_s.capitalize
        action = action.to_s.downcase
        what = schedule.what.to_s.downcase
        next_run_at = schedule.next_run_at
        frequency = schedule.frequency
        server = schedule.server
        block = schedule.block

        id = "server:#{[server].map(&:id).join(",")}" unless server.nil?
        log_fields = [
          "next_run_at:#{next_run_at}",
          "frequency:#{frequency}",
          id,
          "block:#{block}"
        ].compact.join(", ")
        $logger.debug { "[THREAD] #{who} #{action} #{what}: #{log_fields}" }
      else
        $logger.debug { "[THREAD] #{who} #{action} #{schedule.to_s.downcase}" }
      end
    end

    def schedule_next_run(schedule)
      now         = Time.now.to_f
      frequency   = schedule.frequency
      next_run_at = (now + (frequency - (now % frequency)))
      schedule.next_run_at = next_run_at
    end

    def log
      $logger.info { ("=" * 80) }
      @@thread_pool.each do |thread|
        name = (thread.thread_variable_get(:name) || "starting")
        $logger.debug { "[THREAD] #{name}: #{thread.status}" }
      end
      $logger.info { ("=" * 80) }
    end

    def execute
      loop do
        # synchronize do
          @@thread_schedules.each do |schedule|
            if schedule.next_run_at <= Time.now.to_f
              if schedule.server.nil?
                run(schedule) unless Servers.unavailable?
              else
                unless [schedule.server].flatten.map(&:unavailable?).all?(true)
                  run(schedule)
                end
              end

              schedule_next_run(schedule)

              server = schedule.server
              id = "server:#{[server].map(&:id).join(",")}" unless server.nil?
              thread_log_message_fields = [
                "next_run_at:#{schedule.next_run_at}",
                "frequency:#{schedule.frequency}",
                id
              ].compact.join(", ")
              schedule_log(:thread, :scheduled, schedule)
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
              @@thread_pool -= [thread]
            end
          end
        end
        sleep SLEEP_TIME
      # end
    end
  end

  extend ClassMethods
end
