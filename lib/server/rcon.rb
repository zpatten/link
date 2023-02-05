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

    def rcon_command_nonblock(command)
      return false if unavailable?

      @rcon.command_nonblock(command)

      true
    end

    def rcon_command(command)
      return nil if unavailable?

      @rcon.command(command)
    end

################################################################################

    def rcon_handler(what:, command:, &block)
      payload = self.rcon_command(command)
      unless payload.nil? || payload.empty?
        data = JSON.parse(payload)
        unless data.nil? || data.empty?
          block.call(data)
        # else
        #   LinkLogger.warn(log_tag(:rcon)) { "Missing Payload Data! #{command.ai}" }
        end
      else
        LinkLogger.warn(log_tag(:rcon, what)) { "Missing Payload!" }
      end
    end

################################################################################

  end
end
