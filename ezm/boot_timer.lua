local info_queue = {}
local loading_name
local max_queue = 15

function boot_timer(_, next, progress, _new_loading)
  if _new_loading then
    loading_name = _new_loading
    info_queue = {}
  end
  if #info_queue > max_queue then
    table.remove(info_queue, 1)
  end
  info_queue[#info_queue + 1] = next

  progress = progress or 0
  G.LOADING = G.LOADING
    or {
      font = love.graphics.setNewFont("resources/fonts/m6x11plus.ttf", 20),
      love.graphics.dis,
    }
  local realw, realh = love.window.getMode()
  if progress > 0 and progress < 1 then
    love.graphics.setCanvas()
    love.graphics.push()
    love.graphics.setShader()
    love.graphics.clear(0, 0, 0, 1)

    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", 0, realh - 30, realw, 30)
    love.graphics.setColor(HEX("009dff"))
    love.graphics.rectangle("fill", 0, realh - 30, progress * realw, 30)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(3)

    local font = love.graphics.getFont()
    local height = font:getHeight()
    local y = realh - 30 - 5 - (#info_queue * height)
    for i = 1, #info_queue - 1 do
      love.graphics.setColor(1, 1, 1, 1 - ((1 / max_queue) * ((#info_queue - i) - 1)))
      love.graphics.print("> " .. info_queue[i], 5, y)
      y = y + height
    end

    local margin = 5
    local loading_margin = 10
    local loading_text = string.format(" %s ", loading_name or "BALATRO")
    local loading_text_width = font:getWidth(loading_text)
    local loading_width = loading_text_width + (margin * 2)
    local y = realh - 30 - 2 - height
    love.graphics.setColor(HEX("4BC292"))
    love.graphics.rectangle("fill", margin, y, loading_width, height)
    love.graphics.setColor(0.2, 0.1, 0.1, 1)
    love.graphics.print(loading_text, margin * 2, y)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(" " .. info_queue[#info_queue], margin + loading_margin + loading_text_width, y)
    love.graphics.setColor(0, 0, 0, 1)
    local percentage = tostring(progress * 100)
    if #percentage > 4 then
      percentage = percentage:match("(.....)")
    end
    percentage = percentage .. " %"
    local width = font:getWidth(percentage)
    love.graphics.print(percentage, (realw / 2) - (width / 2), realh - height - 5)
    love.graphics.pop()
    love.graphics.present()
  end

  G.ARGS.bt = G.ARGS.bt or love.timer.getTime()
  G.ARGS.bt = love.timer.getTime()
end
