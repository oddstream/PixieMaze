-- Util

local json = require('json')

local Util = {}

local ALL_DIRECTIONS = {'n','e','s','w'}

function Util.BFS(tStart, tDst)
  -- assert(tStart)
  -- assert(tDst)
  _G.game.got:iterator(function(t) t.parent = nil end)
  local q = {tStart}        -- push onto queue
  tStart.parent = tStart   -- mark as itself
  while #q > 0 do
    local t = table.remove(q, 1)
    -- assert(t)
    if t == tDst then
      return
    end
    for _,dir in ipairs(ALL_DIRECTIONS) do
      local tn = t[dir]
      if tn and (not t.walls[dir]) and (tn.parent == nil) then
        tn.parent = t
        q[#q+1] = tn
        -- table.insert(q, tn) -- push to end of q
      end
    end
  end
  assert(false, 'BFS not found')
end

function Util.BFSWallpasser(tStart, tDst)
  -- assert(tStart)
  -- assert(tDst)
  _G.game.got:iterator(function(t) t.parent = nil end)
  local q = {tStart}        -- push onto queue
  tStart.parent = tStart   -- mark as itself
  while #q > 0 do
    local t = table.remove(q, 1)
    -- assert(t)
    if t == tDst then
      return
    end
    for _,dir in ipairs(ALL_DIRECTIONS) do
      local tn = t[dir]
      if tn and (tn.parent == nil) then
        tn.parent = t
        q[#q+1] = tn
        -- table.insert(q, tn) -- push to end of q
      end
    end
  end
  assert(false, 'BFS not found')
end

--[[
function Util.BFS3(tStart)
  -- breath-first search for nearest cul de sac
  assert(tStart)
  _G.game.got:iterator(function(t) t.parent = nil end)
  local q = {tStart}        -- push onto queue
  tStart.parent = tStart   -- mark as itself
  while #q > 0 do
    local t = table.remove(q, 1)
    assert(t)
    if t.isCulDeSac and t ~= tStart then
      return t
    end
    for _,dir in ipairs(ALL_DIRECTIONS) do
      local tn = t[dir]
      if tn and (not t.walls[dir]) and (tn.parent == nil) then
        tn.parent = t
        q[#q+1] = tn
        -- table.insert(q, tn) -- push to end of q
      end
    end
  end
  return nil
end
]]

function Util.BFS3d(tStart)
  -- breath-first search for nearest cul de sac with a spore
  assert(tStart)
  _G.game.got:iterator(function(t) t.parent = nil end)
  local q = {tStart}        -- push onto queue
  tStart.parent = tStart   -- mark as itself
  while #q > 0 do
    local t = table.remove(q, 1)
    assert(t)
    if t.isCulDeSac and t:hasSpore() then
      return t
    end
    for _,dir in ipairs(ALL_DIRECTIONS) do
      local tn = t[dir]
      if tn and (not t.walls[dir]) and (tn.parent == nil) then
        tn.parent = t
        q[#q+1] = tn
        -- table.insert(q, tn) -- push to end of q
      end
    end
  end
  return nil
end

function Util.nearestGhost(tStart)
  _G.game.got:iterator(function(t) t.parent = nil end)
  local q = {tStart}        -- push onto queue
  tStart.parent = tStart   -- mark as itself
  while #q > 0 do
    local t = table.remove(q, 1)
    assert(t)
    local g = _G.game:isTileHaunted(t)
    if g then
      return g
    end
    for _,dir in ipairs(ALL_DIRECTIONS) do
      local tn = t[dir]
      if tn and (not t.walls[dir]) and (tn.parent == nil) then
        tn.parent = t
        -- table.insert(q, tn) -- push to end of q
        q[#q+1] = tn
      end
    end
  end
  return nil
end

function Util.whichDirIs(tSrc, tDst)
  -- quicker to do it the ugly 'if then elseif end' way
  -- assert(tSrc)
  -- assert(tDst)
--[[
  local newDir = nil
  for _,dir in ipairs(ALL_DIRECTIONS) do
    if tSrc[dir] == tDst then
      newDir = dir
      break
    end
  end
  -- assert(newDir)
  return newDir
]]
  if tSrc.n == tDst then
    return 'n'
  elseif tSrc.e == tDst then
    return 'e'
  elseif tSrc.s == tDst then
    return 's'
  elseif tSrc.w == tDst then
    return 'w'
  end
  return nil
end

function Util.forward(dir)
  return dir
end

function Util.opposite(dir)
  local d = { n = 's', e = 'w', s = 'n', w = 'e' }
  return d[dir]
end

function Util.left(dir)
  local d = { n = 'w', e = 'n', s = 'e', w = 's' }
  return d[dir]
end

function Util.right(dir)
  local d = { n = 'e', e = 's', s = 'w', w = 'n' }
  return d[dir]
end

function Util.isValidDir(dir)
  if dir == 'n' or dir == 'e' or dir == 's' or dir == 'w' then
    return true
  end
  debug_log('invalid dir', dir)
  return false
end

function Util.newTriangle(group, x, y, radius)
--[[
  local COS_60 = 0.5
  local COS_30 = 0.5 * math.sqrt(3)
  local side = radius * 2 * COS_30
  local bottomHeight = y - COS_60 * radius
  local vertices = {
    x, y + radius,
    x + COS_60 * side, bottomHeight,
    x - COS_60 * side, bottomHeight
  }
]]
  local pi3 = math.pi / 3
  local vertices = {
    radius * math.cos(0 * 2 * pi3),
    radius * math.sin(0 * 2 * pi3),

    radius * math.cos(1 * 2 * pi3),
    radius * math.sin(1 * 2 * pi3),

    radius * math.cos(2 * 2 * pi3),
    radius * math.sin(2 * 2 * pi3),
  }
  return display.newPolygon(group, x + radius / 5, y, vertices)
end

function Util.newTriangleBack(group, x, y, radius)
  local pi3 = math.pi / 3
  local vertices = {
    radius * math.cos(math.pi + 2 * 2 * pi3),
    radius * math.sin(math.pi + 2 * 2 * pi3),

    radius * math.cos(math.pi + 1 * 2 * pi3),
    radius * math.sin(math.pi + 1 * 2 * pi3),

    radius * math.cos(math.pi + 0 * 2 * pi3),
    radius * math.sin(math.pi + 0 * 2 * pi3),
  }
  return display.newPolygon(group, x - radius / 5, y, vertices)
end

function Util.distance(x1, y1, x2, y2)
  local dx = x1 - x2
  local dy = y1 - y2
  return math.sqrt(dx * dx + dy * dy)
end

local settingsFilePath = system.pathForFile('settings.json', system.DocumentsDirectory)

function Util.loadSettings()
  local decoded = {whiteGhosts=true, greenGhosts=true, redGhosts=true, purpleGhosts=true, qFactor=9}
  local file = io.open(settingsFilePath, 'r')
  if file then
    local contents = file:read('*a')
    io.close(file)
    -- debug_log(contents)
    local pos, msg
    decoded, pos, msg = json.decode(contents)
    if not decoded then
      debug_log(decoded, pos, msg)
    end
  end
  return decoded
end

function Util.saveSettings(settings)
  local file = io.open(settingsFilePath, 'w')
  if file then
    debug_log('write', settingsFilePath, json.encode(settings))
    file:write(json.encode(settings))
    io.close(file )
  end
end

return Util