-- ADD
function add_link_entity(entity)
  if entity.name == ACTIVE_PROVIDER_CHEST_NAME then
    game.print("add_link_entity(ACTIVE_PROVIDER_CHEST_NAME): "..entity.unit_number)
    global.link_provider_chests[entity.unit_number] = {
      entity = entity,
      inventory = entity.get_inventory(defines.inventory.chest)
    }
  elseif entity.name == REQUESTER_PROVIDER_CHEST_NAME then
    game.print("add_link_entity(REQUESTER_PROVIDER_CHEST_NAME): "..entity.unit_number)
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
  elseif entity.name == INVENTORY_COMBINATOR_NAME then
    game.print("add_link_entity(INVENTORY_COMBINATOR_NAME): "..entity.unit_number)
    global.link_inventory_combinators[entity.unit_number] = entity.get_or_create_control_behavior()
  end
end

-- REMOVE
function remove_link_entity(entity)
  if entity.name == ACTIVE_PROVIDER_CHEST_NAME then
    game.print("remove_link_entity(ACTIVE_PROVIDER_CHEST_NAME)"..entity.unit_number)
    global.link_provider_chests[entity.unit_number] = nil
  elseif entity.name == REQUESTER_PROVIDER_CHEST_NAME then
    game.print("remove_link_entity(REQUESTER_PROVIDER_CHEST_NAME)"..entity.unit_number)
    global.link_provider_chests[entity.unit_number] = nil
  elseif entity.name == BUFFER_CHEST_NAME then
    game.print("remove_link_entity(BUFFER_CHEST_NAME)"..entity.unit_number)
    global.link_requester_chests[entity.unit_number] = nil
  elseif entity.name == INVENTORY_COMBINATOR_NAME then
    game.print("remove_link_entity(INVENTORY_COMBINATOR_NAME): "..entity.unit_number)
    global.link_inventory_combinators[entity.unit_number] = nil
  end
end

function add_all_link_entities()
  local names = {
    ACTIVE_PROVIDER_CHEST_NAME,
    BUFFER_CHEST_NAME,
    REQUESTER_CHEST_NAME,
    INVENTORY_COMBINATOR_NAME
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
