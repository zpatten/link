local localised_description = 'Requests electricity from the Link.'


--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = link_build_data({
  inherit = data.raw.recipe['accumulator'],
  type = 'recipe',
  what = 'electrical',
  which = 'requester',
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
  which = 'requester',
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
  which = 'requester',
  attributes = {
    energy_source = {
      buffer_capacity = LINK_ELECTRICAL_BUFFER_CAPACITY,
      input_flow_limit = '0kW',
      output_flow_limit = LINK_ELECTRICAL_FLOW_LIMIT,
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
