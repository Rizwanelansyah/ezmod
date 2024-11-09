local src = {}
src.name = "EZ Mod Loader"
src.id = "ezmod"
src.update_time = 0

function src:setup(add_mods)
  if self.already_setup then
    return
  end
  self.mods = require("ezm.sources.ezmod.mods")
  local total_mods = #self.mods
  local added_mods = {}
  for _, mod in ipairs(self.mods) do
    mod.Repo = Ezmod.git.repo(mod.user, mod.repo, mod.ref or "main")
    mod.Repo:read_file("ezmod.lua", function(ok, content)
      local spec
      if ok then
        spec = Ezmod.parse_mod_spec(content)
      elseif mod.alt_spec then
        spec = Ezmod.format_mod_spec(mod.alt_spec)
      end
      local Mod = Ezmod.Mod(spec)
      added_mods[#added_mods + 1] = Mod
      if #added_mods >= total_mods then
        add_mods(added_mods)
      end
      if Mod.icon and (Mod.icon[1] == "image" or Mod.icon[2] == "animated") then
        local tmp = Mod:tmp_path(true)
        local parent = string.gsub(tmp .. "/" .. Mod.icon[2], "/?[^/]*/?$", "")
        if not NFS.getInfo(parent) then
          NFS.createDirectory(parent)
        end

        mod.Repo:read_file("assets/" .. Mod.icon[2], function(res)
          if res.status ~= 0 then
            EZDBG("DOWNLOADED")
          end
        end, { output_file = tmp .. "/" .. Mod.icon[2] })
      end
    end)
  end
  self.github_mods = {}
  self.already_setup = true
end

return src
