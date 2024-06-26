# frozen_string_literal: true

module Factorio
  class RCon

    module Authentication

      def authenticated?
        @authenticated
      end

      def unauthenticated?
        !authenticated?
      end

      def authenticate
        enqueue_packet(@password, callback: method(:authenticate_callback), type: RCon::PACKET_TYPE_LOGIN)
      end

      def authenticate_callback(host, packet_fields)
        @authenticated = true
        LinkLogger.info(tag) { "Authenticated to #{host_tag.ai}" }
      end

    end

  end
end
