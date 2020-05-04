local localised_description = 'Receives signals from a Link circuit network.'


--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = link_build_data({
  inherit = data.raw.recipe['constant-combinator'],
  type = 'recipe',
  what = 'combinator',
  which = 'receiver',
  attributes = {
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
  which = 'receiver',
  attributes = {
    localised_description = localised_description
  }
})


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = link_build_data({
  inherit = data.raw['constant-combinator']['constant-combinator'],
  what = 'combinator',
  which = 'receiver',
  attributes = {
    item_slot_count = 1024,
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
