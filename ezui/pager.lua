local Pager = Object:extend()

function Pager:init(data, max)
  self.data = data or {}
  self.max = max or 4
end

function Pager:ui(width, height, fn)
  local nodes = {}

  if fn then
    for _, data in ipairs(self:page(1)) do
      nodes[#nodes + 1] = fn(data)
    end
  end
  EZDBG(nodes)

  return Ezui.Row({
    n = {
      Ezui.Row({
        c = { align = "tm", padding = 0.1, minh = height or 7 },
        n = nodes,
      }),
      Ezui.Row({
        n = {
          Ezui.Col({
            c = { align = "cm", minw = width },
            n = {
              Ezui.Button("<", 0.5, G.C.RED, "ezm_pager_prev"),
              Ezui.Space(0.3),
              Ezui.Button("1 / 10", 2.4, G.C.RED, "ezm_pager_location"),
              Ezui.Space(0.3),
              Ezui.Button(">", 0.5, G.C.RED, "ezm_pager_next"),
            },
          }),
        },
      }),
    },
  })
end

function Pager:page(number)
  local data = {}
  local i = 1
  local from = (number - 1) * self.max
  for _, d in pairs(self.data) do
    if i > from then
      if i > self.max then
        break
      end
      data[i] = d
      i = i + 1
    end
  end
  return data
end

return Pager
