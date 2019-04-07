function get_link_transmitter_combinator(force)
  local link_signals = {}
  local noop = { noop = true }

  for unit_number, data in pairs(global.link_transmitter_combinators) do
    local behaviour = data.behaviour
    local entity = data.entity

    if entity.valid and behaviour.valid then
      link_signals[entity.unit_number] = behaviour.signals_last_tick
    end
  end

  if not force and table.compare(global.link_transmitter_combinators_previous_signals, link_signals) then
    rcon.print(game.table_to_json(noop))
  else
    rcon.print(game.table_to_json(link_signals))
    global.link_transmitter_combinators_previous_signals = link_signals
  end
end

-- function extract_network_id_signal(signals)
--   if table_count(signals) > 0 then
--     for _, s in pairs(signals) do
--       if s and s.signal then
--         if s.signal.type == "virtual" and s.signal.name == "signal-link-network-id" then
--           return s
--         end
--       end
--     end
--   end
--   return {
--     signal = {
--       type = "virtual",
--       name = "signal-link-network-id"
--     },
--     count = 0
--   }
-- end

-- function extract_network_id(signals)
--   local network_id_signal = extract_network_id_signal(signals)
--   if network_id_signal then
--     return network_id_signal.count
--   else
--     return 0
--   end
-- end

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
        return link_network_id_signal.count
      end
    end
  end

  return 0
end

function set_link_receiver_combinator(data)
  local link_signal_networks = game.json_to_table(data)

  for unit_number, data in pairs(global.link_receiver_combinators) do
    local behaviour = data.behaviour
    local entity = data.entity
    local link_network_id_entity = data.link_network_id

    if entity.valid and behaviour.valid then
      link_network_id = fetch_circuit_network_id(link_network_id_entity)
      local signals = extract_circuit_network(link_network_id, link_signal_networks)

      for i, s in pairs(signals) do
        behaviour.set_signal(s.index, s)
      end
      behaviour.enabled = true
    end
  end

  for unit_number, data in pairs(global.link_inventory_combinators) do
    local behaviour = data.behaviour
    local entity = data.entity

    if entity.valid and behaviour.valid then
      local signals = extract_circuit_network("inventory", link_signal_networks)

      for i, s in pairs(signals) do
        behaviour.set_signal(s.index, s)
      end
      behaviour.enabled = true
    end
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

function set_link_inventory_combinator(data)
  local storage = game.json_to_table(data)
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
