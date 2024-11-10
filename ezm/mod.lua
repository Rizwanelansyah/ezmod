local Mod = Object:extend()

function Mod:init(opt)
  self.id = opt.id
  self.name = opt.name
  self.prefix = opt.prefix
  self.tags = opt.tags
  self.path = opt.path
  self.icon = opt.icon
  self.downloaded = opt.downloaded
  self.loaded = false
  self.version = Ezmod.util.parse_version(opt.version)
  self.files = opt.files
  self.git_ref = opt.git_ref or function()
    return table.concat(self.version, ".")
  end
  self.author = opt.author
  self.need_relog = opt.need_relog
  self.has_error = false

  self.desc = {}
  if opt.desc then
    for line in opt.desc:gsub("\\\n", ""):gmatch("([^\n]*)\n?") do
      self.desc[#self.desc + 1] = line
    end
  end

  self.deps = {}
  for dep_id, dep_or_version in pairs(opt.deps) do
    if type(dep_id) == "number" then
      self.deps[dep_or_version] = { ok = false }
    else
      self.deps[dep_id] = {
        version = dep_or_version and Ezmod.util.parse_version_spec(dep_or_version),
        ok = false,
      }
    end
  end
end

function Mod:resolve()
  local succes = true
  local new_mods = 0
  for dep_id, spec in pairs(self.deps) do
    if not spec.ok then
      local dep_mod = MODS[dep_id]
      local dep_mods = {}
      if not dep_mod then
        local mods = Ezmod.list_downloaded_mods()
        succes = false
        for _, mod in pairs(mods or {}) do
          if mod.id == dep_id then
            succes = true
          end
        end
      else
        dep_mods = { dep_mod }
      end
      local valid_mod
      for _, mod in pairs(dep_mods) do
        if spec.version then
          if spec.version.upper then
            if Ezmod.util.version_greater_equal(mod.version, spec.version.upper) then
              valid_mod = mod
              break
            end
          elseif spec.version.lower then
            if Ezmod.util.version_less_equal(mod.version, spec.version.upper) then
              valid_mod = mod
              break
            end
          elseif spec.version.exact then
            if Ezmod.util.version_equal(mod.version, spec.version.upper) then
              valid_mod = mod
              break
            end
          elseif spec.version.from and spec.version.to then
            if
              Ezmod.util.version_greater_equal(mod.version, spec.version.from)
              and Ezmod.util.version_less_equal(mod.version, spec.version.to)
            then
              valid_mod = mod
              break
            end
          end
        else
          valid_mod = mod
          break
        end
      end
      if not valid_mod then
        succes = false
      else
        local dep_success, dep_new_mods = valid_mod:resolve()
        if not dep_success then
          succes = false
        else
          spec.ok = true
          new_mods = new_mods + dep_new_mods
        end
      end
    end
  end
  if not succes then
    self.loaded = false
    self.has_error = true
  else
    self.has_error = false
  end
  return succes, new_mods
end

function Mod:load()
  if self.loaded or self.has_error then
    return
  end

  if not Ezmod.boot_time then
    self:resolve()
  end

  self.loaded = true
  local loaded_mod = MODS[self.id]
  if not loaded_mod or not Ezmod.util.version_equal(self.version, loaded_mod) then
    if loaded_mod then
      loaded_mod:unload()
    end
    MODS[self.id] = self
  end

  if self.id == "ezmod" then
    local path = Ezmod.data_path .. "/versions/" .. table.concat(self.version, ".")
    local info = NFS.getInfo(path)
    if info and info.type == "directory" then
      Ezmod.util.fs_move(path, MODS_PATH .. "/ezmod")
    end
  end

  --TODO: run mod files

  if not Ezmod.boot_time and self.need_relog then
    Ezmod.ui.Ask({
      "[G.C.ORANGE]{mod.name} need relog [G.C.RED]{'Balatro'} to enable,",
      "do you want to relog?",
    }, {
      config = { fmt_var = { mod = self } },

      { text = "Yes, Relog", colour = G.C.RED, value = "y" },
      { text = "No", colour = G.C.BLUE, value = "n" },
    }, function(answer)
      if answer == "y" then
        Ezmod.relog_game()
      end
    end)
  end
end

function Mod:unload()
  if not self.loaded then
    return
  end

  if MODS[self.id] and Ezmod.util.version_equal(self.version, MODS[self.id].version) then
    MODS[self.id] = nil
  end

  if self.id == "ezmod" then
    Ezmod.util.fs_move(Ezmod.path, Ezmod.data_path .. "/versions/" .. table.concat(self.version, "."))
  end

  if self.need_relog then
    Ezmod.ui.Ask({
      "[G.C.ORANGE]{mod.name} need relog [G.C.RED]{'Balatro'} to disable,",
      "do you want to relog?",
    }, {
      config = { fmt_var = { mod = self } },

      { text = "Yes, Relog", colour = G.C.RED, value = "y" },
      { text = "No", colour = G.C.BLUE, value = "n" },
    }, function(answer)
      if answer == "y" then
        Ezmod.relog_game()
      end
    end)
  end
  self.loaded = false
  --TODO: unload mod (only work for EZ API only)
end

function Mod:icon_ui(w, h, reset)
  local tmp = self:tmp_path()
  if self.icon then
    if self.icon[1] == "animated" and (self.downloaded or NFS.getInfo(tmp .. "/" .. self.icon[2])) then
      local path = self.icon[2]
      local size = type(self.icon[3]) == "number" and { self.icon[3], self.icon[3] } or self.icon[3]
      local frames = self.icon[4] or 1
      local key = "ezmod_" .. self.id .. "_v" .. table.concat(self.version, "_") .. "_animated_icon:" .. path
      if reset then
        G.ANIMATION_ATLAS[key] = nil
      end
      local s = G.ANIMATION_ATLAS[key]
      if not s then
        local image_path
        if self.downloaded then
          image_path =  self.path .. "/assets/" .. path
        else
          image_path = tmp .. "/" .. self.icon[2]
        end
        local img = love.graphics.newImage(Ezmod.util.new_file_data(image_path), { mipmaps = true, dpiscale = 1 })
        local data = {
          name = key,
          image = img,
          px = size[1],
          py = size[2],
          frames = frames,
        }
        G.ANIMATION_ATLAS[key] = data
        s = data
      end

      return { n = G.UIT.O, config = { object = AnimatedSprite(0, 0, w or 1, h or 1, s), id = "ezm_mod_icon_ui_" .. self.id .. "_v" .. table.concat(self.version, "_") } }
    elseif self.icon[1] == "image" and (self.downloaded or NFS.getInfo(tmp .. "/" .. self.icon[2])) then
      local path = self.icon[2]
      local key = "ezmod_" .. self.id .. "_v" .. table.concat(self.version, "_") .. "_icon:" .. path
      if reset then
        G.ANIMATION_ATLAS[key] = nil
      end
      local s = G.ASSET_ATLAS[key]
      if not s then
        local image_path
        if self.downloaded then
          image_path =  self.path .. "/assets/" .. path
        else
          image_path = tmp .. "/" .. path
        end
        local img = love.graphics.newImage(
          Ezmod.util.new_file_data(image_path),
          { mipmaps = true, dpiscale = 1 }
        )
        local data = {
          name = key,
          image = img,
          px = img:getWidth(),
          py = img:getHeight(),
        }
        G.ASSET_ATLAS[key] = data
        s = data
      end
      return { n = G.UIT.O, config = { object = Sprite(0, 0, w or 1, h or 1, s), id = "ezm_mod_icon_ui_" .. self.id .. "_v" .. table.concat(self.version, "_") } }
    elseif self.icon[1] == "balatro:sprite" then
      local offset = self.icon[3] and { x = self.icon[3][1], y = self.icon[3][2] }
      return {
        n = G.UIT.O,
        config = { object = Sprite(0, 0, w or 1, h or 1, G.ASSET_ATLAS[self.icon[2]], offset), id = "ezm_mod_icon_ui_" .. self.id .. "_v" .. table.concat(self.version, "_") },
      }
    elseif self.icon[1] == "balatro:animation" then
      local offset = self.icon[3] and { x = self.icon[3][1], y = self.icon[3][2] }
      return {
        n = G.UIT.O,
        config = { object = AnimatedSprite(0, 0, w or 1, h or 1, G.ANIMATION_ATLAS[self.icon[2]], offset), id = "ezm_mod_icon_ui_" .. self.id .. "_v" .. table.concat(self.version, "_") },
      }
    end
  end
  -- Use rare joker tag sprite if didn't have an icon
  local sprite = Ezmod.ui.Sprite("tags", w or 1, h or 1, { x = 1, y = 0 })
  sprite.config.id = "ezm_mod_icon_ui_" .. self.id .. "_v" .. table.concat(self.version, "_")
  return sprite
end

function Mod:tmp_path(create)
  local tmp = Ezmod.data_path .. "/tmp/assets/" .. self.id .. "/" .. table.concat(self.version, ".")
  if create and not NFS.getInfo(tmp) then
    NFS.createDirectory(tmp)
  end
  return tmp
end

return Mod
