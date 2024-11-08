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
  local headers = ""
  for key, value in pairs(req.headers or {}) do
    headers = headers .. string.format(" -H '%s: %s'", key, value:gsub("'", '"'))
  end
  local command = curl .. string.format(" -i -X%s%s \"%s\"", req.method, headers, req.url:gsub('"', "'"))
  out_chan:push{dbg = true, v = command}
  local fp, err = io.popen(command)
  if not err and fp then
    local res = {}
    res.handle_id = req.handle_id
    res.status = tonumber(string.match(fp:read("*l") or "", "%w+/[%s%.]+%s*(%d+)")) or 0

    res.headers = {}
    local line = fp:read("*l")
    while line and not line:match("^%s*$") do
      local key, value = string.match(line, "^([%w-]+):%s*(.+)")
      res.headers[key] = value
      line = fp:read("*l")
    end

    res.body = ""
    local line = fp:read("*L")
    while line do
      res.body = res.body .. line
      line = fp:read("*L")
    end

    out_chan:push(res)
  else
    out_chan:push({ status = 0, error = err })
  end
end
]===]):start()

local curl = {}

local handle_id = 1
function curl.get(url, headers, handle_fn)
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

return curl
