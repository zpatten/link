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
local subgroup = link_build_data({
  type = 'item-subgroup',
  what = 'combinator'
})
link_extend_data({subgroup})
