local function ask_menu(question, options, fn, config)
  local nodes = {}
  local width = 7
  local space = 0.1
  local button_width = (width / (#options + 1))

  local choice
  if config.multi then
    choice = function(opt)
      local button = Ezmod.ui.Button(opt.text, width, opt.on and G.C.BLUE or G.C.GREY, "ezui_ask_menu_option" .. opt.i, function(e)
        local value = opt.value or opt.text
        local choices = G.EZUI_ASK_MENU.config.choices
        choices[value] = not choices[value]
        opt.on = choices[value]
        if choices[value] then
          e.config.colour = G.C.BLUE
        else
          e.config.colour = G.C.GREY
        end
      end)

      button.nodes[1].config.shadow = false
      button.nodes[1].config.emboss = 0.05
      return Ezmod.ui.Row({
        c = { align = "cm" },
        n = {
          button,
        },
      })
    end
  else
    choice = function(opt)
      return Ezmod.ui.Button(opt.text, button_width, opt.colour, "ezui_ask_menu_option" .. opt.i, function()
        G.EZUI_ASK_MENU:remove()
        G.EZUI_ASK_MENU = nil
        fn(opt.value or opt.text)
      end)
    end
  end

  for i, opt in ipairs(options) do
    opt.i = i
    nodes[#nodes + 1] = choice(opt)
    if config.multi then
      nodes[#nodes + 1] = Ezmod.ui.Row({ n = { Ezmod.ui.Space(0, space) } })
    else
      nodes[#nodes + 1] = Ezmod.ui.Space(space)
    end
  end

  return Ezmod.ui.DarkBGRoot({
    Ezmod.ui.Col({
      c = { colour = G.C.L_BLACK, padding = 0.1, r = 0.3, emboss = 0.2 },
      n = {
        Ezmod.ui.Row({
          c = { colour = G.C.WHITE, r = 0.2, padding = 0.4, emboss = 0.1, minw = width },
          n = {
            Ezmod.ui.FmText(question, {
              t = { colour = G.C.GREY, scale = 0.4 },
              c = { align = "cm", minw = width, line_space = 0.2 },
              v = { __opt = options },
            }),
          },
        }),
        Ezmod.ui.Row({
          c = { align = "cm", padding = 0.05 },
          n = nodes,
        }),
        config.multi and Ezmod.ui.Row({
          c = { align = "cm", padding = 0.05 },
          n = {
            Ezmod.ui.Button("Submit", width, G.C.GREEN, "ezui_ask_menu_submit", function()
              local choices = G.EZUI_ASK_MENU.config.choices
              G.EZUI_ASK_MENU:remove()
              G.EZUI_ASK_MENU = nil
              fn(choices)
            end),
          },
        }) or nil,
      },
    }),
  })
end

local function ask(question, options, fn)
  question = question or {}
  local config = options.config or {}
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
    definition = ask_menu(question, options, fn or function() end, config),
    config = {
      align = "cm",
      parent = G.ROOM_ATTACH,
      allow_cancel = config.allow_cancel,
      pager = config.pager,
      multi = config.multi,
      choices = config.multi and {} or nil,
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
