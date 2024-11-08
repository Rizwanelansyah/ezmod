function G.FUNCS.ezm_open_mod_menu()
  G.FUNCS.overlay_menu({
    definition = require("ezm.uidef").mod_menu(),
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
  local view = require("ezm.uidef")["mod_menu_" .. name]
  local object = view and UIBox({
    definition = view(),
    config = {
      parent = mod_menu_view,
    },
  }) or Moveable()
  mod_menu_view.config.object:remove()
  mod_menu_view.config.object = object

  if name == "browser" then
    local search_bar = G.OVERLAY_MENU:get_UIE_by_ID("ezui_pager_search_bar")
    if search_bar then
      G.CONTROLLER.text_input_hook = search_bar.children[1].children[1]
    end
  elseif name == "mods" then
    local search_bar = G.OVERLAY_MENU:get_UIE_by_ID("ezui_pager_search_bar")
    if search_bar then
      G.CONTROLLER.text_input_hook = search_bar.children[1].children[1]
    end
  end
end
