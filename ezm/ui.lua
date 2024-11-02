local UI = {}

function UI.mod_box(mod)
  return Ezui.Row({
    c = { align = "cl", padding = 0.1, r = 0.1, emboss = 0.1, colour = G.C.WHITE },
    n = {
      Ezui.Col({ c = { padding = 0.2 }, n = { mod:icon_ui(1.5, 1.5) } }),
      Ezui.Col({
        c = { padding = 0.1 },
        n = {
          Ezui.Row({
            c = { align = "tl" },
            n = {
              Ezui.Row({
                n = { Ezui.DynText({ string = mod.name, colour = G.C.GREY, scale = 0.4, float = true, shadow = true }) },
              }),
              Ezui.Row({ n = { Ezui.Space(0, 0.2) } }),
              Ezui.Row({ n = { Ezui.Box({ h = 0.03, w = 8, colour = G.C.GREY }) } }),
              Ezui.Row({ n = { Ezui.Space(0, 0.2) } }),
              Ezui.FmText(
                mod.desc,
                { t = { colour = G.C.GREY, scale = 0.3 }, c = { align = "cl", line_space = 0.05 }, v = { self = mod } }
              ),
            },
          }),
        },
      }),
    },
  })
end

function UI.error_description(type, mod)
  if type == "duplicate" then
    local function row(node, config)
      return Ezui.Row({ c = config or { align = "cm" }, n = { node } })
    end
    return Ezui.Row({
      c = { align = "cm", padding = 0.05, r = 0.05, colour = G.C.WHITE, emboss = 0.08 },
      n = {
        row(Ezui.Text({ text = "Duplicate Mod ID", colour = G.C.RED, scale = 0.4 }), { padding = 0.1, align = "sm" }),
        row(Ezui.Box({ h = 0.03, w = 5, colour = G.C.GREY })),
        Ezui.FmText({
          "[G.C.ORANGE]{mod.name} and [G.C.ORANGE]{MODS[mod.id].name}",
          "have a same [G.C.WHITE:G.C.RED]{'ID'} which is [G.C.BLUE]{mod.id}.",
        }, { t = { colour = G.C.GREY, scale = 0.3 }, c = { align = "cm", line_space = 0.1 }, v = { mod = mod } }),
      },
    })
  end
end

function UI.error_mods()
  local contents = {}

  for i, error in ipairs(ERROR_MODS) do
    local error_desc = UI.error_description(error.type, error.mod)
    if error_desc then
      contents[#contents + 1] = error_desc
    end
    if i == 4 then
      break
    end
  end

  return Ezui.DarkBGRoot({
    Ezui.Row({
      c = { align = "cm", r = 0.3, colour = G.C.WHITE, emboss = 0.1 },
      n = {
        Ezui.Col({
          c = { align = "cm", r = 0.2, padding = 0.01, colour = G.C.RED },
          n = {
            Ezui.Row({
              c = { align = "cm", padding = 0.1 },
              n = {
                Ezui.Row({
                  c = { align = "cm", padding = 0.2, r = 0.08, colour = G.C.WHITE, emboss = 0.03 },
                  n = {
                    Ezui.Col({
                      c = { align = "cm", colour = G.C.RED, padding = 0.1, r = 0.3 },
                      n = {
                        Ezui.Space(0.1),
                        Ezui.Text({ text = "!", colour = G.C.WHITE, scale = 0.5 }),
                        Ezui.Space(0.1),
                      },
                    }),
                    Ezui.Space(0.3),
                    Ezui.Text({ text = "Error Loading Mods!", colour = G.C.UI.TEXT_DARK, scale = 0.65 }),
                    Ezui.Space(0.3),
                  },
                }),
                Ezui.Row({
                  c = { align = "cm", padding = 0.2, colour = G.C.L_BLACK, emboss = 0.05, r = 0.1 },
                  n = contents,
                }),
              },
            }),
          },
        }),
      },
    }),
  })
end

function UI.mod_menu()
  return Ezui.DarkBGRoot({
    Ezui.Row({
      c = { id = "ez_mod_menu", align = "cm", r = 0.3, padding = 0.05, colour = G.C.WHITE, emboss = 0.1 },
      n = {
        Ezui.Row({
          c = { align = "cm", r = 0.25, padding = 0.3, colour = G.C.L_BLACK },
          n = {
            Ezui.Col({
              c = { minh = 10, align = "tm" },
              n = {
                UI.mod_menu_tabs(),
                Ezui.Col({ n = { Ezui.Space(0.1, 0.5) } }),
                { n = G.UIT.O, config = { id = "ez_mod_menu_view", object = Moveable() } },
              },
            }),
          },
        }),
      },
    }),
  })
end

function UI.mod_menu_tabs()
  local buttons = {
    { "Mods", "mods" },
    { "Browser", "browser" },
    { "Settings", "settings" },
  }
  local tabw = 15
  local btn_width = tabw / #buttons

  local nodes = {}
  for i, btn in ipairs(buttons) do
    nodes[i] = Ezui.Button(btn[1], btn_width, G.C.EZM.TAB, "ez_mod_menu_tabs_" .. btn[2] .. "_button", function()
      G.FUNCS.mod_menu_switch_tab(btn[2])
    end, { scale = 0.6 })
  end

  return Ezui.Row({
    c = { id = "ez_mod_menu_tabs", align = "cm", padding = 0.1, colour = G.C.GREY, r = 0.1, minw = tabw },
    n = nodes,
  })
end

function UI.mod_menu_browser()
  return Ezui.Root({
    c = { align = "cm", colour = G.C.CLEAR },
    n = {
      Ezui.Col({
        c = { align = "tm", padding = 0.1 },
        n = {
          Ezui.Col({
            c = { align = "cm", minw = 15, id = "ez_mod_menu_browser_bar" },
            n = {
              Ezui.Button("<", 0.5, G.C.RED, "ez_mod_menu_browser_back"),
              Ezui.Space(0.1),
              Ezui.Button("Refresh", 1.5, G.C.RED, "ez_mod_menu_browser_refresh"),
              Ezui.Space(0.1),
              Ezui.TextInput({
                prompt_text = "Search...",
                text_scale = 0.4,
                max_length = 50,
                ref_table = G.EZ_MOD_MENU,
                ref_value = "search",
                w = 10,
                accept_all = true,
              }),
            },
          }),
        },
      }),
    },
  })
end

function UI.mod_menu_mods()
  return Ezui.Root({
    c = { align = "cm", colour = G.C.CLEAR },
    n = {
      Ezui.Col({
        c = { align = "tm", padding = 0.1 },
        n = {
          Ezui.Col({
            c = { align = "cm", minw = 15, id = "ez_mod_menu_browser_bar" },
            n = {
              Ezui.Row({ n = {
                UI.mod_menu_mods_tabs(),
              } }),
              Ezui.Pager(MODS, 3):ui(15, 8, UI.mod_box),
            },
          }),
        },
      }),
    },
  })
end

function UI.mod_menu_mods_tabs()
  local buttons = {
    { "Loaded", "loaded" },
    { "All", "all" },
  }
  local tabw = 15
  local btn_width = tabw / #buttons

  local nodes = {}
  for i, btn in ipairs(buttons) do
    nodes[i] = Ezui.Button(
      btn[1],
      btn_width,
      G.C.EZM.MODS_TAB,
      "ez_mod_menu_mods_tabs_" .. btn[2] .. "_button",
      function()
        G.FUNCS.mod_menu_mods_switch_tab(btn[2])
      end,
      { scale = 0.4 }
    )
    nodes[i].nodes[1].config.shadow = false
  end

  return Ezui.Row({
    c = { id = "ez_mod_menu_mods_tab", align = "cm", padding = 0.05, colour = G.C.CLEAR, minw = tabw },
    n = nodes,
  })
end

return UI
