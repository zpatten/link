local localised_name = 'Link Sensor'
local localised_description = 'Provides the contents of the Link via a circuit network.  Provides signals for items, fluids and electricity.'


--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = link_build_data({
  inherit = data.raw.recipe['constant-combinator'],
  type = 'recipe',
  what = 'combinator',
  which = 'inventory',
  attributes = {
    localised_name = localised_name,
    localised_description = localised_description
  }
})


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = link_build_data({
  inherit = data.raw.item['constant-combinator'],
  type = 'item',
  what = 'combinator',
  which = 'inventory',
  attributes = {
    localised_name = localised_name,
    localised_description = localised_description
  }
})


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = link_build_data({
  inherit = data.raw['constant-combinator']['constant-combinator'],
  what = 'combinator',
  which = 'inventory',
  attributes = {
    item_slot_count = 1024,
    localised_name = localised_name,
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
