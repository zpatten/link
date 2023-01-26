# frozen_string_literal: true

# Link Factorio Server Chat Mirroring
################################################################################
class Server
  module Chat

    def handle_chat_events(chat_events)
      chat_events.each do |chat_event|
        message = %(#{chat_event["player_name"]}@#{self.name}: #{chat_event["message"]})
        command = %(game.print('#{message}', {r = 1, g = 0, b = 1, a = 0.5}))
        Servers.rcon_command_nonblock(:chat, command, except: [self.name])
      end
    end

    def start_thread_chat
      # ThreadPool.schedule_server(:chat, server: self) do
      Tasks.schedule(:chat, pool: @pool, cancellation: @cancellation, server: self) do
        command = %(remote.call('link', 'get_chats'))
        payload = self.rcon_command(command)
        unless payload.nil? || payload.empty?
          chat_events = JSON.parse(payload)
          unless chat_events.nil? || chat_events.empty?
            handle_chat_events(chat_events)
          end
        end
      end
    end

  end
end
