# frozen_string_literal: true

class Server
  class RCon

    module Authentication

      def authenticated?
        @authenticated
      end

      def unauthenticated?
        !authenticated?
      end

      def authenticate
        enqueue_packet(@password, method(:authenticate_callback), nil, nil, RCon::PACKET_TYPE_LOGIN)
      end

      def authenticate_callback(host, packet_fields, data)
        @authenticated = true
        $logger.info(:rcon) { "[#{self.id}] Authenticated to #{host_tag}" }
      end

    end

  end
end
