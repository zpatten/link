
function calculate_position(entity)
  local p_network_id, p_lamp, search_area

  local offset_map = {}
  offset_map[LINK_RECEIVER_COMBINATOR_NAME] = {}

  offset_map[LINK_RECEIVER_COMBINATOR_NAME][0] = { x = 1, y = 0 }
  offset_map[LINK_RECEIVER_COMBINATOR_NAME][2] = { x = 0, y = 1 }
  offset_map[LINK_RECEIVER_COMBINATOR_NAME][4] = { x = -1, y = 0 }
  offset_map[LINK_RECEIVER_COMBINATOR_NAME][6] = { x = 0, y = -1 }

  offset_map[LINK_TRANSMITTER_COMBINATOR_NAME] = {}
  offset_map[LINK_TRANSMITTER_COMBINATOR_NAME][0] = { x = 1, y = 0 }
  offset_map[LINK_TRANSMITTER_COMBINATOR_NAME][2] = { x = -1, y = 1 }
  offset_map[LINK_TRANSMITTER_COMBINATOR_NAME][4] = { x = -1, y = -1 }
  offset_map[LINK_TRANSMITTER_COMBINATOR_NAME][6] = { x = 0, y = -1 }

  p_network_id = {
    entity.position.x + offset_map[entity.name][entity.direction].x,
    entity.position.y + offset_map[entity.name][entity.direction].y
  }

  return {
    p_lamp = p_lamp,
    p_network_id = p_network_id
  }
end

function create_combinator(entity)
  local position = calculate_position(entity)

  local link_network_id = entity.surface.find_entity(LINK_NETWORK_ID_COMBINATOR_NAME, position.p_network_id)
  if not link_network_id then
    link_network_id = entity.surface.create_entity{
      name = LINK_NETWORK_ID_COMBINATOR_NAME,
      position = position.p_network_id,
      force = entity.force,
      direction = entity.direction
    }
  end

  link_network_id.operable = true
  link_network_id.minable = false
  link_network_id.destructible = false
  link_network_id.rotatable = false

  return {
    link_network_id = link_network_id
  }
end

function destroy_combinator(data)
  if data.link_network_id and data.link_network_id.valid then data.link_network_id.destroy() end
end

-- ADD
function add_link_entity(entity)

  if not global.link_fluid_providers then global.link_fluid_providers = {} end
  if not global.link_fluid_requesters then global.link_fluid_requesters = {} end

  ------------
  -- CHESTS --
  ------------
  if entity.name == LINK_ACTIVE_PROVIDER_CHEST_NAME then
    link_log(string.format("add_link_entity(LINK_ACTIVE_PROVIDER_CHEST_NAME): %d", entity.unit_number))
    global.link_provider_chests[entity.unit_number] = {
      entity = entity,
      inventory = entity.get_inventory(defines.inventory.chest)
    }
  elseif entity.name == LINK_BUFFER_CHEST_NAME then
    link_log(string.format("add_link_entity(LINK_BUFFER_CHEST_NAME): %d", entity.unit_number))
    global.link_requester_chests[entity.unit_number] = {
      entity = entity,
      filter_count = entity.prototype.filter_count,
      inventory = entity.get_inventory(defines.inventory.chest)
    }
  elseif entity.name == LINK_REQUESTER_PROVIDER_CHEST_NAME then
    link_log(string.format("add_link_entity(LINK_REQUESTER_PROVIDER_CHEST_NAME): %d", entity.unit_number))
    global.link_provider_chests[entity.unit_number] = {
      entity = entity,
      inventory = entity.get_inventory(defines.inventory.chest)
    }
  elseif entity.name == LINK_STORAGE_CHEST_NAME then
    link_log(string.format("add_link_entity(LINK_STORAGE_CHEST_NAME): %d", entity.unit_number))
    global.link_provider_chests[entity.unit_number] = {
      entity = entity,
      inventory = entity.get_inventory(defines.inventory.chest)
    }
  -----------
  -- FLUID --
  -----------
  elseif entity.name == LINK_FLUID_PROVIDER_NAME then
    link_log(string.format("add_link_entity(LINK_FLUID_PROVIDER_NAME): %d", entity.unit_number))
    global.link_fluid_providers[entity.unit_number] = {
      entity = entity
    }
  elseif entity.name == LINK_FLUID_REQUESTER_NAME then
    link_log(string.format("add_link_entity(LINK_FLUID_REQUESTER_NAME): %d", entity.unit_number))
    global.link_fluid_requesters[entity.unit_number] = {
      entity = entity,
      inventory = entity.get_inventory(defines.inventory.assembling_machine_input)
    }
  -----------
  -- POWER --
  -----------
  elseif entity.name == LINK_ELECTRICAL_PROVIDER_NAME then
    link_log(string.format("add_link_entity(LINK_ELECTRICAL_PROVIDER_NAME): %d", entity.unit_number))
    if not global.link_electrical_providers then global.link_electrical_providers = {} end
    global.link_electrical_providers[entity.unit_number] = {
      entity = entity
    }
  elseif entity.name == LINK_ELECTRICAL_REQUESTER_NAME then
    link_log(string.format("add_link_entity(LINK_ELECTRICAL_REQUESTER_NAME): %d", entity.unit_number))
    if not global.link_electrical_requesters then global.link_electrical_requesters = {} end
    global.link_electrical_requesters[entity.unit_number] = {
      entity = entity,
      electric_buffer_size = entity.electric_buffer_size
    }
  -----------------
  -- COMBINATORS --
  -----------------
  elseif entity.name == LINK_INVENTORY_COMBINATOR_NAME then
    link_log(string.format("add_link_entity(LINK_INVENTORY_COMBINATOR_NAME): %d", entity.unit_number))
    entity.operable = false
    global.link_inventory_combinators[entity.unit_number] = {
      entity = entity,
      behaviour = entity.get_or_create_control_behavior()
    }
  elseif entity.name == LINK_RECEIVER_COMBINATOR_NAME then
    link_log(string.format("add_link_entity(LINK_RECEIVER_COMBINATOR_NAME): %d", entity.unit_number))
    entity.operable = false
    entity.rotatable = false
    local parts = create_combinator(entity)
    global.link_receiver_combinators[entity.unit_number] = {
      entity = entity,
      behaviour = entity.get_or_create_control_behavior(),
      link_network_id = parts.link_network_id
    }
  elseif entity.name == LINK_TRANSMITTER_COMBINATOR_NAME then
    link_log(string.format("add_link_entity(LINK_TRANSMITTER_COMBINATOR_NAME): %d", entity.unit_number))
    entity.operable = false
    entity.rotatable = false
    local parts = create_combinator(entity)
    local behavior = entity.get_or_create_control_behavior()
    local parameters = {
      first_signal = { type = "virtual", name = "signal-each" },
      constant = 0,
      comparator = "≠",
      output_signal = { type = "virtual", name = "signal-each" }
    }
    behavior.parameters = { parameters = parameters }
    global.link_transmitter_combinators[entity.unit_number] = {
      entity = entity,
      behaviour = entity.get_or_create_control_behavior(),
      link_network_id = parts.link_network_id
    }
  end
end

-- REMOVE
function remove_link_entity(entity)
  if not global.link_fluid_providers then global.link_fluid_providers = {} end
  if not global.link_fluid_requesters then global.link_fluid_requesters = {} end

  if entity.name == LINK_ACTIVE_PROVIDER_CHEST_NAME then
    link_log(string.format("remove_link_entity(LINK_ACTIVE_PROVIDER_CHEST_NAME): %d", entity.unit_number))
    global.link_provider_chests[entity.unit_number] = nil
  elseif entity.name == LINK_BUFFER_CHEST_NAME then
    link_log(string.format("remove_link_entity(LINK_BUFFER_CHEST_NAME): %d", entity.unit_number))
    global.link_requester_chests[entity.unit_number] = nil
  elseif entity.name == LINK_REQUESTER_PROVIDER_CHEST_NAME then
    link_log(string.format("remove_link_entity(LINK_REQUESTER_PROVIDER_CHEST_NAME): %d", entity.unit_number))
    global.link_provider_chests[entity.unit_number] = nil
  elseif entity.name == LINK_STORAGE_CHEST_NAME then
    link_log(string.format("remove_link_entity(LINK_STORAGE_CHEST_NAME): %d", entity.unit_number))
    global.link_provider_chests[entity.unit_number] = nil
  elseif entity.name == LINK_ELECTRICAL_PROVIDER_NAME then
    link_log(string.format("remove_link_entity(LINK_ELECTRICAL_PROVIDER_NAME): %d", entity.unit_number))
    global.link_electrical_providers[entity.unit_number] = nil
  elseif entity.name == LINK_ELECTRICAL_REQUESTER_NAME then
    link_log(string.format("remove_link_entity(LINK_ELECTRICAL_REQUESTER_NAME): %d", entity.unit_number))
    global.link_electrical_requesters[entity.unit_number] = nil
  elseif entity.name == LINK_FLUID_PROVIDER_NAME then
    link_log(string.format("remove_link_entity(LINK_FLUID_PROVIDER_NAME): %d", entity.unit_number))
    global.link_fluid_providers[entity.unit_number] = nil
  elseif entity.name == LINK_FLUID_REQUESTER_NAME then
    link_log(string.format("remove_link_entity(LINK_FLUID_REQUESTER_NAME): %d", entity.unit_number))
    global.link_fluid_requesters[entity.unit_number] = nil
  elseif entity.name == LINK_INVENTORY_COMBINATOR_NAME then
    link_log(string.format("remove_link_entity(LINK_INVENTORY_COMBINATOR_NAME): %d", entity.unit_number))
    global.link_inventory_combinators[entity.unit_number] = nil
  elseif entity.name == LINK_RECEIVER_COMBINATOR_NAME then
    link_log(string.format("remove_link_entity(LINK_RECEIVER_COMBINATOR_NAME): %d", entity.unit_number))
    data = global.link_receiver_combinators[entity.unit_number]
    destroy_combinator(data)
    global.link_receiver_combinators[entity.unit_number] = nil
  elseif entity.name == LINK_TRANSMITTER_COMBINATOR_NAME then
    link_log(string.format("remove_link_entity(LINK_TRANSMITTER_COMBINATOR_NAME): %d", entity.unit_number))
    data = global.link_transmitter_combinators[entity.unit_number]
    destroy_combinator(data)
    global.link_transmitter_combinators[entity.unit_number] = nil
  end
end

function add_all_link_entities()
  local names = {
    LINK_ACTIVE_PROVIDER_CHEST_NAME,
    LINK_BUFFER_CHEST_NAME,
    LINK_REQUESTER_PROVIDER_CHEST_NAME,
    LINK_STORAGE_CHEST_NAME,

    LINK_ELECTRICAL_PROVIDER_NAME,
    LINK_ELECTRICAL_REQUESTER_NAME,

    LINK_FLUID_PROVIDER_NAME,
    LINK_FLUID_REQUESTER_NAME,

    LINK_INVENTORY_COMBINATOR_NAME,
    LINK_RECEIVER_COMBINATOR_NAME,
    LINK_TRANSMITTER_COMBINATOR_NAME
  }
  local filters = { name = names }

  for i, surface in pairs(game.surfaces) do
    for i, entity in pairs(surface.find_entities_filtered(filters)) do
      add_link_entity(entity)
    end
  end
end

function on_link_entity_died(event)
  local entity = event.entity

  if entity.type ~= "entity-ghost" then
    remove_link_entity(entity)
  end
end
script.on_event(defines.events.on_entity_died, on_link_entity_died)
script.on_event(defines.events.on_robot_pre_mined, on_link_entity_died)
script.on_event(defines.events.on_pre_player_mined_item, on_link_entity_died)

function on_built_link_entity(event)
  local entity = event.created_entity
  if not (entity and entity.valid) then
    return
  end

  if entity.type ~= "entity-ghost" then
    add_link_entity(entity)
  end
end
script.on_event(defines.events.on_built_entity, on_built_link_entity)
script.on_event(defines.events.on_robot_built_entity, on_built_link_entity)
