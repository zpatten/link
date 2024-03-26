# frozen_string_literal: true

module Factorio
  class RConPool

################################################################################

    SEND_TO_ALL_CONNECTIONS = %i( start! stop! connected? disconnected? authenticated? unauthenticated? available? unavailable? )

    def initialize(pool_size: Config.value(:rcon, :pool_size), server:)
      @server          = server
      @all_connections = Concurrent::Array.new

      pool_size.times { @all_connections << Factorio::RCon.new(server: @server) }
      @available_connections = @all_connections.dup
    end

    def method_missing(method_name, *args, **options, &block)
      if SEND_TO_ALL_CONNECTIONS.include?(method_name)
        @all_connections.all? { |connection| connection.send(method_name) }
      else
        Thread.pass while (connection = @available_connections.shift).nil?
        results = connection.send(method_name, *args, &block)
        @available_connections.push(connection)
        results
      end
    end

################################################################################

  end
end
