local function close_ctx_menu()
  G.EZUI_CTX_MENU:remove()
  G.EZUI_CTX_MENU = nil
end

local function format_row(row, i, config)
  local tc = row.colour or G.C.GREY
  local nodes
  if type(row) == "string" then
    nodes = {
      Ezmod.ui.Text({ text = row, colour = tc, scale = 0.3, force_no_shadow = true }),
    }
  else
    nodes = {}

    local icon = type(row.icon) == "string" and Ezmod.ui.Image(row.icon, 0.4, 0.4)
      or (type(row.icon) == "table" and Ezmod.ui.Sprite(row.icon.atlas, 0.4, 0.4, row.icon.offset))
    if icon then
      nodes[#nodes + 1] = icon
      nodes[#nodes].config.align = "cl"
      nodes[#nodes + 1] = Ezmod.ui.Space(0.1)
    end

    nodes[#nodes + 1] = Ezmod.ui.Text({ text = row.text, colour = tc, scale = 0.3, force_no_shadow = true, hover = config.inverse_colour, hover_colour = config.inverse_colour and config.bg or nil })
  end
  local fn = row.fn or function() end
  local funcname = "ezui_ctx_menu_button" .. i .. "_on_click"
  G.FUNCS[funcname] = function()
    fn()
    close_ctx_menu()
  end
  return Ezmod.ui.Row({
    c = {
      padding = 0.1,
      r = 0.05,
      minw = 3,
      hover = true,
      hover_colour = config.inverse_colour and darken(tc, 0.1) or darken(config.bg, 0.15),
      colour = config.bg,
      button = funcname,
      align = "cl",
    },
    n = nodes,
  })
end

function ctx_menu_def(rows)
  local nodes = {}
  for i, row in ipairs(rows) do
    nodes[#nodes + 1] = format_row(row, i, rows.config)
  end
  return Ezmod.ui.Root({
    c = { colour = G.C.CLEAR, padding = 0.1 },
    n = {
      Ezmod.ui.Row({
        c = { colour = rows.config.border, emboss = 0.1, padding = 0.05, r = 0.1 },
        n = {
          Ezmod.ui.Row({
            c = { minw = 3, colour = rows.config.bg, padding = 0.1, r = 0.1 },
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
  rows.config = rows.config or {}
  rows.config.bg = rows.config.bg or G.C.WHITE
  rows.config.border = rows.config.border or G.C.L_BLACK

  local major = at or G.ROOM_ATTACH
  local menu = UIBox({
    definition = ctx_menu_def(rows),
    config = {
      align = major.T.y > G.ROOM.T.h * 0.7 and "tm" or "bm",
      offset = { x = 0, y = major.T.y > G.ROOM.T.h * 0.7 and -0.1 or 0.1 },
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
