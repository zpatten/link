# frozen_string_literal: true

require 'concurrent-edge'

module Factorio
  class Credentials

################################################################################

    def initialize
      @credentials = (JSON.parse(IO.read(filename).strip) rescue Hash.new)

      LinkLogger.info(:credentials) { "Loaded Credentials: #{filename.ai}" }
      LinkLogger.debug(:credentials) { @credentials.ai }
    end

################################################################################

    def filename
      File.expand_path(File.join(LINK_ROOT, 'credentials.json'))
    end

    def save
      IO.write(filename, JSON.pretty_generate(to_h.sort.to_h)+"\n")
      LinkLogger.info(:credentials) { "Saved Credentials: #{filename.ai}" }

      true
    end

    def to_h
      @credentials
    end

################################################################################

    def username
      @credentials['username']
    end

    def username=(value)
      @credentials['username'] = value
    end

################################################################################

    def password
      @credentials['password']
    end

    def password=(value)
      @credentials['password'] = value
    end

################################################################################

    def token
      LinkLogger.info(:credentials) { "Acquiring Factorio web authentication token" }
      @token ||= begin
        LinkLogger.info(:credentials) { "Requesting Factorio web authentication token" }

        body = {
          username: username,
          password: password
        }

        headers = {
          'Content-Type' => 'application/x-www-form-urlencoded',
          'Accept' => 'application/json'
        }

        response = HTTParty.post(Config.factorio_auth_url, body: body, headers: headers)
        parsed_response = response.parsed_response

        if parsed_response.nil? || parsed_response.count < 1
          LinkLogger.warn(:credentials) { "Failed to get Factorio web authentication token!" }
          nil
        else
          parsed_response.first
        end
      end
    end

################################################################################

    module ClassMethods
      @@credentials ||= Factorio::Credentials.new

      def method_missing(method_name, *args, **options, &block)
        @@credentials.send(method_name, *args, &block)
      end
    end

    extend ClassMethods

################################################################################

  end
end
