local g_update = Game.update
function Game:update(...)
  g_update(self, ...)
  if not ERROR_MODS_CHECKED and #ERROR_MODS > 0 then
    G.E_MANAGER:add_event(Event({
      func = function()
        G.FUNCS.overlay_menu({
          definition = require("ezm.ui").error_mods(),
        })
        return true
      end,
    }))
    ERROR_MODS_CHECKED = true
  end
end

local g_init = Game.init
function Game:init()
  g_init(self)
  self:set_ezm_globals()
end

function Game:set_ezm_globals()
  self.C.EZM = {
    TAB = copy_table(self.C.RED),
    TAB_SELECTED = copy_table(self.C.BLUE),
    MODS_TAB = copy_table(self.C.GREY),
  }
  self.EZUI_CTX_MENU = nil
  self.EZ_MOD_MENU = {
    current_tab = "mods",
    search = "",
    mods_current_tab = "loaded",
  }
end
