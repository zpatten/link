--------------------------------------------------------------------------------
-- SUBGROUP
--------------------------------------------------------------------------------
local subgroup = link_build_data({
  type = 'item-subgroup',
  what = 'fluid-item'
})
link_extend_data({subgroup})


--------------------------------------------------------------------------------
-- FLUID ITEMS
--------------------------------------------------------------------------------
for _, fluid in pairs(data.raw.fluid) do
  local fluid_name = capitalize(string.gsub(fluid.name, '-', ' '))
  local localised_name = string.format('Link %s', fluid_name)
  local localised_description = string.format('Link item for transmitting and receiving %s.', fluid_name)

  local fluid_item = link_build_data({
    type = 'item',
    name = fluid.name,
    what = 'fluid',
    place_result = false,
    attributes = {
      localised_name = localised_name,
      localised_description = localised_description,
      icon = data.raw.fluid[fluid.name].icon,
      stack_size = LINK_FLUID_RECIPE_AMOUNT,
      subgroup = 'fluid-item'
    }
  })
  -- local fluid_item = {}
  -- fluid_item.icon = data.raw.fluid[fluid.name].icon
  -- fluid_item.icon_size = 32
  -- fluid_item = link_build_item_data(fluid_item, 'fluid', fluid.name)
  -- fluid_item.name = link_format_fluid_name(fluid.name)
  -- fluid_item.order = link_format_fluid_order(fluid.name)
  -- fluid_item.stack_size = LINK_FLUID_RECIPE_AMOUNT
  -- fluid_item.subgroup = LINK_FLUID_SUBGROUP_NAME
  -- fluid_item.type = 'item'

  -- link_add_tint(fluid_item)

  -- log(string.format("-----\n%s", inspect(fluid_item)))
  -- data:extend({fluid_item})
  link_extend_data({fluid_item})
end
