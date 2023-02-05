# frozen_string_literal: true

class Server
  module Tasks

################################################################################

    def start_tasks!
      return false if @origin.resolved?

      schedule_task_ping
      schedule_task_id
      schedule_task_research_current
      schedule_task_research
      schedule_task_chat
      schedule_task_fulfillments
      schedule_task_providables
      schedule_task_server_list
      schedule_task_signals
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
