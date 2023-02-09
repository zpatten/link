local shortcut = link_build_data({
  type = 'shortcut',
  what = 'shortcut',
  name = 'gui',
  attributes = {
    localised_name = 'Link Servers',
    action = 'lua',
    toggleable = false,
    icon = {
      filename = '__base__/graphics/icons/signal/signal_L.png',
      -- '__base__/graphics/icons/computer.png',
      priority = 'extra-high-no-scale',
      size = 64,
      scale = 1,
      flags = { 'icon' }
    },
    small_icon = {
      filename = '__base__/graphics/icons/signal/signal_L.png',
      priority = 'extra-high-no-scale',
      size = 64,
      scale = 1,
      flags = { 'icon' }
    },
    disabled_small_icon = {
      filename = '__base__/graphics/icons/signal/signal_L.png',
      priority = 'extra-high-no-scale',
      size = 64,
      scale = 1,
      flags = { 'icon' }
    }
  }
})

link_extend_data({
  shortcut
})
