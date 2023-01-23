local localised_description = 'Requests specified items from the Link acting as a buffer chest for the logistic network.'


--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = link_build_data({
  inherit = data.raw.recipe['logistic-chest-buffer'],
  type = 'recipe',
  what = 'chest',
  which = 'buffer',
  attributes = {
    localised_description = localised_description
  }
})


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = link_build_data({
  inherit = data.raw.item['logistic-chest-buffer'],
  type = 'item',
  what = 'chest',
  which = 'buffer',
  attributes = {
    localised_description = localised_description
  }
})


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = link_build_data({
  inherit = data.raw['logistic-container']['logistic-chest-buffer'],
  what = 'chest',
  which = 'buffer',
  attributes = {
    inventory_size = 60,
    max_logistic_slots = 30,
    render_not_in_network_icon = false,
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
