local Mod = Object:extend()

function Mod:init(spec)
  self.id = spec.id
  self.name = spec.name
  self.prefix = spec.prefix
  self.tags = spec.tags
  self.path = spec.path
  self.deps = {}
  self.desc = {}
  self.icon = spec.icon
  self.loaded = false
  for line in spec.desc:gmatch("([^\n]*)\n?") do
    self.desc[#self.desc + 1] = line
  end

  for _, dep in ipairs(spec.deps) do
    self.deps[dep.id] = {
      version = Ezutil.parse_version_spec(dep.version),
      ok = false,
    }
  end
end

function Mod:resolve()
  --TODO: resolove depencdencies and return total of downloaded depencdencies
  return 0
end

function Mod:load()
  if self.loaded then
    return
  end
  self.loaded = true
  --TODO: run then entry point of mod
end

function Mod:unload()
  if not self.loaded then
    return
  end
  self.loaded = false
  --TODO: unload mod (only work for EZ API only)
end

function Mod:icon_ui(w, h)
  if self.icon then
    if self.icon[1] == "animated" then
      local path = self.icon[2]
      local size = type(self.icon[3]) == "number" and {self.icon[3], self.icon[3]} or self.icon[3]
      local frames = self.icon[4]
      local key = "ezmod_" .. self.id .. "_animated_icon:" .. path
      local s = G.ANIMATION_ATLAS[key]
      if not s then
        local img = love.graphics.newImage(
          Ezutil.new_file_data(self.path .. "/assets/" .. path),
          { mipmaps = true, dpiscale = 1 }
        )
        local data = {
          name = path,
          image = img,
          px = size[1],
          py = size[2],
          frames = frames,
        }
        G.ANIMATION_ATLAS[key] = data
        s = data
      end

      return { n = G.UIT.O, config = { object = AnimatedSprite(0, 0, w or 1, h or 1, s) } }
    elseif self.icon[1] == "image" then
      local path = self.icon[2]
      local key = "ezmod_" .. self.id .. "_icon:" .. path
      local s = G.ASSET_ATLAS[key]
      if not s then
        local img = love.graphics.newImage(
          Ezutil.new_file_data(self.path .. "/assets/" .. path),
          { mipmaps = true, dpiscale = 1 }
        )
        local data = {
          name = path,
          image = img,
          px = img:getWidth(),
          py = img:getHeight(),
        }
        G.ASSET_ATLAS[key] = data
        s = data
      end
      return { n = G.UIT.O, config = { object = Sprite(0, 0, w or 1, h or 1, s) } }
    else
    end
  else
    -- Use rare joker tag sprite if didn't have an icon
    return Ezui.Sprite("tags", w or 1, h or 1, { x = 1, y = 0 })
  end
end

return Mod
