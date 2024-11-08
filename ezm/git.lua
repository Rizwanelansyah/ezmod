local git = {}
local Repo = Object:extend()

function Repo:init(user, repo, ref)
  self.user = user
  self.repo = repo
  self.ref = ref or "main"
end

function Repo:download(download_to, after)
  Ezmod.curl.get(string.format("https://codeload.github.com/%s/%s/zip/refs/heads/%s", self.user, self.repo, self.ref), nil, function (res)
    if res.status == 200 then
      Ezmod.util.iter_archive(res.body, self.repo .. '-' .. self.ref, function (path, content)
        local dir = string.gsub(path, "/?[^/]*/?$", "")
        if dir ~= "" then
          NFS.createDirectory(download_to .. "/" .. dir)
        end
        NFS.write(download_to .. '/' .. path, content)
      end)
    end
    if after then after(res.status == 200) end
  end)
end

function Repo:read_file(path, fn)
  Ezmod.curl.get(string.format("https://raw.githubusercontent.com/%s/%s/%s/%s", self.user, self.repo, self.ref, path), nil, function (res)
    if fn then
      fn(res.status == 200, res.body)
    end
  end)
end

function git.repo(user, repo, ref)
  return Repo(user, repo, ref)
end

return git
