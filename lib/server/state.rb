# frozen_string_literal: true

class Server
  module State

################################################################################

    def unresponsive?
      timedout = (@timeouts.nil? ? false : (@timeouts >= 30))
      noping   = ((@pinged_at + @ping_timeout) < Time.now.to_f)

      (timedout || noping)
    end

    def responsive?
      !unresponsive?
    end

################################################################################

    def connected?
      (@rcon && @rcon.connected?)
    end

    def disconnected?
      !connected?
    end

################################################################################

    def authenticated?
      (@rcon && @rcon.authenticated?)
    end

    def unauthenticated?
      !authenticated?
    end

################################################################################

    def available?
      (@rcon && @rcon.available?)
    end

    def unavailable?
      !available?
    end

################################################################################

  end
end
