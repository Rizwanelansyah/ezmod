local lovely = require("lovely")
unpack = unpack or table.unpack
NFS = require("nativefs")
JSON = require("json")
MODS_PATH = lovely.mod_dir:gsub("/$", "")
MODS = {}
ALL_MODS = {}
ERROR_MODS = {}
Ezmod = {}
Ezmod.VERSION = "0.0.1"
Ezmod.path = MODS_PATH .. "/ezmod"
Ezmod.data_path = lovely.mod_dir:gsub("/[^/]*/?$", "") .. "/ezmod"
Ezmod.download_path = Ezmod.data_path .. "/mods"
Ezmod.modlist = { ezmod = true }

package.path = package.path .. (Ezmod.path .. "/?.lua;") .. (Ezmod.path .. "/?/init.lua;")

Ezmod.http = require("ezm.http")
Ezmod.util = require("ezm.util")
Ezmod.Mod = require("ezm.mod")
Ezmod.git = require("ezm.git")
Ezmod.ui = require("ezui")

local local_mods_listed = false
function Ezmod.list_downloaded_mods()
  if local_mods_listed then
    return
  else
    local_mods_listed = true
    for _, mod_id in ipairs(NFS.getDirectoryItems(Ezmod.download_path)) do
      Ezmod.list_mods(Ezmod.download_path .. "/" .. mod_id, function(mod)
        ALL_MODS[#ALL_MODS + 1] = mod
      end, false, true)
    end
  end
  return ALL_MODS
end

function Ezmod.list_mods(mods_path, fn, deep_load, reverse)
  local mods = NFS.getDirectoryItems(mods_path)
  local from, to, inc = 1, #mods, 1
  if reverse then
    from, to, inc = #mods, 1, -1
  end
  for i = from, to, inc do
    local mod_name = mods[i]
    local path = mods_path .. "/" .. mod_name
    local ezm_spec_code = NFS.read(path .. "/ezmod.lua")
    if ezm_spec_code then
      local spec = {
        VFMT = function(fmt)
          return function(self)
            return string.format(fmt, table.concat(self.version, "."))
          end
        end,
      }
      setmetatable(spec, { __index = _G })
      load(ezm_spec_code, string.format("%s Spec", mod_name), "bt", spec)()
      local name = spec.name or mod_name
      local id = spec.id or string.lower(s):gsub("[^%w]+", "_")
      local prefix = spec.prefix or id
      local version = Ezmod.util.parse_version(spec.version or { 0, 0, 1 })
      local spec = {
        name = name,
        id = id,
        prefix = prefix,
        version = version,
        deps = spec.deps or {},
        desc = spec.desc,
        tags = type(spec.tags) == "string" and { spec.tags } or (spec.tags or {}),
        icon = type(spec.icon) == "string" and { "image", spec.icon } or spec.icon,
        path = path,
        author = type(spec.author) == "string" and { spec.author } or (spec.author or {}),
        git_tag = spec.git_tag,
        need_relog = spec.need_relog,
        downloaded = true,
      }

      local mod = Ezmod.Mod(spec)
      ALL_MODS[#ALL_MODS + 1] = mod
      fn(mod)
    elseif deep_load then
      Ezmod.list_mods(path, fn, deep_load, reverse)
    end
  end
end

function Ezmod.boot()
  Ezmod.boot_time = true
  Ezmod.boot_progress = 0
  boot_timer(nil, "Init", Ezmod.boot_progress, "EZ Mod Loader")

  if not NFS.getInfo(Ezmod.download_path, "directory") then
    NFS.createDirectory(Ezmod.download_path)
  end
  if not NFS.getInfo(Ezmod.data_path .. "/modlist.lua", "file") then
    NFS.write(Ezmod.data_path .. "/modlist.lua", "return {}")
  end
  Ezmod.modlist = load(Ezmod.util.read_file(Ezmod.data_path .. "/modlist.lua"), "modlist", "bt")() or {}

  boot_timer(nil, "Loading Assets", Ezmod.boot_progress)
  Ezmod.load_assets()
  Ezmod.boot_progress = 0.05

  local mod_total = 0
  local mods = {}
  Ezmod.list_mods(MODS_PATH, function(mod)
    if not mods[mod.id] then
      mods[mod.id] = mod
      mod_total = mod_total + 1
    else
      ERROR_MODS[#ERROR_MODS + 1] = { type = "duplicate", mod = mod }
    end
  end, true)

  boot_timer(nil, "Checking Dependencies", Ezmod.boot_progress)
  for _, mod in pairs(mods) do
    if next(mod.deps or {}) then
      boot_timer(nil, "Checking Dependencies :: " .. mod.name, Ezmod.boot_progress)
      local succes, new_mods = mod:resolve()
      if not succes then
        ERROR_MODS[#ERROR_MODS + 1] = { type = "missing_deps", mod = mod }
      end
      mod_total = mod_total + new_mods
    end
  end
  Ezmod.boot_progress = 0.15

  boot_timer(nil, "Loading", Ezmod.boot_progress)
  local mod_progress_add = (1 / mod_total) * 0.85
  for _, mod in pairs(mods) do
    boot_timer(nil, "Loading :: " .. mod.name, Ezmod.boot_progress)
    mod:load()
    Ezmod.boot_progress = Ezmod.boot_progress + mod_progress_add
  end

  Ezmod.boot_progress = 1
  boot_timer(nil, "Finish", Ezmod.boot_progress)
  Ezmod.boot_time = false
end

function Ezmod.check_mods_error()
  if not ERROR_MODS_CHECKED and #ERROR_MODS > 0 then
    G.E_MANAGER:add_event(Event({
      func = function()
        G.SETTINGS.paused = true
        G.FUNCS.overlay_menu({
          definition = require("ezm.ui").error_mods(),
        })

        local container = G.OVERLAY_MENU:get_UIE_by_ID("ezm_mod_errors_container")
        container.config.object:remove()
        container.config.object = UIBox({
          definition = Ezmod.ui.Root({
            c = { colour = G.C.CLEAR },
            n = { Ezmod.ui.Pager(ERROR_MODS, 1):cycle():ui(7, 4, require("ezm.ui").error_description) },
          }),
          config = { align = "cm", parent = container },
        })

        return true
      end,
    }))
    ERROR_MODS_CHECKED = true
  end
end

function Ezmod.load_assets()
  boot_timer(nil, "Loading Assets :: EZ Mod Icons", Ezmod.boot_progress)
  G.ASSET_ATLAS.ezm_icons = {
    name = "ezm_icons",
    image = love.graphics.newImage(
      Ezmod.util.new_file_data(Ezmod.path .. "/assets/" .. G.SETTINGS.GRAPHICS.texture_scaling .. "x/icons.png"),
      {
        mipmaps = true,
        dpiscale = G.SETTINGS.GRAPHICS.texture_scaling,
      }
    ),
    px = 32,
    py = 32,
  }
end

function Ezmod.save_modlist()
  local code = "return {"
  local empty = true
  for key, value in pairs(Ezmod.modlist) do
    local lua_key = key
    if not key:match("^[%a%A_][%w_]*$") then
      lua_key = string.format("['%s']", lua_key:gsub("'", "'"):gsub("\\", "\\\\"))
    end
    local lua_value = "true"
    if type(value) == "table" then
      lua_value = '"' .. table.concat(value, ".") .. '"'
    end
    code = code .. string.format("\n  %s = %s,", lua_key, lua_value)
    empty = false
  end
  code = code .. (empty and "" or "\n") .. "}"
  NFS.write(Ezmod.data_path .. "/modlist.lua", code)
end

function Ezmod.enable_mod(mod)
  if mod.id ~= "ezmod" then
    if version then
      Ezmod.modlist[mod.id] = mod.version
    else
      Ezmod.modlist[mod.id] = true
    end
    Ezmod.save_modlist()
  end
  mod:load()
  if G.EZ_MOD_MENU.mod_pager then
    G.EZ_MOD_MENU.mod_pager:update()
  end
end

function Ezmod.disable_mod(mod)
  if id ~= "ezmod" then
    if Ezmod.modlist[mod.id] then
      Ezmod.modlist[mod.id] = nil
      Ezmod.save_modlist()
    end
  end
  mod:unload()
  if G.EZ_MOD_MENU.mod_pager then
    G.EZ_MOD_MENU.mod_pager:update()
  end
end

require("ezm.funcs")
