# frozen_string_literal: true

class Logistics

################################################################################

  def initialize(item_requests)
    @item_requests = item_requests
    calculate_item_totals
    calculate_item_ratios
    calculate_fulfillment_items
  end

################################################################################

  def calculate_item_totals
    @item_totals = Hash.new
    @item_requests.each do |unit_number, item_counts|
      @item_totals.merge!(item_counts) { |k,o,n| o + n }
    end
    $logger.debug(:logistics) { "Request Totals: #{@item_totals.ai}" }

    true
  end

################################################################################

  def calculate_item_ratios
    @item_ratios = Hash.new
    @item_totals.each do |item_name, item_count|
      # puts "#{item_name.inspect}=#{item_count.inspect}"
      # item_ratio = Storage[item_name].to_f / item_count.to_f
      item_ratio = if Storage[item_name] >= item_count
        1.0
      elsif Storage[item_name] > 0
        Storage[item_name].to_f / item_count.to_f
      else
        0.0
      end
      @item_ratios[item_name] = item_ratio
    end
    $logger.debug(:logistics) { "Request Ratios: #{@item_ratios.ai}" }

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

  def acquire_item(item_name, item_count)
    Storage.remove(item_name, item_count)
  end

  def calculate_fulfillment_items
    @items_to_fulfill = Hash.new
    if can_fulfill_all?
      @items_to_fulfill = @item_requests
      Storage.bulk_remove(@item_totals)
    else
      @item_requests.each do |unit_number, items|
        items.each do |item_name, item_count|
          if (fulfill_count = count_to_fulfill(item_name, item_count)) > 0
            if (actual_count = Storage.remove(item_name, fulfill_count)) > 0
              @items_to_fulfill[unit_number] ||= Hash.new
              @items_to_fulfill[unit_number][item_name] = actual_count
            end
          end
        end
      end
    end
    Storage.save

    true
  end

################################################################################

  def fulfill(&block)
    $logger.debug(:logistics) { "Fulfillments: #{@items_to_fulfill.ai}" }
    block.call(@items_to_fulfill)

    true
  end

################################################################################

end
