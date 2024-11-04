local lovely = require("lovely")
NFS = require("nativefs")
MODS_PATH = lovely.mod_dir:gsub("/$", "")
EZM_DATA_PATH = lovely.mod_dir:gsub("/[^/]*/?$", "") .. "/ezmod"
DOWNLOAD_MODS_PATH = EZM_DATA_PATH .. "/mods"
MODS = {}
_MODS = {}
ALL_MODS = {}
ERROR_MODS = {}
local ezm_path = MODS_PATH .. "/ezmod"

package.path = package.path .. (ezm_path .. "/?.lua;") .. (ezm_path .. "/?/init.lua;")

local util = require("ezm.util")
local Mod = require("ezm.mod")

Ezmod = {}
Ezmod.VERSION = "0.0.1"
Ezui = require("ezui")
Ezutil = util

local local_mods_listed = false
function Ezmod.list_downloaded_mods()
  if local_mods_listed then
    return
  else
    local_mods_listed = true
    for _, mod in pairs(_MODS) do
      ALL_MODS[#ALL_MODS + 1] = mod
    end
  end
  Ezmod.list_mods(DOWNLOAD_MODS_PATH, function(mod)
    ALL_MODS[#ALL_MODS + 1] = mod
  end)
  return ALL_MODS
end

function Ezmod.list_mods(mods_path, fn, deep_load)
  local mods = NFS.getDirectoryItems(mods_path)
  for _, mod_name in ipairs(mods) do
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
      local id = spec.id or string.lower(s):gsub("[^%d%w]+", "_")
      local prefix = spec.prefix or id
      local version = util.parse_version(spec.version or { 0, 0, 1 })
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

      local mod = Mod(spec)
      fn(mod)
    elseif deep_load then
      Ezmod.list_mods(path, fn)
    end
  end
end

function Ezmod.boot()
  if not NFS.getInfo(DOWNLOAD_MODS_PATH, "directory") then
    NFS.createDirectory(DOWNLOAD_MODS_PATH)
  end
  Ezmod.boot_time = true
  Ezmod.boot_progress = 0
  boot_timer(nil, "Init", Ezmod.boot_progress, "EZ Mod Loader")

  local mod_total = 0
  Ezmod.list_mods(MODS_PATH, function(mod)
    if not MODS[mod.id] then
      MODS[mod.id] = mod
      _MODS[#_MODS + 1] = mod
      ALL_MODS[#ALL_MODS + 1] = mod
      mod_total = mod_total + 1
    else
      ERROR_MODS[#ERROR_MODS + 1] = { type = "duplicate", mod = mod }
    end
  end, true)

  boot_timer(nil, "Checking Dependencies", Ezmod.boot_progress)
  for _, mod in pairs(MODS) do
    if next(mod.deps or {}) then
      boot_timer(nil, "Checking Dependencies :: " .. mod.name, Ezmod.boot_progress)
      local succes, new_mods = mod:resolve()
      if not succes then
        ERROR_MODS[#ERROR_MODS + 1] = { type = "missing_deps", mod = mod }
      end
      mod_total = mod_total + new_mods
    end
  end
  Ezmod.boot_progress = 0.1

  boot_timer(nil, "Loading", Ezmod.boot_progress)
  local mod_progress_add = (1 / mod_total) * 0.9
  for _, mod in pairs(MODS) do
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
          definition = Ezui.Root({
            c = { colour = G.C.CLEAR },
            n = { Ezui.Pager(ERROR_MODS, 1):cycle():ui(7, 4, require("ezm.ui").error_description) },
          }),
          config = { align = "cm", parent = container },
        })

        return true
      end,
    }))
    ERROR_MODS_CHECKED = true
  end
end

require("ezm.funcs")
