# frozen_string_literal: true

# Link Factorio Server Chat Mirroring
################################################################################
class Server
  module Chat

    def handle_chat_events(chat_events)
      chat_events.each do |chat_event|
        message = %(#{chat_event["player_name"]}@#{@name}: #{chat_event["message"]})
        command = %(game.print('#{message}', {r = 1, g = 0, b = 1, a = 0.5}))
        LinkLogger.info(log_tag(:chat)) { message.ai }
        Servers.rcon_command_nonblock(:chat, command, except: [@name])
      end
    end

    def start_chat
      Tasks.schedule(what: :chat, pool: @pool, cancellation: @cancellation, server: self) do
        command = %(remote.call('link', 'get_chats'))
        rcon_handler(what: :get_chats, command: command) do |chat_events|
          handle_chat_events(chat_events)
        end
      end
    end

  end
end
