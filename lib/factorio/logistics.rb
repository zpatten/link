# frozen_string_literal: true

module Factorio
  class Logistics

################################################################################

    def initialize(server, item_requests)
      @item_requests = item_requests
      @server        = server

      # LinkLogger.debug(log_tag(:logistics)) { "Requests: #{@item_requests.ai}" }
    end

    def log_tag(task)
      @server.log_tag(task)
    end

################################################################################

    def fulfill
      remove_items_from_storage
      calculate_item_ratios unless can_fulfill_all?
      finalize_fulfillment
      metrics_handler

      LinkLogger.debug(log_tag(:logistics)) { "Fulfillment: #{@items_to_fulfill.ai}" }

      if block_given?
        yield @items_to_fulfill
      else
        @items_to_fulfill
      end
    end

################################################################################

    def remove_items_from_storage
      @requested_item_counts = Hash.new(0)
      @item_requests.each do |unit_number, item_counts|
        @requested_item_counts.merge!(item_counts) { |k,o,n| o + n }
      end

      @removed_item_totals = Factorio::Storage.bulk_remove(@requested_item_counts)

      @can_fulfill_all ||= @requested_item_counts.all? do |k,v|
        @removed_item_totals[k] == v
      end

      LinkLogger.debug(log_tag(:logistics)) { "Request Totals: #{@requested_item_counts.ai}" }

      true
    end

################################################################################

    def calculate_item_ratios
      @item_ratios = Hash.new(0.0)
      @requested_item_counts.each do |item_name, item_count|
        removed_item_count = @removed_item_totals[item_name]
        item_ratio = if removed_item_count >= item_count
          1.0
        elsif removed_item_count > 0
          removed_item_count.to_f / item_count.to_f
        else
          0.0
        end
        @item_ratios[item_name] = item_ratio
      end

      LinkLogger.debug(log_tag(:logistics)) { "Request Ratios: #{@item_ratios.ai}" }

      true
    end

################################################################################

    def can_fulfill_all?
      @can_fulfill_all
    end

    def count_to_fulfill(requested_item_name, requested_item_count)
      count = if @item_ratios[requested_item_name] >= 1.0
        requested_item_count
      elsif @item_ratios[requested_item_name] > 0.0
        (requested_item_count * @item_ratios[requested_item_name]).floor
      else
        0
      end

      if count > 0
        if count > @removed_item_totals[requested_item_name]
          count = @removed_item_totals[requested_item_name]
        end
        @removed_item_totals[requested_item_name] -= count

        @removed_item_totals.delete(requested_item_name) if @removed_item_totals[requested_item_name] == 0
      end

      count
    end

    def finalize_fulfillment
      @items_to_fulfill = Hash.new

      @fulfilled_item_counts   = Hash.new(0)
      @unfulfilled_item_counts = Hash.new(0)

      if can_fulfill_all?
        @items_to_fulfill      = @item_requests
        @fulfilled_item_counts = @requested_item_counts.clone
        @removed_item_totals   = Hash.new(0)
      else
        @item_requests.each do |unit_number, requested_items|
          requested_items.each do |requested_item_name, requested_item_count|
            fulfill_count = count_to_fulfill(requested_item_name, requested_item_count)
            @unfulfilled_item_counts[requested_item_name] += (requested_item_count - fulfill_count)
            next if fulfill_count == 0

            @items_to_fulfill[unit_number] ||= Hash.new(0)
            @items_to_fulfill[unit_number][requested_item_name] = fulfill_count

            @fulfilled_item_counts[requested_item_name] += fulfill_count
          end
        end
        LinkLogger.debug(log_tag(:logistics)) { "Overflow: #{@removed_item_totals.ai}" }
        Factorio::Storage.bulk_add(@removed_item_totals)
      end

      true
    end

    def hash_sort(hash)
      Hash[hash.delete_if { |key,value| value == 0 }.sort_by { |key,value| key }]
    end

    def metrics_handler
      # REQUESTS
      @requested_item_counts.each do |requested_item_name, requested_item_count|
        Metrics::Prometheus[:requested_items_total].observe(requested_item_count,
          labels: { server: @server.name, item_name: requested_item_name, item_type: Factorio::ItemTypes[requested_item_name] })
      end
      @server.metrics[:requested] = @requested_item_counts.clone

      # FULFILLED
      @fulfilled_item_counts.each do |fulfilled_item_name, fulfilled_item_count|
        Metrics::Prometheus[:fulfillment_items_total].observe(fulfilled_item_count,
          labels: { server: @server.name, item_name: fulfilled_item_name, item_type: Factorio::ItemTypes[fulfilled_item_name] })
      end
      @server.metrics[:fulfilled] = @fulfilled_item_counts.clone

      # UNFULFILLED
      @unfulfilled_item_counts.each do |unfulfilled_item_name, unfulfilled_item_count|
        Metrics::Prometheus[:unfulfilled_items_total].observe(unfulfilled_item_count,
          labels: { server: @server.name, item_name: unfulfilled_item_name, item_type: Factorio::ItemTypes[unfulfilled_item_name] })
      end
      @server.metrics[:unfulfilled] = @unfulfilled_item_counts.clone

      # OVERFLOW
      @removed_item_totals.each do |removed_item_name, removed_item_count|
        Metrics::Prometheus[:overflow_items_total].observe(removed_item_count,
          labels: { server: @server.name, item_name: removed_item_name, item_type: Factorio::ItemTypes[removed_item_name] })
      end
      @server.metrics[:overflow] = @removed_item_totals.clone

      true
    end

################################################################################

  end
end
