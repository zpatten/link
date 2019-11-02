# frozen_string_literal: true

class Requests

  module ClassMethods

    def reset
      @@requests = Hash.new

      @@count_fractionals = nil

      MemoryCache.delete("requests-can-fulfill-all")
      MemoryCache.delete("requests-fulfillments")
      MemoryCache.delete("requests-item-ratios")
      MemoryCache.delete("requests-can-fulfill-none")
      MemoryCache.delete("requests-item-totals")
      MemoryCache.delete("requests-unfulfilled")
    end

    def add(host, requests)
      @@requests.nil? and reset

      @@requests[host] = {
        fulfilled: false,
        requests: requests,
        created_at: Time.now.utc
      }
    end

    def mark_as_fulfilled(host)
      @@requests.nil? and reset

      unless @@requests[host].nil?
        @@requests[host][:fulfilled] = true

        true
      else
        false
      end
    end

    def requests
      @@requests
    end

    def unfulfilled
      return Hash.new if self.requests.nil?

      MemoryCache.fetch("requests-unfulfilled") do
        r = self.requests.select do |host, data|
          !data[:fulfilled]
        end
        r.reduce(Hash.new) do |hash, (host, data)|
          hash[host] = data[:requests]
          hash
        end
      end
    end

    def item_totals
      return Hash.new if self.requests.nil?

      MemoryCache.fetch("requests-item-totals") do
        item_totals = Hash.new
        self.unfulfilled.each do |host,requests|
          requests.each { |unit_number,item_counts| item_totals.merge!(item_counts) { |k,o,n| o + n } }
        end
        item_totals
      end
    end

    def item_ratios
      return Hash.new if self.requests.nil?

      MemoryCache.fetch("requests-item-ratios") do
        item_ratios = Hash.new
        self.item_totals.each do |item_name,item_count|
          item_ratio = if Storage.count(item_name) >= item_count
            1.0
          else
            (Storage.count(item_name).to_f / item_count.to_f)
          end
          item_ratios[item_name] = item_ratio
        end
        $logger.debug(:logistics) { "Item Ratios: #{item_ratios.ai}" }
        item_ratios
      end
    end

    def can_fulfill_all?(item_name=nil)
      if item_name.nil?
        MemoryCache.fetch("requests-can-fulfill-all") do
          self.item_ratios.values.all? { |v| v.to_f >= 1.0 }
        end
      else
        (self.item_ratios[item_name].to_f >= 1.0)
      end
    end

    def can_fulfill_none?(item_name=nil)
      if item_name.nil?
        MemoryCache.fetch("requests-can-fulfill-none") do
          self.item_ratios.values.all? { |v| v.to_f == 0.0 }
        end
      else
        (self.item_ratios[item_name].to_f == 0.0)
      end
    end

    def count_to_fulfill(item_name, item_count)
      if self.can_fulfill_all?(item_name)
        item_count
      else
        @@count_fractionals ||= Hash.new(0.0)
        count = (item_count.to_f * self.item_ratios[item_name].to_f)
        fractional = count % 1.0
        count = count.floor.to_i
        @@count_fractionals[item_name] += fractional
        if ((@@count_fractionals[item_name] >= 1.0) && (count < item_count))
          @@count_fractionals[item_name] -= 1.0
          count += 1
        end
        count
      end
    end

    def fulfillments_totals
      MemoryCache.read("requests-fulfillment-totals")
    end

    def fulfillments
      return Hash.new if self.requests.nil?

      MemoryCache.fetch("requests-fulfillments") do
        fulfillments_totals = Hash.new
        fulfillments_by_host = Hash.new

        self.unfulfilled.each do |host, requests|
          requests.each do |unit_number, item_counts|
            item_counts.each do |item_name, item_count|

              actual_count = self.count_to_fulfill(item_name, item_count)
              if actual_count > 0

                fulfillments_by_host[host] ||= Hash.new
                fulfillments_by_host[host][unit_number] ||= Hash.new
                fulfillments_by_host[host][unit_number][item_name] = actual_count

                fulfillments_totals[item_name] ||= 0
                fulfillments_totals[item_name] += actual_count
              end
            end
          end
        end
        MemoryCache.write("requests-fulfillment-totals", fulfillments_totals)
        fulfillments_by_host
      end
    end

    def fulfill(&block)
      items_to_remove = if self.can_fulfill_none?
        # we can not fulfill anything; noop
        $logger.debug(:logistics) { "NOOP" }
        {}
      elsif self.can_fulfill_all?
        # fast fulfillment
        #
        # if we can fulfill all requests, skip calculating and just send the same response back we received
        $logger.debug(:logistics) { "Fast Fulfillment: #{self.unfulfilled.ai}" }

        # fulfill requests
        self.unfulfilled.each do |host, fulfillments|
          block.call(host, fulfillments)
          self.mark_as_fulfilled(host)
        end

        # return all items for removal since we could fulfill all requests
        self.item_totals
      else
        # slow fulfillment
        #
        # since some requests can not be fulfilled, calculate the ratios and distribute the items accordingly
        $logger.debug(:logistics) { "Slow Fulfillment: #{self.fulfillments.ai}" }

        self.fulfillments.each do |host, fulfillments|
          block.call(host, fulfillments)
          self.mark_as_fulfilled(host)
        end

        # return fulfilled items for removal
        self.fulfillments_totals
      end

      # update storage and sync it to disk
      items_to_remove.each do |item_name, item_count|
        Storage.remove(item_name, item_count)
      end
      Storage.save
    end

    def process
      $logger.debug(:logistics) { "Requests: #{self.unfulfilled.ai}" }
      self.fulfill do |host, fulfillments|
        server = Servers.find_by_name(host)
        command = %(/#{rcon_executor} remote.call('link', 'set_fulfillments', '#{fulfillments.to_json}'))
        server.rcon_command_nonblock(command, method(:rcon_print))
      end
      self.reset
    end

  end

  extend(ClassMethods)
end

Requests.reset
