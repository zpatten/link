# frozen_string_literal: true

class Server
  module RCon

################################################################################

    def start_rcon!
      sleep 1 until container_alive?

      @pinged_at = Time.now.to_f

      @rcon = Factorio::RConPool.new(server: self)
      @rcon.start!

      true
    end

    def stop_rcon!
      @rcon and @rcon.stop!

      @pinged_at = 0
      @rtt       = 0

      true
    end

################################################################################

  end
end
