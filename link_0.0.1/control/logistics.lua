function get_link_providables()
  global.ticks_since_last_link_operation = 0

  local link_providables = {}

  -- CHESTS
  for unit_number, data in pairs(global.link_provider_chests) do
    local entity = data.entity
    local inventory = data.inventory
    if entity.valid and not entity.to_be_deconstructed(entity.force) then
      local items = inventory.get_contents()
      if table_count(items) > 0 then
        for item_name, item_count in pairs(items) do
          if not link_providables[item_name] then
            link_providables[item_name] = item_count
          else
            link_providables[item_name] = link_providables[item_name] + item_count
          end
          inventory.remove({name = item_name, count = item_count})
        end
      end
    end
  end

  -- POWER
  if not global.link_electrical_providers then global.link_electrical_providers = {} end
  for unit_number, data in pairs(global.link_electrical_providers) do
    local entity = data.entity
    if entity.valid and not entity.to_be_deconstructed(entity.force) then
      local energy = math.floor(entity.energy)
      if energy > 0 then
        log(string.format("[POWER] Energy: %d", energy))
        if not link_providables[LINK_ELECTRICAL_ITEM_NAME] then
          link_providables[LINK_ELECTRICAL_ITEM_NAME] = energy
        else
          link_providables[LINK_ELECTRICAL_ITEM_NAME] = link_providables[LINK_ELECTRICAL_ITEM_NAME] + energy
        end
        entity.energy = entity.energy - energy
      end
    end
  end

  -- FLUID
  for unit_number, data in pairs(global.link_fluid_providers) do
    local entity = data.entity
    if entity and entity.valid then
      local fluid = entity.fluidbox[1]
      if fluid then
        local fluid_amount = math.floor(fluid.amount)
        log(string.format("[FLUID] Fluid: %s - %d", fluid.name, fluid_amount))
        if not link_providables[fluid.name] then
          link_providables[fluid.name] = fluid_amount
        else
          link_providables[fluid.name] = link_providables[fluid.name] + fluid_amount
        end
        fluid.amount = fluid.amount - fluid_amount
        entity.fluidbox[1] = fluid
      end
    end
  end

  rcon.print(game.table_to_json(link_providables))
end

function get_link_requests()
  global.ticks_since_last_link_operation = 0

  -- CHESTS
  local link_requests = {}
  for unit_number, data in pairs(global.link_requester_chests) do
    local entity = data.entity
    if entity.valid and not entity.to_be_deconstructed(entity.force) then
      local inventory = data.inventory
      local filter_count = data.filter_count
      for i = 1, filter_count do
        local requested_item = entity.get_request_slot(i)
        if requested_item then
          current_item_count = inventory.get_item_count(requested_item.name)
          local missing_item_count = requested_item.count - current_item_count
          if missing_item_count > 0 then
            -- calculate per entity totals for the fulfillments
            if not link_requests[unit_number] then link_requests[unit_number] = {} end
            link_requests[unit_number][requested_item.name] = missing_item_count
          end
        end
      end
    end
  end

  -- POWER
  if not global.link_electrical_requesters then global.link_electrical_requesters = {} end
  for unit_number, data in pairs(global.link_electrical_requesters) do
    local entity = data.entity
    if entity.valid and not entity.to_be_deconstructed(entity.force) then
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
  for unit_number, data in pairs(global.link_fluid_providers) do
    local entity = data.entity
    if entity and entity.valid then
      local recipe = entity.get_recipe()
      local fluid = entity.fluidbox[1]
      if fluidbox and recipe then
        local fluid_name = recipe.products[1].name
        -- local needed_fluid = LINK_FLUID_MAX -

        -- local fluid = {
        --   name = fluid_name,

        -- }


        local fluid_amount = math.floor(fluid.amount)
        log(string.format("[FLUID] Fluid: %s - %d", fluid.name, fluid_amount))
        if not link_providables[fluid.name] then
          link_providables[fluid.name] = fluid_amount
        else
          link_providables[fluid.name] = link_providables[fluid.name] + fluid_amount
        end
        fluid.amount = fluid.amount - fluid_amount
        entity.fluidbox[1] = fluid
      end
    end
  end

  rcon.print(game.table_to_json(link_requests))
end

function set_link_fulfillments(data)
  global.ticks_since_last_link_operation = 0

  local link_fulfillments = game.json_to_table(data)
  for unit_number, items in pairs(link_fulfillments) do
    local data = global.link_requester_chests[tonumber(unit_number)]
    if data then
      local entity = data.entity
      if entity.valid then
        -- CHESTS
        local inventory = data.inventory
        local items_to_insert = {}
        for item_name, item_count in pairs(items) do
          item_to_insert = { name = item_name, count = item_count }
          inventory.insert(item_to_insert)
        end
      end
    else
      -- POWER
      data = global.link_electrical_requesters[tonumber(unit_number)]
      local entity = data.entity
      if entity.valid then
        log("POWER RX")
        local energy = entity.energy
        for _, provided_energy in pairs(items) do
          if provided_energy and provided_energy > 0 then
            entity.energy = energy + provided_energy
          end
        end
      end
    end
  end

  rcon.print("OK")
end
