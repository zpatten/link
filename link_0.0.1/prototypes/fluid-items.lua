for _, fluid in pairs(data.raw.fluid) do
  local fluid_item = {}
  fluid_item.icons = {
    {
      icon = data.raw.fluid[fluid.name].icon,
      icon_size = 32,
      tint = LINK_TINT
    }
  }
  fluid_item.name = link_format_fluid_name(fluid.name)
  fluid_item.order = string.format(LINK_FLUID_ORDER, link_format_fluid_name(fluid.name))
  fluid_item.subgroup = LINK_FLUID_ITEM_SUBGROUP_NAME
  fluid_item.stack_size = LINK_FLUID_MAX
  fluid_item.type = "item"

  data:extend{ fluid_item }
end
