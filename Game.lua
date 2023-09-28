-- Game (singleton) class

local composer = require('composer')

local Bubble = require 'Bubble'
local Ghost = require 'Ghost'
local Fireball = require 'Fireball'
local Status = require 'Status'
local Knapsack = require 'Knapsack'
local Util = require 'Util'

local Game = {
  settings = nil,
  difficulty = nil,
  got = nil,
  pixie = nil,
  ghosts = nil,
  pups = nil,
  timers = nil,
  paused = nil,
  fireballs = nil,
  status = nil,
  knapsack = nil,

  levelData = nil,
  soundTable = nil,

  frameCount = nil,

  rnd = nil,
}

function Game:new(o)
  o = o or {}
  self.__index = Game
  setmetatable(o, self)

  o.settings = Util.loadSettings()
  o.difficulty = 'normal'
  o.timers = {}
  o.paused = false
  o.status = Status:new()
  o.knapsack = Knapsack:new()

  -- pearl from the mudbank: argument to math.randomseed() must be an integer

  o.levelData = {
    -- n.b. no .savedSpores
    {name='Start', width=11, height=10, ghosts=1, entrance={{6,0},{6,-1},{6,-2},{6,-3}}, exit={{6,11},{6,12},{6,13},{6,14}}, seed=math.random(1,999999) },
    {name='11x15', width=11, height=15, ghosts=2, entrance={{6,0},{6,-1},{6,-2},{6,-3}}, exit={{6,16},{6,17},{6,18},{6,19}}, seed=math.random(1,999999) },

    {name='Tall', width=11, height=60, ghosts=8, spawntiles={{0,20},{0,30},{0,40},{0,50},{12,20},{12,30},{12,40},{12,50}}, entrance={{6,0},{6,-1},{6,-2},{6,-3}}, exit={{6,61},{6,62},{6,63},{6,64}}, seed=math.random(1,999999) },
    {name='Wide', width=60, height=11, ghosts=8, spawntiles={{10,0},{20,0},{30,0},{40,0},{50,0}}, entrance={{0,6},{-1,6},{-2,6},{-3,6}}, exit={{61,6},{62,6},{63,6},{64,6}}, seed=math.random(1,999999) },

    {name='Charlie', width=20, height=20, ghosts=6, blank={8,9,20,12}, entrance={{21,8},{22,8},{23,8},{24,8}}, exit={{21,13},{22,13},{23,13},{24,13}}, seed=math.random(1,999999) },
    {name='Uniform', width=20, height=20, ghosts=6, blank={10,1,11,13}, entrance={{9,0},{9,-1},{9,-2},{9,-3}}, exit={{12,0},{12,-1},{12,-2},{12,-3}}, seed=math.random(1,999999) },
    {name='Sierra', width=20, height=50, ghosts=10, blanks={{10,10,20,20},{1,30,10,40}}, spawntiles={{0,29},{1,30}}, entrance={{21,9},{22,9},{23,9},{24,9}}, exit={{0,41},{-1,41},{-2,41},{-3,41}}, seed=math.random(1,999999) },
    {name='Hotel', width=30, height=30, ghosts=10, blanks={{10,1,20,14},{10,16,20,30}}, entrance={{5,0},{5,-1},{5,-2},{5,-3}}, exit={{25,31},{25,32},{25,33},{25,34}}, seed=math.random(1,999999) },

    {name='Oscar', width=30, height=30, ghosts=10, blank={10,10,20,20}, entrance={{5,0},{5,-1},{5,-2},{5,-3}}, exit={{25,31},{25,32},{25,33},{25,34}}, seed=math.random(1,999999) },
    {name='Fin', width=30, height=30, ghosts=15, spawntiles={{0,15},{31,15},{15,0},{15,31}}, entrance={{5,0},{5,-1},{5,-2},{5,-3}}, exit={{25,31},{25,32},{25,33},{25,34}}, seed=math.random(1,999999) },
  }

  if _G.MUTE_AUDIO then
    o.soundTable = {}
  else
    o.soundTable = {
      complete = audio.loadSound('sound/complete.wav'),
      ghostdeath = audio.loadSound('sound/stapler_1.wav'),
      beep = audio.loadSound('sound/beep-07.wav'),
      fireball = audio.loadSound('sound/matches-1.wav'),
      pin = audio.loadSound('sound/sound85.wav'),
      pixiedeath = audio.loadSound('sound/sound63.wav'),
      passage = audio.loadSound('sound/scissors-2.wav'),
      shockwave = audio.loadSound('sound/sound5.mp3'),
      teleport = audio.loadSound('sound/sound13.mp3'),
      throw = audio.loadSound('sound/bottle_pop_2.wav'),
      item = audio.loadSound('sound/water-drop-1.wav'),
      spore = audio.loadSound('sound/clik.wav'),
    }
  end

  o.frameCount = 1

  -- debug_log('new Game table created')
  -- for i = 1, #o.levelData do
  --   debug_log(o.levelData[i].seed)
  -- end

  Bubble.load()

  return o
end

--[[
  Handlers for game logic
  These functions reach out to all the main global game objects
  (grid, pixie, ghosts, knapsack items)
]]

function Game:sound(name)
  -- debug_log('sound', name)
  local handle = self.soundTable[name]
  if handle then
    audio.play(handle)
  end
end

-- local function timeLoop()
--   _G.game.status:incTime()
-- end

local function pixieLoop()

  local gam = _G.game

  if not gam then
    debug_log('pixieLoop: game has been deleted')
    return
  end

  if not gam.pixie then
    debug_log('pixieLoop: pixie has been deleted')
    return
  end

  if gam.pixie.tile:removeSpore() then
    gam:sound('spore')
    gam.status:incScore()
  end

  if gam.pixie.tile == gam.got.exit then

    if gam.difficulty == 'evil' and #gam.pups > 0 then
      Bubble:new('Collect all power ups')
      gam.pixie:walkTarget()
    else
      if gam.status.level == gam:numberOfLevels() then
        gam:sound('complete')
        composer.gotoScene('HighScores', {effect='fade', params={banner='C O M P L E T E', score=math.floor(gam.status.score)}})
      else
        gam:saveLevelData()
        composer.gotoScene('Passage', {effect='fade', params={level=gam.status.level + 1, dir='forward'}})
      end
    end

  elseif gam.pixie.tile == gam.got.entrance then

      if gam.status.level == 1 then
        composer.gotoScene('Menu', {effect='fade'})
      else
        gam:saveLevelData()
        composer.gotoScene('Passage', {effect='fade', params={level=gam.status.level - 1, dir='backward'}})
      end

  else

    gam.pixie:walkTarget()

  end

  -- _G.game may have been destroyed by invoking menu
  gam = _G.game -- refresh this
  if gam then
    if not gam:isPixieAlive() then
      composer.gotoScene('HighScores', {effect='fade', params={banner='G A M E  O V E R', score=math.floor(gam.status.score)}})
    end
  end
end

local function ghostSpawn()

  if not _G.game.got then
    debug_log('ghostSpawn: got has been deleted')
    return
  end

  if not _G.game.ghosts then
    debug_log('ghostSpawn: ghosts has been deleted')
    return
  end

  local maxGhosts = _G.game:getLevelData().ghosts
  local numGreen = _G.game:numberOfGhostsOfType(_G.colors.green)

  if #_G.game.ghosts - numGreen < maxGhosts then
    local spawnTiles = _G.game.got.spawnTiles
    local t
    for _ = 0, #spawnTiles do
      t = spawnTiles[math.random(1,#spawnTiles)]
      if not t:inView() then
        break
      end
      t = nil
    end
    if not t then
      debug_log('could not find spawn tile out of view')
      t = spawnTiles[math.random(1,#spawnTiles)]
    end

    local g = Ghost:new(t)
    if _G.game.status.level == 1 then
      g:turnAqua()
    else
      local r = math.random()
      if r > 0.9 and _G.game:numberOfGhostsOfType(_G.colors.red) < 2 then
        g:turnRed()
      elseif r > 0.8 then
        g:turnPurple()
      elseif r > 0.7 and _G.game.settings.whiteGhosts then
        g:turnWhite()
      else
        g:turnAqua()
      end
    end
    table.insert(_G.game.ghosts, g)
  end

end

local function snakeSpawn()

  if not _G.game.got then
    debug_log('snakeSpawn: got has been deleted')
    return
  end

  if not _G.game.ghosts then
    debug_log('snakeSpawn: ghosts has been deleted')
    return
  end

  if _G.game.status.level == 1 then
    return
  end

  -- local px, py = _G.game.pixie:pos()
  local entrance = _G.game.got.entrance
  local exit = _G.game.got.exit
  -- local dist = _G.Q * 2

  -- if Util.distance(px, py, exit.center.x, exit.center.y) > dist then
  if not exit:inView() then

    _G.game.timers['greenSnakeUp'] = timer.performWithDelay(_G.GHOST_SPEED, function(event)
        local g = Ghost:new(_G.game.got.exit)
        g:turnGreen(_G.game.got.entrance)
        table.insert(_G.game.ghosts, g)
      end
    , _G.game.status.level)

  -- if Util.distance(px, py, entrance.center.x, entrance.center.y) > dist then
  elseif not entrance:inView() then

    _G.game.timers['greenSnakeDown'] = timer.performWithDelay(_G.GHOST_SPEED, function(event)
      local g = Ghost:new(_G.game.got.entrance)
      g:turnGreen(_G.game.got.exit)
      table.insert(_G.game.ghosts, g)
    end
    , _G.game.status.level)

  end

end

local function ghostLoop()

  local ghos = _G.game.ghosts

  if not ghos then
    debug_log('ghostLoop: ghosts has been deleted')
    return
  end

  for g = 1, #ghos do
    local gho = ghos[g]
    if gho then -- may have been recently deleted
      gho:walk()
    end
  end

end

local function bubbleLoop()
  Bubble.tryToDisplay()
  if not Bubble.more() then
    if _G.game.timers['bubble'] then
      timer.cancel(_G.game.timers['bubble'])
      _G.game.timers['bubble'] = nil
    end
  end
end

local function pupLoop()
  local pups = _G.game.pups
  if not pups then
    debug_log('pupLoop: pups has been deleted')
    return
  end

  for g = 1, #pups do
    local pup = pups[g]
    if pup then -- may have been recently deleted
      pup:walk()
    end
  end
end

local function fireballLoop()
  local balls = _G.game.fireballs

  -- for i = 1, #balls do
  for _,ball in ipairs(balls) do
    ball:walk()
  end
end

function Game:startTimers()
  -- assert(self.timers and 0 == table.length(self.timers))

  -- self.timers['time'] = timer.performWithDelay(1000, timeLoop, 0)
  self.timers['pixieWalk'] = timer.performWithDelay(_G.PIXIE_SPEED, pixieLoop, 0)
  self.timers['ghostWalk'] = timer.performWithDelay(_G.GHOST_SPEED, ghostLoop, 0)
  self.timers['pupWalk'] = timer.performWithDelay(_G.PUP_SPEED, pupLoop, 0)
  self.timers['fireballWalk'] = timer.performWithDelay(_G.FIREBALL_SPEED, fireballLoop, 0)
  self.timers['ghostSpawn'] = timer.performWithDelay(_G.GHOST_SPAWN_SECONDS * 1000, ghostSpawn, 0)
  ghostSpawn()  -- get a ghost running
  if self.settings.greenGhosts then
    self.timers['snakeSpawn'] = timer.performWithDelay(60 * 1000, snakeSpawn, 0)
    snakeSpawn()  -- get a snake running
  end
  self.timers['bubble'] = timer.performWithDelay(4000, bubbleLoop, 0)

  -- debug_log(table.length(self.timers), '_G.game.timers started')
end

function Game:pauseTimers()
  -- debug_log('pause', table.length(self.timers), '_G.game.timers')

  for k,v in pairs(self.timers) do
    -- debug_log('pausing timer', k, v)
    timer.pause(v)
  end
  if self.pixie then
    self.pixie:pauseTimer()
  end
end

function Game:resumeTimers()
  -- debug_log('resume', table.length(self.timers), '_G.game.timers')

  for k,v in pairs(self.timers) do
    -- print('resuming timer', k, v)
    timer.resume(v)
  end
  if self.pixie then
    self.pixie:resumeTimer()
  end
end

function Game:cancelTimers()
  -- debug_log('cancel', table.length(self.timers), '_G.game.timers')

  for k,v in pairs(self.timers) do
    -- print('cancel timer', k, v)
    timer.cancel(v)
--[[
    The behavior of next is undefined if, during the traversal, you assign any value to a non-existent field in the table.
    You may however modify existing fields.
    In particular, you may clear existing fields.
]]
    self.timers[k] = nil
  end

  if self.pixie then
    self.pixie:cancelTimer()
  end
end

function Game:numberOfGhostsOfType(color)
  local n = 0
  for _,g in ipairs(self.ghosts) do
    if g.color == color then
      n = n + 1
    end
  end
  return n
end

function Game:isTileHaunted(t)
  for g = 1, #self.ghosts do
    if self.ghosts[g].tile == t then
      return self.ghosts[g]
    end
  end
  return nil
end

-- function Game:isVisibleGhost(t, dir)
--   while t do
--     if self:isTileHaunted(t) then
--       return true
--     end
--     if t.walls[dir] then
--       break
--     end
--     t = t[dir]
--   end
--   return false
-- end

function Game:magic(item)
  -- debug_log('magic', item.type, item.duration)

  self:sound('beep')

  if item.duration then
    -- red/ghosteater or blue/teleport magic
    self.pixie:endCountdown()
    self.pixie:startCountdown(item)
  elseif item.type == 'health' then
    self.pixie:resetHealth()
  elseif item.type == 'illumination' then
    self:illumination()
  elseif item.type == 'fireball' then
    self:fireball()
  elseif item.type == 'teleport' then
    self.pixie:setMagic(item)
  end

  self.knapsack:remove(item)
  item:destroy()

end

function Game:pixieMoved()
  self.got:centerOnPixie()
  self.pixie.tile:revealNeighbours()
end

function Game:isPixieAlive()
  return self.pixie ~= nil and self.pixie.group ~= nil
end

function Game:enterFrame(event)
  if not self.pixie or not self.ghosts then
    return
  end

  -- stop fading light when paused
  if self.paused then
    return
  end

  if not self:isPixieAlive() then
    debug_log('enterFrame pixie has been destroyed')
    return  -- pixie has exploded and been destroyed
  end

  local p = self.pixie
  local px, py = p:pos()
  local pRadius = p:getRadius()

  local ghostsForRemoval = {}

  for i = 1, #self.ghosts do
    local g = self.ghosts[i]
    local gx, gy = g:pos()

    if g.markedForRemoval then
      table.insert(ghostsForRemoval, i)
    end

      -- check fireball before pixie
    -- TODO check one fireball can explode multiple ghosts (e.g. if stacked)
    if #self.fireballs then
      for _,f in ipairs(self.fireballs) do
        if g and f:isActive() then
          local fx, fy = f:pos()
          local fdist = Util.distance(fx, fy, gx, gy)
          -- if fdist < 0 then debug_log('fdist < 0') end
          if fdist < f.radius + g.radius then
            -- debug_log(event.name, 'collision fireball')
            if not table.contains(ghostsForRemoval, i) then table.insert(ghostsForRemoval, i) end

            local blingText = display.newText({
              parent = _G.groups.maze,
              text = '+100',
              x = gx,
              y = gy,
              font = native.systemFontBold,
              fontSize = _G.Q / 2,
            })
            -- debug_log('bling at', gx, gy)
            transition.fadeOut(blingText, {
              time = 1000,
              onComplete = function()
                display.remove(blingText)
              end,
            })
            transition.to(blingText, {
              time = 1000,
              x = px,
              y = py,
              onComplete = function()
                self.status:incScore(100)
              end,
            })

            -- don't destroy the fireball, it will time out on it's own
          end
        end
      end
    end

    -- check ghost-ghost
    for j = i+1, #self.ghosts do
      local g2 = self.ghosts[j]
      if g.color ~= g2.color then -- aqua has/had two walkfns
        if not table.contains(ghostsForRemoval, i) and not table.contains(ghostsForRemoval, j) then
          local gx2, gy2 = g2:pos()
          local gdist = Util.distance(gx, gy, gx2, gy2)
          if gdist < g.radius + g2.radius then
            -- debug_log('ghost-ghost collision', i, j)
            table.insert(ghostsForRemoval, i)
            table.insert(ghostsForRemoval, j)
          end
        end
      end
    end

    -- check pixie-ghost
    local pdist = Util.distance(px, py, gx, gy)
    -- if pdist < 0 then debug_log('pdist < 0') end
    if pdist < pRadius + g.radius then
      -- debug_log(event.name, 'collision ghost', i)
      if p.invulnerable or g:isHarmless() then
      else
        if p:isHealthy() then
          p:degradeHealth()
        else
          self:sound('pixiedeath')
          p:explode()
          p:destroy()
          return
        end
      end
    end

  end

  if #ghostsForRemoval > 0 then
    self:sound('ghostdeath')
    local newGhosts = {}
    for i = 1, #self.ghosts do
      local g = self.ghosts[i]
      if table.contains(ghostsForRemoval, i) then
        g:explode()
        g:destroy()
      else
        table.insert(newGhosts, g)
      end
    end
    self.ghosts = newGhosts
    -- debug_log('removed', #ghostsForRemoval, 'ghosts', #self.ghosts, 'remaining')
  end

  -- check pixie-pup
  local pupsForRemoval = {}
  for i = 1, #self.pups do
    local pup = self.pups[i]
    local pupx, pupy = pup:pos()

    local pdist = Util.distance(px, py, pupx, pupy)
    -- if pdist < 0 then debug_log('pdist < 0') end
    if pdist < pRadius + pup.radius then
      local item = pup:createMagicItem()
      self.knapsack:add(item)
      self.knapsack:transition(item)

      table.insert(pupsForRemoval, i)
      -- debug_log('pixie - pup collision', pup.text.text)
    end
  end
  if #pupsForRemoval > 0 then
    local newPups = {}
    for i = 1, #self.pups do
      local pup = self.pups[i]
      if table.contains(pupsForRemoval, i) then
        pup:destroy()
      else
        table.insert(newPups, pup)
      end
    end
    self.pups = newPups
    self:sound('item')

  end

  self.frameCount = self.frameCount + 1
  if self.frameCount > 30 then
    self.frameCount = 1
    -- no need to do this 30 times a second; once a second is enough

    -- 30 FPS, trying to reduce alpha from 1.0 to 0 over about 90 seconds
    -- 0.9 over 90 seconds = 0.01 per second
    -- can't use alpha = 0, because it makes tile unclickable
    self.got:iterator(function(t)
      t:decAlpha()
    end)
  end

  return true
end

function Game:darkness()
  self.got:iterator(function(t) t:transitionAlpha(0.1) end)
end

function Game:illumination()
  self.got:iterator(function(t) t:transitionAlpha(1) end)
end

function Game:fireball()

  if not self:isPixieAlive() then
    return
  end

  local active, inactive = 0, 0
  for _,f in ipairs(self.fireballs) do
    if f:isActive() then
      active = active + 1
    else
      inactive = inactive + 1
    end
  end
  -- debug_log(active, 'active fireballs', inactive, 'inactive fireballs')

  if active == 0 and inactive > 0 then
    self.fireballs = {}
  end

  if _G.game.ghosts and #_G.game.ghosts > 0 then
    local pixtile = self.pixie.tile
    local g = Util.nearestGhost(pixtile)
    if g then
      table.insert(self.fireballs, Fireball:new(pixtile, g.tile))
    end
  end

  self:sound('fireball')

end

function Game:shockwave()

  if not self:isPixieAlive() then
    return
  end

  local px, py = self.pixie:pos()
  for _,g in pairs(self.ghosts) do
    local gx, gy = g:pos()
    if Util.distance(px, py, gx, gy) < _G.SHOCKWAVE_RADIUS then
      g:turnBlue()
    end
  end
  self.pixie:shockwave()
  -- self.status:decScore(math.floor(self.status.score/10))

end

function Game:markPath()
  local tStart = self.got.entrance
  local tDst = self.got.exit
  Util.BFS(tStart, tDst)
  while tDst.parent ~= tStart do
    if tDst.spore and tDst.spore.path and tDst.spore.path.radius then
      -- this is a circle, not an icon
      tDst.spore:setFillColor(unpack(_G.colors.pixie))
      tDst.spore.path.radius = 5 -- was 4
    end
    tDst = tDst.parent
  end
end

function Game:gotoNearestPup()
  if #self.pups == 0 then
    return
  end

  local function pathLength(src, dst)
    Util.BFS(src, dst)
    local len = 1
    while dst.parent ~= src do
      len = len + 1
      dst = dst.parent
    end
    return len
  end

  local min = math.huge
  local target = nil
  for _,pup in pairs(self.pups) do
    local dist = pathLength(self.pixie.tile, pup.tile)
    if dist < min then
      min = dist
      target = pup.tile
    end
  end
  self.pixie:setDestination(target)
end

function Game:gotoPupOrExit()
  if #self.pups == 0 then
    Bubble:new('No more power ups')
    _G.game.pixie:setDestination(_G.game.got.exit)
  else
    self:gotoNearestPup()
  end
end

function Game:getLevelData()
  return self.levelData[self.status.level]
end

function Game:numberOfLevels()
  return #self.levelData
end

function Game:saveLevelData()
  local sav = {}
  self.got:iterator(
    function(t)
      if t.spore then
        table.insert(sav, {t.x, t.y})
      end
  end)
  self.levelData[self.status.level].savedSpores = sav
end

function Game:showResumeButton()
  local group = _G.groups.actors -- put the button on top of pixie
  local xc, yc = self.pixie.tile:centerXY()
  local resumeCircle, resumeTriangle

  local function handleTap(event)
    _G.game.paused = false
    _G.game:resumeTimers()
    resumeTriangle:removeSelf()
    resumeCircle:removeSelf()
    resumeCircle:removeEventListener('tap', handleTap)
    return true
  end

  -- widget leaks event to objects underneath; use display.newCircle
  resumeCircle = display.newCircle(group, xc, yc, display.contentWidth / 6)
  resumeCircle:setFillColor(unpack(_G.colors.button))
  resumeCircle:addEventListener('tap', handleTap)

  -- a tap on the triangle falls through to the circle
  resumeTriangle = Util.newTriangle(group, xc, yc, display.contentWidth / 9)
  resumeTriangle:setFillColor(unpack(_G.colors.black))
end

--[[
  General destructor; need to dispose of
    Runtime listeners
    transitions and timers
    audio
    open files
]]
function Game:destroy()
end

return Game
