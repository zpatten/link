# frozen_string_literal: true

# Link Factorio Server Chat Mirroring
################################################################################
class Server
  module Chat

    def schedule_chat
      ThreadPool.schedule_task(:chat, server: self) do
        command = %(/#{rcon_executor} remote.call('link', 'get_chats'))
        payload = self.rcon_command(command: command)
        unless payload.nil? || payload.empty?
          chat_events = JSON.parse(payload)
          unless chat_events.nil? || chat_events.empty?
            chat_events.each do |chat_event|
              message = %(#{chat_event["player_name"]}@#{self.name}: #{chat_event["message"]})
              command = %(/#{rcon_executor} game.print('#{message}', {r = 1, g = 0, b = 1, a = 0.5}))
              self.method_proxy(
                :Servers,
                :rcon_command_nonblock,
                what: :chat,
                except: [self.name],
                command: command
              )
            end
          end
        end
      end
    end

  end
end
