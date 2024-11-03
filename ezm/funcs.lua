function G.FUNCS.ezm_open_mod_menu()
  G.FUNCS.overlay_menu({
    definition = require("ezm.ui").mod_menu(),
  })
  G.FUNCS.mod_menu_switch_tab(G.EZ_MOD_MENU.current_tab)
end

function G.FUNCS.mod_menu_switch_tab(name)
  local last_tab = G.OVERLAY_MENU:get_UIE_by_ID("ez_mod_menu_tabs_" .. G.EZ_MOD_MENU.current_tab .. "_button")
  local tab = G.OVERLAY_MENU:get_UIE_by_ID("ez_mod_menu_tabs_" .. name .. "_button")

  last_tab.config.colour = G.C.EZM.TAB
  last_tab.config.hover = true
  last_tab.disable_button = false

  tab.config.colour = G.C.EZM.TAB_SELECTED
  tab.config.hover = false
  tab.disable_button = true

  G.EZ_MOD_MENU.current_tab = name

  local mod_menu_view = G.OVERLAY_MENU:get_UIE_by_ID("ez_mod_menu_view")
  local view = require("ezm.ui")["mod_menu_" .. name]
  local object = view and UIBox({
    definition = view(),
    config = {
      parent = mod_menu_view,
    },
  }) or Moveable()
  mod_menu_view.config.object:remove()
  mod_menu_view.config.object = object

  if name == "browser" then
    for _, node in pairs(G.OVERLAY_MENU:get_UIE_by_ID("ez_mod_menu_browser_bar").children) do
      node.UIBox:recalculate()
    end
  elseif name == "mods" then
    G.FUNCS.mod_menu_mods_switch_tab(G.EZ_MOD_MENU.mods_current_tab)
  end
end

function G.FUNCS.mod_menu_mods_switch_tab(name)
  local last_tab = G.OVERLAY_MENU:get_UIE_by_ID("ez_mod_menu_mods_tabs_" .. G.EZ_MOD_MENU.mods_current_tab .. "_button")
  local tab = G.OVERLAY_MENU:get_UIE_by_ID("ez_mod_menu_mods_tabs_" .. name .. "_button")

  last_tab.config.colour = G.C.EZM.MODS_TAB
  last_tab.config.shadow = false
  last_tab.config.hover = true
  last_tab.disable_button = false

  tab.config.colour = G.C.CLEAR
  tab.config.shadow = false
  tab.config.hover = false
  tab.disable_button = true

  G.EZ_MOD_MENU.mods_current_tab = name
end
