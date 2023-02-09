--------------------------------------------------------------------------------

function link_format_fluid_name(fluid_name)
  return string.format("link-fluid-%s", fluid_name)
end

function link_extract_fluid_name(fluid_name)
  return string.sub(fluid_name, string.len('link-fluid-') + 1, -1)
end

function dasherize(str)
  str = string.gsub(str, ' ', '-')
  str = string.gsub(str, '_', '-')
  return str
end

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

  if o.type == 'recipe' then
    o.enabled = true
    if args.attributes.ingredients then
      o.category = string.format('link-%s-%s', args.what, args.which)
      o.hide_from_player_crafting = true
      o.return_ingredients_on_change = false
    end
    if not args.attributes.results then
      o.result = o.name
    end
  elseif o.type == 'item' and args.place_result ~= false then
    o.place_result = o.name
  end

  if o.type == 'item-group' then
    o.order = 'z'
  elseif o.type == 'item-subgroup' then
    o.group = 'link-group'
    o.order = string.sub(args.what, 1, 1)
  else
    o.order = string.format('%s-[%s]', string.sub(args.what, 1, 1), o.name)
    o.subgroup = string.format('link-%s', args.what)
  end

  o.localised_name = string.format('%s', capitalize(string.gsub(o.name, '-', ' ')))
  o.localised_description = string.format('D: %s', capitalize(string.gsub(o.name, '-', ' ')))

  if args.attributes then
    for key, value in pairs(args.attributes) do
      if key == 'subgroup' then
        value = string.format('link-%s', value)
      end

      o[key] = value
    end
  end

  local t = LINK_TINTS[o.name] or LINK_TINT

  if o.type ~= 'shortcut' then
    link_add_tint(o, t)
  end

  return o
end

--------------------------------------------------------------------------------

function link_log(what, message)
  if global.link_debug then
    log(string.format("[LINK:%s] %s", what, message))
  end
end

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

-- http://lua-users.org/wiki/SimpleRound
function round(num, numDecimalPlaces)
  return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

--------------------------------------------------------------------------------

function link_tint_layers(layers, tint)
  if layers then
    for _, layer in pairs(layers) do
      link_tint_layer(layer, tint)
    end
  end
end

function link_tint_layer(layer, tint)
  local t = tint or LINK_TINT

  if layer.layers then
    link_tint_layers(layer.layers, tint)
  else
    if layer.hr_version then
      layer.hr_version.tint = t
    end
    layer.tint = t
  end
end

function link_tint_icon(o, tint)
  local t = tint or LINK_TINT

  if o.icon then
    if not o.icons then
      o.icons = {
        {
          icon = o.icon,
          icon_size = o.icon_size or 64
        }
      }
    end
  end
  if o.icons then
    for _, icon in pairs(o.icons) do
      icon.tint = t
    end
  end
end

function link_add_tint(o, tint)
  link_tint_icon(o, tint)

  if o.animation then
    link_tint_layers(o.animation.layers, tint)
  end

  if o.charge_animation then
    link_tint_layers(o.charge_animation.layers, tint)
  end

  if o.discharge_animation then
    link_tint_layers(o.discharge_animation.layers, tint)
  end

  if o.picture then
    link_tint_layers(o.picture.layers, tint)
  end

  if o.pictures and o.pictures.picture then
    link_tint_layers(o.pictures.picture.sheets, tint)
  end

  if o.sprites then
    for _, direction in pairs(o.sprites) do
      link_tint_layers(direction.layers, tint)
    end
  end

  if o.fluid_box and o.fluid_box.pipe_covers then
    for _, direction in pairs(o.fluid_box.pipe_covers) do
      link_tint_layers(direction.layers, tint)
    end
  end

  if o.fluid_boxes then
    for _, fluid_box in pairs(o.fluid_boxes) do
      if type(fluid_box) == 'table' then
        if fluid_box.pipe_covers then
          for _, direction in pairs(fluid_box.pipe_covers) do
            link_tint_layers(direction.layers, tint)
          end
        end
        if fluid_box.pipe_picture then
          for _, direction in pairs(fluid_box.pipe_picture) do
            link_tint_layer(direction, tint)
          end
        end
      end
    end
  end

end

--------------------------------------------------------------------------------
