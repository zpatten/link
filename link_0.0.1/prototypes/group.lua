-- --------------------------------------------------------------------------------
-- -- FLUID RECIPES
-- --------------------------------------------------------------------------------
-- local link_fluid_provider_recipe_categories = {
--   name = LINK_FLUID_RECIPE_PROVIDER_CATEGORY_NAME,
--   type = "recipe-category"
-- }

-- local link_fluid_requester_recipe_categories = {
--   name = LINK_FLUID_RECIPE_REQUESTER_CATEGORY_NAME,
--   type = "recipe-category"
-- }


-- --------------------------------------------------------------------------------
-- data:extend{
--   link_fluid_provider_recipe_categories,
--   link_fluid_requester_recipe_categories
-- }
-- --------------------------------------------------------------------------------
local group = link_build_data({
  type = 'item-group',
  what = 'group',
  attributes = {
    icons = {
      {
        icon = "__base__/graphics/item-group/logistics.png",
        icon_size = 64,
        tint = LINK_TINT
      }
    },
    inventory_order = 'z',
    order = 'z'
  }
})
link_extend_data({group})
