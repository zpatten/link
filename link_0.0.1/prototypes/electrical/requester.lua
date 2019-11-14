--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = link_build_data({
  inherit = data.raw.recipe['accumulator'],
  type = 'recipe',
  what = 'electrical',
  which = 'requester'
})

-- local recipe = table.deepcopy(data.raw.recipe["accumulator"])
-- recipe.enabled = true
-- recipe.name = LINK_ELECTRICAL_REQUESTER_NAME
-- recipe.order = string.format(LINK_ELECTRICAL_ORDER, LINK_ELECTRICAL_REQUESTER_NAME)
-- recipe.result = LINK_ELECTRICAL_REQUESTER_NAME
-- recipe.subgroup = LINK_ELECTRICAL_SUBGROUP
-- link_add_tint(recipe)


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = link_build_data({
  inherit = data.raw.item['accumulator'],
  type = 'item',
  what = 'electrical',
  which = 'requester'
})

-- local item = table.deepcopy(data.raw.item["accumulator"])
-- item.name = LINK_ELECTRICAL_REQUESTER_NAME
-- item.order = string.format(LINK_ELECTRICAL_ORDER, LINK_ELECTRICAL_REQUESTER_NAME)
-- item.place_result = LINK_ELECTRICAL_REQUESTER_NAME
-- item.subgroup = LINK_ELECTRICAL_SUBGROUP
-- link_add_tint(item)


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = link_build_data({
  inherit = data.raw['accumulator']['accumulator'],
  what = 'electrical',
  which = 'requester',
  energy_source = {
    buffer_capacity = LINK_ELECTRICAL_BUFFER_CAPACITY,
    input_flow_limit = "0kW",
    output_flow_limit = LINK_ELECTRICAL_FLOW_LIMIT
  }
})

-- local entity = table.deepcopy(data.raw["accumulator"]["accumulator"])
-- entity.energy_source.buffer_capacity = LINK_ELECTRICAL_BUFFER_CAPACITY
-- entity.energy_source.input_flow_limit = "0kW"
-- entity.energy_source.output_flow_limit = LINK_ELECTRICAL_FLOW_LIMIT
-- entity.minable = { mining_time = 0.5, result = LINK_ELECTRICAL_REQUESTER_NAME }
-- entity.name = LINK_ELECTRICAL_REQUESTER_NAME
-- link_add_tint(entity)


link_extend_data({
  recipe,
  item,
  entity
})

--------------------------------------------------------------------------------
-- data:extend{
--   recipe,
--   item,
--   entity
-- }
--------------------------------------------------------------------------------
