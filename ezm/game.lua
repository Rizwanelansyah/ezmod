local game_update = Game.update
function Game:update(...)
  game_update(self, ...)

  local has_response, status_code, body, header, handle_id = Ezmod.http.poll_response()
  if has_response and handle_id and G.EZM_HTTP_HANDLERS[handle_id] then
    local handle = G.EZM_HTTP_HANDLERS[handle_id]
    handle(status_code, body, header)
    G.EZM_HTTP_HANDLERS[handle_id] = nil
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
  self.EZM_HTTP_HANDLERS = {}
  self.EZ_MOD_MENU = {
    current_tab = "mods",
    search = "",
    mod_pager = nil,
    setting_loc = { "main" },
  }
end
