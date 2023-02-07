# frozen_string_literal: true

require 'prometheus/client'
require 'prometheus/client/push'
require 'prometheus/client/data_stores/direct_file_store'

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

    def configure!
      guage(:storage_items_total,
        docstring: 'Link Storage Items',
        labels: [:item_name, :item_type])

      histogram(:fulfillment_items_total,
        docstring: 'Link Fulfillment Items',
        labels: [:server, :item_name, :item_type])

      histogram(:unfulfilled_items_total,
        docstring: 'Link Fulfillment Items',
        labels: [:server, :item_name, :item_type])

      histogram(:requested_items_total,
        docstring: 'Link Requested Items',
        labels: [:server, :item_name, :item_type])

      histogram(:overflow_items_total,
        docstring: 'Link Overflow Items',
        labels: [:server, :item_name, :item_type])

      histogram(:providable_items_total,
        docstring: 'Link Providable Items',
        labels: [:server, :item_name, :item_type])

      guage(:server_rtt,
        docstring: 'Factorio Server RTT',
        labels: [:server])

      histogram(:thread_duration_seconds,
        docstring: 'Link Thread Timings',
        labels: [:server, :task])

      guage(:threads,
        docstring: 'Link Threads')

      guage(:threads_running,
        docstring: 'Link Threads Running')

      guage(:threads_queue_length,
        docstring: 'Link Threads Queue Length')
    end

################################################################################

    def push
      ::Prometheus::Client::Push.new(
        job: PROGRAM_NAME,
        gateway: 'http://tatooine.lan:9091',
        grouping_key: { hostname: 'zara' }
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

################################################################################

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
      @@prometheus_public_methods ||= @@prometheus.public_methods

      def method_missing(method_name, *args, &block)
        if @@prometheus_public_methods.include?(method_name)
          @@prometheus.send(method_name, *args, &block)
        else
          super
        end
      end

      def respond_to?(method_name, include_private=false)
        @@prometheus_public_methods.include?(method_name) || super
      end

      def respond_to_missing?(method_name, include_private=false)
        @@prometheus_public_methods.include?(method_name) || super
      end
    end

    extend ClassMethods

################################################################################

  end
end


