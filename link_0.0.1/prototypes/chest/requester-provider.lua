local localised_description = 'Provides contents to the Link requesting specified items from the logistic network.'


--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = link_build_data({
  inherit = data.raw.recipe['logistic-chest-requester'],
  type = 'recipe',
  what = 'chest',
  which = 'requester-provider',
  attributes = {
    localised_description = localised_description
  }
})


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = link_build_data({
  inherit = data.raw.item['logistic-chest-requester'],
  type = 'item',
  what = 'chest',
  which = 'requester-provider',
  attributes = {
    localised_description = localised_description
  }
})


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = link_build_data({
  inherit = data.raw['logistic-container']['logistic-chest-requester'],
  what = 'chest',
  which = 'requester-provider',
  attributes = {
    inventory = 60,
    logistic_slots_count = 18,
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
