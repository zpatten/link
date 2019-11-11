--------------------------------------------------------------------------------
-- PROVIDABLES
--------------------------------------------------------------------------------
function get_link_providables()
  global.ticks_since_last_link_operation = 0

  if not global.link_providables then global.link_providables = {} end

  ------------
  -- CHESTS --
  ------------
  for unit_number, data in pairs(global.link_provider_chests) do
    local entity = data.entity
    local inventory = data.inventory
    if entity and entity.valid and not entity.to_be_deconstructed(entity.force) then
      local items = inventory.get_contents()
      if table_size(items) > 0 then
        for item_name, item_count in pairs(items) do
          removed_item_count = inventory.remove({name = item_name, count = item_count})
          if global.link_providables[item_name] then
            global.link_providables[item_name] = global.link_providables[item_name] + removed_item_count
          else
            global.link_providables[item_name] = removed_item_count
          end
          link_log("ITEM", string.format("Item: %s - %d", item_name, removed_item_count))
        end
      end
    end
  end

  -----------
  -- FLUID --
  -----------
  for unit_number, data in pairs(global.link_fluid_providers) do
    local entity = data.entity
    if entity and entity.valid and not entity.to_be_deconstructed(entity.force) then
      local fluids = entity.get_fluid_contents()
      if table_size(fluids) > 0 then
        for fluid_name, fluid_amount in pairs(fluids) do
          removed_fluid_amount = entity.remove_fluid({name = fluid_name, amount = math.floor(fluid_amount)})
          removed_fluid_amount_adjusted = math.ceil(removed_fluid_amount)
          removed_fluid_amount_remainder = removed_fluid_amount_adjusted - removed_fluid_amount
          if removed_fluid_amount_remainder > 0 then
            entity.insert_fluid({name = fluid_name, amount = removed_fluid_amount_remainder})
          end
          if global.link_providables[fluid_name] then
            global.link_providables[fluid_name] = global.link_providables[fluid_name] + removed_fluid_amount_adjusted
          else
            global.link_providables[fluid_name] = removed_fluid_amount_adjusted
          end
          link_log("FLUID", string.format("Fluid: %s - %d", fluid_name, removed_fluid_amount_adjusted))
        end
      end
    end
  end

  -----------
  -- POWER --
  -----------
  for unit_number, data in pairs(global.link_electrical_providers) do
    local entity = data.entity
    if entity and entity.valid and not entity.to_be_deconstructed(entity.force) then
      local energy = math.floor(entity.energy)
      if energy > 0 then
        entity.energy = entity.energy - energy
        if global.link_providables[LINK_ELECTRICAL_ITEM_NAME] then
          global.link_providables[LINK_ELECTRICAL_ITEM_NAME] = global.link_providables[LINK_ELECTRICAL_ITEM_NAME] + energy
        else
          global.link_providables[LINK_ELECTRICAL_ITEM_NAME] = energy
        end
        link_log("POWER", string.format("Energy: %d", energy))
      end
    end
  end

  rcon.print(game.table_to_json(global.link_providables))
  global.link_providables = {}
end


--------------------------------------------------------------------------------
-- REQUESTS
--------------------------------------------------------------------------------
function get_link_requests()
  global.ticks_since_last_link_operation = 0

  local link_requests = {}

  ------------
  -- CHESTS --
  ------------
  if not global.link_requester_chests then global.link_requester_chests = {} end
  for unit_number, data in pairs(global.link_requester_chests) do
    local entity = data.entity
    local filter_count = data.filter_count
    local inventory = data.inventory
    if entity and entity.valid and not entity.to_be_deconstructed(entity.force) then
      for i = 1, filter_count do
        local requested_item = entity.get_request_slot(i)
        if requested_item then
          local requested_item_name = requested_item.name
          local requested_item_count = requested_item.count
          local current_item_count = inventory.get_item_count(requested_item_name)
          local needed_item_count = math.floor(requested_item_count - current_item_count)
          if needed_item_count > 0 then
            local can_insert = inventory.can_insert({ name = requested_item_name, count = needed_item_count })
            if can_insert then
              if not link_requests[unit_number] then link_requests[unit_number] = {} end
              link_requests[unit_number][requested_item_name] = needed_item_count
            end
          end
        end
      end
    end
  end

  -----------
  -- FLUID --
  -----------
  if not global.link_fluid_requesters then global.link_fluid_requesters = {} end
  for unit_number, data in pairs(global.link_fluid_requesters) do
    local entity = data.entity
    local inventory = data.inventory
    if entity and entity.valid and not entity.to_be_deconstructed(entity.force) then
      local recipe = entity.get_recipe()
      if recipe and recipe.valid then
        local ingredient_name = recipe.ingredients[1].name
        local ingredient_amount = recipe.ingredients[1].amount
        local product_name = recipe.products[1].name
        local current_fluid_amount = inventory.get_item_count(ingredient_name)
        local needed_fluid_amount = math.floor(ingredient_amount - current_fluid_amount)
        if needed_fluid_amount > 0 then
          local can_insert = inventory.can_insert({ name = ingredient_name, count = needed_fluid_amount })
          if can_insert then
            if not link_requests[unit_number] then link_requests[unit_number] = {} end
            link_requests[unit_number][product_name] = needed_fluid_amount
          end
        end
      end
    end
  end

  -----------
  -- POWER --
  -----------
  if not global.link_electrical_requesters then global.link_electrical_requesters = {} end
  for unit_number, data in pairs(global.link_electrical_requesters) do
    local entity = data.entity
    local electric_buffer_size = data.electric_buffer_size
    if entity and entity.valid and not entity.to_be_deconstructed(entity.force) then
      local current_energy = entity.energy
      local needed_energy = math.floor(electric_buffer_size - current_energy)
      if needed_energy > 0 then
        if not link_requests[unit_number] then link_requests[unit_number] = {} end
        link_requests[unit_number][LINK_ELECTRICAL_ITEM_NAME] = needed_energy
      end
    end
  end

  rcon.print(game.table_to_json(link_requests))
end


--------------------------------------------------------------------------------
-- FULFILLMENTS
--------------------------------------------------------------------------------
function set_link_fulfillments(data)
  global.ticks_since_last_link_operation = 0

  if not global.link_providables then global.link_providables = {} end

  local link_fulfillments = game.json_to_table(data)

  for unit_number, items in pairs(link_fulfillments) do

    ------------
    -- CHESTS --
    ------------
    local data = global.link_requester_chests[tonumber(unit_number)]
    if data then
      local entity = data.entity
      if entity and entity.valid and not entity.to_be_deconstructed(entity.force) then
        link_log("ITEMS", "Received")
        local inventory = data.inventory
        -- local items_to_insert = {}
        for item_name, item_count in pairs(items) do
          if item_count > 0 then
            local item_to_insert = { name = item_name, count = item_count }
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
    end

    -----------
    -- FLUID --
    -----------
    local data = global.link_fluid_requesters[tonumber(unit_number)]
    if data then
      local entity = data.entity
      local inventory = data.inventory
      if entity and entity.valid and not entity.to_be_deconstructed(entity.force) then
        link_log("FLUID", "Received")
        for fluid_name, fluid_amount in pairs(items) do
          if fluid_amount > 0 then
            local fluid_to_insert = { name = link_fluid_name(fluid_name), count = fluid_amount }
            local fluid_amount_inserted = entity.insert(fluid_to_insert)
            local fluid_amount_remainder = fluid_amount - fluid_amount_inserted
            if fluid_amount_remainder > 0 then
              if not global.link_providables[fluid_name] then
                global.link_providables[fluid_name] = fluid_amount_remainder
              else
                global.link_providables[fluid_name] = global.link_providables[fluid_name] + fluid_amount_remainder
              end
            end
          end
        end
      end
    end

    -----------
    -- POWER --
    -----------
    local data = global.link_electrical_requesters[tonumber(unit_number)]
    if data then
      local entity = data.entity
      if entity and entity.valid and not entity.to_be_deconstructed(entity.force) then
        link_log("POWER", "Received")
        for _, energy in pairs(items) do
          if energy > 0 then
            entity.energy = entity.energy + energy
          end
        end
      end
    end
  end

  rcon.print("OK")
end
