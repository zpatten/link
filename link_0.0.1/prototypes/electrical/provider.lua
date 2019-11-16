local localised_description = 'Provides electricity to the Link inventory'

--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = link_build_data({
  inherit = data.raw.recipe['accumulator'],
  type = 'recipe',
  what = 'electrical',
  which = 'provider',
  attributes = {
    localised_description = localised_description
  }
})

-- local recipe = table.deepcopy(data.raw.recipe["accumulator"])
-- recipe.enabled = true
-- recipe.name = LINK_ELECTRICAL_PROVIDER_NAME
-- recipe.order = string.format(LINK_ELECTRICAL_ORDER, LINK_ELECTRICAL_PROVIDER_NAME)
-- recipe.result = LINK_ELECTRICAL_PROVIDER_NAME
-- recipe.subgroup = LINK_ELECTRICAL_SUBGROUP
-- link_add_tint(recipe)


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = link_build_data({
  inherit = data.raw.item['accumulator'],
  type = 'item',
  what = 'electrical',
  which = 'provider',
  attributes = {
    localised_description = localised_description
  }
})

-- local item = table.deepcopy(data.raw.item["accumulator"])
-- item.name = LINK_ELECTRICAL_PROVIDER_NAME
-- item.order = string.format(LINK_ELECTRICAL_ORDER, LINK_ELECTRICAL_PROVIDER_NAME)
-- item.place_result = LINK_ELECTRICAL_PROVIDER_NAME
-- item.subgroup = LINK_ELECTRICAL_SUBGROUP
-- link_add_tint(item)


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = link_build_data({
  inherit = data.raw['accumulator']['accumulator'],
  what = 'electrical',
  which = 'provider',
  attributes = {
    energy_source = {
      buffer_capacity = LINK_ELECTRICAL_BUFFER_CAPACITY,
      input_flow_limit = LINK_ELECTRICAL_FLOW_LIMIT,
      output_flow_limit = '0kW',
      type = 'electrical',
      usage_priority = 'tertiary'
    },
    localised_description = localised_description
  }
})

-- local entity = table.deepcopy(data.raw["accumulator"]["accumulator"])
-- entity.energy_source.buffer_capacity = LINK_ELECTRICAL_BUFFER_CAPACITY
-- entity.energy_source.input_flow_limit = LINK_ELECTRICAL_FLOW_LIMIT
-- entity.energy_source.output_flow_limit = "0kW"
-- entity.minable = { mining_time = 0.5, result = LINK_ELECTRICAL_PROVIDER_NAME }
-- entity.name = LINK_ELECTRICAL_PROVIDER_NAME
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
