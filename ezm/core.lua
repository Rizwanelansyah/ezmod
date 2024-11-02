-- EZDBG(require("https").request("https://raw.githubusercontent.com/SirMaiquis/Balatro-Stickers-Always-Shown/refs/heads/main/manifest.json"))
local lovely = require("lovely")
NFS = require("nativefs")
MODS_PATH = lovely.mod_dir:gsub("/$", "")
MODS = {}
ERROR_MODS = {}
local ezm_path = MODS_PATH .. "/Ezm"

package.path = package.path .. (ezm_path .. "/?.lua;") .. (ezm_path .. "/?/init.lua;")

local util = require("ezm.util")
local Mod = require("ezm.mod")

Ezm = {}
Ezm.VERSION = "0.0.1"
Ezui = require("ezui")
Ezutil = util

function Ezm.list_mods(mods_path, fn)
  local mods = NFS.getDirectoryItems(mods_path)
  for _, mod_name in ipairs(mods) do
    local path = mods_path .. "/" .. mod_name
    local ezm_spec_code = NFS.read(path .. "/ezmod.lua")
    if ezm_spec_code then
      local spec = {}
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
      }

      local mod = Mod(spec)
      fn(mod)
    else
      Ezm.list_mods(path, fn)
    end
  end
end

function Ezm.boot()
  Ezm.boot_time = true
  Ezm.boot_progress = 0
  boot_timer(nil, "Init", Ezm.boot_progress, "EZ Mod Loader")

  Ezm.list_mods(MODS_PATH, function(mod)
    if not MODS[mod.id] then
      MODS[mod.id] = mod
    else
      ERROR_MODS[#ERROR_MODS + 1] = { type = "duplicate", mod = mod }
    end
  end)

  boot_timer(nil, "Checking Dependencies", Ezm.boot_progress)
  local mod_total = 0
  for _, mod in pairs(MODS) do
    boot_timer(nil, "Checking Dependencies :: ", Ezm.boot_progress)
    mod_total = mod_total + 1
    mod_total = mod_total + mod:resolve()
  end
  Ezm.boot_progress = 0.1

  boot_timer(nil, "Loading", Ezm.boot_progress)
  local mod_progress_add = (1 / mod_total) * 0.9
  for _, mod in pairs(MODS) do
    boot_timer(nil, "Loading :: " .. mod.name, Ezm.boot_progress)
    mod:load()
    Ezm.boot_progress = Ezm.boot_progress + mod_progress_add
  end

  Ezm.boot_progress = 1
  boot_timer(nil, "Finish", Ezm.boot_progress)
  Ezm.boot_time = false
end

require("ezm.button_callbacks")
