local link_groups = {
  {
    icons = {
      {
        icon = "__base__/graphics/item-group/logistics.png",
        icon_size = 64,
        tint = LINK_TINT
      }
    },
    type = "item-group",
    name = LINK_GROUP_NAME,
    inventory_order = "z",
    order = "z"
  },
  {
    type = "item-subgroup",
    name = LINK_CHEST_SUBGROUP_NAME,
    group = LINK_GROUP_NAME,
    order = "a"
  },
  {
    type = "item-subgroup",
    name = LINK_ELECTRICAL_SUBGROUP,
    group = LINK_GROUP_NAME,
    order = "b"
  },
  {
    type = "item-subgroup",
    name = LINK_FLUID_RECIPE_SUBGROUP_NAME,
    group = LINK_GROUP_NAME,
    order = "c"
  },
  {
    type = "item-subgroup",
    name = LINK_FLUID_SUBGROUP_NAME,
    group = LINK_GROUP_NAME,
    order = "d"
  },
  {
    type = "item-subgroup",
    name = LINK_FLUID_ITEM_SUBGROUP_NAME,
    group = LINK_GROUP_NAME,
    order = "e"
  },
  {
    type = "item-subgroup",
    name = LINK_COMBINATOR_SUBGROUP_NAME,
    group = LINK_GROUP_NAME,
    order = "f"
  },
  {
    type = "item-subgroup",
    name = LINK_SIGNAL_SUBGROUP_NAME,
    group = LINK_GROUP_NAME,
    order = "g"
  }
}

data:extend(link_groups)
