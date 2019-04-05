local remote_interface = {
  get_current_research = get_link_current_research,
  get_chats = get_link_chats,
  get_commands = get_link_commands,
  set_command_whitelist = set_link_command_whitelist,
  get_providables = get_link_providables,
  get_requests = get_link_requests,
  get_research = get_link_research,
  set_inventory_combinator = set_link_inventory_combinator,
  rtt = rtt,
  ping = ping,
  reset = on_init,
  set_current_research = set_link_current_research,
  set_fulfillments = set_link_fulfillments,
  set_research = set_link_research
}

remote.add_interface("link", remote_interface)
