local localised_description = 'Provides electricity to the Link.'


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


--------------------------------------------------------------------------------
link_extend_data({
  recipe,
  item,
  entity
})
--------------------------------------------------------------------------------
