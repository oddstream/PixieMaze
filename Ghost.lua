-- Ghost class

local Util = require 'Util'

local Ghost = {
  -- prototype object
  tile = nil,     -- Tile we are sitting on
  target = nil,   -- Tile we are trying to get to
  path = nil,     -- Tile-path to target

  group = nil,      -- Ghost Group, contains Ghost display objects
  circle = nil,     -- ShapeObject
  radius = nil,

  eyeGroup = nil,
  leftEye = nil,
  rightEye = nil,
  leftPupil = nil,
  rightPupil = nil,

  eyeSize = nil,
  pupilSize = nil,
  eyeY = nil,

  facing = nil,
  walkfn = nil,
  color = nil,
}

local polyCoords = {
  -12, 10,   -- bottom left
  -8, 8,
  -4, 12,
  0, 8,
  4, 12,
  8, 8,
  12, 10,    -- bottom right
  12, 0,
  -- arch
  11, -5,
  10, -7,
  9, -8,
  8, -9,
  6, -10,

  0, -11,

  -6, -10,
  -8, -9,
  -9, -8,
  -10, -7,
  -11, -5,
  -- end of arch
  -12, 0
}

local ALL_DIRECTIONS = {'n','e','s','w'}

local MAX_ALPHA = 0.75

function Ghost:new(tile)
  local o = {}
  self.__index = self
  setmetatable(o, self)
  o.tile = tile
  o.target = nil

  -- https://docs.coronalabs.com/guide/graphics/group.html
  -- create a group for ghost that contains circle and countdownText
  local xc, yc = tile:centerXY()
  o.group = display.newGroup()
  -- move origin of group to center of owning tile
  o.group.x = xc
  o.group.y = yc
  _G.groups.actors:insert(o.group)
  o.radius = _G.Q3
  o.circle = display.newPolygon(o.group, 0,0, polyCoords)
  o.circle.height = o.radius * 2
  o.circle.width = o.radius * 2

  o.eyeSize = math.round(_G.Q / 10)
  o.pupilSize = math.round(_G.Q / 20)
  o.eyeY = -o.eyeSize

  o.eyeGroup = display.newGroup()
  o.leftEye = display.newCircle(o.eyeGroup, -o.eyeSize,o.eyeY, o.eyeSize)
  o.rightEye = display.newCircle(o.eyeGroup, o.eyeSize,o.eyeY, o.eyeSize)
  o.leftEye:setFillColor(unpack(_G.colors.white))
  o.rightEye:setFillColor(unpack(_G.colors.white))

  o.leftPupil = display.newCircle(o.eyeGroup, -o.eyeSize,o.eyeY, o.pupilSize)
  o.rightPupil = display.newCircle(o.eyeGroup, o.eyeSize,o.eyeY, o.pupilSize)
  o.leftPupil:setFillColor(unpack(_G.colors.black))
  o.rightPupil:setFillColor(unpack(_G.colors.black))

  o.group:insert(o.eyeGroup)

  o.countdownText = nil
  o.seconds = 0

  o:setFacing((ALL_DIRECTIONS)[math.random(4)])

  return o
end

function Ghost:pos()
  return self.group.x, self.group.y
end

function Ghost:isDir(dir)
  -- assert(Util.isValidDir(dir))
  local ok = false
  -- turn lookups into locals
  local t = self.tile
  local tn = t[dir]

  if tn then
    if t.walls[dir] then
      ok = false
    else
      ok = true
    end
  end
  return ok
end

function Ghost:isGoodDir(dir)
  -- assert(Util.isValidDir(dir))
  local ok = false
  -- turn lookups into locals
  local t = self.tile
  local tn = t[dir]

  if tn then
    if t.walls[dir] then
      ok = false
    elseif tn.isCulDeSac then
      ok = false
    else
      ok = true
    end
  end
  return ok
end

function Ghost:movePupils()
  if self.facing == 'n' then
    self.leftPupil.x = -self.eyeSize
    self.leftPupil.y = -(self.eyeSize + self.eyeSize)
    self.rightPupil.x = self.eyeSize
    self.rightPupil.y = -(self.eyeSize + self.eyeSize)
  elseif self.facing == 'e' then
    self.leftPupil.x = 0
    self.leftPupil.y = self.eyeY
    self.rightPupil.x = self.eyeSize + self.eyeSize
    self.rightPupil.y = self.eyeY
  elseif self.facing == 's' then
    self.leftPupil.x = -self.eyeSize
    self.leftPupil.y = 0
    self.rightPupil.x = self.eyeSize
    self.rightPupil.y = 0
  elseif self.facing == 'w' then
    self.leftPupil.x = -(self.eyeSize + self.eyeSize)
    self.leftPupil.y = self.eyeY
    self.rightPupil.x = 0
    self.rightPupil.y = self.eyeY
  end
end

function Ghost:setFacing(dir)
  self.facing = dir
  self:movePupils()
end

function Ghost:explode()

  local xc, yc = self.tile:centerXY()
  local circle = display.newCircle(_G.groups.actors, xc, yc, self.radius)
  circle:setFillColor(unpack(self.color))
  transition.scaleBy(circle,
  {
    xScale = 20,
    yScale = 20,
    time = 500,
    onComplete = function()
      -- circle:removeSelf()
      display.remove(circle)
    end
  })
  transition.fadeOut(circle,
  {
    time = 500,
  })

end

function Ghost:move(dir)
  local tNew = self.tile[dir]
  local xNew, yNew = tNew:centerXY()

  transition.moveTo(self.group, {x=xNew, y=yNew, time=_G.GHOST_SPEED})

  self:setFacing(dir)
  self.tile = tNew

  self.circle.alpha = math.min(self.tile.alpha, MAX_ALPHA)
end

function Ghost:buildPath(dst)
  Util.BFS(self.tile, dst)
  self.path = {dst}
  while dst.parent ~= self.tile do
    table.insert(self.path, dst.parent)
    dst = dst.parent
  end
end

function Ghost:walkPath()
  if self.path == nil or #self.path == 0 or self.tile == self.target then
    self.path = nil
    self.markedForRemoval = true
  else
    local dst = table.remove(self.path)  -- pop and return last element
    local dir = Util.whichDirIs(self.tile, dst)
    if dir then
      self:move(dir)
    else
      debug_log('walkPath cannot find dir from', self.tile.x, self.tile.y, 'to', dst.x, dst.y)
    end
  end
  if self.tile == self.target then
    self.target:removeFlag()
  end
end

function Ghost:walkWhite()
  if not self.tile:hasSpore() then
    self.tile:addSpore()
  end
  self:walkAqua()
end

function Ghost:walkAqua()
  self.target = nil
  local dirs
  if math.random() > 0.5 then
    dirs = {Util.left,Util.forward,Util.right,Util.opposite}
  else
    dirs = {Util.right,Util.forward,Util.left,Util.opposite}
  end
  for i = 1, #dirs do
    local dir = dirs[i](self.facing)
    if self:isGoodDir(dir) then -- don't enter cul-de-sacs
      self:move(dir)
      break
    end
  end
end

--[[
function Ghost:walkLeft()
  self.target = nil
  local dirs = {Util.left,Util.forward,Util.right,Util.opposite}
  for i = 1, #dirs do
    local dir = dirs[i](self.facing)
    if self:isGoodDir(dir) then -- don't enter cul-de-sacs
      self:move(dir)
      break
    end
  end
end
]]

--[[
function Ghost:walkRight()
  self.target = nil
  local dirs = {Util.right,Util.forward,Util.left,Util.opposite}
  for i = 1, #dirs do
    local dir = dirs[i](self.facing)
    if self:isGoodDir(dir) then -- don't enter cul-de-sacs
      self:move(dir)
      break
    end
  end
end
]]

function Ghost:walkTarget()
  assert(self.target)
  if self.tile == self.target then
    self.markedForRemoval = true
    return
  end
  local tDst = self.target
  Util.BFS(self.tile, tDst)
  while tDst.parent ~= self.tile do
    tDst = tDst.parent
    -- assert(tDst)
  end
  self:move(Util.whichDirIs(self.tile, tDst))
end

function Ghost:walkRed()
  self.target = _G.game.pixie.tile
  self:walkTarget()
end

-- function Ghost:walkOrange()
--   self:walkPath()
-- end

function Ghost:walkBlue()
end

function Ghost:walkPurple()
  -- target path set by turnPurple
  self:walkPath()
end

function Ghost:walkGreen()
  -- target path set by turnGreen
  self:walkPath()
end

function Ghost:walkPink()
  -- target path set by turnPink
  self:walkPath()
end

function Ghost:walk()
  self:walkfn()
end

function Ghost:turnBlue()
  if self.target and self.path then
    self.target:removeFlag()
    self.target = nil
    self.path = nil
  end
  self.color = _G.colors.blue
  self.walkfn = Ghost.walkBlue
  self.circle:setFillColor(unpack(self.color))
  self.group:toFront()
end

function Ghost:turnRed()
  -- target is set dynamically
  self.path = nil
  self.color = _G.colors.red
  self.walkfn = Ghost.walkRed
  self.circle:setFillColor(unpack(self.color))
  self.group:toFront()
end

-- function Ghost:turnOrange()
--   self.target = _G.game.pixie.target
--   self.color = _G.colors.orange
--   self.target:setFlag(self.color)
--   self:buildPath(_G.game.pixie.target)
--   self.walkfn = Ghost.walkOrange
--   self.circle:setFillColor(unpack(self.color))
--   self.group:toFront()
-- end

function Ghost:turnPurple()
  self.target = _G.game.pixie.target
  self.color = _G.colors.purple
  self.target:setFlag(self.color)
  self:buildPath(self.target)
  self.walkfn = Ghost.walkPurple
  self.circle:setFillColor(unpack(self.color))
end

function Ghost:turnAqua()
  self.target = nil
  self.path = nil
  self.color = _G.colors.aqua
  self.walkfn = Ghost.walkAqua
  self.circle:setFillColor(unpack(self.color))
end

function Ghost:turnWhite()
  self.target = nil
  self.path = nil
  self.color = _G.colors.white
  self.walkfn = Ghost.walkWhite
  self.circle:setFillColor(unpack(self.color))
end

function Ghost:turnGreen(target)
  self.target = target
  self.color = _G.colors.green
  -- self.target:setFlag(self.color)
  self:buildPath(self.target)
  self.walkfn = Ghost.walkGreen
  self.circle:setFillColor(unpack(self.color))
  -- no need to reset .facing from it's random value created by new()
  -- because entrance/exit tunnel only has one direction
end

--[[
function Ghost:turnPink()
  self.target = _G.game.got.spawnTiles[1]
  self.color = _G.colors.pink
  self.target:setFlag(self.color)
  self:buildPath(self.target)
  self.walkfn = Ghost.walkPink
  self.circle:setFillColor(unpack(self.color))
end
]]

function Ghost:isHarmless()
  return self.walkfn == Ghost.walkBlue
end

--[[
  General destructor; need to dispose of
    Runtime listeners
    transitions and timers
    audio
    open files
]]
function Ghost:destroy()

  if self.target then
    self.target:removeFlag()
  end

  display.remove(self.group)

end

return Ghost