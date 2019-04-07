
function calculate_position(entity, offset)
  local p_network_id, p_lamp, search_area

  local x = entity.position.x
  local y = entity.position.y
  local rotation = entity.direction

  if entity.direction == 0 then -- South-North
    p_network_id = { x + offset, y - 1 }
    p_lamp = { x - 1 - offset, y - 1}
    search_area = { { x - 1 + offset, y - 1 }, { x + 1 + offset, y } }
  elseif entity.direction == 2 then -- West-East
    p_network_id = { x, y + offset }
    p_lamp = { x, y - 1 + offset}
    search_area = { { x, y - 1 + offset }, { x + 1, y + 1 + offset } }
  elseif entity.direction == 4 then -- North-South
    p_network_id = { x - 1 - offset, y }
    p_lamp = { x - offset, y}
    search_area = { { x - 1 - offset, y }, { x + 1 - offset, y + 1 } }
  elseif entity.direction == 6 then -- East-West
    p_network_id = { x - 1, y - 1 - offset }
    p_lamp = { x - 1, y - offset}
    search_area = { { x - 1, y - 1 - offset }, { x, y + 1 - offset } }
  end

  return {
    p_lamp = p_lamp,
    p_network_id = p_network_id,
    rotation = rotation,
    search_area = search_area
  }
end

function create_combinator(entity)
  local position = calculate_position(entity, 0)

  local link_network_id = entity.surface.create_entity{
    name = NETWORK_ID_COMBINATOR_NAME,
    position = position.p_network_id,
    force = entity.force
  }

  link_network_id.operable = true
  link_network_id.minable = false
  link_network_id.destructible = false

  return {
    link_network_id = link_network_id
  }
end

function destroy_combinator(data)
  if data.link_network_id and data.link_network_id.valid then data.link_network_id.destroy() end
end

-- ADD
function add_link_entity(entity)
  if entity.name == ACTIVE_PROVIDER_CHEST_NAME then
    game.print("add_link_entity(ACTIVE_PROVIDER_CHEST_NAME): "..entity.unit_number)
    global.link_provider_chests[entity.unit_number] = {
      entity = entity,
      inventory = entity.get_inventory(defines.inventory.chest)
    }
  elseif entity.name == BUFFER_CHEST_NAME then
    game.print("add_link_entity(BUFFER_CHEST_NAME): "..entity.unit_number)
    global.link_requester_chests[entity.unit_number] = {
      entity = entity,
      filter_count = entity.prototype.filter_count,
      inventory = entity.get_inventory(defines.inventory.chest)
    }
  elseif entity.name == REQUESTER_PROVIDER_CHEST_NAME then
    game.print("add_link_entity(REQUESTER_PROVIDER_CHEST_NAME): "..entity.unit_number)
    global.link_provider_chests[entity.unit_number] = {
      entity = entity,
      inventory = entity.get_inventory(defines.inventory.chest)
    }
  elseif entity.name == INVENTORY_COMBINATOR_NAME then
    game.print("add_link_entity(INVENTORY_COMBINATOR_NAME): "..entity.unit_number)
    entity.operable = false
    global.link_inventory_combinators[entity.unit_number] = {
      entity = entity,
      behaviour = entity.get_or_create_control_behavior()
    }
  elseif entity.name == RECEIVER_COMBINATOR_NAME then
    game.print("add_link_entity(RECEIVER_COMBINATOR_NAME): "..entity.unit_number)
    entity.operable = false
    local parts = create_combinator(entity)
    global.link_receiver_combinators[entity.unit_number] = {
      entity = entity,
      behaviour = entity.get_or_create_control_behavior(),
      link_network_id = parts.link_network_id
    }
  elseif entity.name == TRANSMITTER_COMBINATOR_NAME then
    entity.operable = false
    game.print("add_link_entity(TRANSMITTER_COMBINATOR_NAME): "..entity.unit_number)
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
      behaviour = entity.get_or_create_control_behavior()
    }
  end
end

-- REMOVE
function remove_link_entity(entity)
  if entity.name == ACTIVE_PROVIDER_CHEST_NAME then
    game.print("remove_link_entity(ACTIVE_PROVIDER_CHEST_NAME)"..entity.unit_number)
    global.link_provider_chests[entity.unit_number] = nil
  elseif entity.name == BUFFER_CHEST_NAME then
    game.print("remove_link_entity(BUFFER_CHEST_NAME)"..entity.unit_number)
    global.link_requester_chests[entity.unit_number] = nil
  elseif entity.name == REQUESTER_PROVIDER_CHEST_NAME then
    game.print("remove_link_entity(REQUESTER_PROVIDER_CHEST_NAME)"..entity.unit_number)
    global.link_provider_chests[entity.unit_number] = nil
  elseif entity.name == INVENTORY_COMBINATOR_NAME then
    game.print("remove_link_entity(INVENTORY_COMBINATOR_NAME): "..entity.unit_number)
    global.link_inventory_combinators[entity.unit_number] = nil
  elseif entity.name == RECEIVER_COMBINATOR_NAME then
    game.print("remove_link_entity(RECEIVER_COMBINATOR_NAME): "..entity.unit_number)
    data = global.link_receiver_combinators[entity.unit_number]
    destroy_combinator(data)
    global.link_receiver_combinators[entity.unit_number] = nil
  elseif entity.name == TRANSMITTER_COMBINATOR_NAME then
    game.print("remove_link_entity(TRANSMITTER_COMBINATOR_NAME): "..entity.unit_number)
    global.link_transmitter_combinators[entity.unit_number] = nil
  end
end

function add_all_link_entities()
  local names = {
    ACTIVE_PROVIDER_CHEST_NAME,
    BUFFER_CHEST_NAME,
    REQUESTER_CHEST_NAME,
    INVENTORY_COMBINATOR_NAME,
    RECEIVER_COMBINATOR_NAME,
    TRANSMITTER_COMBINATOR_NAME
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
