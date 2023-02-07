# frozen_string_literal: true

class Servers
  module Actions

################################################################################

    def start!(container: false)
      LinkLogger.info(:servers) { "Start Servers (container: #{container.ai})" }
      each { |server| Runner.pool.post { server.start!(container: container) }; sleep 3 }
    end

    def stop!(container: false)
      LinkLogger.warn(:servers) { "Stopping Servers (container: #{container.ai})" }
      each { |server| Runner.pool.post { server.stop!(container: container) } }
    end

    def restart!(container: false)
      LinkLogger.warn(:servers) { "Restart Servers (container: #{container.ai})" }
      each { |server| Runner.pool.post { server.restart!(container: container) } }
    end

################################################################################

  end
end
