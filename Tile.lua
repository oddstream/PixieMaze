-- Tile class

local Util = require 'Util'

local Tile = {
  -- prototype object
  x = nil,        -- column
  y = nil,        -- row
  center = nil,   -- table of x, y

  n, e, s, w = nil, nil, nil, nil,

  visited = false,-- used when carving passages
  parent = nil,   -- used by BFS
  isCulDeSac = false,

  rect = nil,     -- ShapeObject
  -- cap = nil,      -- ShapeObject
  caps = nil,     -- array of four ShapeObjects
  walls = nil,    -- array of four ShapeObjects
  alpha = 1,      -- seen/unseen

  spore = nil,    -- ShapeObject
  flag = nil,     -- ShapeObject

  -- slime = nil,

  routeObjects = nil,
}

local ALL_DIRECTIONS = {'n','e','s','w'}

local wallCoords = {
  -- coords for a line from x1,y1 to x2,y2
  -- return multiple coords on stack faster than returning a table
  -- coords are relative to center of tile
  n = function() return -_G.Q2,-_G.Q2, _G.Q2,-_G.Q2 end,
  e = function() return _G.Q2,-_G.Q2, _G.Q2,_G.Q2 end,
  s = function() return -_G.Q2,_G.Q2, _G.Q2,_G.Q2 end,
  w = function() return -_G.Q2,-_G.Q2, -_G.Q2,_G.Q2 end
}

function Tile:new(x, y)
  local o = {}
  self.__index = self
  setmetatable(o, self)

  o.x = x
  o.y = y
  -- content coords of the center of each tile
  -- add Q/2 to give center of tile
  -- substract Q because tiles are indexed from 1, but content coords are from 0,0
  o.center = {x=x * _G.Q + (_G.Q2) - _G.Q, y=y * _G.Q + (_G.Q2) - _G.Q}

  o.walls = {n=nil, e=nil, s=nil, w=nil}

  o.visited = false
  o.isCulDeSac = false
  o.alpha = 1

  return o
end

function Tile:centerXY()
  return self.center.x, self.center.y
end

--[[
function Tile:reset()
  self.visited = false
  self:removeSpore()
  self.walls = {n=true, e=true, s=true, w=true}
  if self.rect then
    display.remove(self.rect)
    self.rect = nil
  end
end
]]

function Tile:id()
  return self.x .. ',' .. self.y
end

--[[
function Tile:isWall(dir)
  -- not used, gets called > 1,000,000 times per 10x50 level
  -- assert(Util.isValidDir(dir))
  return self.walls[dir]
end
]]

function Tile:removeWall(dir)
  -- assert(Util.isValidDir(dir))
  if self.walls[dir] then
    self.walls[dir]:removeSelf()
    self.walls[dir] = nil
  end
end

function Tile:removeWalls(dir)
  local neighbour = self[dir]
  if neighbour then
    self:removeWall(dir)
    neighbour:removeWall(Util.opposite(dir))
  end
end

function Tile:countWalls()
  local n = 0
  for _,dir in ipairs(ALL_DIRECTIONS) do
    if self.walls[dir] then
      n = n + 1
    end
  end
  return n
end

function Tile:recursiveBacktracker()
  local dirs = _G.table.shuffle({'n','e','s','w'})

  for _,dir in ipairs(dirs) do
    local neighbour = self[dir]
    if neighbour and neighbour.visited == false then
      self:removeWall(dir)
      neighbour:removeWall(Util.opposite(dir))
      neighbour.visited = true
      neighbour:recursiveBacktracker()
    end
  end
end

--[[
  Prim's algorithm
  http://weblog.jamisbuck.org/2011/1/10/maze-generation-prim-s-algorithm
  https://en.wikipedia.org/wiki/Maze_generation_algorithm#Randomized_Prim's_algorithm
]]

function Tile:primMark(frontier)
  -- mark this tile as 'in',
  -- then mark the 'out' neighbours as frontier tiles
  self.visited = true
  for _,dir in ipairs(ALL_DIRECTIONS) do
    local n = self[dir]
    if n and not n.visited then
      table.insert(frontier, n)
    end
  end
end

function Tile:primNeighbours()
  -- return all the 'in' neighbours of a frontier tile
  local lst = {}
  for _,dir in ipairs(ALL_DIRECTIONS) do
    local n = self[dir]
    if n and n.visited then
      table.insert(lst, n)
    end
  end
  return lst
end

function Tile:prim()
  -- called on a random tile

  -- Tile:new made all Tile.visited = false
  assert(self.visited==false)

  local frontier = {}
  self:primMark(frontier)
  while #frontier > 0 do
    -- choose a frontier tile at random
    local t1 = table.remove(frontier, math.random(#frontier))
    -- choose a random 'in' neighbour of that tile
    local lst = t1:primNeighbours()
    assert(#lst>0)
    local t2 = lst[math.random(#lst)]
    -- record a passage between the two tiles
    local dir = Util.whichDirIs(t1, t2)
    assert(dir)
    -- If only one of the two cells that the wall divides is visited...
    if (t1.visited and not t2.visited) or (not t1.visited and t2.visited) then
      t1:removeWall(dir)
      t2:removeWall(Util.opposite(dir))
    end
    -- mark the frontier tile as being 'in' the maze
    -- (and add any of it's outside neighbours to the frontier)
    t1:primMark(frontier)
  end
end

function Tile:tap(event)
  -- table listener for tap events
  -- event.target == self.rect
  -- debug_table('tile tap event', event)
  -- debug_log('tile tap event')
  if _G.game.pixie then
    _G.game.pixie:setDestinationOrTeleport(self)
  end
  return true
end

function Tile:touch(event)
  -- table listener for touch events
  -- event.x / event.y - the x and y position of the touch, in content coordinates.
  -- event.xStart / event.yStart — the x and y position of the touch from the "began" phase of the touch sequence, in content coordinates
  -- self varies strangely during moved phase, but can be constrained to starting tile with setFocus()

  -- debug_table('tile touch event', event)
  -- debug_log('tile touch event', event.phase)
  if _G.game.pixie then
    if _G.game.pixie:isMoving() then
      -- makes tap more responsive
      -- but will also get a tap event afterwards
      _G.game.pixie:setDestinationOrTeleport(self)
      return true
    else
      if event.phase == 'moved' then
        _G.game.got:drag(event.x - event.xStart, event.y - event.yStart)
      elseif event.phase == 'canceled' or event.phase == 'ended' then
        _G.game.got:drop()
      end
    end
  end

  return true
end

function Tile:addSpore()

  local xc, yc = self.center.x, self.center.y
  self.spore = display.newCircle(_G.groups.spores, xc, yc, 4)
  self.spore:setFillColor(unpack(_G.colors.spore))
  self.spore.alpha = self.alpha

end

function Tile:hasSpore()
  return self.spore ~= nil
end

function Tile:removeSpore()
  if self.spore then
    display.remove(self.spore)
    self.spore = nil
    return true
  else
    return false
  end
end

function Tile:createGraphics()
  -- called before linking tiles
  -- so we end up with walls overlapping their neighbour's walls
  -- which isn't great
  local xc, yc = self.center.x, self.center.y

  self.rect = display.newRect(_G.groups.maze, xc, yc, _G.Q, _G.Q)
  self.rect:setFillColor(unpack(_G.colors.tileBack))
  self.rect.alpha = self.alpha

  self.rect:addEventListener('tap', self) -- table listener
  self.rect:addEventListener('touch', self) -- table listener

  for _,dir in ipairs(ALL_DIRECTIONS) do

    -- only do south of there's no link to the south
    -- only do east of there's no link to the east

    if dir == 's' and self.s then
    elseif dir == 'e' and self.e then
    else

      local x1,y1,  x2,y2 = wallCoords[dir]()
      local wall = display.newLine(_G.groups.maze,
        xc + x1, yc + y1,
        xc + x2, yc + y2)
      wall.strokeWidth = math.round(_G.Q / 10)
      wall:setStrokeColor(unpack(_G.colors.wall))

      -- local debugWallColors = {
      --   n = {1,1,1},  -- white
      --   e = {0,1,0},  -- green
      --   s = {1,1,0},  -- yellow
      --   w = {1,0,0},  -- red
      -- }
      -- wall:setStrokeColor(unpack(debugWallColors[dir]))

      wall.blendMode = 'src'
      wall.alpha = self.alpha
      self.walls[dir] = wall
    end

  end
end

function Tile:setFlag(color)
  self:removeFlag()
  self.flag = display.newImage(_G.groups.maze, _G.iconImageSheet, 6)
  self.flag.x = self.center.x
  self.flag.y = self.center.y
  self.flag.width = _G.Q2
  self.flag.height = _G.Q2
  self.flag:setFillColor(unpack(color))
  self.flag.alpha = 0.5
end

function Tile:removeFlag()
  if self.flag then
    display.remove(self.flag)
    self.flag = nil
  end
end

--[[
function Tile:createCap()
  -- currently putting one cap at top left of tile
  -- has to be done after linking tiles
  if self.n and self.w then
    local xc, yc = self.center.x, self.center.y
    self.cap = display.newCircle(_G.groups.maze, xc - _G.Q2, yc - _G.Q2, math.round(_G.Q / 20))
    self.cap:setFillColor(unpack(_G.colors.wall))
    self.cap.alpha = self.alpha
    self.cap.blendMode = 'src'
  end
end
]]

function Tile:createCaps()
  local capCoords = {
    {-_G.Q2,-_G.Q2},  -- NW
    {_G.Q2,-_G.Q2},   -- NE
    {_G.Q2,_G.Q2},    -- SE
    {-_G.Q2,_G.Q2}    -- SW
  }

  self.caps = {}
  local xc, yc = self.center.x, self.center.y
    -- for _,cc in pairs(capCoords) do
  for i=1, #capCoords do

    if i == 3 and self.e and self.s then
    else
      local cc = capCoords[i]
      local x, y = unpack(cc)
      local cap = display.newCircle(_G.groups.maze, xc - x, yc - y, math.round(_G.Q / 20))

      -- local debugCapColors = {
      --   {1,1,1},  -- white
      --   {0,1,0},  -- green
      --   {1,1,0},  -- yellow
      --   {1,0,0},  -- red
      -- }
      -- cap:setFillColor(unpack(debugCapColors[i]))
      cap:setFillColor(unpack(_G.colors.wall))
      cap.alpha = self.alpha
      cap.blendMode = 'src'
      table.insert(self.caps, cap)
    end
  end
end

--[[
function Tile:getNeighbours(depth)
  depth = depth or 3
  local arr = {self}

  local function getNeighbours_(arrIn)
    -- can't copy new neighbours into the input arr, because ipairs appears to be dynamic, so will find all tiles on the first pass
    -- local arrOut = {unpack(arrIn)}  -- quick and dirty array copy
    local arrOut = table.copy(arrIn)  -- shallow table copy added to Lua by Corona
    for _,t in ipairs(arrIn) do
      for _,dir in ipairs(ALL_DIRECTIONS) do
        if not t.walls[dir] then
          local nb = t[dir]
          if nb ~= self and not table.contains(arrOut, nb) then
            table.insert(arrOut, nb)
            -- nb:markRect()
          end
        end
      end
    end
    return arrOut
  end

  while depth > 0 do
    arr = getNeighbours_(arr)
    depth = depth - 1
  end

  return arr
end
]]

function Tile:decAlpha()
  -- geddit?
  self.alpha = math.max(0.1, self.alpha - 0.01)
  self.rect.alpha = self.alpha
  if self.spore then
    self.spore.alpha = self.alpha
  end
  if self.routeObjects then
    for _,ro in pairs(self.routeObjects) do
      ro.alpha = self.alpha
    end
  end
end

function Tile:transitionAlpha(newAlpha)

  if newAlpha ~= self.alpha then
    self.alpha = newAlpha

    transition.to(self.rect, {alpha=newAlpha, time=500})

    if self.spore then
      transition.to(self.spore, {alpha=newAlpha, time=500})
    end

    if self.routeObjects then
      for _,ro in pairs(self.routeObjects) do
        transition.to(ro, {alpha=newAlpha, time=500})
      end
    end

  end
end

function Tile:revealNeighbours()
  for _,dir in ipairs(ALL_DIRECTIONS) do
    local t = self
    local a = 1
    while t do
      if not t[dir] then
        break
      end
      if t.walls[dir] then
        break
      end
      t = t[dir]
      a = a - 0.1
      t:transitionAlpha(math.max(t.alpha,a))
    end
  end
end

function Tile:inView()
--[[
  local cx, cy = self.centerXY()
  local ox, oy = _G.game.got.groupOriginX, _G.game.got.groupOriginY
  local px = ox + cx
  local py = oy + cy
  -- debug_log('tile', self.x, self.y, 'center', cx, cy, 'origin', ox, oy, 'point', px, py, 'inview', px >= 0 and py >= 0 and px <= display.contentWidth and py <= display.contentHeight)
  -- debug_log('display.content', display.contentWidth, display.contentHeight)
  return px >= 0 and py >= 0 and px <= display.contentWidth and py <= display.contentHeight
]]
  local x = _G.game.got.groupOriginX + self.center.x
  local y = _G.game.got.groupOriginY + self.center.y
  return x >= 0 and y >= 0 and x <= display.contentWidth and y <= display.contentHeight
end

function Tile:addRoute(t)
  local group = _G.groups.maze
  local color = _G.colors.pixie
  local offset = _G.Q / 4
  local xc, yc = self.center.x, self.center.y

  if self.n == t then
    yc = yc - offset
  elseif self.e == t then
    xc = xc + offset
  elseif self.s == t then
    yc = yc + offset
  elseif self.w == t then
    xc = xc - offset
  end
  local ro = display.newCircle(group, xc, yc, 3)  -- less than a spore
  ro:setFillColor(unpack(color))
  ro.alpha = 0
  transition.to(ro, {alpha=self.alpha, time=1000})

  if nil == self.routeObjects then
    self.routeObjects = {}
  end
  table.insert(self.routeObjects, ro)

end

function Tile:removeRoute()
  if self.routeObjects then
    for _,ro in pairs(self.routeObjects) do
      display.remove(ro)
    end
  end
  self.routeObjects = nil
end

--[[
  General destructor; need to dispose of
    Runtime listeners
    transitions and timers
    audio
    open files
]]
function Tile:destroy()
end

return Tile