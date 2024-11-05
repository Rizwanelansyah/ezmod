local function ask_menu(question, options, fn)
  local nodes = {}
  local width = 7
  local space = 0.1
  local button_width = (width / (#options + 1))

  for i, opt in ipairs(options) do
    nodes[#nodes + 1] = Ezmod.ui.Button(opt.text, button_width, opt.colour, "ezui_ask_menu_option" .. i, function()
      fn(opt.value or opt.text)
      G.EZUI_ASK_MENU:remove()
      G.EZUI_ASK_MENU = nil
    end)
    nodes[#nodes+1] = Ezmod.ui.Space(space)
  end

  return Ezmod.ui.DarkBGRoot({
    Ezmod.ui.Col({
      c = { colour = G.C.L_BLACK, padding = 0.1, r = 0.3, emboss = 0.2 },
      n = {
        Ezmod.ui.Row({
          c = { colour = G.C.WHITE, r = 0.2, padding = 0.4, emboss = 0.1, minw = width },
          n = {
            Ezmod.ui.FmText(
              question,
              { t = { colour = G.C.GREY, scale = 0.4 }, c = { align = "cm", line_space = 0.2 }, v = { __opt = options } }
            ),
          },
        }),
        Ezmod.ui.Row {
          c = { align = "cm", padding = 0.05 },
          n = nodes
        }
      },
    }),
  })
end

local function ask(question, options, fn)
  question = question or {}
  options = options or {}
  if type(question) == "string" then
    local question_t = {}
    for line in question:gmatch("([^\n]+)\n?") do
      question_t[#question_t + 1] = line
    end
    question = question_t
  end

  for i, option in ipairs(options) do
    option = type(option) == "string" and { text = option } or option
    option.colour = option.colour or G.C.BLUE
    options[i] = option
  end

  if G.EZUI_ASK_MENU then
    G.EZUI_ASK_MENU:remove()
    G.EZUI_ASK_MENU = nil
  end

  local menu = UIBox({
    definition = ask_menu(question, options, fn or function() end),
    config = {
      align = "cm",
      parent = G.ROOM_ATTACH,
    },
  })

  G.EZUI_ASK_MENU = menu
  for k, v in pairs(G.I.UIBOX) do
    if v == menu then
      table.remove(G.I.UIBOX, k)
      break
    end
  end
end

return ask
