-- Pup (power up) class

local Util = require 'Util'
local MagicItem = require 'MagicItem'

local Pup = {
  -- class constants
  radius = nil,

  -- class members
  tile = nil,
  facing = nil,
  slot = nil,

  path = nil,   -- path to pixie

  -- graphical objects
  group = nil,
  circle = nil,
  icon = nil,
}

local data = {
  {type='health', color=_G.colors.red, slot=1},
  {type='teleport', color=_G.colors.blue, slot=2},  -- used to have duration=4,
  -- middle/three slot is action button
  {type='illumination', color=_G.colors.white, slot=3},
  {type='fireball', color=_G.colors.orange, slot=4},
}

function Pup:new(tile, slot)
  local o = {}
  self.__index = self
  setmetatable(o, self)

  o.tile = tile

  local xc, yc = tile:centerXY()
  o.group = display.newGroup()
  -- move origin of group to center of owning tile
  o.group.x = xc
  o.group.y = yc
  _G.groups.actors:insert(o.group)

  o.radius = math.round(_G.Q/4)
  o.circle = display.newCircle(o.group, 0, 0, o.radius)
  o.circle:setFillColor(unpack(data[slot].color))
  o.circle.blendMode = 'src'
  -- transition.to(o.circle, {transition = easing.continuousLoop, iterations = -1, time = 1000, xScale = 0.8, yScale = 0.8})

  o.icon = display.newImage(o.group, _G.iconImageSheet, slot)
  o.icon.width = _G.Q3
  o.icon.height = _G.Q3

  o.facing = 'n'
  o.slot = slot

  o.group.alpha = tile.alpha

  return o
end

function Pup:pos()
  return self.group.x, self.group.y
end

function Pup:walk()
  local pix = _G.game.pixie

  if pix == nil or pix.group == nil then
    return
  end

  if pix.target == self.tile then
    return
  end

  if pix.path and table.contains(pix.path, self.tile) then
    return
  end

  local dirs
  if math.random() > 0.5 then
    dirs = {Util.left,Util.forward,Util.right,Util.opposite}
  else
    dirs = {Util.right,Util.forward,Util.left,Util.opposite}
  end

  local goDir
  for i = 1, #dirs do
    local dir = dirs[i](self.facing)
    local t = self.tile
    local tn = t[dir]
    if tn and not t.walls[dir] then
      goDir = dir
      break
    end
  end

  if goDir then
    local tNew = self.tile[goDir]
    local xNew, yNew = tNew:centerXY()
    transition.moveTo(self.group, {x=xNew, y=yNew, time=_G.PUP_SPEED})
    self.tile = tNew
    self.facing = goDir
    self.group.alpha = self.tile.alpha
  end

end

function Pup:createMagicItem()

  -- transform content coords into viewPort coords
  local cx = self.tile.center.x + self.group.parent.x
  local cy = self.tile.center.y + self.group.parent.y
  local obj = {x=cx, y=cy}
  for k,v in pairs(data[self.slot]) do
    obj[k] = v
  end
  -- TODO assign knapsack position/depth when adding to knapsack
  return MagicItem:new(obj)

end

--[[
  General destructor; need to dispose of
    Runtime listeners
    transitions and timers
    audio
    open files
]]
function Pup:destroy()

  display.remove(self.group)

end

return Pup
