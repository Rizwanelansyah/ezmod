local in_channel = love.thread.getChannel("ezm_http_request")
local out_channel = love.thread.getChannel("ezm_http_response")
local url = require("socket.url")
local handle_id = 1

local function url_encode(t)
  local result = ""
  local first = true
  for key, value in pairs(t) do
    if first then
      first = false
    else
      result = result .. "&"
    end
    key = tostring(key)
    result = result .. key .. "=" .. url.escape(tostring(value))
  end
  return result
end

local http_thread = love.thread.newThread([[
local requests = {}
local https = require("https")
local unpack = unpack or table.unpack

local in_channel = love.thread.getChannel("ezm_http_request")
local out_channel = love.thread.getChannel("ezm_http_response")

while true do
  local req = in_channel:demand()
  local method, url, data, header, handle_id = req[1], req[2], req[3], req[4], req[5]
  local code, body, header = https.request(url, { data = data, headers = header, method = method })
  out_channel:push({code, body, header, handle_id})
end
]])

http_thread:start()

local http = {}

function http.get(url, data, header, handle_fn)
  url = url .. (data and ("?" .. url_encode(data)) or "")
  local req = { "GET", url, nil, header or {} }
  if handle_fn then
    req[5] = handle_id
    G.EZM_HTTP_HANDLERS[handle_id] = handle_fn
    handle_id = handle_id + 1
  end
  in_channel:push(req)
end

function http.poll_response()
  local result = out_channel:pop()
  if not result then
    return false
  end
  return true, result[1], result[2], result[3], result[4]
end

return http
