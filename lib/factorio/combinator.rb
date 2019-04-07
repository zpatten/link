

# Link Inventory Combinator Update
################################################################################

schedule_server(:inventory_combinators) do |server|
  cache_key = "inventory-combinator-previous-signals-#{server.name}"
  previous_storage = MemoryCache.read(cache_key)
  # get a copy of the storage
  storage = Storage.clone

  # if we have a previous copy of the storage detect changes and skip updating
  # if nothing has changed
  if (!!previous_storage && (previous_storage == storage))
    $logger.debug { "[#{server.id}] Skipping sending storage to inventory combinators; no changes detected." }
  else
    $logger.debug { "[#{server.id}] Storage changed, updating to inventory combinators." }

    # update inventory combinators with the current storage
    command = %(/#{rcon_executor} remote.call('link', 'set_inventory_combinator', '#{storage.to_json}'))
    server.rcon_command(command, method(:rcon_print))

    # stash a copy of the current storage so we can detect changes on the next run
    MemoryCache.write(cache_key, storage)
  end
end

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

# Link Receiver Combinator
################################################################################
def set_receiver_combinator(host, packet_fields, server)
  payload = packet_fields.payload
  unless payload.empty?
    network_ids = JSON.parse(payload)
    unless network_ids.empty?
      network_ids.collect! { |nid| nid.is_a?(Integer) ? nid : nid.to_sym }
      $logger.debug { "[#{server.id}] network-ids: #{network_ids}" }
      signal_networks = Hash.new
      network_ids.each do |network_id|
        cache_key = "receiver-combinator-previous-signals-#{server.name}-#{network_id}"
        previous_signals = MemoryCache.read(cache_key)
        signals = Combinators.rx(server, network_id).clone
        if (!!previous_signals && (previous_signals == signals))
          $logger.debug { "[#{server.id}] network-id(#{network_id}): Skipping sending signals to receiver combinators; no changes detected." }
        else
          signal_deltas = Array.new
          signals.each do |signal|
            signal_name = signal["signal"]["name"]
            previous_signal = lookup_signal(previous_signals, signal_name)
            if previous_signal.nil?
              $logger.debug { "[#{server.id}] network-id(#{network_id}): Signal #{signal_name} is new; adding to delta." }
              signal_deltas << signal
            else
              count_changed = (previous_signal["count"].to_i != signal["count"].to_i)
              index_changed = (previous_signal["signal"]["index"] != signal["signal"]["index"])
              if count_changed || index_changed
                $logger.debug { "[#{server.id}] network-id(#{network_id}): Signal #{signal_name} changed; adding to delta." }
                signal_deltas << signal
              end
            end
          end
          $logger.info { "[#{server.id}] network-id(#{network_id}): Signals changed (#{signal_deltas.count} of #{signals.count}), updating receiver combinators." }
          signal_networks[network_id] = signal_deltas
        end
        MemoryCache.write(cache_key, signals)
      end

      if signal_networks.count > 0
        # update rx combinators with the signal networks
        command = %(/#{rcon_executor} remote.call('link', 'set_receiver_combinator', '#{signal_networks.to_json}'))
        server.rcon_command(command, method(:rcon_print))
      end
    end
  end
end

schedule_server(:receiver_combinators) do |server|
  command = %(/#{rcon_executor} remote.call('link', 'get_receiver_combinator_network_ids'))
  server.rcon_command(command, method(:set_receiver_combinator))
end


# Link Transmitter Combinator
################################################################################

def get_transmitter_combinator(host, packet_fields, server)
  payload = packet_fields.payload
  unless payload.empty?
    signal_lists = JSON.parse(payload)
    unless signal_lists.empty?
      if signal_lists["noop"].nil?
        puts ("X" * 80)
        puts ("X" * 80)
        puts ("X" * 80)
        $logger.debug { "[#{server.id}] tx-signals: #{PP.singleline_pp(signal_lists, "")}" }
        Combinators.tx(server, signal_lists)
      else
        $logger.debug { "[#{server.id}] tx-signals: NOOP" }
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
  server.rcon_command(command, method(:get_transmitter_combinator))
end
