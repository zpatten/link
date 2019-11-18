local localised_description = 'Provides contents to the Link acting as a storage chest for the logistic network.'


--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = link_build_data({
  inherit = data.raw.recipe['logistic-chest-storage'],
  type = 'recipe',
  what = 'chest',
  which = 'storage',
  attributes = {
    localised_description = localised_description
  }
})


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = link_build_data({
  inherit = data.raw.item['logistic-chest-storage'],
  type = 'item',
  what = 'chest',
  which = 'storage',
  attributes = {
    localised_description = localised_description
  }
})


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = link_build_data({
  inherit = data.raw['logistic-container']['logistic-chest-storage'],
  what = 'chest',
  which = 'storage',
  attributes = {
    inventory = 60,
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
