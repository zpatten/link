require 'prometheus/client'
require 'prometheus/client/push'
require 'prometheus/client/data_stores/direct_file_store'

METRIC_PATH = File.expand_path(File.join(LINK_ROOT, 'metrics'))
begin
  FileUtils.rm_r(METRIC_PATH)
rescue Errno::ENOENT
end

begin
  FileUtils.mkdir_p(METRIC_PATH)
rescue Errno::ENOENT
end

Prometheus::Client.config.data_store = Prometheus::Client::DataStores::DirectFileStore.new(dir: METRIC_PATH)

class Metrics
  module ClassMethods

    @@prometheus ||= Prometheus::Client.registry
    @@metrics ||= Concurrent::Hash.new

    def push
      RescueRetry.attempt do
        Prometheus::Client::Push.new(
          'link',
          'master',
          'http://127.0.0.1:9091'
        ).add(@@prometheus)
      end
    end

    def [](key)
      @@metrics[key]
    end

    def build_options(**options)
      {
        docstring: '...',
        store_settings: {
          aggregation: :max
        },
        labels: [ :name ]
      }.merge!(options)
    end

    def guage(key, **options)
      @@metrics[key] ||= begin
        metric = Prometheus::Client::Gauge.new(key, **build_options(options))
        @@prometheus.register(metric)
        metric
      end
    end

    def histogram(key, **options)
      @@metrics[key] ||= begin
        metric = Prometheus::Client::Histogram.new(key, **build_options(options))
        @@prometheus.register(metric)
        metric
      end
    end

  end

  extend ClassMethods
end

Metrics.guage(:storage_item_count)
Metrics.guage(:storage_delta_count)
Metrics.guage(:electrical_count)
Metrics.guage(:electrical_delta_count)
Metrics.guage(:thread_count)
# Metrics.histogram(:thread_execution)
Metrics.guage(:thread_timing)
Metrics.guage(:server_rtt)