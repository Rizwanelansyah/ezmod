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
      local spec = Ezmod.parse_mod_spec(ok and content or mod.alt_spec)
      local Mod = Ezmod.Mod(spec)
      mod.Mod = Mod
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

        mod.Repo:read_file("assets/" .. Mod.icon[2], function(ok, content)
          if ok then
            NFS.write(tmp .. "/" .. Mod.icon[2], content)
            G.EZ_MOD_MENU.browser_pager:update()
          end
        end)
      end
    end)
  end
  self.github_mods = {}
  self.already_setup = true
end

function src:download(mod_id, version, after)
  local mod
  for _, m in ipairs(self.mods) do
    if m.Mod.id == mod_id then
      mod = m
    end
  end
  if mod then
    mod.Mod.version = version or mod.Mod.version
    mod.Repo.ref = mod.Mod.git_ref()
    local download_path = Ezmod.download_path .. "/" .. mod.Mod.id .. "/" .. table.concat(mod.Mod.version, '.')
    mod.Repo:download(download_path, function (succes)
      if succes then
        if not NFS.getInfo(download_path .. "/ezmod.lua") then
          NFS.write(download_path .. "/ezmod.lua", mod.alt_spec)
        end
      end
      after(succes)
    end)
  end
  return mod ~= nil
end

return src
