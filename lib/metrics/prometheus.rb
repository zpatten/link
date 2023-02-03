require 'prometheus/client'
require 'prometheus/client/push'
require 'prometheus/client/data_stores/direct_file_store'

# #<Errno::ECONNREFUSED: Failed to open TCP connection to pushgateway.tatooine.jovelabs.io:443 (Connection refused - connect(2) for "pushgateway.tatooine.jovelabs.io" port 443)>


module Metrics
  class Prometheus

    METRIC_PATH = File.expand_path(File.join(LINK_ROOT, 'metrics'))

################################################################################

    def initialize
      ::Prometheus::Client.config.data_store = ::Prometheus::Client::DataStores::DirectFileStore.new(dir: METRIC_PATH)

      begin
        FileUtils.rm_r(METRIC_PATH)
      rescue Errno::ENOENT
      end

      begin
        FileUtils.mkdir_p(METRIC_PATH)
      rescue Errno::ENOENT
      end

      @prometheus = ::Prometheus::Client.registry
      @metrics    = Concurrent::Map.new
    end

################################################################################

    def push
      ::Prometheus::Client::Push.new(
        job: PROGRAM_NAME,
        gateway: 'http://tatooine.lan:9091',
        grouping_key: { hostname: 'zara' }
          #Socket.gethostname }
     ).replace(@prometheus)
    end

    def scrub_key(key)
      ["link", key].flatten.compact.join('_').to_sym
    end

    def [](key)
      @metrics[scrub_key(key)]
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
      @metrics[key] ||= begin
        LinkLogger.info(:metrics) { "Creating Gauge #{key.ai}" }
        metric = ::Prometheus::Client::Gauge.new(key, **build_options(options))
        @prometheus.register(metric)
        metric
      end
    end

    def histogram(key, **options)
      key = scrub_key(key)
      @metrics[key] ||= begin
        LinkLogger.info(:metrics) { "Creating Histogram #{key.ai}" }
        metric = ::Prometheus::Client::Histogram.new(key, **build_options(options))
        @prometheus.register(metric)
        metric
      end
    end

    def summary(key, **options)
      key = scrub_key(key)
      @metrics[key] ||= begin
        LinkLogger.info(:metrics) { "Creating Summary #{key.ai}" }
        metric = ::Prometheus::Client::Summary.new(key, **build_options(options))
        @prometheus.register(metric)
        metric
      end
    end

################################################################################

    module ClassMethods
      @@prometheus ||= Metrics::Prometheus.new

      def method_missing(method_name, *args, &block)
        @@prometheus.send(method_name, *args, &block)
      end
    end

    extend ClassMethods

################################################################################

  end
end


