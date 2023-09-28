-- GridOfTiles class

local Tile = require 'Tile'

local GridOfTiles = {
  -- prototype object
  tiles = nil,    -- array of Tile objects
  width = nil,    -- number of columns
  height = nil,   -- number of rows

  start = nil,    -- tile Pixie will start on
  backStart = nil,    -- tile Pixie will start on if going backwards
  entrance = nil,
  exit = nil,
}

function GridOfTiles:new(data)
  local o = {}
  self.__index = self
  setmetatable(o, self)

  o.width = data.width
  o.height = data.height

  o.tiles = {}
  o.spawnTiles = {}

  local function inRect(x, y, x1,y1, x2, y2)
    return x >= x1 and x <= x2 and y >= y1 and y <= y2
  end

  local function isBlank(x, y)
    if data.blank ~= nil then
      return inRect(x, y, unpack(data.blank))
    elseif data.blanks ~= nil then
      for _,blank in pairs(data.blanks) do
        if inRect(x, y, unpack(blank)) then
          return true
        end
      end
    end
    return false
  end

  for y = 1, o.height do
    for x = 1, o.width do
      if not isBlank(x, y) then
        local t = Tile:new(x, y)
        t:createGraphics()
        table.insert(o.tiles, t)
      end
    end
  end

  for i = 1, #data.entrance do
    o.start = o.entrance  -- last but one is pixie start tile
    o.entrance = Tile:new(unpack(data.entrance[i]))
    o.entrance:createGraphics()
    table.insert(o.tiles, o.entrance)
  end
  if _G.game.status.level == 1 then
    o.entrance.spore = display.newImage(_G.groups.spores, _G.iconImageSheet, 7)
    local oe = o.entrance
    local oes = oe.spore
    oes.x = oe.center.x
    oes.y = oe.center.y
    oes.width = _G.Q2
    oes.height = _G.Q2
  else
    o.entrance.spore = display.newText({parent=_G.groups.spores, text=tostring(_G.game.status.level-1), x=o.entrance.center.x, y=o.entrance.center.y, font=native.systemFontBold, fontSize=_G.Q2})
  end

  for i = 1, #data.exit do
    o.backStart = o.exit  -- last but one is pixie start tile when going back a level
    o.exit = Tile:new(unpack(data.exit[i]))
    o.exit:createGraphics()
    table.insert(o.tiles, o.exit)
  end
  if _G.game.status.level == _G.game:numberOfLevels() then
    o.exit.spore = display.newImage(_G.groups.spores, _G.iconImageSheet, 7)
    local oe = o.exit
    local oes = oe.spore
    oes.x = oe.center.x
    oes.y = oe.center.y
    oes.width = _G.Q2
    oes.height = _G.Q2
  else
    o.exit.spore = display.newText({parent=_G.groups.spores, text=tostring(_G.game.status.level+1), x=o.exit.center.x, y=o.exit.center.y, font=native.systemFontBold, fontSize=_G.Q2})
  end

  local spawnTiles = {
    {0,1}, {1,0},  -- top left
    {0,o.height}, {1,o.height+1}, -- bottom left
    {o.width,0}, {o.width+1,1},  -- top right
    {o.width+1,o.height}, {o.width,o.height+1}, -- bottom right
  }
  -- assert(#spawnTiles==8)

  local cornerTiles = {
    -- doubled up to make the loop easier
    {1,1},{1,1},  -- top left
    {1,o.height},{1,o.height}, -- bottom left
    {o.width,1},{o.width,1},  -- top right
    {o.width,o.height},{o.width,o.height},  -- bottom right
  }
  -- assert(#cornerTiles==8)

  -- add automatic spawn tiles
  for i = 1, #spawnTiles do
    if o:findTile(unpack(cornerTiles[i])) ~= nil then
      local t = Tile:new(unpack(spawnTiles[i]))
      t:createGraphics()
      table.insert(o.tiles, t)
      table.insert(o.spawnTiles, t)
    end
  end

  -- add extra level-specific spawn tiles
  if data.spawntiles then
    for i = 1, #data.spawntiles do
      local t = Tile:new(unpack(data.spawntiles[i]))
      t:createGraphics()
      table.insert(o.tiles, t)
      table.insert(o.spawnTiles, t)
    end
  end

  o:linkTiles()

  for _,t in ipairs(o.tiles) do
    t:createCaps()
  end

  return o
end

function GridOfTiles:linkTiles()
  -- TODO could also link ne, se, sw, nw
  for _,t in ipairs(self.tiles) do
    t.n = self:findTile(t.x, t.y - 1)
    t.e = self:findTile(t.x + 1, t.y)
    t.s = self:findTile(t.x, t.y + 1)
    t.w = self:findTile(t.x - 1, t.y)
  end
end

function GridOfTiles:carvePassages()
  local t = self:randomTile()
  if _G.game.difficulty == 'hard' or _G.game.difficulty == 'evil' then
    t:recursiveBacktracker()
  else
    t:prim()
  end
end

function GridOfTiles:iterator(fn)
  for _,t in ipairs(self.tiles) do
    fn(t)
  end
end

function GridOfTiles:inMainGrid(t)
  return t.x >= 1 and t.x <= self.width and t.y >= 1 and t.y <= self.height
end

function GridOfTiles:addSpores()
  for _,t in ipairs(self.tiles) do
    -- only add spore to tiles in main grid i.e. not in ghost spawn, entrance or exit tiles
    -- TODO why?
    if self:inMainGrid(t) then
      t:addSpore()
    end
  end
end

function GridOfTiles:addSavedSpores(saved)
  for i = 1, #saved do
    local x, y = unpack(saved[i])
    local t = self:findTile(x,y)
    t:addSpore()
  end
end

--[[
function GridOfTiles:hasSpores()
  for _,t in ipairs(self.tiles) do
    if t:hasSpore() then
      return true
    end
  end
  return false
end
]]

--[[
function GridOfTiles:unmarkSporePath()
  for _,t in ipairs(self.tiles) do
    if t.spore then
      t.spore:setFillColor(unpack(_G.colors.spore))
    end
  end
end
]]

function GridOfTiles:findTile(x,y)
  for _,t in ipairs(self.tiles) do
    if t.x == x and t.y == y then
      return t
    end
  end
  return nil
end

function GridOfTiles:randomTile()
  return self.tiles[math.random(#self.tiles)]
end

--[[
function GridOfTiles:removeRandomWall()
  local dirs = {'n','e','s','w'}
  local dir = dirs[math.random(#dirs)]
  local t = self.tiles[math.random(#self.tiles)]
  local neighbour = t[dir]
  if neighbour then
    t:removeWalls(dir)
    debug_log('tried to remove wall', dir, 'from', t.x, t.y)
  end
end
]]

--[[
function GridOfTiles:findCulDeSacs()
  local arr = {}
  self:iterator(function(t)
    if t.isCulDeSac then
      arr[#arr+1] = t
    end
  end)
  -- print(#arr, 'cul-de-sacs found')
  return arr
end
]]

--[[
function GridOfTiles:createGraphics()
  self:iterator(function(t) t:createGraphics() end)
end
]]

function GridOfTiles:centerOnPixie()
  local xc, yc = _G.game.pixie.tile:centerXY()
  -- local xc, yc = _G.game.pixie.group.x, _G.game.pixie.group.y
  local halfViewPortWidth = display.contentWidth / 2
  local halfViewPortHeight = display.contentHeight / 2
  local xNew, yNew = -xc + halfViewPortWidth, -yc + halfViewPortHeight
  transition.moveTo(_G.groups.maze, {x=xNew, y=yNew, time=_G.PAN_SPEED, transition=easing.linear})
  transition.moveTo(_G.groups.spores, {x=xNew, y=yNew, time=_G.PAN_SPEED, transition=easing.linear})
  transition.moveTo(_G.groups.actors, {x=xNew, y=yNew, time=_G.PAN_SPEED, transition=easing.linear})
  self.groupOriginX = xNew
  self.groupOriginY = yNew
  -- _G.game.status.levelNameText.text = string.format('%d,%d', xNew, yNew)
  -- _G.game.status:debug(string.format('%d,%d', xNew, yNew))
  -- _G.game.status:debug(string.format('%d,%d : %d %d - %d %d',
  --   _G.game.pixie.group.x,
  --   _G.game.pixie.group.y,
  --   xNew, yNew, xNew + display.contentWidth, yNew + display.contentHeight))
end

--[[
function GridOfTiles:centerOnTile(t)
  local xc, yc = t.center.x, t.center.y
  local halfViewPortWidth = display.contentWidth / 2
  local halfViewPortHeight = display.contentHeight / 2
  local xNew = -xc + halfViewPortWidth
  local yNew = -yc + halfViewPortHeight
  transition.moveTo(_G.groups.maze, {x=xNew, y=yNew, time=100})
  transition.moveTo(_G.groups.spores, {x=xNew, y=yNew, time=100})
  transition.moveTo(_G.groups.actors, {x=xNew, y=yNew, time=100})
  -- _G.groups.maze.x=xNew
  -- _G.groups.maze.y=yNew
  -- _.groups.spores.x=xNew
  -- _.groups.spores.y=yNew
  -- _G.groups.actors.x=xNew
  -- _G.groups.actors.y=yNew
end
]]

function GridOfTiles:drag(x,y)
  local xNew = self.groupOriginX + x
  local yNew = self.groupOriginY + y
  _G.groups.maze.x = xNew
  _G.groups.maze.y = yNew
  _G.groups.spores.x = xNew
  _G.groups.spores.y = yNew
  _G.groups.actors.x = xNew
  _G.groups.actors.y = yNew
end

function GridOfTiles:drop()
  local xNew = self.groupOriginX
  local yNew = self.groupOriginY
  transition.moveTo(_G.groups.maze, {x=xNew, y=yNew, time=_G.PAN_SPEED, transition=easing.linear})
  transition.moveTo(_G.groups.spores, {x=xNew, y=yNew, time=_G.PAN_SPEED, transition=easing.linear})
  transition.moveTo(_G.groups.actors, {x=xNew, y=yNew, time=_G.PAN_SPEED, transition=easing.linear})
end

--[[
function GridOfTiles:revealNeighbours(ct)
  -- turn up alpha of all tiles within distance
  local cx, cy = ct.center.x, ct.center.y
  local radius = _G.Q * 2

  for _,t in ipairs(self.tiles) do
    local tx, ty = t.center.x, t.center.y
    if Util.distance(cx, cy, tx, ty) < radius then
      t:transitionAlpha(1)
    end
  end
end
]]

--[[
  General destructor; need to dispose of
    Runtime listeners
    transitions and timers
    audio
    open files
]]
function GridOfTiles:destroy()

end

return GridOfTiles