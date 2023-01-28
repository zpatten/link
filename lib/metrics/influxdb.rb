# frozen_string_literal: true
require 'influxdb'

module Metrics
  class InfluxDB

    module ClassMethods

      TIME_PRECISION = 'ns'

      @@influxdb ||= ::InfluxDB::Client.new('link',
        url: 'https://influxdb.tatooine.jovelabs.io',
        time_precision: TIME_PRECISION
      )

      def write(key, **data)
        @@influxdb.write_point(key, {
          timestamp: ::InfluxDB.convert_timestamp(Time.now, TIME_PRECISION)
        }.merge!(data))
      end

    end

    extend ClassMethods

  end
end

# Metrics::InfluxDB.write('test', values: { tvalue: 0 }, tags: { test: 'tag' })
