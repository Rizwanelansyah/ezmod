local in_chan = love.thread.getChannel("ezm_curl_request")
local out_chan = love.thread.getChannel("ezm_curl_response")

love.thread.newThread([===[
require("love.system")
local in_chan = love.thread.getChannel("ezm_curl_request")
local out_chan = love.thread.getChannel("ezm_curl_response")

local curl = 'curl'
if love.system.getOS() == "Windows" then
  curl = ']===] .. Ezmod.path .. [===[/bin/curl.exe'
end

while true do
  local req = in_chan:demand()
  if req == 'kill' then
    break
  end
  local headers = ""
  for key, value in pairs(req.headers or {}) do
    headers = headers .. string.format(" -H '%s: %s'", key, value:gsub("'", "\\'"))
  end
  local output = ']===] .. Ezmod.data_path .. [===[/tmp/curl_response'
  local command = curl .. string.format(" -i -X%s%s \"%s\" --output %s", req.method, headers, req.url:gsub("'", "\\'"), output)
  local fp, err = io.popen(command)
  local res = {}
  res.handle_id = req.handle_id
  if not err and fp then
    fp:close()
    fp = io.open(output, "rb")
    res.status = tonumber(string.match(fp:read("*l") or "", "%w+/[%d%.]+%s*(%d+)")) or 0

    res.headers = {}
    local line = fp:read("*l")
    while line and not line:match("^%s*$") do
      local key, value = string.match(line, "^([%w-]+):%s*([^%s]+)")
      res.headers[key] = value
      line = fp:read("*l")
    end

    res.body = fp:read("*a")
  else
    res.status = 0
    res.error = error
  end
  if res.headers.location then
    in_chan:push { url = res.headers.location, headers = req.headers, handle_id = req.handle_id, method = req.method }
  else
    out_chan:push(res)
  end
end
]===]):start()

local curl = {}

local handle_id = 1
function curl.get(url, headers, handle_fn, opt)
  local req = { url = url, headers = headers, handle_id = handle_fn and handle_id or nil, method = "GET" }
  if handle_fn then
    G.EZM_CURL_HANDLERS[handle_id] = handle_fn
    handle_id = handle_id + 1
  end
  in_chan:push(req)
end

function curl.poll_response()
  local res = out_chan:pop()
  if not res then
    return false
  else
    return true, res
  end
end

function curl.kill_thread()
  in_chan:push("kill")
end

return curl
