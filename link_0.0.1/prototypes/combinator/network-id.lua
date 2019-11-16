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

-- local recipe = table.deepcopy(data.raw.recipe["constant-combinator"])
-- recipe.enabled = true
-- recipe.hidden = true
-- recipe.name = LINK_NETWORK_ID_COMBINATOR_NAME
-- recipe.order = string.format(LINK_COMBINATOR_ORDER, LINK_NETWORK_ID_COMBINATOR_NAME)
-- recipe.result = LINK_NETWORK_ID_COMBINATOR_NAME
-- recipe.subgroup = LINK_COMBINATOR_SUBGROUP_NAME
-- link_add_tint(recipe)


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

-- local item = table.deepcopy(data.raw.item["constant-combinator"])
-- -- item.icons = { { icon = item.icon, tint = LINK_TINT } }
-- item.name = LINK_NETWORK_ID_COMBINATOR_NAME
-- item.order = string.format(LINK_COMBINATOR_ORDER, LINK_NETWORK_ID_COMBINATOR_NAME)
-- item.place_result = LINK_NETWORK_ID_COMBINATOR_NAME
-- item.subgroup = LINK_COMBINATOR_SUBGROUP_NAME
-- link_add_tint(item)


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

-- local entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
-- -- entity.icons = { { icon = entity.icon, tint = LINK_TINT } }
-- entity.item_slot_count = 1
-- entity.minable = { mining_time = 0.5, result = LINK_NETWORK_ID_COMBINATOR_NAME }
-- entity.name = LINK_NETWORK_ID_COMBINATOR_NAME
-- link_add_tint(entity)

link_extend_data({
  recipe,
  item,
  entity
})

--------------------------------------------------------------------------------
-- data:extend{ recipe, item, entity }
--------------------------------------------------------------------------------
