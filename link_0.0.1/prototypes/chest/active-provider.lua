local localised_description = 'Actively provides contents to the Link.'


--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = link_build_data({
  inherit = data.raw.recipe['logistic-chest-active-provider'],
  type = 'recipe',
  what = 'chest',
  which = 'active-provider',
  attributes = {
    localised_description = localised_description
  }
})


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = link_build_data({
  inherit = data.raw.item['logistic-chest-active-provider'],
  type = 'item',
  what = 'chest',
  which = 'active-provider',
  attributes = {
    localised_description = localised_description
  }
})


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = link_build_data({
  inherit = data.raw.container['steel-chest'],
  what = 'chest',
  which = 'active-provider',
  attributes = {
    inventory = 60,
    picture = table.deepcopy(data.raw['logistic-container']['logistic-chest-active-provider'].animation),
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
