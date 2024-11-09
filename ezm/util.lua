local util = {}
local version_pattern = "(%d+)%.?(%d*)%.?(%d*)"

function util.parse_version(version, vv, vvv)
  if not version then
    return { 0, 0, 0 }
  end
  if type(version) == "table" then
    return version
  elseif type(version) == "number" then
    return { tonumber(version), 0, 0 }
  elseif type(version) == "string" then
    if string.match(version, "^%d+$") then
      return { tonumber(version), tonumber(vv) or 0, tonumber(vvv) or 0 }
    end
    local ret = util.parse_version(string.match(version, "^%s*" .. version_pattern .. "%s*$"))
    return ret
  end
  return { 0, 0, 0 }
end

function util.parse_version_spec(version)
  if string.match(version, ".%s*%-%s*.") then
    local from = util.parse_version(string.match(version, version_pattern .. "%s*%-"))
    local to = util.parse_version(string.match(version, "%-%s*" .. version_pattern))
    return { from = from, to = to }
  elseif string.match(version, "+%s*$") then
    return { upper = util.parse_version(string.match(version, version_pattern)) }
  elseif string.match(version, "-%s*$") then
    return { lower = util.parse_version(string.match(version, version_pattern)) }
  else
    return { exact = util.parse_version(version) }
  end
end

function util.version_equal(v1, v2)
  return v1[1] == v2[1] and v1[2] == v2[2] and v1[3] == v2[3]
end

function util.version_greater_than(v1, v2)
  if v1[1] > v2[1] then
    return true
  end
  if v1[1] == v2[1] and v1[2] > v2[2] then
    return true
  end
  if v1[1] == v2[1] and v1[2] == v2[2] and v1[3] > v2[3] then
    return true
  end
  return false
end

function util.version_less_than(v1, v2)
  if v1[1] < v2[1] then
    return true
  end
  if v1[1] == v2[1] and v1[2] < v2[2] then
    return true
  end
  if v1[1] == v2[1] and v1[2] == v2[2] and v1[3] < v2[3] then
    return true
  end
  return false
end

function util.version_greater_equal(v1, v2)
  return util.version_greater_than(v1, v2) or util.version_equal(v1, v2)
end

function util.version_less_equal(v1, v2)
  return util.version_less_than(v1, v2) or util.version_equal(v1, v2)
end

function util.trim(s)
  return string.match(s, "^%s*(.*)%s*$")
end

function util.read_file(filepath)
  local f, err = io.open(filepath, "rb")
  if not err then
    local result = f:read("*a")
    f:close()
    return result
  end
end

function util.new_file_data(filepath)
  return love.filesystem.newFileData(util.read_file(filepath) or "", "")
end

function util.fs_remove(path)
  local info = NFS.getInfo(path)
  if info and info.type == "directory" then
    local paths = NFS.getDirectoryItems(path)
    for _, p in ipairs(paths) do
      util.fs_remove(path .. "/" .. p)
    end
  end
  NFS.remove(path)
end

function util.mount(archive_content, fn)
  local mount_point = "ezm-tmp-mountpoint"
  local zip_name = mount_point .. ".zip"
  love.filesystem.mount(love.filesystem.newFileData(archive_content, zip_name), mount_point)
  fn(mount_point)
  love.filesystem.unmount(zip_name)
end

local function iter_files(path, fn)
  local info = love.filesystem.getInfo(path)
  if not info then
    return
  end
  if info.type == "directory" then
    for _, p in ipairs(love.filesystem.getDirectoryItems(path)) do
      iter_files(path .. "/" .. p, fn)
    end
  else
    fn(path)
  end
end

function util.iter_archive(archive_content, base_path, fn)
  util.mount(archive_content, function(mp)
    local path = mp .. "/" .. base_path
    iter_files(path, function(p)
      local content = love.filesystem.read(p)
      p = string.sub(p, #path + 2, -1)
      fn(p, content)
    end)
  end)
end

function util.fs_move(path, to)
  local info = NFS.getInfo(path)
  if not info then
    return
  end
  if info.type == "directory" then
    local to_info = NFS.getInfo(to)
    if not to_info then
      NFS.createDirectory(to)
    end
    for _, p in ipairs(NFS.getDirectoryItems(path)) do
      util.fs_move(path .. "/" .. p, to .. "/" .. p)
    end
    NFS.remove(path)
  else
    local parent = string.gsub(to, "/?[^/]*/?$", "")
    if parent ~= "" then
      if not NFS.getInfo(parent) then
        NFS.createDirectory(parent)
      end
    end
    os.rename(path, to)
  end
end

function util.fuzzy_search(s, substr)
  if #substr < 1 then
    return {}
  end
  substr = substr:gsub("%s+", "")
  local len = #s
  local sublen = #substr
  local matches = {}
  local match = {}
  local char = util.strat(s, 1)
  local sub_i = 1
  local sub_char = util.strat(substr, sub_i)
  local i = 1
  while i <= len do
    if char == sub_char then
      match[#match + 1] = i
      sub_i = sub_i + 1
      sub_char = util.strat(substr, sub_i)

      if #match == sublen then
        matches[#matches + 1] = match
        match = {}

        sub_i = 1
        sub_char = util.strat(substr, sub_i)
      end
    end

    i = i + 1
    char = util.strat(s, i)
  end

  return matches
end

function util.strat(s, i)
  return string.sub(s, i, i)
end

function util.eval(code, var)
  local env = setmetatable({}, {
    __index = function(t, k)
      return rawget(t, k) or var[k] or _G[k]
    end,
  })
  local f = load("return " .. (code or "nil"), "eval", "bt", env)
  return f and f()
end

function util.parse_fmtext(text, conf, var)
  local result = {}
  local i = 1
  local len = #text
  local cur
  local has_bg = false
  conf = conf or {}
  conf.colour = conf.colour or G.C.GREY
  conf.scale = conf.scale or 0.5

  while i <= len do
    local char = util.strat(text, i)
    if char == "[" then
      if cur then
        result[#result + 1] = { type = "text", text = cur }
      end
      cur = char
      i = i + 1
      local fg, bg, text_scale, val
      local fail = false

      if i <= len and util.strat(text, i) ~= ":" and util.strat(text, i) ~= "]" then
        fg = ""
        while i <= len and util.strat(text, i) ~= ":" and util.strat(text, i) ~= "]" do
          if util.strat(text, i) == "%" then
            i = i + 1
          end
          fg = fg .. util.strat(text, i)
          i = i + 1
        end
        cur = cur .. fg
      end

      if i <= len and util.strat(text, i) == ":" then
        i = i + 1
        cur = cur .. ":"
        bg = ""
        while i <= len and util.strat(text, i) ~= "]" and util.strat(text, i) ~= ":" do
          if util.strat(text, i) == "%" then
            i = i + 1
          end
          bg = bg .. util.strat(text, i)
          i = i + 1
        end
        cur = cur .. bg
      end

      if i <= len and util.strat(text, i) == ":" then
        i = i + 1
        cur = cur .. ":"
        text_scale = ""
        while i <= len and util.strat(text, i) ~= "]" do
          if util.strat(text, i) == "%" then
            i = i + 1
          end
          text_scale = text_scale .. util.strat(text, i)
          i = i + 1
        end
        cur = cur .. bg
      end

      if i <= len and util.strat(text, i) == "]" then
        cur = cur .. util.strat(text, i)
        i = i + 1
      else
        fail = true
      end

      if not fail and i <= len and util.strat(text, i) == "{" then
        cur = cur .. util.strat(text, i)
        i = i + 1
        val = ""
        while i <= len and util.strat(text, i) ~= "}" do
          if util.strat(text, i) == "%" then
            i = i + 1
          end
          val = val .. util.strat(text, i)
          i = i + 1
        end
      else
        fail = true
      end

      if not fail and i <= len and util.strat(text, i) == "}" then
        cur = cur .. util.strat(text, i)
        i = i + 1
      else
        fail = true
      end

      if not fail then
        cur = nil
        local bgcolor = util.eval(bg, var)
        local scale = 1
        if text_scale then
          scale = util.eval(text_scale, var) or scale
        end
        if bgcolor then
          if not has_bg then
            has_bg = true
          end
          result[#result + 1] = {
            type = "textbox",
            bg = bgcolor,
            fg = fg and util.eval(fg, var) or conf.colour,
            scale = conf.scale * scale,
            text = util.eval(val, var),
          }
        else
          result[#result + 1] = {
            type = "colored",
            colour = fg and util.eval(fg, var) or conf.colour,
            scale = conf.scale * scale,
            text = util.eval(val, var),
          }
        end
      end
    elseif char == "#" then
      if cur then
        result[#result + 1] = { type = "text", text = cur }
      end
      cur = nil
      i = i + 1
      local val = ""
      while i <= len and util.strat(text, i) ~= "#" do
        if util.strat(text, i) == "%" then
          i = i + 1
        end
        val = val .. util.strat(text, i)
        i = i + 1
      end
      if i <= len then
        i = i + 1
      end
      result[#result + 1] = { type = "text", text = util.eval(val, var) }
    elseif char == "@" then
      if cur then
        result[#result + 1] = { type = "text", text = cur }
      end
      cur = char
      i = i + 1
      local object
      local fail = false
      if i <= len and util.strat(text, i) == "(" then
        cur = cur .. "("
        i = i + 1
      end

      if i <= len and util.strat(text, i) ~= ")" then
        object = ""
        while i <= len and util.strat(text, i) ~= ")" do
          if util.strat(text, i) == "%" then
            i = i + 1
          end
          object = object .. util.strat(text, i)
          i = i + 1
        end
        cur = cur .. object
      end

      if i <= len and util.strat(text, i) == ")" then
        cur = cur .. util.strat(text, i)
        i = i + 1
      else
        fail = true
      end

      if not fail then
        cur = nil
        local o = util.eval(object, var)
        result[#result + 1] = { type = "object", object = o or Moveable() }
      end
    elseif char == "%" then
      cur = (cur or "") .. util.strat(text, i + 1)
      i = i + 2
    else
      cur = (cur or "") .. char
      i = i + 1
    end
  end
  if cur then
    result[#result + 1] = { type = "text", text = cur }
  end
  return result
end

function read_fmtext(text, conf, var)
  local result = ""
  local nodes = util.parse_fmtext(text, conf, var)
  for _, node in ipairs(nodes) do
    if node.type == "object" then
      if node.object:is(DynaText) then
        for _, letters in ipairs(node.object.strings) do
          result = result .. letters.string
        end
      end
    else
      result = result .. node.text
    end
  end
  return result
end

function util.read_fmtext(lines, opt)
  opt = opt or {}
  opt.c = opt.c or {}
  opt.t = opt.t or {}
  local text = ""
  if type(lines) == "string" then
    lines = { lines }
  end
  local var = {}
  for key, value in pairs(opt.v) do
    var[key] = value
  end
  var.__opt = opt
  for _, line in ipairs(lines) do
    text = text .. read_fmtext(line, opt.t, var)
  end
  return text
end

function EZDBG(...)
  local result = {}
  for i, v in ipairs({ ... }) do
    result[i] = type(v) == "table" and tprint(v) or tostring(v)
  end
  print(unpack(result))
end

return util
