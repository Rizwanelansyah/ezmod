local git = {}
local Repo = Object:extend()

function Repo:init(user, repo, ref)
  self.user = user
  self.repo = repo
  self.ref = ref or "main"
end

function Repo:download(download_to, after)
  Ezmod.http.get(string.format("https://codeload.github.com/%s/%s/zip/refs/heads/%s", self.user, self.repo, self.ref), nil, nil, function (status, body)
    if status == 200 then
      Ezmod.util.iter_archive(body, self.repo .. '-' .. self.ref, function (path, content)
        local dir = string.gsub(path, "/?[^/]*/?$", "")
        if dir ~= "" then
          NFS.createDirectory(download_to .. "/" .. dir)
        end
        NFS.write(download_to .. '/' .. path, content)
      end)
    end
    if after then after(status == 200) end
  end)
end

function Repo:read_file(path, fn)
  Ezmod.http.get(string.format("https://raw.githubusercontent.com/%s/%s/%s/%s", self.user, self.repo, self.ref, path), nil, nil, function (status, body)
    if fn then
      fn(status == 200, body)
    end
  end)
end

function git.repo(user, repo, ref)
  return Repo(user, repo, ref)
end

return git
