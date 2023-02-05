# frozen_string_literal: true

class Server
  module Pool

################################################################################

    def start_pool!
      return false if pool_running?

      LinkLogger.info(log_tag(:pool)) { "Starting Thread Pool" }
      @pool = THREAD_EXECUTOR.new(
        name: @name.downcase,
        auto_terminate: false,
        min_threads: 2,
        max_threads: [2, Concurrent.processor_count].max,
        max_queue: [2, Concurrent.processor_count * 5].max,
        fallback_policy: :abort
      )
      @cancellation, @origin = Concurrent::Cancellation.new
      @cancellation = @cancellation.join(Runner.cancellation)

      true
    end

    def stop_pool!
      return false if pool_shutdown?

      LinkLogger.info(log_tag(:pool)) { "Thread Pool Shutting Down" }
      @pool.shutdown
      LinkLogger.info(log_tag(:pool)) { "Waiting for Thread Pool Termination" }
      @pool.wait_for_termination(Config.value(:timeout, :pool))
      LinkLogger.info(log_tag(:pool)) { "Thread Pool Shutdown Complete" }

      true
    end

################################################################################

    def pool_running?
      @pool && @pool.running?
    end

    def pool_shutdown?
      @pool && @pool.shutdown?
    end

################################################################################

  end
end
