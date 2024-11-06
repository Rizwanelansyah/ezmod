local UI = {}

function UI.mod_box(mod)
  local control_buttons = {}
  local icons = G.ASSET_ATLAS.ezm_icons
  local base_id = "ez_mod_control_" .. mod.id .. "_v" .. (table.concat(mod.version, "_"))
  local ctx_rows = {
    {
      text = "Detail",
      colour = mix_colours(G.C.WHITE, G.C.PURPLE, 0.4),
      icon = { atlas = icons, offset = { x = 0, y = 1 } },
    },
  }

  if mod.loaded then
    ctx_rows[#ctx_rows + 1] = {
      text = "Setting",
      colour = mix_colours(G.C.WHITE, G.C.BLUE, 0.4),
      icon = { atlas = icons, offset = { x = 2, y = 1 } },
    }

    ctx_rows[#ctx_rows + 1] = {
      text = "Switch version",
      colour = mix_colours(G.C.WHITE, G.C.ORANGE, 0.4),
      icon = { atlas = icons, offset = { x = 1, y = 1 } },
    }
  end

  local _control_buttons = {}

  if mod.loaded then
    _control_buttons[#_control_buttons + 1] = {
      "Disable",
      "disable",
      darken(G.C.ORANGE, 0.1),
      function()
        Ezmod.disable_mod(mod)
      end,
      icons,
      { x = 3, y = 0 },
    }
  else
    _control_buttons[#_control_buttons + 1] = {
      "Enable",
      "enable",
      G.C.GREEN,
      function()
        Ezmod.enable_mod(mod)
      end,
      icons,
      { x = 2, y = 0 },
    }
  end

  if mod.downloaded then
    _control_buttons[#_control_buttons + 1] = {
      "Delete",
      "delete",
      G.C.RED,
      function()
        local mods = {}
        for _, del_mod in ipairs(ALL_MODS) do
          if del_mod.id == mod.id then
            mods[#mods + 1] = del_mod
          end
        end
        if #mods == 1 then
          local del_mod = mods[1]
          Ezmod.ui.Ask(
            string.format(
              "Do you really wanna [G.C.RED]{'delete'} [G.C.ORANGE]{'%s'} [G.C.GREEN]{'v%s'} [::1.5]{'?'}",
              del_mod.name,
              table.concat(del_mod.version, ".")
            ),
            {
              config = { allow_cancel = true },

              { text = "Yes", colour = G.C.RED },
              { text = "No", colour = G.C.BLUE },
            },
            function(choice)
              if choice == "Yes" then
                del_mod:unload()
                for i, mod in ipairs(ALL_MODS) do
                  if mod == del_mod then
                    table.remove(ALL_MODS, i)
                    break
                  end
                end
                NFS.remove(del_mod.path)
                G.EZ_MOD_MENU.mod_pager:update()
              end
            end
          )
        else
          local options = {
            config = { allow_cancel = true, multi = true, pager = true },
          }

          for i, del_mod in ipairs(mods) do
            options[#options + 1] = { text = "v" .. table.concat(del_mod.version, "."), value = i }
          end

          Ezmod.ui.Ask("Version(s) to [G.C.RED]{'delete'} [::1.4]{'?'}", options, function(choices)
            local text = {
              string.format("Do you really wanna [G.C.RED]{'delete'} [G.C.ORANGE]{'%s'}", mod.name),
            }
            local del_mods = {}
            local first = true
            for i, delete in pairs(choices) do
              if delete then
                if first then
                  first = false
                else
                  text[#text] = text[#text] .. ","
                end
                text[#text + 1] = string.format("Version [G.C.GREEN]{'%s'}", table.concat(mods[i].version, "."))
                del_mods[#del_mods + 1] = mods[i]
              end
            end
            if not next(del_mods) then
              return
            end
            if #del_mods > 1 then
              text[#text] = "and " .. text[#text]
            end
            text[#text] = text[#text] .. "[::1.2]{'?'}"
            Ezmod.ui.Ask(text, {
              { text = "Yes", colour = G.C.RED },
              { text = "No", colour = G.C.BLUE },
            }, function(choice)
              if choice == "Yes" then
                for _, del_mod in ipairs(del_mods) do
                  del_mod:unload()
                  for i, mod in ipairs(ALL_MODS) do
                    if mod == del_mod then
                      table.remove(ALL_MODS, i)
                      break
                    end
                  end
                  Ezmod.util.fs_remove(del_mod.path)
                end
                G.EZ_MOD_MENU.mod_pager:update()
              end
            end)
          end)
        end
      end,
      icons,
      { x = 1, y = 0 },
    }
  else
    _control_buttons[#_control_buttons + 1] = {
      "Download",
      "download",
      darken(G.C.GREEN, 0.2),
      function()
        --TODO: download the mod
      end,
      icons,
    }
  end

  ctx_rows.config = { bg = G.C.GREY, inverse_colour = true }
  _control_buttons[#_control_buttons + 1] = {
    "...",
    "other",
    G.C.L_BLACK,
    function()
      Ezmod.ui.CtxMenu(ctx_rows, G.OVERLAY_MENU:get_UIE_by_ID(base_id .. "_other_area"))
    end,
  }

  for i, btn in ipairs(_control_buttons) do
    local button = Ezmod.ui.Button(
      btn[1],
      2,
      btn[3],
      base_id .. "_" .. btn[2] .. "_button",
      btn[4],
      { scale = 0.3, ref_table = mod, icon = btn[5], icon_offset = btn[6] }
    )
    button.nodes[1].config.shadow = false
    control_buttons[i] = Ezmod.ui.Row({
      c = { padding = 0.1 },
      n = {
        Ezmod.ui.Stack({
          Ezmod.ui.Box({ id = base_id .. "_" .. btn[2] .. "_area", w = 2, h = 0.3 }),
          button,
        }),
      },
    })
  end

  return Ezmod.ui.Row({
    c = { align = "cl", padding = 0.1, r = 0.1, emboss = 0.1, colour = G.C.WHITE },
    n = {
      Ezmod.ui.Row({
        n = {
          Ezmod.ui.Col({ c = { padding = 0.2, align = "cm" }, n = { mod:icon_ui(1.5, 1.5) } }),
          Ezmod.ui.Col({
            c = { padding = 0.1 },
            n = {
              Ezmod.ui.Row({
                c = { align = "tl" },
                n = {
                  Ezmod.ui.Row({
                    c = { align = "bl" },
                    n = {
                      Ezmod.ui.Stack({
                        Ezmod.ui.Box({ h = 0.01, w = 8 }),
                        Ezmod.ui.Row({
                          c = { align = "bl" },
                          n = {
                            Ezmod.ui.DynText({
                              string = mod.name,
                              colour = G.C.GREY,
                              scale = 0.4,
                              float = true,
                              shadow = true,
                            }),
                            #mod.author == 1 and Ezmod.ui.Space(0.2) or nil,
                            #mod.author == 1
                                and Ezmod.ui.Col({
                                  c = { align = "lb" },
                                  n = {
                                    Ezmod.ui.Text({
                                      text = "by " .. mod.author[1],
                                      colour = G.C.UI.TEXT_INACTIVE,
                                      scale = 0.3,
                                    }),
                                  },
                                })
                              or nil,
                          },
                        }),
                        mod.loaded
                            and Ezmod.ui.Row({
                              c = { align = "br" },
                              n = {
                                Ezmod.ui.Text({
                                  text = "Loaded",
                                  colour = G.C.BLUE,
                                  scale = 0.3,
                                }),
                                Ezmod.ui.Space(0.2),
                                Ezmod.ui.Text({
                                  text = "v" .. table.concat(mod.version, "."),
                                  colour = G.C.GREEN,
                                  scale = 0.3,
                                }),
                              },
                            })
                          or nil,
                      }),
                    },
                  }),
                  Ezmod.ui.Row({ n = { Ezmod.ui.Space(0, 0.05) } }),
                  Ezmod.ui.Row({ n = { Ezmod.ui.Box({ h = 0.03, w = 8, colour = G.C.GREY }) } }),
                  Ezmod.ui.Row({ n = { Ezmod.ui.Space(0, 0.1) } }),
                  Ezmod.ui.FmText(mod.desc, {
                    t = { colour = G.C.GREY, scale = 0.3 },
                    c = { align = "cl", line_space = 0.05 },
                    v = { self = mod },
                  }),
                },
              }),
            },
          }),
          Ezmod.ui.Col({ n = { Ezmod.ui.Space(0.1) } }),
          Ezmod.ui.Col({
            c = { align = "cl" },
            n = control_buttons,
          }),
        },
      }),

      Ezmod.ui.Row({
        c = { minw = 0.3 },
        n = (function()
          local tags = {}
          for i, tag in ipairs(mod.tags or {}) do
            if i ~= 1 then
              tags[#tags + 1] = Ezmod.ui.Col({ n = { Ezmod.ui.Space(0.1) } })
            end
            tags[#tags + 1] = Ezmod.ui.Col({
              c = { padding = 0.1, r = 0.1, emboss = 0.05, colour = G.C.GREEN },
              n = { Ezmod.ui.Text({ scale = 0.3, colour = G.C.WHITE, text = tag }) },
            })
          end
          return tags
        end)(),
      }),
    },
  })
end

function UI.error_description(error)
  local type = error.type
  local mod = error.mod
  local error_desc
  local function row(node, config)
    return Ezmod.ui.Row({ c = config or { align = "cm" }, n = { node } })
  end
  if type == "duplicate" then
    error_desc = Ezmod.ui.FmText({
      "[G.C.ORANGE]{mod.name} and [G.C.ORANGE]{MODS[mod.id].name}",
      "have a same [G.C.WHITE:G.C.RED]{'ID'} which is [G.C.BLUE]{mod.id}.",
    }, { t = { colour = G.C.GREY, scale = 0.3 }, c = { align = "cm", line_space = 0.1 }, v = { mod = mod } })
  elseif type == "missing_deps" then
    local text = {
      "[G.C.ORANGE]{mod.name} missing dependencies.",
    }
    for mod_id, spec in pairs(mod.deps) do
      if not spec.ok then
        if MODS[mod_id] then
          local indent = string.rep(" ", 8)
          text[#text + 1] =
            string.format("[:G.C.RED]{'ERROR'} Mod with id [G.C.ORANGE]{'%s'} version [G.C.RED]{'not match'} ", mod_id)
          text[#text + 1] = string.format(
            indent .. "- loaded version: [G.C.GREEN]{'%s'}",
            "v" .. table.concat(MODS[mod_id].version, ".")
          )

          if spec.version.upper then
            text[#text + 1] = string.format(
              indent .. "- required version: [G.C.GREEN]{'%s'} or [G.C.IMPORTANT]{'upper'}",
              "v" .. table.concat(spec.version.upper, ".")
            )
          elseif spec.version.lower then
            text[#text + 1] = string.format(
              indent .. "- required version: [G.C.GREEN]{'%s'} or [G.C.IMPORTANT]{'lower'}",
              "v" .. table.concat(spec.version.lower, ".")
            )
          elseif spec.version.exact then
            text[#text + 1] = string.format(
              indent .. "- required version: [G.C.GREEN]{'%s'}",
              "v" .. table.concat(spec.version.exact, ".")
            )
          elseif spec.version.from and spec.version.to then
            text[#text + 1] = string.format(
              indent .. "- required version: [G.C.GREEN]{'%s'} [G.C.IMPORTANT]{'to'} [G.C.GREEN]{'%s'}",
              "v" .. table.concat(spec.version.from, "."),
              "v" .. table.concat(spec.version.to, ".")
            )
          end
        else
          text[#text + 1] =
            string.format("[:G.C.RED]{'ERROR'} Mod with id [G.C.ORANGE]{'%s'} [G.C.RED]{'not found'} ", mod_id)
        end
      else
        text[#text + 1] = string.format("[:G.C.GREEN:1.2]{' OK '} Mod with id [G.C.ORANGE]{'%s'} loaded", mod_id)
      end
    end

    local formated = Ezmod.ui.FmText(
      text,
      { t = { colour = G.C.GREY, scale = 0.3 }, c = { align = "tl", line_space = 0.1 }, v = { mod = mod } }
    )
    formated.nodes[1].config = { align = "cm" }
    error_desc = row(formated, { padding = 0.1, align = "cm" })
  end
  return Ezmod.ui.Row({
    c = { align = "cm", padding = 0.05, r = 0.05, colour = G.C.WHITE, emboss = 0.08, minw = 7 },
    n = {
      row(
        Ezmod.ui.Text({ text = "Missing Dependencies", colour = G.C.RED, scale = 0.4 }),
        { padding = 0.1, align = "sm" }
      ),
      row(Ezmod.ui.Box({ h = 0.03, w = 6, colour = G.C.GREY })),
      error_desc,
    },
  })
end

function UI.error_mods()
  return Ezmod.ui.DarkBGRoot({
    Ezmod.ui.Row({
      c = { align = "cm", r = 0.3, colour = G.C.WHITE, emboss = 0.1 },
      n = {
        Ezmod.ui.Col({
          c = { align = "cm", r = 0.2, padding = 0.01, colour = G.C.RED },
          n = {
            Ezmod.ui.Row({
              c = { align = "cm", padding = 0.1 },
              n = {
                Ezmod.ui.Row({
                  c = { align = "cm", padding = 0.2, r = 0.08, colour = G.C.WHITE, emboss = 0.03 },
                  n = {
                    Ezmod.ui.Col({
                      c = { align = "cm", colour = G.C.RED, padding = 0.1, r = 0.3 },
                      n = {
                        Ezmod.ui.Space(0.1),
                        Ezmod.ui.Text({ text = "!", colour = G.C.WHITE, scale = 0.5 }),
                        Ezmod.ui.Space(0.1),
                      },
                    }),
                    Ezmod.ui.Space(0.3),
                    Ezmod.ui.Text({ text = "Error Loading Mods!", colour = G.C.UI.TEXT_DARK, scale = 0.65 }),
                    Ezmod.ui.Space(0.3),
                  },
                }),
                Ezmod.ui.Row({
                  c = { align = "cm", padding = 0.2, colour = G.C.L_BLACK, emboss = 0.05, r = 0.1, minw = 6, minh = 5 },
                  n = {
                    { n = G.UIT.O, config = { object = Moveable(), id = "ezm_mod_errors_container" } },
                  },
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
  return Ezmod.ui.DarkBGRoot({
    Ezmod.ui.Row({
      c = { id = "ez_mod_menu", align = "cm", r = 0.3, padding = 0.05, colour = G.C.WHITE, emboss = 0.1 },
      n = {
        Ezmod.ui.Row({
          c = { align = "cm", r = 0.25, padding = 0.3, colour = G.C.L_BLACK },
          n = {
            Ezmod.ui.Col({
              c = { minh = 11.5, align = "tm" },
              n = {
                UI.mod_menu_tabs(),
                Ezmod.ui.Col({ n = { Ezmod.ui.Space(0.1, 0.5) } }),
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
  local tabw = 17
  local btn_width = tabw / #buttons

  local nodes = {}
  for i, btn in ipairs(buttons) do
    nodes[i] = Ezmod.ui.Button(btn[1], btn_width, G.C.EZM.TAB, "ez_mod_menu_tabs_" .. btn[2] .. "_button", function()
      G.FUNCS.mod_menu_switch_tab(btn[2])
    end, { scale = 0.6 })
  end

  return Ezmod.ui.Row({
    c = { id = "ez_mod_menu_tabs", align = "cm", padding = 0.1, colour = G.C.GREY, r = 0.1, minw = tabw },
    n = nodes,
  })
end

function UI.mod_menu_browser()
  return Ezmod.ui.Root({
    c = { align = "cm", colour = G.C.CLEAR },
    n = {
      Ezmod.ui.Col({
        c = { align = "tm", padding = 0.1 },
        n = {
          Ezmod.ui.Col({
            c = { align = "cm", minw = 17, id = "ez_mod_menu_browser_bar" },
            n = {
              Ezmod.ui.Button("<", 0.5, G.C.RED, "ez_mod_menu_browser_back"),
              Ezmod.ui.Space(0.1),
              Ezmod.ui.Button("Refresh", 1.5, G.C.RED, "ez_mod_menu_browser_refresh"),
              Ezmod.ui.Space(0.1),
              Ezmod.ui.TextInput({
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
  local pager = G.EZ_MOD_MENU.mod_pager or Ezmod.ui.Pager(ALL_MODS, 3):cycle()
  G.EZ_MOD_MENU.mod_pager = pager
  function pager.unique_id(mod)
    return mod.id
  end

  return Ezmod.ui.Root({
    c = { align = "cm", colour = G.C.CLEAR },
    n = {
      Ezmod.ui.Col({
        c = { align = "tm", padding = 0.1 },
        n = {
          Ezmod.ui.Col({
            c = { align = "cm", minw = 17, id = "ez_mod_menu_browser_bar" },
            n = {
              Ezmod.ui.Row({
                n = {
                  UI.mod_menu_mods_tabs(),
                  pager:ui(17, 9.3, UI.mod_box),
                },
              }),
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
  local tabw = 17
  local btn_width = tabw / #buttons

  local nodes = {}
  for i, btn in ipairs(buttons) do
    nodes[i] = Ezmod.ui.Button(
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

  return Ezmod.ui.Row({
    c = { id = "ez_mod_menu_mods_tab", align = "cm", padding = 0.05, colour = G.C.CLEAR, minw = tabw },
    n = nodes,
  })
end

return UI
