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

      def method_missing(method_name, *args, &block)
        @@influxdb.send(method_name, *args, &block)
      end
    end

    extend ClassMethods

################################################################################

  end
end

