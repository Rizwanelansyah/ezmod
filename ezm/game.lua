local game_update = Game.update
function Game:update(...)
  game_update(self, ...)
  Ezmod.check_mods_error()
end

local game_splash_screen = Game.splash_screen
function Game:splash_screen()
  Ezmod.check_mods_error()
  game_splash_screen(self)
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
    mod_pager = nil,
  }
end
