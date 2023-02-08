function link_gui_create(player)
  if not global.link_gui then

--------------------------------------------------------------------------------

    global.link_gui = player.gui.screen.add{
      type      = 'frame',
      name      = 'link-outer-frame',
      direction = 'horizontal',
      style = 'outer_frame',
      visible   = false
    }

    -- global.link_gui.add{
    --   type = 'empty-widget',
    --   style = 'draggable_space_header',
    --   ignored_by_interaction = true
    -- }

    -- local server_list_outer_frame = global.link_gui.add{
    --   type  = 'frame',
    --   name  = 'link-server-list-outer-frame',
    --   style = 'outer_frame'
    -- }

    local server_list_outer_frame = global.link_gui.add{
      type  = 'frame',
      name  = 'link-server-list-inner-frame',
      style = 'inner_frame_in_outer_frame'
    }

    local server_list_inner_frame = server_list_outer_frame.add{
      type      = 'frame',
      name      = 'link-server-list-frame',
      style     = 'inner_frame',
      caption = 'Servers'
    }

    local server_list_scroll_pane = server_list_inner_frame.add{
      type                     = 'scroll-pane',
      name                     = 'link-server-list-scroll-pane',
      horizontal_scroll_policy = 'never',
      vertical_scroll_policy   = 'auto',
      style = 'inner_frame_scroll_pane'
    }

    global.link_gui_servers_table = server_list_scroll_pane.add{
      type = 'table',
      name = 'link-servers-table',
      column_count = 5,
      draw_horizontal_lines = true,
      draw_horizontal_lines_after_headers = true
    }

--------------------------------------------------------------------------------

    -- local servers_tab = link_main_tabbed_pane.add{
    --   type = 'tab',
    --   name = 'servers-tab',
    --   caption = 'Servers'
    -- }
    -- -- local servers_flow = link_main_tabbed_pane.add{
    -- --   type = 'flow',
    -- --   name = 'servers-flow',
    -- --   direction = 'vertical',
    -- -- }
    -- global.link_gui_servers_table = link_main_tabbed_pane.add{
    --   type = 'table',
    --   name = 'servers-table',
    --   column_count = 5,
    --   draw_horizontal_lines = true,
    --   draw_horizontal_lines_after_headers = true
    -- }
    -- link_main_tabbed_pane.add_tab(servers_tab, global.link_gui_servers_table)
    -- link_main_tabbed_pane.selected_tab_index = 1

--------------------------------------------------------------------------------

    -- local storage_outer_frame = global.link_gui.add{
    --   type  = 'frame',
    --   name  = 'link-storage-outer-frame',
    --   style = 'inner_frame_in_outer_frame'
    -- }

    local storage_inner_frame = server_list_outer_frame.add{
      type  = 'frame',
      name  = 'link-storage-inner-frame',
      style = 'inner_frame',
      caption = 'Storage'
    }

    local storage_frame = storage_inner_frame.add{
      type      = 'frame',
      name      = 'link-storage-frame',
      direction = 'vertical',
      style     = 'inside_shallow_frame'
    }

    local storage_scroll_pane = storage_frame.add{
      type                     = 'scroll-pane',
      name                     = 'link-storage-scroll-pane',
      horizontal_scroll_policy = 'never',
      vertical_scroll_policy   = 'auto',
      style = 'inner_frame_scroll_pane'
    }

    global.link_gui_storage_table = storage_scroll_pane.add{
      type = 'table',
      name = 'link-storage-table',
      column_count = 2,
      draw_horizontal_lines = true,
      draw_horizontal_lines_after_headers = true
    }

    -- local storage_frame = global.link_gui.add{
    --   type      = 'frame',
    --   name      = 'storage-frame',
    --   direction = 'vertical',
    -- }

    -- storage_frame.add{
    --   type    = 'label',
    --   name    = 'storage-label',
    --   caption = 'Storage'
    -- }

    -- storage_frame.add{
    --   type = 'line',
    --   name = 'storage-line'
    -- }

    -- local storage_scroll_pane = storage_frame.add{
    --   type                     = 'scroll-pane',
    --   name                     = 'storage-scroll-pane',
    --   horizontal_scroll_policy = 'never',
    --   vertical_scroll_policy   = 'auto'
    -- }

    -- global.link_gui_storage_table = storage_scroll_pane.add{
    --   type = 'table',
    --   name = 'storage-table',
    --   column_count = 2,
    --   draw_horizontal_lines = true,
    --   draw_horizontal_lines_after_headers = true
    -- }


    -- local storage_tab = link_main_tabbed_pane.add{
    --   type = 'tab',
    --   name = 'storage-tab',
    --   caption = 'Storage'
    -- }
    -- local storage_flow = global.link_gui.add{
    --   type = 'scroll-pane',
    --   name = 'storage-flow',
    --   horizontal_scroll_policy = 'never',
    --   vertical_scroll_policy = 'auto'
    -- }
    -- storage_flow.add{
    --   type = 'label',
    --   name = 'storage-label',
    --   caption = 'Storage'
    -- }

    -- -- local storage_flow = link_main_tabbed_pane.add{
    -- --   type = 'flow',
    -- --   name = 'storage-flow',
    -- --   direction = 'vertical',
    -- -- }
    -- global.link_gui_storage_table = storage_flow.add{
    --   type = 'table',
    --   name = 'storage-table',
    --   column_count = 2,
    --   draw_horizontal_lines = true,
    --   draw_horizontal_lines_after_headers = true
    -- }
    -- link_main_tabbed_pane.add_tab(storage_tab, storage_flow)

--------------------------------------------------------------------------------

    local logistics_provided_frame = global.link_gui.add{
      type      = 'frame',
      name      = 'logistics-provided-frame',
      direction = 'vertical',
    }

    logistics_provided_frame.add{
      type    = 'label',
      name    = 'logistics-provided-label',
      caption = 'Provided'
    }

    logistics_provided_frame.add{
      type = 'line',
      name = 'logistics-provided-line'
    }

    local logistics_provided_scroll_pane = logistics_provided_frame.add{
      type                     = 'scroll-pane',
      name                     = 'logistics-provided-scroll-pane',
      horizontal_scroll_policy = 'never',
      vertical_scroll_policy   = 'auto'
    }

    global.link_gui_logistics_table_provided = logistics_provided_scroll_pane.add{
      type = 'table',
      name = 'logistics-provided-table',
      column_count = 2,
      draw_horizontal_lines = true,
      draw_horizontal_lines_after_headers = true
    }

--------------------------------------------------------------------------------

    local logistics_requested_frame = global.link_gui.add{
      type      = 'frame',
      name      = 'logistics-requested-frame',
      direction = 'vertical',
    }

    logistics_requested_frame.add{
      type    = 'label',
      name    = 'logistics-requested-label',
      caption = 'Requested'
    }

    logistics_requested_frame.add{
      type = 'line',
      name = 'logistics-requested-line'
    }

    local logistics_requested_scroll_pane = logistics_requested_frame.add{
      type                     = 'scroll-pane',
      name                     = 'logistics-requested-scroll-pane',
      horizontal_scroll_policy = 'never',
      vertical_scroll_policy   = 'auto'
    }

    global.link_gui_logistics_table_requested = logistics_requested_scroll_pane.add{
      type = 'table',
      name = 'logistics-requested-table',
      column_count = 2,
      draw_horizontal_lines = true,
      draw_horizontal_lines_after_headers = true
    }

--------------------------------------------------------------------------------

    local logistics_fulfilled_frame = global.link_gui.add{
      type      = 'frame',
      name      = 'logistics-fulfilled-frame',
      direction = 'vertical',
    }

    logistics_fulfilled_frame.add{
      type    = 'label',
      name    = 'logistics-fulfilled-label',
      caption = 'Fulfilled'
    }

    logistics_fulfilled_frame.add{
      type = 'line',
      name = 'logistics-fulfilled-line'
    }

    local logistics_fulfilled_scroll_pane = logistics_fulfilled_frame.add{
      type                     = 'scroll-pane',
      name                     = 'logistics-fulfilled-scroll-pane',
      horizontal_scroll_policy = 'never',
      vertical_scroll_policy   = 'auto'
    }

    global.link_gui_logistics_table_fulfilled = logistics_fulfilled_scroll_pane.add{
      type = 'table',
      name = 'logistics-fulfilled-table',
      column_count = 2,
      draw_horizontal_lines = true,
      draw_horizontal_lines_after_headers = true
    }

--------------------------------------------------------------------------------

    local logistics_unfulfilled_frame = global.link_gui.add{
      type      = 'frame',
      name      = 'logistics-unfulfilled-frame',
      direction = 'vertical',
    }

    logistics_unfulfilled_frame.add{
      type    = 'label',
      name    = 'logistics-unfulfilled-label',
      caption = 'Unfulfilled'
    }

    logistics_unfulfilled_frame.add{
      type = 'line',
      name = 'logistics-unfulfilled-line'
    }

    local logistics_unfulfilled_scroll_pane = logistics_unfulfilled_frame.add{
      type                     = 'scroll-pane',
      name                     = 'logistics-unfulfilled-scroll-pane',
      horizontal_scroll_policy = 'never',
      vertical_scroll_policy   = 'auto'
    }

    global.link_gui_logistics_table_unfulfilled = logistics_unfulfilled_scroll_pane.add{
      type = 'table',
      name = 'logistics-unfulfilled-table',
      column_count = 2,
      draw_horizontal_lines = true,
      draw_horizontal_lines_after_headers = true
    }

--------------------------------------------------------------------------------

    local logistics_overflow_frame = global.link_gui.add{
      type      = 'frame',
      name      = 'logistics-overflow-frame',
      direction = 'vertical',
    }

    logistics_overflow_frame.add{
      type    = 'label',
      name    = 'logistics-overflow-label',
      caption = 'Overflow'
    }

    logistics_overflow_frame.add{
      type = 'line',
      name = 'logistics-overflow-line'
    }

    local logistics_overflow_scroll_pane = logistics_overflow_frame.add{
      type                     = 'scroll-pane',
      name                     = 'logistics-overflow-scroll-pane',
      horizontal_scroll_policy = 'never',
      vertical_scroll_policy   = 'auto'
    }

    global.link_gui_logistics_table_overflow = logistics_overflow_scroll_pane.add{
      type = 'table',
      name = 'logistics-overflow-table',
      column_count = 2,
      draw_horizontal_lines = true,
      draw_horizontal_lines_after_headers = true
    }





    -- local link_main_tabbed_pane = global.link_gui.add{
    --   type = 'tabbed-pane',
    --   name = 'tabbed-pane'
    -- }

    -- local logistics_tab = link_main_tabbed_pane.add{
    --   type = 'tab',
    --   name = 'logistics-tab',
    --   caption = 'Logistics'
    -- }
    -- local logistics_tabbed_pane = link_main_tabbed_pane.add{
    --   type = 'tabbed-pane',
    --   name = 'logistics-tabbed-pane'
    -- }
    -- link_main_tabbed_pane.add_tab(logistics_tab, logistics_tabbed_pane)
    -- logistics_tabbed_pane.selected_tab_index = 1

--------------------------------------------------------------------------------

    -- local logistics_tab_provided = logistics_tabbed_pane.add{
    --   type = 'tab',
    --   name = 'logistics-tab-provided',
    --   caption = 'Provided'
    -- }
    -- local logistics_flow_provided = logistics_tabbed_pane.add{
    --   type = 'scroll-pane',
    --   name = 'logistics-flow-provided',
    --   horizontal_scroll_policy = 'never',
    --   vertical_scroll_policy = 'auto-and-reserve-space'
    -- }
    -- global.link_gui_logistics_table_provided = logistics_flow_provided.add{
    --   type = 'table',
    --   name = 'logistics-table-provided',
    --   column_count = 2,
    --   draw_horizontal_lines = true,
    --   draw_horizontal_lines_after_headers = true
    -- }
    -- logistics_tabbed_pane.add_tab(logistics_tab_provided, logistics_flow_provided)

--------------------------------------------------------------------------------

    -- local logistics_tab_requested = logistics_tabbed_pane.add{
    --   type = 'tab',
    --   name = 'logistics-tab-requested',
    --   caption = 'Requested'
    -- }
    -- local logistics_flow_requested = logistics_tabbed_pane.add{
    --   type = 'scroll-pane',
    --   name = 'logistics-flow-requested',
    --   horizontal_scroll_policy = 'never',
    --   vertical_scroll_policy = 'auto-and-reserve-space'
    -- }
    -- global.link_gui_logistics_table_requested = logistics_flow_requested.add{
    --   type = 'table',
    --   name = 'logistics-table-requested',
    --   column_count = 2,
    --   draw_horizontal_lines = true,
    --   draw_horizontal_lines_after_headers = true
    -- }
    -- logistics_tabbed_pane.add_tab(logistics_tab_requested, logistics_flow_requested)

--------------------------------------------------------------------------------

    -- local logistics_tab_fulfilled = logistics_tabbed_pane.add{
    --   type = 'tab',
    --   name = 'logistics-tab-fulfilled',
    --   caption = 'Fulfilled'
    -- }
    -- local logistics_flow_fulfilled = logistics_tabbed_pane.add{
    --   type = 'scroll-pane',
    --   name = 'logistics-flow-fulfilled',
    --   horizontal_scroll_policy = 'never',
    --   vertical_scroll_policy = 'auto-and-reserve-space'
    -- }
    -- global.link_gui_logistics_table_fulfilled = logistics_flow_fulfilled.add{
    --   type = 'table',
    --   name = 'logistics-table-fulfilled',
    --   column_count = 2,
    --   draw_horizontal_lines = true,
    --   draw_horizontal_lines_after_headers = true
    -- }
    -- logistics_tabbed_pane.add_tab(logistics_tab_fulfilled, logistics_flow_fulfilled)

--------------------------------------------------------------------------------

--     local logistics_tab_unfulfilled = logistics_tabbed_pane.add{
--       type = 'tab',
--       name = 'logistics-tab-unfulfilled',
--       caption = 'Unfulfilled'
--     }
--     local logistics_flow_unfulfilled = logistics_tabbed_pane.add{
--       type = 'scroll-pane',
--       name = 'logistics-flow-unfulfilled',
--       horizontal_scroll_policy = 'never',
--       vertical_scroll_policy = 'auto-and-reserve-space'
--     }
--     global.link_gui_logistics_table_unfulfilled = logistics_flow_unfulfilled.add{
--       type = 'table',
--       name = 'logistics-table-unfulfilled',
--       column_count = 2,
--       draw_horizontal_lines = true,
--       draw_horizontal_lines_after_headers = true
--     }
--     logistics_tabbed_pane.add_tab(logistics_tab_unfulfilled, logistics_flow_unfulfilled)

-- --------------------------------------------------------------------------------

--     local logistics_tab_overflow = logistics_tabbed_pane.add{
--       type = 'tab',
--       name = 'logistics-tab-overflow',
--       caption = 'Overflow'
--     }
--     local logistics_flow_overflow = logistics_tabbed_pane.add{
--       type = 'scroll-pane',
--       name = 'logistics-flow-overflow',
--       horizontal_scroll_policy = 'never',
--       vertical_scroll_policy = 'auto-and-reserve-space'
--     }
--     global.link_gui_logistics_table_overflow = logistics_flow_overflow.add{
--       type = 'table',
--       name = 'logistics-table-overflow',
--       column_count = 2,
--       draw_horizontal_lines = true,
--       draw_horizontal_lines_after_headers = true
--     }
--     logistics_tabbed_pane.add_tab(logistics_tab_overflow, logistics_flow_overflow)

--------------------------------------------------------------------------------

    -- global.link_gui.force_auto_center()

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

function link_gui_storage_table_update(player)
  if global.link_gui_storage_table and global.link_gui_storage_table.valid then
    global.link_gui_storage_table.clear()
    global.link_gui_storage_table.add{
      type = 'label',
      caption = 'Name'
    }
    global.link_gui_storage_table.add{
      type = 'label',
      caption = 'Count'
    }
    if global.link_storage then
      for item_name, item_count in pairs(global.link_storage) do
        global.link_gui_storage_table.add{
          type = 'label',
          caption = item_name
        }
        global.link_gui_storage_table.add{
          type = 'label',
          caption = tostring(item_count)
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
