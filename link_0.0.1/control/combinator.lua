function link_sn(signal)
  return signal.signal.name
end

function link_sc(signal)
  return signal.count
end

function get_link_transmitter_combinator(force)
  local link_signals = {}
  local signal_delta = {}
  local noop = { noop = true }

  for unit_number, data in pairs(global.link_transmitter_combinators) do
    local behaviour = data.behaviour
    local entity = data.entity
    local link_network_id_entity = data.link_network_id
    local unit_signal_delta = {}

    if entity.valid and behaviour.valid and link_network_id_entity.valid then
      link_network_id = fetch_circuit_network_id(link_network_id_entity)
      link_signals[entity.unit_number] = {}
      link_signals[entity.unit_number][link_network_id] = behaviour.signals_last_tick

      link_log("SIGNALS-TX", string.format("Processing Network ID: %d", link_network_id))

      if not force and global.link_previous_signals then
        -- get the current signals
        local current_signals = link_signals[entity.unit_number][link_network_id]
        if not current_signals then current_signals = {} end

        -- do we have previous signals to generate a delta with?
        if global.link_previous_signals[entity.unit_number] and global.link_previous_signals[entity.unit_number][link_network_id] then

          -- get the previous signals
          local previous_signals = global.link_previous_signals[entity.unit_number][link_network_id]
          if not previous_signals then previous_signals = {} end

          -- did the signals change?
          if not table.compare(current_signals, previous_signals) then

            -- build a hash map of the current signals for faster lookup
            local current_signals_map = {}
            for i, signal in pairs(current_signals) do
              current_signals_map[link_sn(signal)] = signal
            end

            -- build a hash map of the previous signals for faster lookup
            local previous_signals_map = {}
            for i, signal in pairs(previous_signals) do
              previous_signals_map[link_sn(signal)] = signal
            end

            -- look for new or changed signals
            for i, current_signal in pairs(current_signals) do
              local previous_signal = previous_signals_map[link_sn(current_signal)]
              if not previous_signal then
                -- new signal
                link_log("SIGNALS-TX", string.format("Create Signal: %s (%d)", current_signal.signal.name, current_signal.count))
                table.insert(unit_signal_delta, current_signal)
              elseif link_sc(current_signal) ~= link_sc(previous_signal) then
                -- signal count changed
                link_log("SIGNALS-TX", string.format("Update Signal: %s (%d -> %d)", current_signal.signal.name, previous_signal.count, current_signal.count))
                table.insert(unit_signal_delta, current_signal)
              end
            end

            -- look for deleted signals
            for i, previous_signal in pairs(previous_signals) do
              local current_signal = current_signals_map[link_sn(previous_signal)]
              if not current_signal then
                -- signal deleted
                link_log("SIGNALS-TX", string.format("Delete Signal: %s", previous_signal.signal.name))
                previous_signal["count"] = 0
                table.insert(unit_signal_delta, previous_signal)
              end
            end

            if table_size(unit_signal_delta) > 0 then
              -- if we we able to generate a delta for this entity, add the signal deltas to the list
              if not signal_delta[unit_number] then signal_delta[unit_number] = {} end
              signal_delta[unit_number][link_network_id] = unit_signal_delta
            end

          else
            -- signals are the same; NOOP
          end

        else
          -- no previous signals

          -- if we could not generate a delta and we have signals, add all signals to the list
          if table_size(link_signals[entity.unit_number][link_network_id]) > 0 then
            if not signal_delta[unit_number] then signal_delta[unit_number] = {} end
            signal_delta[unit_number][link_network_id] = link_signals[entity.unit_number][link_network_id]
          end

        end
      end
    end
  end

  if not force and table_size(signal_delta) == 0 then
    -- if this is not a forced refresh and if no signals changed send a NOOP
    rcon.print(game.table_to_json(noop))
    link_log("SIGNALS-TX", "NOOP")
  elseif not force and table_size(signal_delta) > 0 then
    -- if this is not a forced refresh and we have a delta send it
    link_log("SIGNALS-TX", "Sending signal deltas.")
    rcon.print(game.table_to_json(signal_delta))
  else
    -- otherwise send everything
    link_log("SIGNALS-TX", "Sending all signals (forced).")
    rcon.print(game.table_to_json(link_signals))
  end

  -- update the previous signals
  global.link_previous_signals = table.deepcopy(link_signals)
end

function get_link_receiver_combinator_network_ids()
  local network_ids = {}

  for unit_number, data in pairs(global.link_receiver_combinators) do
    local entity = data.entity
    local link_network_id_entity = data.link_network_id

    if entity and entity.valid and link_network_id_entity and link_network_id_entity.valid then
      table.insert(network_ids, fetch_circuit_network_id(link_network_id_entity))
    end
  end

  for unit_number, data in pairs(global.link_inventory_combinators) do
    local entity = data.entity

    if entity and entity.valid then
      table.insert(network_ids, "inventory")
    end
  end

  rcon.print(game.table_to_json(uniq(network_ids)))
end

function extract_circuit_network(network_id, link_signal_networks)
  for id, link_signal_network in pairs(link_signal_networks) do
    if tostring(network_id) == tostring(id) then
      return link_signal_network
    end
  end

  return {}
end

function fetch_circuit_network_id(entity)
  if entity and entity.valid then
    local behaviour = entity.get_or_create_control_behavior()
    if behaviour and behaviour.valid then
      link_network_id_signal = behaviour.get_signal(1)
      if link_network_id_signal then
        return tostring(link_network_id_signal.count)
      end
    end
  end

  return tostring(0)
end

function scrub_signals(signals)
  local s = {}

  for _, signal in pairs(signals) do
    if signal.count ~= 0 then
      signal.index = #s+1
      s[#s+1] = signal
    end
  end

  return s
end

function set_link_receiver_combinator(force, json)
  local link_signal_networks = game.json_to_table(json)

  if not global.rx_signals then global.rx_signals = {} end

  for unit_number, data in pairs(global.link_receiver_combinators) do
    local behaviour = data.behaviour
    local entity = data.entity
    local link_network_id_entity = data.link_network_id

    if entity.valid and behaviour.valid then
      link_network_id = fetch_circuit_network_id(link_network_id_entity)
      local signals = extract_circuit_network(link_network_id, link_signal_networks)

      link_log("SIGNALS-RX", string.format("Processing Network ID: %d", link_network_id))

      if force or not global.rx_signals[link_network_id] then
        global.rx_signals[link_network_id] = signals
      else
        local signals_map = {}
        for i, signal in pairs(global.rx_signals[link_network_id]) do
          signals_map[link_sn(signal)] = signal
        end

        for i, s in pairs(signals) do
          local existing_signal = signals_map[s.signal.name]
          if existing_signal then
            if s.count == 0 then
              link_log("SIGNALS-RX", string.format("Delete Signal: %s", s.signal.name))
              existing_signal.count = s.count
            else
              link_log("SIGNALS-RX", string.format("Update Signal: %s (%d -> %d)", s.signal.name, existing_signal.count, s.count))
              existing_signal.count = s.count
            end
          else
            link_log("SIGNALS-RX", string.format("Create Signal: %s (%d)", s.signal.name, s.count))
            table.insert(global.rx_signals[link_network_id], s)
          end
        end
      end

      global.rx_signals[link_network_id] = scrub_signals(global.rx_signals[link_network_id])

      behaviour.parameters = { parameters = global.rx_signals[link_network_id] }
      behaviour.enabled = true
    end
  end

  for unit_number, data in pairs(global.link_inventory_combinators) do
    local behaviour = data.behaviour
    local entity = data.entity
    -- local link_network_id_entity = data.link_network_id

    if entity.valid and behaviour.valid then
      link_network_id = "inventory"
      local signals = extract_circuit_network(link_network_id, link_signal_networks)

      link_log("SIGNALS-RX", string.format("Processing Network ID: %s", link_network_id))

      if force or not global.rx_signals[link_network_id] then
        global.rx_signals[link_network_id] = signals
      else
        local signals_map = {}
        for i, signal in pairs(global.rx_signals[link_network_id]) do
          signals_map[link_sn(signal)] = signal
        end

        for i, s in pairs(signals) do
          local existing_signal = signals_map[s.signal.name]
          if existing_signal then
            if s.count == 0 then
              link_log("SIGNALS-RX", string.format("Delete Signal: %s", s.signal.name))
              existing_signal.count = s.count
            else
              link_log("SIGNALS-RX", string.format("Update Signal: %s (%d -> %d)", s.signal.name, existing_signal.count, s.count))
              existing_signal.count = s.count
            end
          else
            link_log("SIGNALS-RX", string.format("Create Signal: %s (%d)", s.signal.name, s.count))
            table.insert(global.rx_signals[link_network_id], s)
          end
        end
      end

      global.rx_signals[link_network_id] = scrub_signals(global.rx_signals[link_network_id])

      behaviour.parameters = { parameters = global.rx_signals[link_network_id] }
      behaviour.enabled = true
    end
    -- local behaviour = data.behaviour
    -- local entity = data.entity

    -- if entity.valid and behaviour.valid then
    --   local signals = extract_circuit_network("inventory", link_signal_networks)

    --   local deleted_signals = {}
    --   local non_zero_signals = {}

    --   for i, s in pairs(signals) do
    --     if s.count ~= 0 then
    --       behaviour.set_signal(s.index, s)
    --       non_zero_signals[s.index] = true
    --     else
    --       table.insert(deleted_signals, s)
    --     end
    --   end

    --   for i, s in pairs(deleted_signals) do
    --     if not non_zero_signals[s.index] then
    --       behaviour.set_signal(s.index, nil)
    --     end
    --   end

    --   behaviour.enabled = true

    --   -- for i, s in pairs(signals) do
    --   --   behaviour.set_signal(s.index, s)
    --   -- end
    --   -- behaviour.enabled = true
    -- end
  end

  rcon.print("OK")
end

function link_lookup_item_type(item_name)
  local fluids = game.fluid_prototypes
  local items = game.item_prototypes
  local virtuals = game.virtual_signal_prototypes

  if items[item_name] then
    rcon.print("item")
  elseif fluids[item_name] then
    rcon.print("fluid")
  elseif virtuals[item_name] then
    rcon.print("virtual")
  end

  rcon.print("")
end

function set_link_inventory_combinator(json)
  local storage = game.json_to_table(json)
  local signals = {}


  for item_name, item_count in pairs(storage) do
    local signal_id = {
      name = item_name,
      type = link_lookup_item_type(item_name)
    }
    signals[#signals+1] = { signal = signal_id, count = item_count, index = #signals+1 }
  end

  for unit_number, data in pairs(global.link_inventory_combinators) do
    local behaviour = data.behaviour
    local entity = data.entity

    if entity.valid and behaviour.valid then
      behaviour.parameters = { parameters = signals }
      behaviour.enabled = true
    end
  end

  rcon.print("OK")
end
