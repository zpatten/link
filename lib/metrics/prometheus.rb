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


# #<Errno::ECONNREFUSED: Failed to open TCP connection to pushgateway.tatooine.jovelabs.io:443 (Connection refused - connect(2) for "pushgateway.tatooine.jovelabs.io" port 443)>


module Metrics
  class Prometheus

  module ClassMethods

      @@prometheus ||= ::Prometheus::Client.registry
      @@metrics ||= Concurrent::Hash.new

      def push
        ::Prometheus::Client::Push.new(
          job: PROGRAM_NAME,
          gateway: 'http://tatooine.lan:9091',
          grouping_key: { hostname: 'zara' }
            #Socket.gethostname }
       ).replace(@@prometheus)
      end

      def scrub_key(key)
        ["link", key].flatten.compact.join('_').to_sym
      end

      def [](key)
        @@metrics[scrub_key(key)]
      end

      def build_options(options)
        h = {
          docstring: '...',
          store_settings: {
            aggregation: :max
          }
        }.merge!(options)
        LinkLogger.debug { h.ai }
        h
      end

      def guage(key, **options)
        key = scrub_key(key)
        @@metrics[key] ||= begin
          LinkLogger.info(:metrics) { "Creating Gauge #{key.ai}" }
          metric = ::Prometheus::Client::Gauge.new(key, **build_options(options))
          @@prometheus.register(metric)
          metric
        end
      end

      def histogram(key, **options)
        key = scrub_key(key)
        @@metrics[key] ||= begin
          LinkLogger.info(:metrics) { "Creating Histogram #{key.ai}" }
          metric = ::Prometheus::Client::Histogram.new(key, **build_options(options))
          @@prometheus.register(metric)
          metric
        end
      end

      def summary(key, **options)
        key = scrub_key(key)
        @@metrics[key] ||= begin
          LinkLogger.info(:metrics) { "Creating Summary #{key.ai}" }
          metric = ::Prometheus::Client::Summary.new(key, **build_options(options))
          @@prometheus.register(metric)
          metric
        end
      end

    end

    extend ClassMethods

  end
end

################################################################################

Metrics::Prometheus.guage(:storage_items_total,
  docstring: 'Link Storage Items',
  labels: [:item_name, :item_type])

Metrics::Prometheus.histogram(:fulfillment_items_total,
  docstring: 'Link Fulfillment Items',
  labels: [:server, :item_name, :item_type])

Metrics::Prometheus.histogram(:unfulfilled_items_total,
  docstring: 'Link Fulfillment Items',
  labels: [:server, :item_name, :item_type])

Metrics::Prometheus.histogram(:requested_items_total,
  docstring: 'Link Requested Items',
  labels: [:server, :item_name, :item_type])

Metrics::Prometheus.histogram(:overflow_items_total,
  docstring: 'Link Overflow Items',
  labels: [:server, :item_name, :item_type])

Metrics::Prometheus.histogram(:providable_items_total,
  docstring: 'Link Providable Items',
  labels: [:server, :item_name, :item_type])


################################################################################

Metrics::Prometheus.guage(:server_rtt, docstring: 'Factorio Server RTT', labels: [:server])

################################################################################

Metrics::Prometheus.histogram(:thread_duration_seconds,
  docstring: 'Link Thread Timings',
  labels: [:server, :task])

Metrics::Prometheus.guage(:threads,
  docstring: 'Link Threads')

Metrics::Prometheus.guage(:threads_running,
  docstring: 'Link Threads Running')

Metrics::Prometheus.guage(:threads_queue_length,
  docstring: 'Link Threads Queue Length')

################################################################################
