# frozen_string_literal: true

class Server
  module Actions

################################################################################

    def start!(container: true)
      LinkLogger.info(log_tag) { "Start Server (container: #{container.ai})" }

      if container
        start_container!
        sleep 1 while container_dead?
      end
      start_pool!
      sleep 0.25 while !pool_running? && container_alive?
      start_rcon!
      sleep 0.25 while unauthenticated? && container_alive?
      start_tasks!
      sleep 0.25 while unavailable? && container_alive?
      @watch = true

      true
    end

    def stop!(container: true)
      LinkLogger.info(log_tag) { "Stop Server (container: #{container.ai})" }

      @watch = false
      stop_tasks!
      stop_rcon!
      stop_pool!
      if container
        stop_container!
        sleep 1 while container_alive?
      end

      true
    end

    def restart!(container: true)
      LinkLogger.info(log_tag) { "Restart Server (container: #{container.ai})" }

      stop!(container: container)
      sleep 3
      start!(container: container)

      true
    end

################################################################################

  end
end


