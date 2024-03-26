local localised_description = 'Transmits signals to a Link circuit network.'


--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = link_build_data({
  inherit = data.raw.recipe['decider-combinator'],
  type = 'recipe',
  what = 'combinator',
  which = 'transmitter',
  attributes = {
    localised_description = localised_description
  }
})


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = link_build_data({
  inherit = data.raw.item['decider-combinator'],
  type = 'item',
  what = 'combinator',
  which = 'transmitter',
  attributes = {
    localised_description = localised_description
  }
})


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = link_build_data({
  inherit = data.raw['decider-combinator']['decider-combinator'],
  what = 'combinator',
  which = 'transmitter',
  attributes = {
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
