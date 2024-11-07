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
  if info.type == "directory" then
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

function EZDBG(...)
  local result = {}
  for i, v in ipairs({ ... }) do
    result[i] = type(v) == "table" and tprint(v) or tostring(v)
  end
  print(unpack(result))
end

return util
