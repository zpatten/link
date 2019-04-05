function get_link_providables()
  global.ticks_since_last_link_operation = 0

  local link_providables = {}
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

  rcon.print(game.table_to_json(link_providables))
end

function get_link_requests()
  global.ticks_since_last_link_operation = 0

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
            if not link_requests[unit_number] then
              link_requests[unit_number] = {}
            end
            link_requests[unit_number][requested_item.name] = missing_item_count
          end
        end
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
    local inventory = data.inventory
    local items_to_insert = {}
    for item_name, item_count in pairs(items) do
      item_to_insert = { name = item_name, count = item_count }
      inventory.insert(item_to_insert)
    end
  end

  rcon.print("OK")
end
