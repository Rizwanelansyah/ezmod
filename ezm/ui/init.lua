local UI = {}

function UI.Root(opt)
  return { n = G.UIT.ROOT, config = opt.c, nodes = opt.n }
end

function UI.DarkBGRoot(nodes)
  return UI.Root({
    c = {
      align = "cm",
      minw = G.ROOM.T.w * 5,
      minh = G.ROOM.T.h * 5,
      padding = 0.1,
      r = 0.1,
      colour = { G.C.GREY[1], G.C.GREY[2], G.C.GREY[3], 0.8 },
    },
    n = nodes,
  })
end

function UI.Row(opt)
  return { n = G.UIT.R, config = opt.c, nodes = opt.n }
end

function UI.Col(opt)
  return { n = G.UIT.C, config = opt.c, nodes = opt.n }
end

function UI.Text(opt)
  if type(opt) == "string" then
    opt = { text = opt }
  end
  return { n = G.UIT.T, config = opt }
end

function UI.Box(opt)
  return { n = G.UIT.B, config = opt }
end

function UI.Space(w, h)
  return UI.Box({ w = w, h = h or 0.1 })
end

function UI.DynText(opt)
  if type(opt) == "string" then
    opt = { string = opt }
  end
  return { n = G.UIT.O, config = { object = DynaText(opt) } }
end

local function create_fmtext(text, conf, var)
  local result = {}
  conf = conf or {}
  conf.colour = conf.colour or G.C.GREY
  conf.scale = conf.scale or 0.5

  for i, node in ipairs(Ezmod.util.parse_fmtext(text, conf, var)) do
    if node.type == "text" then
      result[i] = UI.Text({ text = node.text, colour = conf.colour, scale = conf.scale })
    elseif node.type == "textbox" then
      local scale = node.scale
      result[i] = UI.Col({
        c = { colour = node.bg or conf.colour, padding = 0.05 * scale, align = "cm", r = 0.03 },
        n = {
          UI.Space(0.3 * scale),
          UI.Text({
            text = node.text,
            colour = node.fg,
            scale = scale,
          }),
          UI.Space(0.3 * scale),
        },
      })
    elseif node.type == "colored" then
      result[i] = UI.Text({
        text = node.text,
        colour = node.colour,
        scale = node.scale,
      })
    elseif node.type == "object" then
      result[i] = { n = G.UIT.O, config = { object = node.object } }
    end
  end
  return result
end

function UI.FmText(lines, opt)
  opt = opt or {}
  opt.c = opt.c or {}
  opt.t = opt.t or {}
  local parsed_lines = {}
  if type(lines) == "string" then
    lines = { lines }
  end
  local var = {}
  for key, value in pairs(opt.v) do
    var[key] = value
  end
  var.__opt = opt
  for i, line in ipairs(lines) do
    if opt.c.line_space and i ~= 1 then
      parsed_lines[#parsed_lines + 1] = UI.Row({ n = { UI.Space(0.01, opt.c.line_space * (opt.t.scale or 1)) } })
    end
    parsed_lines[#parsed_lines + 1] = UI.Row({
      n = {
        UI.Col({ c = { align = "cm" }, n = create_fmtext(line, opt.t, var) }),
      },
      c = opt.c,
    })
  end
  return UI.Row({ c = opt.c, n = parsed_lines })
end

function UI.TextInput(opt)
  if opt.colour then
    opt.hooked_colour = opt.hooked_colour or darken(copy_table(opt.colour), 0.3)
  end
  local input = create_text_input(opt)
  input.nodes[1].config.id = opt.id
  return input
end

function UI.Button(opt, width, colour, id, fn, alt_opt)
  if type(opt) == "table" then
    return UIBox_button(opt)
  else
    opt = {
      id = id or string.lower(tostring(opt)):gsub("[^%d%w]+", "_"),
      label = opt and { tostring(opt) },
      colour = colour,
      col = true,
      scale = 0.4,
      minh = 0.4,
      minw = width,
      padding = 0.1,
    }
    if fn then
      opt.button = opt.id .. "_on_click"
      G.FUNCS[opt.button] = fn
    else
      opt.button = nil
    end
    for k, v in pairs(alt_opt or {}) do
      opt[k] = v
    end
    return UIBox_button(opt)
  end
end

function UI.Toggle(opt, width, id, ref_table, ref_value, alt_opt)
  if type(opt) == "table" then
    return create_toggle(opt)
  else
    opt = {
      id = id or string.lower(tostring(opt)):gsub("[^%d%w]+", "_"),
      label = opt,
      h = 0.4,
      w = width,
      col = true,
      padding = 0.1,
      ref_table = ref_table,
      ref_value = ref_value,
    }
    for k, v in pairs(alt_opt or {}) do
      opt[k] = v
    end
    return create_toggle(opt)
  end
end

function UI.Image(path, width, height)
  local key = "ezui_image:" .. path
  local s = G.ASSET_ATLAS[key]
  if not s then
    local img = love.graphics.newImage(Ezmod.util.new_file_data(path), { mipmaps = true, dpiscale = 1 })
    local data = {
      name = path,
      image = img,
      px = img:getWidth(),
      py = img:getHeight(),
    }
    G.ASSET_ATLAS[key] = data
    s = data
  end
  return { n = G.UIT.O, config = { object = Sprite(0, 0, width, height, G.ASSET_ATLAS[key]) } }
end

function UI.Sprite(name, width, height, offset)
  if type(name) == "table" then
    return { n = G.UIT.O, config = { object = Sprite(0, 0, width, height, name, offset) } }
  end
  return { n = G.UIT.O, config = { object = Sprite(0, 0, width, height, G.ASSET_ATLAS[name], offset) } }
end

function UI.Stack(nodes)
  return { n = G.UIT.STK, nodes = nodes }
end

UI.Ask = require("ezm.ui.ask")
UI.Pager = require("ezm.ui.pager")
UI.CtxMenu = require("ezm.ui.ctx_menu")

return UI
