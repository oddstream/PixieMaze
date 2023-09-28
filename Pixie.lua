-- Pixie class

local Util = require 'Util'

local Pixie = {
  -- prototype object
  tile = nil,     -- Tile we are sitting on
  target = nil,   -- Tile we are trying to get to
  path = nil,     -- Tile-path to target (stack)

  group = nil,      -- contains pixie objects
  circle = nil,     -- ShapeObject

  color = nil,      -- overriden by magic

  timer = nil,      -- magic spell timer
  countdownText = nil,
  seconds = nil,    -- value to count down

  magicType = nil,      -- magic spell currently in effect

  invulnerable = false,

  marker = nil,     -- ShapeObject
}

function Pixie:new(tile)
  local o = {}
  self.__index = self
  setmetatable(o, self)

  o.tile = tile
  o.target = tile -- so target is never nil

  o.minHealth = math.round(_G.Q / 10)
  o.maxHealth = _G.Q3
  o.markerRadius = math.round(_G.Q / 7)

  -- create a group for pixie that contains circle and countdownText
  local xc, yc = tile:centerXY()
  o.group = display.newGroup()
  -- move origin of group to center of owning tile
  o.group.x = xc
  o.group.y = yc
  _G.groups.actors:insert(o.group)

  o.color = _G.colors.pixie
  o.circle = display.newCircle(o.group, 0, 0, o.maxHealth)
  transition.to(o.circle, {transition = easing.continuousLoop, iterations = -1, time = 1200, xScale = 0.85, yScale = 0.95})

  -- unpack() in 5.1, table.unpack() in 5.2, 5.3
  o.circle:setFillColor(unpack(o.color))
  o.circle.blendMode = 'src'

  o.countdownText = nil
  o.seconds = 0

  -- use o instead of self
  -- otherwise self in table lister will refer to prototype object
  -- not object made by this function
  o.circle:addEventListener('tap', o) -- table listener

  return o
end

function Pixie:getRadius()
  return self.circle.path.radius
end

function Pixie:tap(event)
  _G.game:gotoPupOrExit()
  return true
end

function Pixie:pos()
  return self.group.x, self.group.y
end

function Pixie:animateToStart()
  local xc, yc = self.tile:centerXY()
  transition.moveTo(self.group, {x=xc, y=yc, time=_G.PAN_SPEED, transition=easing.outQuart})
  _G.game:pixieMoved()
end

function Pixie:isHealthy()
  return self.circle.path.radius > self.minHealth
end

function Pixie:resetHealth()
  self.circle.path.radius = self.maxHealth
end

function Pixie:degradeHealth()
  -- strokeWidth likes to be an integer
  if self.circle.path.radius > self.minHealth then
    self.circle.path.radius = self.circle.path.radius - 1
  end
end

function Pixie:explode()

  local xc, yc = self.tile:centerXY()
  local circle = display.newCircle(_G.groups.actors, xc, yc, self.maxHealth)
  circle:setFillColor(unpack(self.color))
  transition.scaleBy(circle,
  {
    xScale = 20,
    yScale = 20,
    time = 500,
    onComplete = function()
      display.remove(circle)
    end
  })
  transition.fadeOut(circle,
  {
    time = 500,
  })
end

function Pixie:shockwave()
  _G.game:sound('shockwave')

  local xc, yc = self.tile:centerXY()
  local circle = display.newCircle(_G.groups.actors, xc, yc, self.maxHealth)
  circle:setFillColor(0,0,0, 0.5)
  transition.scaleBy(circle,
  {
    xScale = 20,
    yScale = 20,
    time = 500,
    onComplete = function()
      display.remove(circle)
    end
  })
  transition.fadeOut(circle,
  {
    time = 500,
  })
end

function Pixie:removeRoute()
  -- then, do ... c'mon Roberto Ierusalimschy I thought this was supposed to be simple
  if self.path then
    while #self.path > 0 do
      local t = table.remove(self.path)
      t:removeRoute()
    end
  end
end

function Pixie:setDestination(dst)

  -- might get double call from touch/tap
  if not dst or dst == self.tile or dst == self.target then
    return
  end

  self:removeRoute()

  if not self.marker then
    -- create the marker where we are now
    local xOld, yOld = self.tile:centerXY()
    self.marker = display.newCircle(_G.groups.actors, xOld, yOld, self.markerRadius)
    self.marker:setFillColor(unpack(_G.colors.pixie))
    self.marker.alpha = 1
    self.marker.blendMode = 'src'

    self.marker:toBack()
  end

  -- _G.game.got:unmarkSporePath()

  Util.BFS(self.tile, dst)

  local d = dst
  self.path = {d}
  while d.parent ~= self.tile do
    table.insert(self.path, d.parent)

    d:addRoute(d.parent)
    d.parent:addRoute(d)

    d = d.parent
    -- assert(dst)
  end

  local xNew, yNew = dst:centerXY()

  self.target = dst
  transition.moveTo(self.marker, {x=xNew, y=yNew, time=1000, transition=easing.outQuart})
  -- debug_log('new pixie path', #self.path)

  _G.game:sound('throw')
end

function Pixie:setDestinationOrTeleport(dst)
  if self.magicType == 'teleport' then
    _G.game:sound('teleport')
    self:removeMagic()
    self:removeRoute()
    self:move(dst)
    if self.marker ~= nil then
      self.marker:removeSelf() -- setDestination will create marker
      self.marker = nil
    end
  else
    self:setDestination(dst)
  end
end

--[[
function Pixie:gotoNearestCuldeSac()
  self:setDestination(Util.BFS3(self.tile))
end
]]

function Pixie:move(tNew)

  if not (self.circle and self.circle.setFillColor) then
    return
  end

  local xNew, yNew = tNew:centerXY()

  transition.moveTo(self.group, {x=xNew, y=yNew, time=_G.PIXIE_SPEED})

  self.tile = tNew

  if tNew.isCulDeSac then
    self.circle.alpha = 0.2
  else
    self.circle.alpha = 1
  end

  if tNew == self.target then
    _G.game:sound('pin')
  end

  tNew:removeRoute()

  _G.game:pixieMoved()

end

function Pixie:isMoving()
  if self.target == nil or self.target == self.tile then
    return false
  end
  return true
end

function Pixie:walkTarget()

  if not self:isMoving() then
    return
  end

  if self.path and #self.path > 0 then
    local dst = table.remove(self.path)  -- pop and return last element
    if dst then
      self:move(dst)
    end
  end

end

function Pixie:pauseTimer()
  if self.timer then
    timer.pause(self.timer)
  end
end

function Pixie:resumeTimer()
  if self.timer then
    timer.resume(self.timer)
  end
end

function Pixie:cancelTimer()
  if self.timer then
    timer.cancel(self.timer)
    self.timer = nil
  end
end

--[[
function Pixie:isCountingDown()
  return self.timer ~= nil
end
]]

function Pixie:startCountdown(item)
  -- debug_log('pixie start countdown', item.type, item.duration)

  local function countdown()
    -- gets called once per second by a timer loop
    assert(self.timer)
    assert(self.countdownText)
    self.seconds = self.seconds - 1
    if self.seconds < 1 then
      self:endCountdown()
      self:removeMagic()
    else
      -- debug_log('pixie countdown', self.seconds)
      self.countdownText.text = tostring(self.seconds)
    end
  end

  if self.timer then
    debug_log('pixie timer already running')
    self:endCountdown()
  end

  self.seconds = item.duration
  self.countdownText = display.newText({
    parent = self.group,
    text = tostring(self.seconds),
    x = 0,
    y = 0,
    font = native.systemFontBold,
    fontSize = _G.Q3,
    align = 'center',
  })
  self.countdownText:setFillColor(unpack(_G.colors.black))
  self.timer = timer.performWithDelay(900, countdown, 0) -- use duration
  self:setMagic(item)
end

function Pixie:endCountdown()
  -- debug_log('pixie end countdown')
  if self.timer then
    timer.cancel(self.timer)
    self.timer = nil
  end
  display.remove(self.countdownText)
  self.countdownText = nil
end

function Pixie:setMagic(item)
  self.magicType = item.type
  self.color = item.color
  self.circle:setFillColor(unpack(self.color))
end

function Pixie:removeMagic()
  self.magicType = nil  -- turn off magic spell
  self.color = _G.colors.pixie
  self.circle:setFillColor(unpack(self.color))
end

--[[
  General destructor; need to dispose of
    Runtime listeners
    transitions and timers
    audio
    open files
]]
function Pixie:destroy()

  self:endCountdown()

  display.remove(self.group)
  self.group = nil

end

return Pixie
