local link_groups = {
  {
    type = "item-group",
    name = LINK_GROUP_NAME,
    inventory_order = "z",
    order = "z",
    icon = "__base__/graphics/item-group/production.png",
    icon_size = 64
  },
  {
    type = "item-subgroup",
    name = LINK_CHEST_SUBGROUP_NAME,
    group = LINK_GROUP_NAME,
    order = "a",
    -- icon = "__base__/graphics/item-group/production.png",
    -- icon_size = 64
  },
  {
    type = "item-subgroup",
    name = LINK_ELECTRICAL_SUBGROUP,
    group = LINK_GROUP_NAME,
    order = "b",
    -- icon = "__base__/graphics/item-group/production.png",
    -- icon_size = 64
  },
  {
    type = "item-subgroup",
    name = LINK_FLUID_RECIPE_SUBGROUP_NAME,
    group = LINK_GROUP_NAME,
    order = "c",
    -- icon = "__base__/graphics/item-group/production.png",
    -- icon_size = 64
  },
  {
    type = "item-subgroup",
    name = LINK_FLUID_SUBGROUP_NAME,
    group = LINK_GROUP_NAME,
    order = "d",
    -- icon = "__base__/graphics/item-group/production.png",
    -- icon_size = 64
  },
  {
    type = "item-subgroup",
    name = LINK_SIGNAL_SUBGROUP_NAME,
    group = LINK_GROUP_NAME,
    order = "e",
    -- icon = "__base__/graphics/item-group/production.png",
    -- icon_size = 64
  }
}

data:extend(link_groups)
