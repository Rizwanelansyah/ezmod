local git = {}
local Repo = Object:extend()

function Repo:init(user, repo, ref)
  self.user = user
  self.repo = repo
  self.ref = ref or "main"
end

function Repo:download(download_to, after)
  Ezmod.curl.get(
    string.format("https://github.com/%s/%s/zipball/%s", self.user, self.repo, self.ref),
    nil,
    function(res)
      if res.status == 200 then
        Ezmod.util.iter_archive(res.body, "*", function(path, content)
          local dir = string.gsub(path, "/?[^/]*/?$", "")
          if dir ~= "" then
            NFS.createDirectory(download_to .. "/" .. dir)
          end
          NFS.write(download_to .. "/" .. path, content)
        end)
      end
      if after then
        after(res.status == 200)
      end
    end
  )
end

function Repo:read_file(path, fn, opt)
  Ezmod.curl.get(
    string.format("https://raw.githubusercontent.com/%s/%s/%s/%s", self.user, self.repo, self.ref, path),
    nil,
    opt and fn or function(res)
      if fn then
        fn(res.status == 200, res.body)
      end
    end,
    opt
  )
end

function git.repo(user, repo, ref)
  return Repo(user, repo, ref)
end

function git.repo_search(query, per_page, page, fn)
  per_page = per_page or 30
  page = page or 1
  query = require("socket.url").escape(query and query:gsub(" ", "+") or "")
  Ezmod.curl.get(
    string.format("https://api.github.com/search/repositories?q=%s&page=%d&per_page=%d", query, page, per_page),
    { ["User-Agent"] = "EZ Mod Loader" },
    function(res)
      if res.status == 200 then
        local result = JSON.decode(res.body)
        fn(true, result)
      else
        fn(false)
      end
    end
  )
end

return git
