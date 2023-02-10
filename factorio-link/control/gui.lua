function link_gui_create(player)
  if not global.link_gui then

--------------------------------------------------------------------------------

    global.link_gui = link_gui_frame(player.gui.screen, 'Link Control Panel for Server '..capitalize(global.link_name))

    tabbed_pane     = link_gui_tabbed_pane(global.link_gui)

    servers_tab     = link_gui_tab(tabbed_pane, 'Servers')
    logistics_tab   = link_gui_tab(tabbed_pane, 'Logistics')
    signals_tab     = link_gui_tab(tabbed_pane, 'Signals')

--------------------------------------------------------------------------------

    global.link_gui_servers_table = link_gui_server_frame(servers_tab, 'Servers')

--------------------------------------------------------------------------------

    global.link_gui_storage_table = link_gui_logistics_frame(logistics_tab, 'Link Storage')

    local logistics_flow = logistics_tab.add{
      type      = 'flow',
      direction = 'vertical'
    }
    global.link_gui_logistics_table_all_provided    = link_gui_logistics_frame(logistics_flow, 'All Servers: Provided')
    global.link_gui_logistics_table_all_requested   = link_gui_logistics_frame(logistics_flow, 'All Servers: Requested')
    global.link_gui_logistics_table_all_fulfilled   = link_gui_logistics_frame(logistics_flow, 'All Servers: Fulfilled')
    global.link_gui_logistics_table_all_unfulfilled = link_gui_logistics_frame(logistics_flow, 'All Servers: Unfulfilled')
    global.link_gui_logistics_table_all_overflow    = link_gui_logistics_frame(logistics_flow, 'All Servers: Overflow')

    local logistics_flow = logistics_tab.add{
      type      = 'flow',
      direction = 'vertical'
    }
    global.link_gui_logistics_table_provided    = link_gui_logistics_frame(logistics_flow, 'This Server: Provided')
    global.link_gui_logistics_table_requested   = link_gui_logistics_frame(logistics_flow, 'This Server: Requested')
    global.link_gui_logistics_table_fulfilled   = link_gui_logistics_frame(logistics_flow, 'This Server: Fulfilled')
    global.link_gui_logistics_table_unfulfilled = link_gui_logistics_frame(logistics_flow, 'This Server: Unfulfilled')
    global.link_gui_logistics_table_overflow    = link_gui_logistics_frame(logistics_flow, 'This Server: Overflow')

--------------------------------------------------------------------------------

    global.link_gui_signals_table = link_gui_signal_frame(signals_tab, 'Signals')

--------------------------------------------------------------------------------

    global.link_gui.force_auto_center()

--------------------------------------------------------------------------------

  end
end

function link_gui_frame(parent, caption)
  local frame = parent.add{
    type      = 'frame',
    caption   = caption,
    visible   = false
  }

  return frame
end

--------------------------------------------------------------------------------

function link_gui_tabbed_pane(parent, caption)
  local frame = parent.add{
    type  = 'frame',
    style = 'inside_deep_frame_for_tabs'
  }

  local tabbed_pane = frame.add{
    type  = 'tabbed-pane',
    style = 'tabbed_pane_with_extra_padding'
  }
  tabbed_pane.selected_tab_index = 1

  return tabbed_pane
end

function link_gui_tab(parent, caption)
  local tab = parent.add{
    type    = 'tab',
    caption = caption
  }
  local frame = parent.add{
    type  = 'frame',
    style = 'naked_frame'
  }
  parent.add_tab(tab, frame)

  return frame
end

--------------------------------------------------------------------------------

function link_gui_signal_frame(parent, caption)
  local frame = parent.add{
    type  = 'frame',
    style = 'naked_frame'
  }

  local scroll_pane = frame.add{
    type                     = 'scroll-pane',
    horizontal_scroll_policy = 'never',
    vertical_scroll_policy   = 'auto-and-reserve-space',
    style                    = 'naked_scroll_pane'
  }

  scroll_pane.style.vertically_stretchable   = 'stretch_and_expand'
  scroll_pane.style.horizontally_stretchable = 'stretch_and_expand'

  -- scroll_pane.style.width = 800

  return scroll_pane
end

function link_gui_signal_network_frame(parent, caption)
  -- local outer_frame = parent.add{
  --   type    = 'frame',
  --   style   = 'inside_shallow_frame_with_padding',
  -- }

  local inner_frame = parent.add{
    type    = 'frame',
    style   = 'invisible_frame_with_title_for_inventory',
    caption = caption
  }

  local flow = inner_frame.add{ type = 'flow', direction = 'vertical' }
  flow.add{ type = 'line', direction = 'horizontal' }
  local table_frame = flow.add{
    type  = 'frame',
    style = 'inside_deep_frame'
  }
  flow.add{ type = 'line', direction = 'horizontal' }

  local signal_table = table_frame.add{
    type         = 'table',
    column_count = 25,
    style        = 'slot_table'
  }

  return signal_table
end

--------------------------------------------------------------------------------

function link_gui_server_frame(parent, caption)
  local frame = parent.add{
    type  = 'frame',
    style = 'naked_frame'
  }

  local scroll_pane = frame.add{
    type                     = 'scroll-pane',
    horizontal_scroll_policy = 'never',
    vertical_scroll_policy   = 'auto-and-reserve-space',
    style                    = 'naked_scroll_pane'
  }

  scroll_pane.style.vertically_stretchable   = 'stretch_and_expand'
  scroll_pane.style.horizontally_stretchable = 'stretch_and_expand'

  local server_table = scroll_pane.add{
    type         = 'table',
    name         = 'link-servers-table',
    column_count = 3,
    style        = 'inset_frame_container_table'
  }

  -- scroll_pane.style.height = 800


  return server_table
end

--------------------------------------------------------------------------------

function link_gui_logistics_frame(parent, caption)
  local outer_frame = parent.add{
    type    = 'frame',
    style   = 'invisible_frame_with_title_for_inventory',
    caption = caption
  }

  local scroll_pane = outer_frame.add{
    type                     = 'scroll-pane',
    style                    = 'logistics_scroll_pane',
    horizontal_scroll_policy = 'never',
    vertical_scroll_policy   = 'auto-and-reserve-space'
  }

  scroll_pane.style.width = 290
  if caption == 'Link Storage' then
    scroll_pane.style.vertically_stretchable   = 'stretch_and_expand'
    scroll_pane.style.horizontally_stretchable = 'stretch_and_expand'
    scroll_pane.style.height = 800
  else
    scroll_pane.style.height = 120
  end

  local inner_frame = scroll_pane.add{
    type  = 'frame',
    style = 'logistics_scroll_pane_background_frame'
  }

  local logistics_slot_table = inner_frame.add{
    type         = 'table',
    style        = 'logistics_slot_table',
    column_count = 7
  }

  return logistics_slot_table
end

--------------------------------------------------------------------------------

function link_gui_servers_table_update(player)
  if global.link_gui_servers_table and global.link_gui_servers_table.valid then
    global.link_gui_servers_table.clear()
    if global.link_server_list then
      for _, server in pairs(global.link_server_list) do
        local button = global.link_gui_servers_table.add{
          name = server.name,
          type = 'button',
          caption = server.name,
          style = 'menu_button'
        }
        button.style.width = 300
        button.style.height = 80

        local flow = button.add{
          type = 'flow',
          direction = 'vertical'
        }
        flow.add{
          type = 'label',
          caption = server.rtt..' ms'
        }
        if server.research then
          flow.add{
            type = 'label',
            caption = '[RESEARCH]',
            style = 'bold_green_label'
          }
        end
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

function link_gui_signal_frame_update(gui, signal_networks)
  if gui and gui.valid then
    gui.clear()
    if signal_networks then
      for network_id, signals in pairs(signal_networks) do
        local signal_network_frame = link_gui_signal_network_frame(gui, 'Network ID: '..network_id)
        for i, s in pairs(signals) do
          local type = s.signal.type
          if type == 'virtual' then
            type = 'virtual-signal'
          end
          local sprite = signal_network_frame.add{
            type = 'sprite-button',
            style = 'green_circuit_network_content_slot',
            sprite = type..'/'..s.signal.name,
            number = s.count,
            tooltip = s.signal.name
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
