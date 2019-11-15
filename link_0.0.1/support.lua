inspect = require "inspect"

--------------------------------------------------------------------------------

function link_format_fluid_name(fluid_name)
  return string.format("link-fluid-%s", fluid_name)
end

function link_extract_fluid_name(fluid_name)
  return string.sub(fluid_name, string.len('link-fluid-') + 1, -1)
end

-- function link_format_fluid_recipe_name(fluid_name, recipe_type)
--   return string.format("%s-%s", link_format_fluid_name(fluid_name), recipe_type)
-- end

-- function link_format_subgroup(subgroup_name, subgroup_type)
--   return string.format("%s-%s", subgroup_name, subgroup_type)
-- end

-- function link_format_fluid_order(fluid_name)
--   link_format_order(LINK_FLUID_ORDER_FORMAT, link_format_fluid_name(fluid.name))
-- end

-- function link_format_order(order_format, name)
--   string.format(order_format, name)
-- end

--------------------------------------------------------------------------------

function titleCase(first, rest)
   return first:upper()..rest:lower()
end

function capitalize(str)
  return string.gsub(str, "(%a)([%w_']*)", titleCase)
end

function link_extend_data(d)
  -- print(string.format("--------------------\n%s\n", serpent.block(d)))
  -- log(string.format("--------------------\n%s\n", serpent.block(d)))
  data:extend(d)
end

function strcopy(str)
  return string.format('%s', str)
end

function link_build_data(args)
  local o

  if args.inherit then
    o = table.deepcopy(args.inherit)
  else
    o = {}
  end

  if args.type then
    o.type = args.type
  end
  if not args.subgroup then
    args.subgroup = args.what
  end

  if args.name and args.which then
    o.name = string.format('link-%s-%s-%s', args.what, args.which, args.name)
  elseif args.name and not args.which then
    o.name = string.format('link-%s-%s', args.what, args.name)
  elseif args.which then
    o.name = string.format('link-%s-%s', args.what, args.which)
  else
    o.name = string.format('link-%s', args.what)
  end

  if args.icon then
    o.icon = args.icon
    if args.icon_size then
      o.icon_size = args.icon_size
    else
      o.icon_size = 32
    end
  end

  if o.crafting_categories then
    o.crafting_categories = { o.name }
  end

  if args.hidden then
    o.hidden = true
  end

  if args.item_slot_count then
    o.item_slot_count = args.item_slot_count
  end

  if o.minable then
    o.minable = {
      mining_time = 0.5,
      result = o.name
    }
  end

  if o.module_specification then
    o.module_specification = {
      module_slots = 0
    }
  end

  if args.stack_size then
    o.stack_size = args.stack_size
  end

  if args.fluid_boxes then
    o.fluid_boxes = args.fluid_boxes
  end

  if args.energy_source then
    o.energy_source = args.energy_source
    o.energy_source.type = 'electrical'
    o.energy_source.usage_priority = 'tertiary'
  end

  if args.inventory then
    o.inventory = args.inventory
  end

  if args.picture then
    o.picture = table.deepcopy(args.picture)
  end

  if o.type == 'recipe' then
    o.enabled = true
    if args.energy_required then
      o.energy_required = args.energy_required
    end
    if args.ingredients then
      o.ingredients = args.ingredients
      o.category = string.format('link-%s-%s', args.what, args.which)
      o.hide_from_player_crafting = true
      o.return_ingredients_on_change = false
    end
    if args.results then
      o.results = args.results
    else
      o.result = o.name
    end
  elseif o.type == 'item' and args.place_result ~= false then
    o.place_result = o.name
  end

  if o.type == 'item-group' then
    o.order = 'z'
  elseif o.type == 'item-subgroup' then
    o.group = LINK_GROUP_NAME
    o.order = string.sub(args.what, 1, 1)
  else
    o.order = string.format('%s-[%s]', string.sub(args.what, 1, 1), o.name)
    o.subgroup = string.format('link-%s', args.subgroup)
  end

  if args.lname then
    o.localised_name = args.lname
  else
    o.localised_name = string.format('%s', capitalize(string.gsub(o.name, '-', ' ')))
  end

  if args.ldescription then
    o.localised_description = args.ldescription
  else
    o.localised_description = string.format('D: %s', capitalize(string.gsub(o.name, '-', ' ')))
  end

  if args.attributes then
    for key, value in pairs(args.attributes) do
      o[key] = value
    end
  end

  link_add_tint(o)

  return o
end

--------------------------------------------------------------------------------

function link_log(what, message)
  if global.link_debug then
    log(string.format("[LINK:%s] %s", what, message))
  end
end

--------------------------------------------------------------------------------

-- https://stackoverflow.com/questions/2705793/how-to-get-number-of-entries-in-a-lua-table
-- function table_count(t)
--   local count = 0
--   if not t then
--     return 0
--   end
--   for _ in pairs(t) do count = count + 1 end
--   return count
-- end

--------------------------------------------------------------------------------

function uniq(a)
  local hash = {}
  local res = {}

  for _,v in ipairs(a) do
    if (not hash[v]) then
      res[#res+1] = v -- you could print here instead of saving to result table if you wanted
      hash[v] = true
    end
  end

  return res
end

--------------------------------------------------------------------------------

-- https://stackoverflow.com/questions/9168058/how-to-dump-a-table-to-console
-- function dump(o, indent)
--   if not indent then
--     indent = 0
--   end

--   indent_str = string.rep(" ", indent)

--   if type(o) == 'table' then
--     local s = string.format("{ \n")
--     for k,v in pairs(o) do
--       if type(k) ~= 'number' then k = string.format("%s\"%s\"", indent_str, k) end
--       if type(v) == 'table' then
--         s = string.format("%s%s[%s] = %s", indent_str, s, k, dump(v, indent + 2))
--       else
--         s = string.format("%s%s[%s] = %s,\n", indent_str, s, k, tostring(v))
--       end
--     end
--     return string.format("%s%s }\n", indent_str, s)
--   elseif type(o) == "number" then
--     return string.format("%s%f\n", indent_str, tonumber(o))
--   else
--     return string.format("%s%s\n", indent_str, tostring(o))
--   end
-- end

-- http://lua-users.org/wiki/SimpleRound
function round(num, numDecimalPlaces)
  return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

--------------------------------------------------------------------------------

function link_tint_layers(layers)
  if layers then
    for _, layer in pairs(layers) do
      link_tint_layer(layer)
    end
  end
end

function link_tint_layer(layer)
  if layer.layers then
    link_tint_layers(layer.layers)
  else
    if layer.hr_version then
      layer.hr_version.tint = LINK_TINT
    end
    layer.tint = LINK_TINT
  end
end

function link_tint_icon(o)
  if o.icon then
    if not o.icons then
      o.icons = {
        {
          icon = o.icon,
          icon_size = o.icon_size or 32
        }
      }
    end
  end
  if o.icons then
    for _, icon in pairs(o.icons) do
      icon.tint = LINK_TINT
    end
  end
end

function link_add_tint(o)
  link_tint_icon(o)

  if o.animation then
    link_tint_layers(o.animation.layers)
    -- for _, layer in pairs(o.animation.layers) do
    --   layer.hr_version.tint = LINK_TINT
    --   layer.tint = LINK_TINT
    -- end
  end

  if o.charge_animation then
    link_tint_layers(o.charge_animation.layers)
  end

  if o.discharge_animation then
    link_tint_layers(o.discharge_animation.layers)
  end

  if o.picture then
    link_tint_layers(o.picture.layers)
    -- for _, layer in pairs(o.picture.layers) do
    --   layer.hr_version.tint = LINK_TINT
    --   layer.tint = LINK_TINT
    -- end
  end

  if o.pictures and o.pictures.picture then
    link_tint_layers(o.pictures.picture.sheets)
    -- for _, layer in pairs(o.pictures.picture.sheets) do
    --   layer.hr_version.tint = LINK_TINT
    --   layer.tint = LINK_TINT
    -- end
  end

  if o.sprites then
    for _, direction in pairs(o.sprites) do
      link_tint_layers(direction.layers)
      -- for _, layer in pairs(direction.layers) do
      --   layer.hr_version.tint = LINK_TINT
      --   layer.tint = LINK_TINT
      -- end
    end
  end

  -- TANKS
  if o.fluid_box and o.fluid_box.pipe_covers then
    for _, direction in pairs(o.fluid_box.pipe_covers) do
      link_tint_layers(direction.layers)
      -- for _, layer in pairs(direction.layers) do
      --   layer.hr_version.tint = LINK_TINT
      --   layer.tint = LINK_TINT
      -- end
    end
  end

  -- ASSEMBLERS
  if o.fluid_boxes then
    for _, fluid_box in pairs(o.fluid_boxes) do
      if type(fluid_box) == 'table' then
        if fluid_box.pipe_covers then
          for _, direction in pairs(fluid_box.pipe_covers) do
            link_tint_layers(direction.layers)
            -- for _, layer in pairs(direction.layers) do
            --   layer.hr_version.tint = LINK_TINT
            --   layer.tint = LINK_TINT
            -- end
          end
        end
        if fluid_box.pipe_picture then
          for _, direction in pairs(fluid_box.pipe_picture) do
            link_tint_layer(direction)
            -- direction.hr_version.tint = LINK_TINT
            -- direction.tint = LINK_TINT
          end
        end
      end
    end
  end

end
