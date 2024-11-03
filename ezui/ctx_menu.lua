local function close_ctx_menu()
  G.EZUI_CTX_MENU:remove()
  G.EZUI_CTX_MENU = nil
end

local function format_row(row, i)
  local tc = row.colour or G.C.GREY
  local nodes
  if type(row) == "string" then
    nodes = {
      Ezui.Text({ text = row, colour = tc, scale = 0.3, force_no_shadow = true }),
    }
  else
    nodes = {}

    local icon = type(row.icon) == "string" and Ezui.Image(row.icon, 0.4, 0.4)
      or (type(row.icon) == "table" and Ezui.Sprite(row.icon.atlas, 0.4, 0.4, row.icon.offset))
    if icon then
      nodes[#nodes + 1] = icon
      nodes[#nodes].config.align = "cl"
      nodes[#nodes + 1] = Ezui.Space(0.1)
    end

    nodes[#nodes + 1] = Ezui.Text({ text = row.text, colour = tc, scale = 0.3, force_no_shadow = true })
  end
  local fn = row.fn or function() end
  local funcname = "ezui_ctx_menu_button" .. i .. "_on_click"
  G.FUNCS[funcname] = function()
    fn()
    close_ctx_menu()
  end
  return Ezui.Row({
    c = {
      padding = 0.1,
      r = 0.05,
      minw = 3,
      hover = true,
      hover_colour = darken(G.C.WHITE, 0.15),
      colour = G.C.WHITE,
      button = funcname,
      align = "cl",
    },
    n = nodes,
  })
end

function ctx_menu_def(rows)
  local nodes = {}
  for i, row in ipairs(rows) do
    nodes[#nodes + 1] = format_row(row, i)
  end
  return Ezui.Root({
    c = { colour = G.C.CLEAR, padding = 0.1 },
    n = {
      Ezui.Row({
        c = { colour = G.C.L_BLACK, emboss = 0.1, padding = 0.05, r = 0.1 },
        n = {
          Ezui.Row({
            c = { minw = 3, minh = 1, colour = G.C.WHITE, padding = 0.1, r = 0.1 },
            n = nodes,
          }),
        },
      }),
    },
  })
end

local function ctx_menu(rows, at)
  if G.EZUI_CTX_MENU then
    G.EZUI_CTX_MENU:remove()
    G.EZUI_CTX_MENU = nil
  end

  local major = at or G.ROOM_ATTACH
  local menu = UIBox({
    definition = ctx_menu_def(rows),
    config = {
      align = major.T.y > G.ROOM.T.h / 2 and "tm" or "bm",
      offset = { x = 0, y = major.T.y > G.ROOM.T.h / 2 and -0.1 or 0.1 },
      major = major,
    },
  })

  G.EZUI_CTX_MENU = menu
  for k, v in pairs(G.I.UIBOX) do
    if v == menu then
      table.remove(G.I.UIBOX, k)
      break
    end
  end
end

return ctx_menu
