# frozen_string_literal: true

module Link
  class Tasks
    class Base

################################################################################

      module ClassMethods
        @@result = nil
        @@what   = nil

        def start
          @@what = self.to_s.split('::').last.underscore
          unless @@result.nil?
            raise "Task #{@@what.inspect} Already Started!"
          end
          logger.debug { "Starting Task: #{@@what.inspect}" }

          @@cancellation, @@origin = Concurrent::Cancellation.new

          @@result = Concurrent::Promises.future_on(
            THREAD_POOL,
            interval,
            @@cancellation,
            method(:task_runner),
            &method(:task_scheduler)
          ).run
        end

        def stop
          logger.debug { "Stopping Task: #{@@what.inspect}" }
          @@origin.resolve
        end

      private

        def interval
          Link::Data::Config['master']['scheduler'][@@what.to_s]
        end

        def task_scheduler(interval, cancellation, task)
          cancellation.check!

          Concurrent::Promises.schedule_on(
            THREAD_POOL,
            interval,
            cancellation,
            &task
          ).rescue_on(
            THREAD_POOL,
            &method(:task_rescue)
          ).chain_on(
            THREAD_POOL
          ) {
            task_scheduler(interval, cancellation, task)
          }
        end

        def task_rescue(e)
          logger.fatal { "#{@@what} Exception: #{e.inspect}" }
          e.backtrace.each do |line|
            logger.fatal { line }
          end
        end

        def task_runner(cancellation)
          cancellation.check!

          result = nil
          logger.debug { "--- #{@@what}" }
          runtime = Benchmark.realtime do
            result = Timeout.timeout(interval) do
              task
            end
          end
          logger.debug { "--- #{@@what}[#{runtime.round(3)}s]: #{result.inspect}" }
          result
        end

      end

      extend ClassMethods

################################################################################

    end
  end
end
