function link_gui_create(player)
  if not global.link_gui then

--------------------------------------------------------------------------------

    global.link_gui = link_gui_frame(player.gui.screen, 'Link')

    tabbed_pane     = link_gui_tabbed_pane(global.link_gui, 'Link Tabbed Pane')

    server_tab      = link_gui_tab(tabbed_pane, 'Servers')
    logistics_tab   = link_gui_tab(tabbed_pane, 'Logistics')
    signals_tab     = link_gui_tab(tabbed_pane, 'Signals')

    -- local server_list_inner_frame = server_tab.add{
    --   type      = 'frame',
    --   name      = 'link-server-list-frame',
    --   style     = 'inventory_frame'
    -- }

    -- local server_list_scroll_pane = server_list_inner_frame.add{
    --   type                     = 'scroll-pane',
    --   name                     = 'link-server-list-scroll-pane',
    --   horizontal_scroll_policy = 'never',
    --   vertical_scroll_policy   = 'auto-and-reserve-space',
    --   style = 'inner_frame_scroll_pane'
    -- }

    -- global.link_gui_servers_table = server_list_scroll_pane.add{
    --   type = 'table',
    --   name = 'link-servers-table',
    --   column_count = 4,
    --   draw_horizontal_lines = true,
    --   draw_horizontal_lines_after_headers = true
    -- }
    global.link_gui_servers_table = link_gui_server_frame(server_tab, 'Servers')
    -- global.link_gui_servers_table.style.width = 400

--------------------------------------------------------------------------------

    global.link_gui_storage_table    = link_gui_logistics_frame(logistics_tab, 'Storage')

--------------------------------------------------------------------------------

    local logistics_flow = logistics_tab.add{
      type      = 'flow',
      name      = 'link-logistics-flow',
      direction = 'vertical'
    }
    global.link_gui_logistics_table_provided    = link_gui_logistics_frame(logistics_flow, 'Provided')
    global.link_gui_logistics_table_requested   = link_gui_logistics_frame(logistics_flow, 'Requested')
    global.link_gui_logistics_table_fulfilled   = link_gui_logistics_frame(logistics_flow, 'Fulfilled')
    global.link_gui_logistics_table_unfulfilled = link_gui_logistics_frame(logistics_flow, 'Unfulfilled')
    global.link_gui_logistics_table_overflow    = link_gui_logistics_frame(logistics_flow, 'Overflow')

--------------------------------------------------------------------------------

    global.link_gui.force_auto_center()

--------------------------------------------------------------------------------

  end
end

function link_gui_frame(parent, caption)
  local frame = parent.add{
    type      = 'frame',
    name      = 'link-gui-frame',
    caption   = caption,
    visible   = false
  }

  -- local inner_frame = global.link_gui.add{
  --   type      = 'frame',
  --   name      = 'link-gui-inner-frame',
  --   direction = 'horizontal',
  --   style     = 'inside_shallow_frame_with_padding'
  -- }

  return frame
end

function link_gui_tabbed_pane(parent, caption)
  local outer_frame = parent.add{
    type = 'frame',
    name = dasherize(string.lower('link-'..caption..'-outer-frame')),
    style = 'inside_deep_frame_for_tabs'
  }

  local tabbed_pane = outer_frame.add{
    type = 'tabbed-pane',
    name = dasherize(string.lower('link-'..caption..'-tabbed-pane')),
    style = 'tabbed_pane_with_extra_padding'
  }
  tabbed_pane.selected_tab_index = 1

  return tabbed_pane
end

function link_gui_tab(parent, caption)
  local tab = parent.add{
    type = 'tab',
    name = dasherize(string.lower('link-'..caption..'-tab')),
    caption = caption
  }
  local frame = parent.add{
    type = 'frame',
    name = dasherize(string.lower('link-'..caption..'-outer-frame')),
    style = 'invisible_frame'
  }
  parent.add_tab(tab, frame)

  return frame
end

function link_gui_server_frame(parent, caption)
  -- local inner_frame = parent.add{
  --   type      = 'frame',
  --   name      = 'link-server-list-frame',
  --   style     = 'inside_shallow_frame_with_padding'
  -- }

  local scroll_pane = parent.add{
    type                     = 'scroll-pane',
    name                     = 'link-server-list-scroll-pane',
    horizontal_scroll_policy = 'never',
    vertical_scroll_policy   = 'auto-and-reserve-space',
    style = 'scroll_frame_in_shallow_frame'
  }

  local server_table = scroll_pane.add{
    type = 'table',
    name = 'link-servers-table',
    column_count = 4,
    draw_horizontal_lines = true,
    draw_horizontal_lines_after_headers = true
  }

  server_table.style.vertically_stretchable  = 'stretch_and_expand'
  server_table.style.horizontally_stretchable = 'stretch_and_expand'
  server_table.style.column_alignments[1] = 'center'
  server_table.style.column_alignments[2] = 'left'
  server_table.style.column_alignments[3] = 'left'
  server_table.style.column_alignments[4] = 'center'

  return server_table
end

function link_gui_logistics_frame(parent, caption)
  local outer_frame = parent.add{
    type = 'frame',
    name = string.lower('link-'..caption..'-outer-frame'),
    style = 'invisible_frame_with_title_for_inventory',
    caption = caption
  }

  local scroll_pane = outer_frame.add{
    type = 'scroll-pane',
    name = string.lower('link-'..caption..'-scroll-pane'),
    style = 'logistics_scroll_pane',
    horizontal_scroll_policy = 'never',
    vertical_scroll_policy = 'auto-and-reserve-space'
  }

  scroll_pane.style.width = 300
  if caption == 'Storage' then
    scroll_pane.style.height = 800
  end

  local inner_frame = scroll_pane.add{
    type = 'frame',
    name = string.lower('link-'..caption..'-inner-frame'),
    style = 'logistics_scroll_pane_background_frame'
  }

  local logistics_slot_table = inner_frame.add{
    type = 'table',
    name = string.lower('link-'..caption..'-table'),
    style = 'logistics_slot_table',
    column_count = 7
  }

  return logistics_slot_table
end

function link_gui_servers_table_update(player)
  if global.link_gui_servers_table and global.link_gui_servers_table.valid then
    global.link_gui_servers_table.clear()
    global.link_gui_servers_table.add{
      type = 'label',
      caption = ''
    }
    global.link_gui_servers_table.add{
      type = 'label',
      caption = 'Name'
    }
    global.link_gui_servers_table.add{
      type = 'label',
      caption = 'Details'
    }
    global.link_gui_servers_table.add{
      type = 'label',
      caption = 'RTT'
    }
    if global.link_server_list then
      for _, server in pairs(global.link_server_list) do
        global.link_gui_servers_table.add{
          name = server.name,
          type = 'button',
          caption = 'Connect'
        }
        global.link_gui_servers_table.add{
          type = 'label',
          caption = server.name
        }
        if server.research then
          global.link_gui_servers_table.add{
            type = 'label',
            caption = '[RESEARCH]',
            style = 'bold_green_label'
          }
        else
          global.link_gui_servers_table.add{
            type = 'label',
            caption = ''
          }
        end
        global.link_gui_servers_table.add{
          type = 'label',
          caption = tostring(server.rtt)
        }
      end
    end
  end
end

function link_gui_logistics_frame_update(gui, items, yellow_items, red_items)
  if gui and gui.valid then
    gui.clear()
    if items then
      for item_name, item_count in pairs(items) do
        if item_name ~= 'electricity' then
          local style = 'logistic_slot_button'
          if yellow_items and yellow_items[item_name] and red_items and red_items[item_name] then
            style = 'yellow_logistic_slot_button'
          elseif red_items and red_items[item_name] then
            style = 'red_logistic_slot_button'
          end
          local sprite = gui.add{
            type = 'sprite-button',
            style = style,
            sprite = lookup_item_type(item_name)..'/'..item_name,
            number = item_count,
            tooltip = item_name
          }
        end
      end
    end
  end
end

function link_gui_destroy(player)
  if global.link_gui and global.link_gui.valid then
    global.link_gui.destroy()
    global.link_gui = nil
  end
end

function link_gui_toggle(player)
  if global.link_gui and global.link_gui.valid then
    global.link_gui.visible = not global.link_gui.visible
  end
end

function on_gui_click(event)
  local player = game.players[event.player_index]
  local element = event.element
  if element.parent.name == 'link-servers-table' then
    server = global.link_server_list[element.name]
    player.connect_to_server{
      address = string.format('%s:%s', server.host, server.port),
      name = server.name
    }
  end
end
script.on_event(defines.events.on_gui_click, on_gui_click)
