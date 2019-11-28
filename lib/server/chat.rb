# frozen_string_literal: true

# Link Factorio Server Chat Mirroring
################################################################################
class Server
  module Chat

    def handle_chat_events(chat_events)
      chat_events.each do |chat_event|
        message = %(#{chat_event["player_name"]}@#{self.name}: #{chat_event["message"]})
        command = %(game.print('#{message}', {r = 1, g = 0, b = 1, a = 0.5}))
        self.method_proxy.Servers(
          :rcon_command_nonblock,
          what: :chat,
          except: [self.name],
          command: command
        )
      end
    end

    def schedule_chat
      ThreadPool.schedule_server(:chat, server: self) do
        command = %(remote.call('link', 'get_chats'))
        payload = self.rcon_command(command: command)
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
