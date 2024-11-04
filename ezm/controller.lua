local c_L_cursor_press = Controller.L_cursor_press
function Controller:L_cursor_press(x, y)
  c_L_cursor_press(self, x, y)

  if G.EZUI_CTX_MENU and self.cursor_down and self.cursor_down.target then
    local node = self.cursor_down.target
    local remove = true
    while node do
      if node.parent == G.EZUI_CTX_MENU then
        remove = false
        break
      end
      node = node.parent
    end
    if remove and G.EZUI_CTX_MENU then
      G.EZUI_CTX_MENU:remove()
      G.EZUI_CTX_MENU = nil
    end
  end

  if not self.cursor_down.target then
    self.cursor_down.target = G.ROOM
  end
end
