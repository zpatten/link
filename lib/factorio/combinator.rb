

# Link Inventory Combinator Update
################################################################################

# schedule_server(:inventory_combinators) do |server|
#   cache_key = "inventory-combinator-previous-signals-#{server.name}"
#   previous_storage = MemoryCache.read(cache_key)
#   # get a copy of the storage
#   storage = Storage.clone

#   # if we have a previous copy of the storage detect changes and skip updating
#   # if nothing has changed
#   if (!!previous_storage && (previous_storage == storage))
#     $logger.debug { "[#{server.id}] Skipping sending storage to inventory combinators; no changes detected." }
#   else
#     $logger.debug { "[#{server.id}] Storage changed, updating to inventory combinators." }

#     # update inventory combinators with the current storage
#     command = %(/#{rcon_executor} remote.call('link', 'set_inventory_combinator', '#{storage.to_json}'))
#     server.rcon_command_nonblock(command, method(:rcon_print))

#     # stash a copy of the current storage so we can detect changes on the next run
#     MemoryCache.write(cache_key, storage)
#   end
# end

def lookup_signal(signals, name)
  return nil if signals.nil?
  signals.each do |signal|
    return signal if (signal["signal"]["name"] == name)
  end

  nil
end

def header(what)
  puts ("=" * 80)
  puts what
  puts ("=" * 80)
end

def write_log(what)
  $log_mutex ||= Mutex.new
  $log_mutex.synchronize do
    File.open("combinator.log", "a") do |f|
      f.puts what
    end
  end
end

# Link Receiver Combinator
################################################################################
$receiver_combinators_initalized ||= Hash.new
def set_receiver_combinator(host, packet_fields, server)
  payload = packet_fields.payload
  unless payload.empty?
    write_log("set_receiver_combinator:#{JSON.pretty_generate(payload)}")
    network_ids = JSON.parse(payload)
    unless network_ids.empty?
      # network_ids = network_ids.map(&:deep_symbolize_keys!)
      #network_ids.collect! { |nid, count| [nid == "inventory" ? nid.to_sym : nid.to_i, count] }
      $logger.debug(:combinators_rx) { "[#{server.id}] Received circuit networks: #{pp_inline(network_ids)}" }

      signal_networks = Hash.new
      network_ids.each do |network_id|
        # cache_key = "receiver-combinator-previous-signals-#{server.name}-#{network_id}"
        # previous_signals = MemoryCache.read(cache_key)
        network_signals = Combinators.rx(network_id, server)

        unless network_signals.nil? || network_signals.empty?
          signal_networks[network_id] = network_signals
        end

        # if (!!previous_signals && (previous_signals == signals))
        #   $logger.debug { "[#{server.id}] network-id(#{network_id}): Skipping sending signals to receiver combinators; no changes detected." }
        # else
        #   signal_deltas = Array.new
        #   signals.each do |signal|
        #     signal_name = signal["signal"]["name"]
        #     previous_signal = lookup_signal(previous_signals, signal_name)
        #     if previous_signal.nil? || $receiver_combinators_initalized[server.name].nil?
        #       $logger.debug { "[#{server.id}] network-id(#{network_id}): Signal #{signal_name} is new; adding to delta." }
        #       signal_deltas << signal
        #     else
        #       count_changed = (previous_signal["count"].to_i != signal["count"].to_i)
        #       index_changed = (previous_signal["index"].to_i != signal["index"].to_i)
        #       if count_changed || index_changed
        #         $logger.debug { "[#{server.id}] network-id(#{network_id}): Signal #{signal_name} changed; adding to delta; #{previous_signal["count"]} != #{signal["count"]}" }
        #         signal_deltas << signal
        #       else
        #         # $logger.debug { "[#{server.id}] network-id(#{network_id}): Signal #{signal_name} unchanged; #{previous_signal["count"]} == #{signal["count"]}" }
        #       end
        #     end
        #   end
        #   $logger.info { "[#{server.id}] network-id(#{network_id}): Signals changed (#{signal_deltas.count} of #{signals.count}), updating receiver combinators." }
        #   signal_networks[network_id] = signal_deltas
        # end
        # MemoryCache.write(cache_key, signals)
      end

      if signal_networks.count > 0
        # update rx combinators with the signal networks
        force = ($receiver_combinators_initalized[server.name] != true)
        command = %(/#{rcon_executor} remote.call('link', 'set_receiver_combinator', #{force}, '#{signal_networks.to_json}'))
    write_log("signal_networks:#{JSON.pretty_generate(signal_networks)}")
        server.rcon_command_nonblock(command, method(:rcon_print))
        $receiver_combinators_initalized[server.name] = true
      end
    end
  end
end

schedule_server(:receiver_combinators) do |server|
  command = %(/#{rcon_executor} remote.call('link', 'get_receiver_combinator_network_ids'))
  server.rcon_command_nonblock(command, method(:set_receiver_combinator))
end


# Link Transmitter Combinator
################################################################################

def get_transmitter_combinator(host, packet_fields, server)
  payload = packet_fields.payload
  unless payload.empty?
    write_log("get_transmitter_combinator:#{payload}")
    unit_networks_list = JSON.parse(payload)
    unless unit_networks_list.empty?
      if unit_networks_list["noop"].nil?
        $logger.debug(:combinator_tx) { "[#{server.id}] Received signals for circuit networks: #{pp_inline(unit_networks_list.values.map(&:keys).flatten.uniq.sort)}" }
        Combinators.tx(unit_networks_list, server)
      else
        $logger.debug(:combinator_tx) { "[#{server.id}] NOOP" }
        return
      end
    end
  end
end

$transmitter_combinators_initalized ||= Hash.new
schedule_server(:transmitter_combinators) do |server|
  command = if $transmitter_combinators_initalized[server.name].nil?
    $transmitter_combinators_initalized[server.name] = true
    %(/#{rcon_executor} remote.call('link', 'get_transmitter_combinator', true))
  else
    %(/#{rcon_executor} remote.call('link', 'get_transmitter_combinator'))
  end
  server.rcon_command_nonblock(command, method(:get_transmitter_combinator))
end
