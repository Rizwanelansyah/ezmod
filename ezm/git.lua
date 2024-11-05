local User_Agent = "EZ Mod Loader by @Rizwanelansyah"
local github_api_base_url = "https://api.github.com"
local socket_url = require("socket.url")
local git = {}
local Repo = Object:extend()

local function format_repo_path(path)
  if path:match("^/") then
    path = path:match("^/(.*)") or ""
  end
  return path
end

function Repo:init(user_repo, ref)
  local user, repo = user_repo:match("([^/]+)/(.+)")
  self.user = user
  self.repo = repo
  self.ref = ref or "main"
  self.requesting_info = true
  self.request_queue = {}
  self.stars = 0
  self:info(function(status_code, body)
    if status_code == 200 then
      self.requesting_info = false
      local data = JSON.decode(body)
      self.ref = self.ref or data.default_branch
      self.stars = data.stargazers_count or self.stars
      for _, fn in ipairs(self.request_queue) do
        fn()
      end
      self.request_queue = {}
    else
      self.requesting_info = false
      self.error = true
    end
  end)
end

function Repo:request(url, data, header, handle_fn)
  if self.error then
    return
  end
  git.request(string.format("/repos/%s/%s%s", self.user, self.repo, url or ""), data, header, handle_fn)
end

function Repo:info(handle_fn)
  self:request("", nil, nil, handle_fn)
end

function Repo:info_required(fn)
  if self.requesting_info then
    self.request_queue[#self.request_queue + 1] = fn
  else
    fn()
  end
end

function Repo:contents(path, handle_fn)
  self:info_required(function()
    self:request("/contents/" .. format_repo_path(path) .. "?ref=" .. socket_url.escape(self.ref), nil, nil, handle_fn)
  end)
end

function Repo:tree(recursive, handle_fn)
  self:info_required(function()
    self:request("/git/trees/" .. socket_url.escape(self.ref) .. "?recursive=" .. (recursive and 1 or 0), nil, nil, handle_fn)
  end)
end

function Repo:download(download_to, after)
  local progress = { percentage = 0, current = 0, of = 0 }
  self:info_required(function()
    self:tree(true, function(status_code, body)
      if status_code == 200 then
        local data = JSON.decode(body)
        local paths = {}
        for _, node in ipairs(data.tree) do
          if node.type == "blob" then
            progress.of = progress.of + 1
            paths[#paths + 1] = node.path
          end
        end
        for _, path in ipairs(paths) do
          --using https://raw.githubusercontent didn't work i don't know why
          --using this is fine but its limited
          --FIXME: find a new way to download file form github
          self:request("/contents/" .. path .. "?ref=" .. socket_url.escape(self.ref), nil, { Accept = "application/vnd.github.v3.raw" }, function(status_code, body)
            if status_code == 200 then
              local parent = path:gsub("/[^/]*$", "")
              NFS.createDirectory(download_to .. "/" .. parent)
              NFS.write(download_to .. "/" .. path, body)
              progress.current = progress.current + 1
            else
              --TODO: handle error
              progress.error = true
              progress.current = progress.current + 1
            end
            progress.percentage = progress.current / progress.of
            if progress.percentage == 1 then
              after(not progress.error)
            end
          end)
        end
      else
        after(false)
      end
    end)
  end)
  return progress
end

function git.repo(user_repo, ref)
  return Repo(user_repo, ref)
end

function git.request(url, data, header, handle_fn)
  header = header or {}
  header["User-Agent"] = User_Agent
  Ezmod.http.get(github_api_base_url .. url, data, header, handle_fn)
end

return git
