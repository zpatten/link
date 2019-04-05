function on_link_configuration_changed(data)
  if data.mod_changes and data.mod_changes.link then
    on_link_init()
  end
end
script.on_configuration_changed(on_link_configuration_changed)
