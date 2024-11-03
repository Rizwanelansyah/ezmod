local Pager = Object:extend()

function Pager:init(data, max)
  self._data = data or {}
  self.data = self._data
  self.max = max or 4
  self.current_page = 1
  self:update()
end

function Pager:update()
  self.max_page = 1
  local len, field = 0, next(self.data)
  while field do
    len = len + 1
    field = next(self.data, field)
  end
  self.max_page = math.max(1, math.ceil(len / self.max))

  self.location_display = self.current_page .. " / " .. self.max_page
end

function Pager:ui(width, height, fn)
  self.format_data = fn

  return Ezui.Row({
    n = {
      Ezui.Row({
        c = { align = "tm", minh = height or 7 },
        n = {
          { n = G.UIT.O, config = { object = self:data_preview(1), id = "ezui_pager_data_preview" } },
        },
      }),
      Ezui.Row({
        n = {
          Ezui.Col({
            c = { align = "cm", minw = width },
            n = {
              Ezui.Button("<", 0.5, G.C.RED, "ezui_pager_prev", function()
                self:prev_page()
              end),
              Ezui.Space(0.3),
              Ezui.Button(
                nil,
                2.4,
                G.C.RED,
                "ezui_pager_location",
                nil,
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
  self:update()
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

function Pager:data_preview()
  if not self.format_data then
    return Movable()
  end

  local nodes = {}

  for _, data in ipairs(self:page()) do
    nodes[#nodes + 1] = self.format_data(data)
  end

  return UIBox({
    definition = Ezui.Root({ c = { colour = G.C.CLEAR }, n = {
      Ezui.Row({ c = { padding = 0.1 }, n = nodes }),
    } }),
    config = { parent = G.OVERLAY_MENU:get_UIE_by_ID("ezui_pager_data_preview") },
  })
end

function Pager:next_page()
  self.current_page = math.min(self.max_page, self.current_page + 1)
  local preview = G.OVERLAY_MENU:get_UIE_by_ID("ezui_pager_data_preview")
  preview.config.object:remove()
  preview.config.object = self:data_preview()
  self:update()
end

function Pager:prev_page()
  self.current_page = math.max(1, self.current_page - 1)
  local preview = G.OVERLAY_MENU:get_UIE_by_ID("ezui_pager_data_preview")
  preview.config.object:remove()
  preview.config.object = self:data_preview()
  self:update()
end

return Pager
