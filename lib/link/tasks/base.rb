# frozen_string_literal: true

module Link
  class Tasks
    class Base

################################################################################

      class_attribute :cancellation, :origin, :future, :what,
        instance_accessor: false,
        instance_predicate: false

################################################################################

      module ClassMethods

        def start!
          self.what = self.to_s.split('::').last.underscore
          unless self.future.nil?
            raise "Task #{tag} Already Started!"
          end
          logger.debug { "Task Scheduled: #{tag}" }

          self.cancellation, self.origin = Concurrent::Cancellation.new

          self.cancellation.origin.chain do
            logger.fatal { "Task Cancelled: #{tag}" }
          end

          self.future = Concurrent::Promises.future(
            interval,
            self.cancellation,
            method(:task_runner),
            &method(:task_scheduler)
          ).run
        end

        def stop!
          logger.debug { "Task Descheduled: #{tag}" }
          self.origin.resolve
        end

      private

        def interval
          Link::Data::Config['master']['scheduler'][tag]
        end

        def task_scheduler(interval, cancellation, task)
          cancellation.check!

          Concurrent::Promises.schedule(
            interval,
            cancellation,
            &task
          ).rescue(
            &method(:task_rescue)
          ).chain {
            task_scheduler(interval, cancellation, task)
          }
        end

        def task_rescue(e)
          logger.fatal { "Task: #{tag} Exception: #{e.inspect}" }
          e.backtrace.each do |line|
            logger.fatal { line }
          end
        end

        def task_runner(cancellation)
          cancellation.check!

          result = nil
          logger.debug { "Task Started: #{tag}" }
          runtime = task_instrumentation do
            task_timeout do
              result = task
            end
          end
          logger.debug { "Task Stopped: #{tag}[#{runtime.round(3)}s]: #{result.inspect}" }
          result
        end

        def task_timeout(&block)
          Timeout.timeout(interval, &block)
        end

        def task_instrumentation(&block)
          elapsed_time = Benchmark.realtime(&block)
          Link::Support::Metrics[:thread_timing].set(
            elapsed_time,
            labels: { name: tag }
          )
          elapsed_time
        end

        def tag
          self.what.to_s
        end

      end
      extend ClassMethods

################################################################################

    end
  end
end
