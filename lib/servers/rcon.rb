# frozen_string_literal: true

class Servers
  module RCon

################################################################################

    def rcon_command(task, command, except=[])
      find_by_task(task, except).each do |server|
        unless server.unavailable?
          server.rcon_command(command)
        end
      end

      true
    end

    def rcon_command_nonblock(task, command, except=[])
      find_by_task(task, except).each do |server|
        unless server.unavailable?
          server.rcon_command_nonblock(command)
        end
      end

      true
    end

################################################################################

  end
end
