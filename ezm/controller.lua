local c_L_cursor_press = Controller.L_cursor_press
function Controller:L_cursor_press(x, y)
  c_L_cursor_press(self, x, y)

  if G.EZUI_CTX_MENU and self.cursor_down and self.cursor_down.target and menu ~= self.cursor_down.target then
    G.EZUI_CTX_MENU:remove()
    G.EZUI_CTX_MENU = nil
  end

  if not self.cursor_down.target then
    self.cursor_down.target = G.ROOM
  end
end
