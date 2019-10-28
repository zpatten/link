function get_link_providables()
  global.ticks_since_last_link_operation = 0

  if not global.link_providables then global.link_providables = {} end

  -- CHESTS
  -- if not global.link_provider_chests then global.link_provider_chests = {} end
  for unit_number, data in pairs(global.link_provider_chests) do
    local entity = data.entity
    local inventory = data.inventory
    if entity and entity.valid and not entity.to_be_deconstructed(entity.force) then
      local items = inventory.get_contents()
      if table_size(items) > 0 then
        for item_name, item_count in pairs(items) do
          if not global.link_providables[item_name] then
            global.link_providables[item_name] = item_count
          else
            global.link_providables[item_name] = global.link_providables[item_name] + item_count
          end
          inventory.remove({name = item_name, count = item_count})
        end
      end
    end
  end

  -- POWER
  -- if not global.link_electrical_providers then global.link_electrical_providers = {} end
  for unit_number, data in pairs(global.link_electrical_providers) do
    local entity = data.entity
    if entity and entity.valid and not entity.to_be_deconstructed(entity.force) then
      local energy = math.floor(entity.energy)
      if energy > 0 then
        link_log("POWER", string.format("Energy: %d", energy))
        if not global.link_providables[LINK_ELECTRICAL_ITEM_NAME] then
          global.link_providables[LINK_ELECTRICAL_ITEM_NAME] = energy
        else
          global.link_providables[LINK_ELECTRICAL_ITEM_NAME] = global.link_providables[LINK_ELECTRICAL_ITEM_NAME] + energy
        end
        entity.energy = entity.energy - energy
      end
    end
  end

  -- FLUID
  -- if not global.link_fluid_providers then global.link_fluid_providers = {} end
  for unit_number, data in pairs(global.link_fluid_providers) do
    local entity = data.entity
    if entity and entity.valid and not entity.to_be_deconstructed(entity.force) then
      local fluid = entity.fluidbox[1]
      if fluid and (fluid.amount - 1) > 1 then
        local fluid_amount = math.floor(fluid.amount - 1)
        link_log("FLUID", string.format("Fluid: %s - %d", fluid.name, fluid_amount))
        if not global.link_providables[fluid.name] then
          global.link_providables[fluid.name] = fluid_amount
        else
          global.link_providables[fluid.name] = global.link_providables[fluid.name] + fluid_amount
        end
        fluid.amount = fluid.amount - fluid_amount
        entity.fluidbox[1] = fluid
      end
    end
  end

  rcon.print(game.table_to_json(global.link_providables))
  global.link_providables = {}
end

function get_link_requests()
  global.ticks_since_last_link_operation = 0

  local link_requests = {}

  -- CHESTS
  -- if not global.link_requester_chests then global.link_requester_chests = {} end
  for unit_number, data in pairs(global.link_requester_chests) do
    local entity = data.entity
    if entity and entity.valid and not entity.to_be_deconstructed(entity.force) then
      local inventory = data.inventory
      local filter_count = data.filter_count
      for i = 1, filter_count do
        local requested_item = entity.get_request_slot(i)
        if requested_item then
          current_item_count = inventory.get_item_count(requested_item.name)
          local missing_item_count = requested_item.count - current_item_count
          if missing_item_count > 0 then
            local can_insert = inventory.can_insert({ name = requested_item.name, count = missing_item_count })
            if can_insert then
              -- calculate per entity totals for the fulfillments
              if not link_requests[unit_number] then link_requests[unit_number] = {} end
              link_requests[unit_number][requested_item.name] = missing_item_count
            end
          end
        end
      end
    end
  end

  -- POWER
  -- if not global.link_electrical_requesters then global.link_electrical_requesters = {} end
  for unit_number, data in pairs(global.link_electrical_requesters) do
    local entity = data.entity
    if entity and entity.valid and not entity.to_be_deconstructed(entity.force) then
      local buffer_size = entity.electric_buffer_size
      local energy = entity.energy
      local needed_energy = math.floor(buffer_size - energy)
      if needed_energy > 0 then
        if not link_requests[unit_number] then link_requests[unit_number] = {} end
        link_requests[unit_number][LINK_ELECTRICAL_ITEM_NAME] = needed_energy
      end
    end
  end

  -- FLUID
  -- if not global.link_fluid_requesters then global.link_fluid_requesters = {} end
  for unit_number, data in pairs(global.link_fluid_requesters) do
    local entity = data.entity
    if entity and entity.valid and not entity.to_be_deconstructed(entity.force) then
      local recipe = entity.get_recipe()
      if recipe then
        local fluid_name = recipe.products[1].name
        local fluid = entity.fluidbox[1] or { name = fluid_name, amount = 0 }
        local fluid_amount = math.floor(fluid.amount)
        local needed_fluid = math.ceil(LINK_FLUID_MAX - fluid_amount)
        if needed_fluid > 0 then
          if not link_requests[unit_number] then link_requests[unit_number] = {} end
          link_requests[unit_number][fluid_name] = needed_fluid
        end
      end
    end
  end

  rcon.print(game.table_to_json(link_requests))
end

function set_link_fulfillments(data)
  global.ticks_since_last_link_operation = 0

  if not global.link_providables then global.link_providables = {} end

  local link_fulfillments = game.json_to_table(data)
  for unit_number, items in pairs(link_fulfillments) do
    -- CHESTS
    local data = global.link_requester_chests[tonumber(unit_number)]
    if data then
      local entity = data.entity
      if entity and entity.valid and not entity.to_be_deconstructed(entity.force) then
        link_log("ITEMS", "Received")
        local inventory = data.inventory
        local items_to_insert = {}
        for item_name, item_count in pairs(items) do
          item_to_insert = { name = item_name, count = item_count }
          local item_count_inserted = inventory.insert(item_to_insert)
          local item_count_remainder = item_count - item_count_inserted
          if item_count_remainder > 0 then
            if not global.link_providables[item_name] then
              global.link_providables[item_name] = item_count_remainder
            else
              global.link_providables[item_name] = global.link_providables[item_name] + item_count_remainder
            end
          end
        end
      end
    end
    -- POWER
    local data = global.link_electrical_requesters[tonumber(unit_number)]
    if data then
      local entity = data.entity
      if entity and entity.valid and not entity.to_be_deconstructed(entity.force) then
        link_log("POWER", "Received")
        local energy = entity.energy
        for _, provided_energy in pairs(items) do
          if provided_energy and provided_energy > 0 then
            entity.energy = energy + provided_energy
          end
        end
      end
    end
    -- FLUID
    local data = global.link_fluid_requesters[tonumber(unit_number)]
    if data then
      local entity = data.entity
      if entity and entity.valid and not entity.to_be_deconstructed(entity.force) then
        link_log("FLUID", "Received")
        for fluid_name, provided_fluid in pairs(items) do
          local fluid = entity.fluidbox[1] or { name = fluid_name, amount = 0 }
          if provided_fluid and provided_fluid > 0 then
            fluid.amount = fluid.amount + provided_fluid
            entity.fluidbox[1] = fluid
          end
        end
      end
    end
  end

  rcon.print("OK")
end
