local game_update = Game.update
function Game:update(...)
  game_update(self, ...)

  local has_response, res = Ezmod.curl.poll_response()
  if has_response and res and res.handle_id and G.EZM_CURL_HANDLERS[res.handle_id] then
    local handle = G.EZM_CURL_HANDLERS[res.handle_id]
    handle(res)
    G.EZM_CURL_HANDLERS[res.handle_id] = nil
  end

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
  self.EZM_CURL_HANDLERS = {}
  self.EZ_MOD_MENU = {
    current_tab = "mods",
    search = "",
    mod_pager = nil,
    browser_pager = nil,
    setting_loc = { "main" },
  }
end
