# frozen_string_literal: true

class Logistics

################################################################################

  def initialize(server, item_requests)
    @item_requests = item_requests
    @server        = server

    # $logger.debug(@server.name) { "[LOGISTICS] Requests: #{@item_requests.ai}" }

  end

################################################################################

  def calculate_item_totals
    @item_totals = Hash.new(0)
    @item_requests.each do |unit_number, item_counts|
      @item_totals.merge!(item_counts) { |k,o,n| o + n }
    end

    removed_items = Storage.bulk_remove(@item_totals)
    @removed_item_totals = removed_items

    @obtained_all_requested_items ||= @item_totals.all? do |k,v|
      @removed_item_totals[k] == v
    end

    $logger.debug(@server.name) { "[LOGISTICS] Request Totals: #{@item_totals.ai}" }

    true
  end

################################################################################

  def calculate_item_ratios
    @item_ratios = Hash.new(0.0)
    @item_totals.each do |item_name, item_count|
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

    $logger.debug(@server.name) { "[LOGISTICS] Request Ratios: #{@item_ratios.ai}" }

    true
  end

################################################################################

  def can_fulfill_all?
    @can_fulfill_all ||= (@item_ratios.all? { |item_name, item_ratio| item_ratio >= 1.0 } && @obtained_all_requested_items)
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

  def calculate_fulfillment_items
    @items_to_fulfill = Hash.new

    if can_fulfill_all?
      @items_to_fulfill = @item_requests
      item_fulfillment_totals = @item_totals
    else
      @item_requests.each do |unit_number, requested_items|
        requested_items.each do |requested_item_name, requested_item_count|
          fulfill_count = count_to_fulfill(requested_item_name, requested_item_count)
          next if fulfill_count == 0

          @items_to_fulfill[unit_number] ||= Hash.new(0)
          @items_to_fulfill[unit_number][requested_item_name] = fulfill_count
        end
      end

    end

    true
  end

  def metrics_handler
    @item_totals.each do |requested_item_name, requested_item_count|
      Metrics::Prometheus[:requested_items_total].observe(requested_item_count,
        labels: { server: @server.name, item_name: requested_item_name, item_type: ItemTypes[requested_item_name] })
    end

    unfulfilled_item_counts = Hash.new
    @items_to_fulfill.each do |unit_number, fulfilled_items|
      fulfilled_items.each do |fulfilled_item_name, fulfilled_item_count|
        unfulfilled_item_counts[fulfilled_item_name] ||= @item_totals[fulfilled_item_name]
        Metrics::Prometheus[:fulfillment_items_total].observe(fulfilled_item_count,
          labels: { server: @server.name, item_name: fulfilled_item_name, item_type: ItemTypes[fulfilled_item_name] })
        unfulfilled_item_counts[fulfilled_item_name] -= fulfilled_item_count
      end
    end

    unless can_fulfill_all?
      unfulfilled_item_counts.each do |unfulfilled_item_name, unfulfilled_item_count|
        Metrics::Prometheus[:unfulfilled_items_total].observe(unfulfilled_item_count,
          labels: { server: @server.name, item_name: unfulfilled_item_name, item_type: ItemTypes[unfulfilled_item_name] })
      end
    end

    if !can_fulfill_all? && @removed_item_totals.values.any? { |v| v > 0 }
      Storage.bulk_add(@removed_item_totals)

      $logger.debug(@server.name) { "[LOGISTICS] Overflow Items: #{@removed_item_totals.ai}" }

      @removed_item_totals.each do |item_name, item_count|
        Metrics::Prometheus[:overflow_items_total].observe(item_count,
          labels: { server: @server.name, item_name: item_name, item_type: ItemTypes[item_name] })
      end
    end

    true
  end

################################################################################

  def fulfill
    calculate_item_totals
    calculate_item_ratios
    calculate_fulfillment_items
    metrics_handler

    # $logger.debug(@server.name) { "[LOGISTICS] Fulfillments: #{@items_to_fulfill.ai}" }

    if block_given?
      yield @items_to_fulfill
    else
      @items_to_fulfill
    end
  end

################################################################################

end
