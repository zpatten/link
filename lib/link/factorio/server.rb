# frozen_string_literal: true

module Link
  module Factorio
    class Server

################################################################################

      attr_reader :client_password
      attr_reader :client_port
      attr_reader :details
      attr_reader :factorio_port
      attr_reader :host
      attr_reader :name
      attr_reader :research
      attr_reader :child_pid
      attr_reader :id
      attr_reader :network_id
      attr_reader :pinged_at

      attr_reader :method_proxy
      attr_reader :rcon

      RECV_MAX_LEN = 64 * 1024

################################################################################

      def initialize(name, details)
        @name                = name.dup
        @id                  = Zlib::crc32(@name.to_s)
        @network_id          = [@id].pack("L").unpack("l").first
        @pinged_at           = 0

        @details             = details
        @active              = details['active']
        @chats               = details['chats']
        @client_password     = details['client_password']
        @client_port         = details['client_port']
        @command_whitelist   = details['command_whitelist']
        @commands            = details['commands']
        @factorio_port       = details['factorio_port']
        @host                = details['host']
        @research            = details['research']

        @rx_signals_initalized = false
        @tx_signals_initalized = false

        @parent_pid          = Process.pid
      end

################################################################################

      def host_tag
        "#{@name}@#{@host}:#{@client_port}"
      end

################################################################################

    end
  end
end
