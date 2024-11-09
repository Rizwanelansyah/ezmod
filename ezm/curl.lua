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
  local output = req.output_file or "-"
  local show_header = output == "-"
  local command = curl .. string.format(" %s-X%s%s \"%s\" --output %s", show_header and "-i " or "", req.method, headers, req.url:gsub('"', "'"), output)
  local fp, err = io.popen(command)
  if output == '-' then
    if not err and fp then
      local res = {}
      res.handle_id = req.handle_id
      res.status = tonumber(string.match(fp:read("*l") or "", "%w+/[%d%.]+%s*(%d+)")) or 0

      res.headers = {}
      local line = fp:read("*l")
      while line and not line:match("^%s*$") do
        local key, value = string.match(line, "^([%w-]+):%s*(.+)")
        res.headers[key] = value
        line = fp:read("*l")
      end

      res.body = fp:read("*a")

      out_chan:push(res)
    else
      out_chan:push({ status = 0, error = err })
    end
  else
    if not err and fp then
      out_chan:push({ handle_id = handle_id })
    else
      out_chan:push({ status = 0, error = err })
    end
  end
end
]===]):start()

local curl = {}

local handle_id = 1
function curl.get(url, headers, handle_fn, opt)
  local req = { url = url, headers = headers, handle_id = handle_fn and handle_id or nil, method = "GET", output_file = opt and opt.output_file }
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
