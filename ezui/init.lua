local UI = {}

local function strat(s, i)
  return string.sub(s, i, i)
end

local function eval(code, var)
  local env = setmetatable({}, {
    __index = function(t, k)
      return rawget(t, k) or var[k] or _G[k]
    end,
  })
  local f = load("return " .. (code or "nil"), "eval", "bt", env)
  return f and f()
end

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

function parse_text(text, conf, var)
  local result = {}
  local i = 1
  local len = #text
  local cur
  local has_bg = false
  conf = conf or {}
  conf.colour = conf.colour or G.C.GREY
  conf.scale = conf.scale or 0.5

  while i <= len do
    local char = strat(text, i)
    if char == "[" then
      if cur then
        result[#result + 1] = UI.Text({ text = cur, colour = conf.colour, scale = conf.scale })
      end
      cur = char
      i = i + 1
      local fg, bg, text_scale, val
      local fail = false

      if i <= len and strat(text, i) ~= ":" and strat(text, i) ~= "]" then
        fg = ""
        while i <= len and strat(text, i) ~= ":" and strat(text, i) ~= "]" do
          if strat(text, i) == "%" then
            i = i + 1
          end
          fg = fg .. strat(text, i)
          i = i + 1
        end
        cur = cur .. fg
      end

      if i <= len and strat(text, i) == ":" then
        i = i + 1
        cur = cur .. ":"
        bg = ""
        while i <= len and strat(text, i) ~= "]" and strat(text, i) ~= ":" do
          if strat(text, i) == "%" then
            i = i + 1
          end
          bg = bg .. strat(text, i)
          i = i + 1
        end
        cur = cur .. bg
      end

      if i <= len and strat(text, i) == ":" then
        i = i + 1
        cur = cur .. ":"
        text_scale = ""
        while i <= len and strat(text, i) ~= "]" do
          if strat(text, i) == "%" then
            i = i + 1
          end
          text_scale = text_scale .. strat(text, i)
          i = i + 1
        end
        cur = cur .. bg
      end

      if i <= len and strat(text, i) == "]" then
        cur = cur .. strat(text, i)
        i = i + 1
      else
        fail = true
      end

      if not fail and i <= len and strat(text, i) == "{" then
        cur = cur .. strat(text, i)
        i = i + 1
        val = ""
        while i <= len and strat(text, i) ~= "}" do
          if strat(text, i) == "%" then
            i = i + 1
          end
          val = val .. strat(text, i)
          i = i + 1
        end
      else
        fail = true
      end

      if not fail and i <= len and strat(text, i) == "}" then
        cur = cur .. strat(text, i)
        i = i + 1
      else
        fail = true
      end

      if not fail then
        cur = nil
        local bgcolor = eval(bg, var)
        local scale = 1
        if text_scale then
          scale = eval(text_scale, var) or scale
        end
        if bgcolor then
          if not has_bg then
            has_bg = true
          end
          result[#result + 1] = UI.Col({
            c = { colour = bgcolor or conf.colour, padding = 0.05 * conf.scale * scale, align = "cm" },
            n = {
              UI.Space(0.3 * conf.scale * scale),
              UI.Text({
                text = eval(val, var),
                colour = fg and eval(fg, var) or conf.colour,
                scale = conf.scale * scale,
              }),
              UI.Space(0.3 * conf.scale * scale),
            },
          })
        else
          result[#result + 1] = UI.Text({
            text = eval(val, var),
            colour = fg and eval(fg, var) or conf.colour,
            scale = conf.scale * scale,
          })
        end
      end
    elseif char == "#" then
      if cur then
        result[#result + 1] = UI.Text({ text = cur, colour = conf.colour, scale = conf.scale })
      end
      cur = nil
      i = i + 1
      local val = ""
      while i <= len and strat(text, i) ~= "#" do
        if strat(text, i) == "%" then
          i = i + 1
        end
        val = val .. strat(text, i)
        i = i + 1
      end
      if i <= len then
        i = i + 1
      end
      result[#result + 1] = UI.Text({ text = eval(val, var), colour = conf.colour, scale = conf.scale })
    elseif char == "@" then
      if cur then
        result[#result + 1] = UI.Text({ text = cur, colour = conf.colour, scale = conf.scale })
      end
      cur = char
      i = i + 1
      local object
      local fail = false
      if i <= len and strat(text, i) == "(" then
        cur = cur .. "("
        i = i + 1
      end

      if i <= len and strat(text, i) ~= ")" then
        object = ""
        while i <= len and strat(text, i) ~= ")" do
          if strat(text, i) == "%" then
            i = i + 1
          end
          object = object .. strat(text, i)
          i = i + 1
        end
        cur = cur .. object
      end

      if i <= len and strat(text, i) == ")" then
        cur = cur .. strat(text, i)
        i = i + 1
      else
        fail = true
      end

      if not fail then
        cur = nil
        local o = eval(object, var)
        result[#result + 1] = { n = G.UIT.O, config = { object = o or Moveable() } }
      end
    elseif char == "%" then
      cur = (cur or "") .. strat(text, i + 1)
      i = i + 2
    else
      cur = (cur or "") .. char
      i = i + 1
    end
  end
  if cur then
    result[#result + 1] = UI.Text({ text = cur, colour = conf.colour, scale = conf.scale })
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
        UI.Col({ c = { align = "cm" }, n = parse_text(line, opt.t, var) }),
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
  return create_text_input(opt)
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

UI.Ask = require("ezui.ask")
UI.Pager = require("ezui.pager")
UI.CtxMenu = require("ezui.ctx_menu")

return UI
