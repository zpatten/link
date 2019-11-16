local localised_description = 'Actively provides its contents to the Link inventory'

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

-- local recipe = table.deepcopy(data.raw.recipe['logistic-chest-active-provider'])
-- recipe.enabled = true
-- recipe.name = LINK_ACTIVE_PROVIDER_CHEST_NAME
-- recipe.order = string.format(LINK_CHEST_ORDER, LINK_ACTIVE_PROVIDER_CHEST_NAME)
-- recipe.result = LINK_ACTIVE_PROVIDER_CHEST_NAME
-- recipe.subgroup = LINK_CHEST_SUBGROUP_NAME
-- link_add_tint(recipe)


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

-- local item = table.deepcopy(data.raw.item['logistic-chest-active-provider'])
-- -- item.icons = { { icon = item.icon, tint = LINK_TINT } }
-- item.name = LINK_ACTIVE_PROVIDER_CHEST_NAME
-- item.order = string.format(LINK_CHEST_ORDER, LINK_ACTIVE_PROVIDER_CHEST_NAME)
-- item.place_result = LINK_ACTIVE_PROVIDER_CHEST_NAME
-- item.subgroup = LINK_CHEST_SUBGROUP_NAME
-- link_add_tint(item)


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

-- local entity = table.deepcopy(data.raw.container['steel-chest'])
-- -- entity.icons = { { icon = entity.icon, tint = LINK_TINT } }
-- entity.icon = data.raw['logistic-container']['logistic-chest-active-provider'].icon
-- entity.inventory = 60
-- entity.minable = { mining_time = 0.5, result = LINK_ACTIVE_PROVIDER_CHEST_NAME }
-- entity.name = LINK_ACTIVE_PROVIDER_CHEST_NAME
-- entity.picture = table.deepcopy(data.raw['logistic-container']['logistic-chest-active-provider'].animation)
-- link_add_tint(entity)


link_extend_data({
  recipe,
  item,
  entity
})

--------------------------------------------------------------------------------
-- data:extend{ recipe, item, entity }
--------------------------------------------------------------------------------
