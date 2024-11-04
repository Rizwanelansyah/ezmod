local Pager = Object:extend()

function Pager:init(data, max)
  self._data = data or {}
  self.data = self._data
  self.max = max or 4
  self.current_page = 1
  self:update()
end

function Pager:update()
  self:filter()
  self.max_page = 1
  local len, field = 0, next(self.data)
  while field do
    len = len + 1
    field = next(self.data, field)
  end
  self.max_page = math.max(1, math.ceil(len / self.max))

  self.location_display = self.current_page .. " / " .. self.max_page
  if G.OVERLAY_MENU then
    local preview = G.OVERLAY_MENU:get_UIE_by_ID("ezui_pager_data_preview")
    if preview then
      preview.config.object:remove()
      preview.config.object = self:data_preview()
    end
  end
end

function Pager:ui(width, height, fn)
  self.format_data = fn

  return Ezui.Row({
    n = {
      Ezui.Row({
        c = { align = "tm", minh = height or 7 },
        n = {
          { n = G.UIT.O, config = { object = self:data_preview(), id = "ezui_pager_data_preview" } },
        },
      }),
      Ezui.Row({
        n = {
          Ezui.Col({
            c = { align = "cm", minw = width or 10 },
            n = {
              Ezui.Button("<", 0.5, G.C.RED, "ezui_pager_prev", function()
                self:prev_page()
              end),
              Ezui.Space(0.3),
              Ezui.Button(
                nil,
                (width or 10) * 0.5,
                G.C.RED,
                "ezui_pager_location",
                function()
                  local rows = {}
                  for i = 1, self.max_page do
                    rows[#rows+1] = {
                      text = tostring(i),
                      fn = function ()
                        self:set_page(i)
                      end,
                    }
                  end
                  Ezui.CtxMenu(rows, G.OVERLAY_MENU:get_UIE_by_ID("ezui_pager_location"))
                end,
                { ref_table = self, text_field = "location_display" }
              ),
              Ezui.Space(0.3),
              Ezui.Button(">", 0.5, G.C.RED, "ezui_pager_next", function()
                self:next_page()
              end),
            },
          }),
        },
      }),
    },
  })
end

function Pager:page(number)
  self.current_page = math.max(1, math.min(self.max_page, number or self.current_page))

  local data = {}
  local i = 1
  local c = 1
  local from = (self.current_page - 1) * self.max
  for _, d in pairs(self.data) do
    if c > from then
      if i > self.max then
        break
      end
      data[i] = d
      i = i + 1
    end
    c = c + 1
  end
  return data
end

function Pager:set_filter(fn)
  self.filter_fn = fn
  self:update()
end

function Pager:filter()
  if not self.filter_fn then
    self.data = self._data
    return
  end
  self.data = {}
  for _, d in pairs(self._data) do
    if self.filter_fn(d) then
      self.data[#self.data + 1] = d
    end
  end
end

function Pager:data_preview()
  if not self.format_data then
    return Moveable()
  end

  local nodes = {}

  for _, data in ipairs(self:page()) do
    nodes[#nodes + 1] = self.format_data(data)
  end

  return UIBox({
    definition = Ezui.Root({
      c = { colour = G.C.CLEAR },
      n = {
        Ezui.Row({ c = { align = "cm", padding = 0.1 }, n = nodes }),
      },
    }),
    config = { parent = G.OVERLAY_MENU:get_UIE_by_ID("ezui_pager_data_preview") },
  })
end

function Pager:next_page()
  local new_page = self.current_page + 1
  self.current_page = self._cycle and (new_page > self.max_page and 1 or new_page) or math.min(self.max_page, new_page)
  self:update()
end

function Pager:prev_page()
  local new_page = self.current_page - 1
  self.current_page = self._cycle and (new_page < 1 and self.max_page or new_page) or math.max(1, new_page)
  self:update()
end

function Pager:set_page(number)
  number = number or 1
  self.current_page = number
  self:update()
end

function Pager:cycle()
  self._cycle = true
  return self
end

return Pager
