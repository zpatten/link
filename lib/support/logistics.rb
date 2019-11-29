# frozen_string_literal: true

class Logistics

################################################################################

  def initialize(server, item_requests)
    @item_requests = item_requests
    @server        = server

    $logger.debug(:logistics) {
      "[#{@server.name}] Requests: #{@item_requests.ai}"
    }

  end

################################################################################

  def calculate_item_totals
    @item_totals = Hash.new(0)
    @item_requests.each do |unit_number, item_counts|
      @item_totals.merge!(item_counts) { |k,o,n| o + n }
    end

    $logger.debug(:logistics) {
      "[#{@server.name}] Request Totals: #{@item_totals.ai}"
    }

    true
  end

################################################################################

  def calculate_item_ratios
    @item_ratios = Hash.new(0.0)
    storage_clone = @server.method_proxy.Storage(:select, @item_totals.keys)
    @item_totals.each do |item_name, item_count|
      storage_count = storage_clone[item_name]
      item_ratio = if storage_count >= item_count
        1.0
      elsif storage_count > 0
        storage_count.to_f / item_count.to_f
      else
        0.0
      end
      @item_ratios[item_name] = item_ratio
    end

    $logger.debug(:logistics) {
      "[#{@server.name}] Request Ratios: #{@item_ratios.ai}"
    }

    true
  end

################################################################################

  def can_fulfill_all?
    @item_ratios.all? { |item_name, item_ratio| item_ratio >= 1.0 }
  end

  def count_to_fulfill(item_name, item_count)
    if @item_ratios[item_name] >= 1.0
      item_count
    elsif @item_ratios[item_name] > 0.0
      (item_count * @item_ratios[item_name]).floor
    else
      0
    end
  end

  def calculate_fulfillment_items
    item_fulfillment_totals = Hash.new(0)
    @items_to_fulfill = Hash.new

    if can_fulfill_all?
      @items_to_fulfill = @item_requests
      item_fulfillment_totals = @item_totals
    else
      @item_requests.each do |unit_number, items|
        items.each do |item_name, item_count|
          fulfill_count = count_to_fulfill(item_name, item_count)
          next if fulfill_count == 0

          item_fulfillment_totals[item_name] += fulfill_count

          @items_to_fulfill[unit_number] ||= Hash.new(0)
          @items_to_fulfill[unit_number][item_name] = fulfill_count
        end
      end
    end

    unless item_fulfillment_totals.empty?
      @server.method_proxy.Storage(:bulk_remove, item_fulfillment_totals)
    end

    true
  end

################################################################################

  def fulfill
    calculate_item_totals
    calculate_item_ratios
    calculate_fulfillment_items

    $logger.debug(:logistics) {
      "[#{@server.name}] Fulfillments: #{@items_to_fulfill.ai}"
    }

    if block_given?
      yield @items_to_fulfill
    else
      @items_to_fulfill
    end
  end

################################################################################

end
