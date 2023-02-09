# frozen_string_literal: true

require_relative 'task/chat'
require_relative 'task/fulfillments'
require_relative 'task/gui'
require_relative 'task/id'
require_relative 'task/name'
require_relative 'task/ping'
require_relative 'task/providables'
require_relative 'task/research'
require_relative 'task/save'
require_relative 'task/signals'

class Server
  module Task

################################################################################

    include Server::Task::Chat
    include Server::Task::Fulfillments
    include Server::Task::GUI
    include Server::Task::ID
    include Server::Task::Name
    include Server::Task::Ping
    include Server::Task::Providables
    include Server::Task::Research
    include Server::Task::Save
    include Server::Task::Signals

################################################################################

    def start_tasks!
      return false if @origin.resolved?

      schedule_task_id
      schedule_task_name
      schedule_task_ping
      schedule_task_gui

      schedule_task_fulfillments
      schedule_task_providables
      schedule_task_signals

      schedule_task_chat
      schedule_task_research
      schedule_task_research_current

      schedule_task_save

      true
    end

    def stop_tasks!
      return false if @origin.resolved?

      @origin and (@origin.resolved? or @origin.resolve)
      sleep (Config.value(:timeout, :thread) + 1)

      true
    end

################################################################################

  end
end
