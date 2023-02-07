function link_gui_create(player)
  if not global.link_gui then

--------------------------------------------------------------------------------

    global.link_gui = player.gui.screen.add{
      type        = 'frame',
      name        = 'link-frame',
      caption     = 'Link',
      visible     = false,
      auto_center = true
    }

    local link_main_tabbed_pane = global.link_gui.add{
      type = 'tabbed-pane',
      name = 'tabbed-pane'
    }

--------------------------------------------------------------------------------

    local servers_tab = link_main_tabbed_pane.add{
      type = 'tab',
      name = 'servers-tab',
      caption = 'Servers'
    }
    -- local servers_flow = link_main_tabbed_pane.add{
    --   type = 'flow',
    --   name = 'servers-flow',
    --   direction = 'vertical',
    -- }
    global.link_gui_servers_table = link_main_tabbed_pane.add{
      type = 'table',
      name = 'servers-table',
      column_count = 5,
      draw_horizontal_lines = true,
      draw_horizontal_lines_after_headers = true
    }
    link_main_tabbed_pane.add_tab(servers_tab, global.link_gui_servers_table)
    link_main_tabbed_pane.selected_tab_index = 1

--------------------------------------------------------------------------------

    local logistics_tab = link_main_tabbed_pane.add{
      type = 'tab',
      name = 'logistics-tab',
      caption = 'Logistics'
    }
    local logistics_tabbed_pane = link_main_tabbed_pane.add{
      type = 'tabbed-pane',
      name = 'logistics-tabbed-pane'
    }
    link_main_tabbed_pane.add_tab(logistics_tab, logistics_tabbed_pane)
    logistics_tabbed_pane.selected_tab_index = 1
--------------------------------------------------------------------------------

    local logistics_tab_provided = logistics_tabbed_pane.add{
      type = 'tab',
      name = 'logistics-tab-provided',
      caption = 'Provided'
    }
    local logistics_flow_provided = logistics_tabbed_pane.add{
      type = 'scroll-pane',
      name = 'logistics-flow-provided',
      horizontal_scroll_policy = 'never',
      vertical_scroll_policy = 'auto-and-reserve-space'
    }
    global.link_gui_logistics_table_provided = logistics_flow_provided.add{
      type = 'table',
      name = 'logistics-table-provided',
      column_count = 2,
      draw_horizontal_lines = true,
      draw_horizontal_lines_after_headers = true
    }
    logistics_tabbed_pane.add_tab(logistics_tab_provided, logistics_flow_provided)

--------------------------------------------------------------------------------

    local logistics_tab_requested = logistics_tabbed_pane.add{
      type = 'tab',
      name = 'logistics-tab-requested',
      caption = 'Requested'
    }
    local logistics_flow_requested = logistics_tabbed_pane.add{
      type = 'scroll-pane',
      name = 'logistics-flow-requested',
      horizontal_scroll_policy = 'never',
      vertical_scroll_policy = 'auto-and-reserve-space'
    }
    global.link_gui_logistics_table_requested = logistics_flow_requested.add{
      type = 'table',
      name = 'logistics-table-requested',
      column_count = 2,
      draw_horizontal_lines = true,
      draw_horizontal_lines_after_headers = true
    }
    logistics_tabbed_pane.add_tab(logistics_tab_requested, logistics_flow_requested)

--------------------------------------------------------------------------------

    local logistics_tab_fulfilled = logistics_tabbed_pane.add{
      type = 'tab',
      name = 'logistics-tab-fulfilled',
      caption = 'Fulfilled'
    }
    local logistics_flow_fulfilled = logistics_tabbed_pane.add{
      type = 'scroll-pane',
      name = 'logistics-flow-fulfilled',
      horizontal_scroll_policy = 'never',
      vertical_scroll_policy = 'auto-and-reserve-space'
    }
    global.link_gui_logistics_table_fulfilled = logistics_flow_fulfilled.add{
      type = 'table',
      name = 'logistics-table-fulfilled',
      column_count = 2,
      draw_horizontal_lines = true,
      draw_horizontal_lines_after_headers = true
    }
    logistics_tabbed_pane.add_tab(logistics_tab_fulfilled, logistics_flow_fulfilled)

--------------------------------------------------------------------------------

    local logistics_tab_unfulfilled = logistics_tabbed_pane.add{
      type = 'tab',
      name = 'logistics-tab-unfulfilled',
      caption = 'Unfulfilled'
    }
    local logistics_flow_unfulfilled = logistics_tabbed_pane.add{
      type = 'scroll-pane',
      name = 'logistics-flow-unfulfilled',
      horizontal_scroll_policy = 'never',
      vertical_scroll_policy = 'auto-and-reserve-space'
    }
    global.link_gui_logistics_table_unfulfilled = logistics_flow_unfulfilled.add{
      type = 'table',
      name = 'logistics-table-unfulfilled',
      column_count = 2,
      draw_horizontal_lines = true,
      draw_horizontal_lines_after_headers = true
    }
    logistics_tabbed_pane.add_tab(logistics_tab_unfulfilled, logistics_flow_unfulfilled)

--------------------------------------------------------------------------------

    local logistics_tab_overflow = logistics_tabbed_pane.add{
      type = 'tab',
      name = 'logistics-tab-overflow',
      caption = 'Overflow'
    }
    local logistics_flow_overflow = logistics_tabbed_pane.add{
      type = 'scroll-pane',
      name = 'logistics-flow-overflow',
      horizontal_scroll_policy = 'never',
      vertical_scroll_policy = 'auto-and-reserve-space'
    }
    global.link_gui_logistics_table_overflow = logistics_flow_overflow.add{
      type = 'table',
      name = 'logistics-table-overflow',
      column_count = 2,
      draw_horizontal_lines = true,
      draw_horizontal_lines_after_headers = true
    }
    logistics_tabbed_pane.add_tab(logistics_tab_overflow, logistics_flow_overflow)

--------------------------------------------------------------------------------

    global.link_gui.force_auto_center()

--------------------------------------------------------------------------------

  end
end

function link_gui_update(player)
  link_gui_servers_table_update(player)
end

function link_gui_servers_table_update(player)
  if global.link_gui_servers_table and global.link_gui_servers_table.valid then
    global.link_gui_servers_table.clear()
    global.link_gui_servers_table.add{
      type = 'label',
      caption = 'Connect'
    }
    global.link_gui_servers_table.add{
      type = 'label',
      caption = 'Name'
    }
    global.link_gui_servers_table.add{
      type = 'label',
      caption = 'Research'
    }
    global.link_gui_servers_table.add{
      type = 'label',
      caption = 'Responsive?'
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
        global.link_gui_servers_table.add{
          type = 'label',
          caption = tostring(server.research)
        }
        global.link_gui_servers_table.add{
          type = 'label',
          caption = tostring(server.responsive)
        }
        global.link_gui_servers_table.add{
          type = 'label',
          caption = tostring(server.rtt)
        }
      end
    end
  end
end

function link_gui_logistics_provided_table_update(player)
  if global.link_gui_logistics_table_provided and global.link_gui_logistics_table_provided.valid then
    global.link_gui_logistics_table_provided.clear()
    global.link_gui_logistics_table_provided.add{
      type = 'label',
      caption = 'Name'
    }
    global.link_gui_logistics_table_provided.add{
      type = 'label',
      caption = 'Count'
    }
    if global.link_logistics_provided then
      for item_name, item_count in pairs(global.link_logistics_provided) do
        global.link_gui_logistics_table_provided.add{
          type = 'label',
          caption = item_name
        }
        global.link_gui_logistics_table_provided.add{
          type = 'label',
          caption = tostring(item_count)
        }
      end
    end
  end
end

function link_gui_logistics_requested_table_update(player)
  if global.link_gui_logistics_table_requested and global.link_gui_logistics_table_requested.valid then
    global.link_gui_logistics_table_requested.clear()
    global.link_gui_logistics_table_requested.add{
      type = 'label',
      caption = 'Name'
    }
    global.link_gui_logistics_table_requested.add{
      type = 'label',
      caption = 'Count'
    }
    if global.link_logistics_requested then
      for item_name, item_count in pairs(global.link_logistics_requested) do
        global.link_gui_logistics_table_requested.add{
          type = 'label',
          caption = item_name
        }
        global.link_gui_logistics_table_requested.add{
          type = 'label',
          caption = tostring(item_count)
        }
      end
    end
  end
end

function link_gui_logistics_fulfilled_table_update(player)
  if global.link_gui_logistics_table_fulfilled and global.link_gui_logistics_table_fulfilled.valid then
    global.link_gui_logistics_table_fulfilled.clear()
    global.link_gui_logistics_table_fulfilled.add{
      type = 'label',
      caption = 'Name'
    }
    global.link_gui_logistics_table_fulfilled.add{
      type = 'label',
      caption = 'Count'
    }
    if global.link_logistics_fulfilled then
      for item_name, item_count in pairs(global.link_logistics_fulfilled) do
        global.link_gui_logistics_table_fulfilled.add{
          type = 'label',
          caption = item_name
        }
        global.link_gui_logistics_table_fulfilled.add{
          type = 'label',
          caption = tostring(item_count)
        }
      end
    end
  end
end

function link_gui_logistics_unfulfilled_table_update(player)
  if global.link_gui_logistics_table_unfulfilled and global.link_gui_logistics_table_unfulfilled.valid then
    global.link_gui_logistics_table_unfulfilled.clear()
    global.link_gui_logistics_table_unfulfilled.add{
      type = 'label',
      caption = 'Name'
    }
    global.link_gui_logistics_table_unfulfilled.add{
      type = 'label',
      caption = 'Count'
    }
    if global.link_logistics_unfulfilled then
      for item_name, item_count in pairs(global.link_logistics_unfulfilled) do
        global.link_gui_logistics_table_unfulfilled.add{
          type = 'label',
          caption = item_name
        }
        global.link_gui_logistics_table_unfulfilled.add{
          type = 'label',
          caption = tostring(item_count)
        }
      end
    end
  end
end

function link_gui_logistics_overflow_table_update(player)
  if global.link_gui_logistics_table_overflow and global.link_gui_logistics_table_overflow.valid then
    global.link_gui_logistics_table_overflow.clear()
    global.link_gui_logistics_table_overflow.add{
      type = 'label',
      caption = 'Name'
    }
    global.link_gui_logistics_table_overflow.add{
      type = 'label',
      caption = 'Count'
    }
    if global.link_logistics_overflow then
      for item_name, item_count in pairs(global.link_logistics_overflow) do
        global.link_gui_logistics_table_overflow.add{
          type = 'label',
          caption = item_name
        }
        global.link_gui_logistics_table_overflow.add{
          type = 'label',
          caption = tostring(item_count)
        }
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
  if element.parent.name == 'servers-table' then
    server = global.link_server_list[element.name]
    player.connect_to_server{
      address = string.format('%s:%s', server.host, server.port),
      name = server.name
    }
  end
end
script.on_event(defines.events.on_gui_click, on_gui_click)
