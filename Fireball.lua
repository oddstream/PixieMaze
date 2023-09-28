-- class Fireball

local Util = require 'Util'

local Fireball = {
  -- prototype object
  -- class constants
  radius =  nil,
  lifespan = 3000,

  -- class data
  tile = nil,
  timer = nil,
  path = nil, -- Tile-path to target (stack)

  -- class display objects
  circle = nil,
}

function Fireball:new(tile, target)
  local o = {}
  self.__index = self
  setmetatable(o, self)

  o.tile = tile -- tile we are on

  Util.BFS(o.tile, target)
  o.path = {target}
  while target.parent ~= o.tile do
    -- assert(target.parent)
    table.insert(o.path, target.parent)
    target = target.parent
    -- assert(target)
  end

  -- debug_log('new fireball path', table.length(o.path))
  -- debug_log('new fireball path', #o.path)
  -- assert(#o.path==table.length(o.path))

  o.radius = math.round(_G.Q / 6)
  o.circle = display.newCircle(_G.groups.actors, tile.center.x, tile.center.y, o.radius)
  -- using a glyph for the fireball makes it look like a chuffing snowflake, ffs
  -- o.circle = display.newText({parent=_G.groups.actors, text='☼', x=tile.center.x, y=tile.center.y, font=native.systemFontBold, fontSize=_G.Q/2})
  o.circle:setFillColor(unpack(_G.colors.orange))
  transition.to(o.circle, {alpha=0.1, time=o.lifespan})
  o.timer = timer.performWithDelay(o.lifespan, function()
    o.timer = nil
    display.remove(o.circle)
    o.circle = nil
  end, 1)

  _G.game:sound('fireball')

  return o
end

function Fireball:pos()
  return self.circle.x, self.circle.y
end

function Fireball:isActive()
  return self.circle and self.timer
end

function Fireball:walk()

  if not _G.game.ghosts or #_G.game.ghosts == 0 then
    return
  end

  if not self:isActive() then
    return
  end

  -- fireball can expire before all of path is used
  if #self.path > 0 then
    local dst = table.remove(self.path)  -- pop and return last element
    if dst then
      local xNew, yNew = dst.center.x, dst.center.y
      transition.moveTo(self.circle, {x=xNew, y=yNew, time=_G.FIREBALL_SPEED})
      self.tile = dst
    else
      debug_log('popped a nil off path length', #self.path)
    end
    -- debug_log('fireball path now', #self.path)
    -- assert(#self.path==table.length(self.path))
  end

  self.tile:transitionAlpha(1)

end

function Fireball:destroy()
  if self.timer then
    timer.cancel(self.timer)
    self.timer = nil
  end
  if self.circle then
    display.remove(self.circle)
    self.circle = nil
  end
end

return Fireball
