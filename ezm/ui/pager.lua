local Pager = Object:extend()

function Pager:init(data, max, opt)
  self._data = data or {}
  self.data = self._data
  self.max = max or 4
  self.current_page = 1

  opt = opt or {}

  if opt.search_str or opt.match_search then
    self.search = ""
    self.search_str = opt.search_str
    self.match_search = opt.match_search
  end

  if opt.filters and next(opt.filters) then
    self.default_filter = opt.default_filter or next(opt.filters)
    self.filters = opt.filters
    self.filter = self.filters[self.default_filter]
  end

  if opt.unique_id then
    self.unique_id = opt.unique_id
  end

  self.cycle = opt.cycle
  self.on_duplicate = opt.on_duplicate

  self:update()
end

function Pager:update()
  self:filter_data()
  self.max_page = 1
  local len, field = 0, next(self.data)
  while field do
    len = len + 1
    field = next(self.data, field)
  end
  self.max_page = math.max(1, math.ceil(len / self.max))
  self:update_ui()
  return self
end

function Pager:update_ui()
  self.location_display = self.current_page .. " / " .. self.max_page
  local preview = self:get_UIE("ezui_pager_data_preview")
  if preview then
    preview.config.object:remove()
    preview.config.object = self:data_preview()
    preview.UIBox:recalculate()
  end
  return self
end

function Pager:get_UIE(id)
  local uie
  for _, ui in ipairs({ G.OVERLAY_MENU, G.EZUI_ASK_MENU }) do
    local c = ui:get_UIE_by_ID(id)
    if c then
      uie = c
      break
    end
  end
  return uie
end

function Pager:ui(width, height, fn)
  self.format_data = fn
  self.ui_width = width
  self.ui_height = height

  local nodes = {}

  if self.search then
    nodes[#nodes + 1] = Ezmod.ui.Col({
      c = { align = "cm", minw = width - 1.8 },
      n = {
        Ezmod.ui.TextInput({
          id = "ezui_pager_search_bar",
          prompt_text = "Search...",
          text_scale = 0.4,
          max_length = 50,
          ref_table = self,
          ref_value = "search",
          w = width - 2,
          accept_all = true,
          on_esc = function()
            self:update()
          end,
        }),
      },
    })
  end

  if self.filters then
    nodes[#nodes + 1] = Ezmod.ui.Col({
      c = { align = "cm", minw = 1.5 },
      n = {
        Ezmod.ui.Button("Filter", 1.5, G.C.RED, "ezui_pager_filter", function()
          local rows = {}
          for name, fn in pairs(self.filters) do
            rows[#rows + 1] = {
              text = name,
              colour = fn == self.filter and G.C.RED or nil,
              fn = function()
                self.filter = self.filters[name]
                self:update()
              end,
            }
          end
          Ezmod.ui.CtxMenu(rows, self:get_UIE("ezui_pager_filter"))
        end),
      },
    })
  end

  return Ezmod.ui.Row({
    n = {
      (self.search or self.filters) and Ezmod.ui.Row({
        c = { align = "cm", minw = width, padding = 0.05 },
        n = nodes,
      }) or nil,
      Ezmod.ui.Row({
        c = { align = "tm", minh = height or 7 },
        n = {
          { n = G.UIT.O, config = { object = self:data_preview(), id = "ezui_pager_data_preview" } },
        },
      }),
      Ezmod.ui.Row({
        n = {
          Ezmod.ui.Col({
            c = { align = "cm", minw = width or 10 },
            n = {
              Ezmod.ui.Button("<", 0.5, G.C.RED, "ezui_pager_prev", function()
                self:prev_page()
              end),
              Ezmod.ui.Space(0.3),
              Ezmod.ui.Button(nil, (width or 10) * 0.5, G.C.RED, "ezui_pager_location", function()
                local rows = {}
                local page_numbers = {}
                if self.max_page == 1 then
                  return
                end

                page_numbers[#page_numbers + 1] = 1
                if self.current_page - 2 > 1 then
                  page_numbers[#page_numbers + 1] = self.current_page - 2
                end
                if self.current_page - 1 > 1 then
                  page_numbers[#page_numbers + 1] = self.current_page - 1
                end
                if self.current_page + 1 < self.max_page then
                  page_numbers[#page_numbers + 1] = self.current_page + 1
                end
                if self.current_page + 2 < self.max_page then
                  page_numbers[#page_numbers + 1] = self.current_page + 2
                end
                page_numbers[#page_numbers + 1] = self.max_page

                for _, i in ipairs(page_numbers) do
                  rows[#rows + 1] = {
                    text = tostring(i),
                    colour = (i == 1 or i == self.max_page) and G.C.RED or nil,
                    fn = function()
                      self:set_page(i)
                    end,
                  }
                end

                Ezmod.ui.CtxMenu(rows, self:get_UIE("ezui_pager_location"))
              end, { ref_table = self, text_field = "location_display" }),
              Ezmod.ui.Space(0.3),
              Ezmod.ui.Button(">", 0.5, G.C.RED, "ezui_pager_next", function()
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

function Pager:filter_data()
  if not self.filter and not self.unique_id then
    self.data = self._data
    return
  end
  self.data = {}
  local unique_datas = {}
  for _, d in pairs(self._data) do
    local add = false
    local id = self.unique_id(d)
    if self.unique_id then
      local exists = unique_datas[id]
      if not exists then
        add = true
      end
    end

    if self.filter and not self.filter(d) then
      add = false
    end

    if add and self.search and self.search ~= "" then
      add = false
      if self.match_search then
        add = self.match_search(self.search, d)
      elseif self.search_str then
        local search_str = self.search_str(d)
        for _, str in ipairs(search_str) do
          if next(Ezmod.util.fuzzy_search(str:lower(), self.search:lower())) then
            add = true
            break
          end
        end
      end
    end

    if self.on_duplicate and not add and unique_datas[id] then
      local unique_data = unique_datas[id]
      local new_data = self.on_duplicate(unique_datas[id], d) or unique_data
      if new_data ~= unique_data then
        for key, listed_data in pairs(self.data) do
          if listed_data == unique_data then
            self.data[key] = new_data
            unique_datas[id] = new_data
          end
        end
      end
    end

    if add then
      unique_datas[id] = d
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
    definition = Ezmod.ui.Root({
      c = { colour = G.C.CLEAR },
      n = {
        Ezmod.ui.Row({ c = { align = "cm", padding = 0.1 }, n = nodes }),
      },
    }),
    config = { parent = self:get_UIE("ezui_pager_data_preview") },
  })
end

function Pager:next_page()
  local new_page = self.current_page + 1
  self.current_page = self.cycle and (new_page > self.max_page and 1 or new_page) or math.min(self.max_page, new_page)
  return self:update_ui()
end

function Pager:prev_page()
  local new_page = self.current_page - 1
  self.current_page = self.cycle and (new_page < 1 and self.max_page or new_page) or math.max(1, new_page)
  return self:update_ui()
end

function Pager:set_page(number)
  number = number or 1
  self.current_page = number
  return self:update_ui()
end

return Pager
