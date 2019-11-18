local localised_name = 'Link Network ID'
local localised_description = 'Specifies the network ID for a Link circuit network.'


--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = link_build_data({
  inherit = data.raw.recipe['constant-combinator'],
  type = 'recipe',
  what = 'combinator',
  which = 'network-id',
  attributes = {
    hidden = true,
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
  which = 'network-id',
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
  which = 'network-id',
  attributes = {
    item_slot_count = 1,
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
