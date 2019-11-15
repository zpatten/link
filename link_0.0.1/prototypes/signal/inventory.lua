--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = link_build_data({
  inherit = data.raw.recipe['constant-combinator'],
  type = 'recipe',
  what = 'signal',
  which = 'inventory',
  lname = 'Link Inventory',
  ldescription = 'Provides the contents of the Link inventory via a circuit network'
})

-- local recipe = table.deepcopy(data.raw.recipe["constant-combinator"])
-- recipe.enabled = true
-- recipe.name = LINK_INVENTORY_COMBINATOR_NAME
-- recipe.order = string.format(LINK_COMBINATOR_ORDER, LINK_INVENTORY_COMBINATOR_NAME)
-- recipe.result = LINK_INVENTORY_COMBINATOR_NAME
-- recipe.subgroup = LINK_COMBINATOR_SUBGROUP_NAME
-- link_add_tint(recipe)


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = link_build_data({
  inherit = data.raw.item['constant-combinator'],
  type = 'item',
  what = 'signal',
  which = 'inventory',
  lname = 'Link Inventory',
  ldescription = 'Provides the contents of the Link inventory via a circuit network'
})


-- local item = table.deepcopy(data.raw.item["constant-combinator"])
-- -- item.icons = { { icon = item.icon, tint = LINK_TINT } }
-- item.name = LINK_INVENTORY_COMBINATOR_NAME
-- item.order = string.format(LINK_COMBINATOR_ORDER, LINK_INVENTORY_COMBINATOR_NAME)
-- item.place_result = LINK_INVENTORY_COMBINATOR_NAME
-- item.subgroup = LINK_COMBINATOR_SUBGROUP_NAME
-- link_add_tint(item)


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = link_build_data({
  inherit = data.raw['constant-combinator']['constant-combinator'],
  what = 'signal',
  which = 'inventory',
  lname = 'Link Inventory',
  ldescription = 'Provides the contents of the Link inventory via a circuit network',
  item_slot_count = 1024
})

-- local entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
-- -- entity.icons = { { icon = entity.icon, tint = LINK_TINT } }
-- entity.item_slot_count = 1024
-- entity.minable = { mining_time = 0.5, result = LINK_INVENTORY_COMBINATOR_NAME }
-- entity.name = LINK_INVENTORY_COMBINATOR_NAME
-- link_add_tint(entity)

print(string.format("--------------------\n%s\n", serpent.block(entity)))

link_extend_data({
  recipe,
  item,
  entity
})

--------------------------------------------------------------------------------
-- data:extend{ recipe, item, entity }
--------------------------------------------------------------------------------
