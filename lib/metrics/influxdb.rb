# frozen_string_literal: true

require 'influxdb'

module Metrics
  class InfluxDB

    TIME_PRECISION = 'ns'

################################################################################

    def initialize
      @influxdb = ::InfluxDB::Client.new(PROGRAM_NAME,
        url: 'https://influxdb.tatooine.jovelabs.io',
        time_precision: TIME_PRECISION
      )
    end

################################################################################

    def configure!
      raise "Not Implemented!"
      # Metrics::InfluxDB.write('test', values: { tvalue: 0 }, tags: { test: 'tag' })
    end

################################################################################

    def write(key, **data)
      @influxdb.write_point(key, {
        timestamp: ::InfluxDB.convert_timestamp(Time.now, TIME_PRECISION)
      }.merge!(data))
    end

################################################################################

    module ClassMethods
      @@influxdb ||= Metrics::InfluxDB.new
      @@influxdb_public_methods ||= @@influxdb.public_methods

      def method_missing(method_name, *args, &block)
        if @@influxdb_public_methods.include?(method_name)
          @@influxdb.send(method_name, *args, &block)
        else
          super
        end
      end

      def respond_to?(method_name, include_private=false)
        @@influxdb_public_methods.include?(method_name) || super
      end

      def respond_to_missing?(method_name, include_private=false)
        @@influxdb_public_methods.include?(method_name) || super
      end
    end

    extend ClassMethods

################################################################################

  end
end

