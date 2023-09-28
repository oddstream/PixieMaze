-- Maze.lua

local composer = require('composer')
local scene = composer.newScene()

local GridOfTiles = require 'GridOfTiles'
local Pixie = require 'Pixie'
local Pup = require 'Pup'
local Util = require 'Util'

-----------------------------
local profileThreshold = 0
if system.getInfo('environment') == 'simulator' then
  profileThreshold = 0
end
local Counters = {}
local Names = {}

local function hook ()
  local f = debug.getinfo(2, "f").func
  if Counters[f] == nil then    -- first time `f' is called?
    Counters[f] = 1
    Names[f] = debug.getinfo(2, "Sn")
  else  -- only increment the counter
    Counters[f] = Counters[f] + 1
  end
end

local function getname (func)
  local n = Names[func]
  if n.what == "C" then
    return n.name
  end
  local loc = string.format("[%s]:%s", n.short_src, n.linedefined)
  if n.namewhat ~= "" then
    return string.format("%s (%s)", loc, n.name)
  else
    return string.format("%s", loc)
  end
end
-----------------------------

function scene:create(event)
--[[
  In scene:create() you create display.* objects that you want to have transition on the screen when the scene shows.
  Things that get created later, like new enemies that are spawning can be deferred until after scene:show() happens.

  for k,_ in pairs(scene) do print(k) end
  scene contains {destroy, _tableListeners, view, show, create, hide}
]]
  debug_log('Maze scene:create')

  assert(_G.game)
  assert(_G.game.status)
  assert(_G.game.knapsack)

  assert(event.params.level)
  assert(event.params.dir)

  local sceneGroup = self.view

  -- display.setDefault("background", unpack(_G.colors.wall))

  _G.groups.maze = display.newGroup()
  sceneGroup:insert(_G.groups.maze)

  _G.groups.spores = display.newGroup()
  sceneGroup:insert(_G.groups.spores)

  _G.groups.actors = display.newGroup()
  sceneGroup:insert(_G.groups.actors)

  _G.groups.bubbles = display.newGroup()
  sceneGroup:insert(_G.groups.bubbles)

  local statusGroup = display.newGroup()
  sceneGroup:insert(statusGroup)
  _G.game.status:setGroup(statusGroup)

  local knapsackGroup = display.newGroup()
  sceneGroup:insert(knapsackGroup)
  _G.game.knapsack:setGroup(knapsackGroup)

  -- difficulty will be set when coming from Menu.lua
  -- difficulty will NOT be set when coming from Passage.lua
  if event.params.difficulty then
    _G.game.difficulty = event.params.difficulty
  end
  _G.game.status:setLevel(event.params.level)

  local data = _G.game:getLevelData()
  _G.game.status:setLevelName(data.name)

  _G.game.status:incScore(0)

  debug_log('=== level', _G.game.status.level, data.name, 'grid width', data.width, 'grid height', data.height, 'seed', data.seed, '===')

  _G.game.got = GridOfTiles:new(data)
  debug_log('using seed', data.seed)
  math.randomseed(data.seed)
  _G.game.got:carvePassages()
  _G.game.got:iterator(function(t)
    if t:countWalls() == 3 then
      t.isCulDeSac = true
    end
  end)

  if data.savedSpores then
    _G.game.got:addSavedSpores(data.savedSpores)
    data.savedSpores = nil
  else
    _G.game.got:addSpores()
  end

  if _G.game.difficulty == 'easy' or _G.game.difficulty == 'hard' then
    _G.game:markPath()
  end

  _G.game.pups = {}
  for _ = 1, math.floor(#_G.game.got.tiles / 100) do
    for _,slot in ipairs({1,2,3,4}) do
      local t = _G.game.got:randomTile()
      -- local spawnTiles = _G.game.got.spawnTiles
      -- local t = spawnTiles[math.random(1,#spawnTiles)]
      local pup = Pup:new(t, slot)
      table.insert(_G.game.pups, pup)
    end
  end

  do -- scope for tStart
    local tStart
    if event.params.dir == 'forward' then
      tStart = _G.game.got.start
    else
      tStart = _G.game.got.backStart
    end
    _G.game.pixie = Pixie:new(tStart)
  end
  _G.game.ghosts = {}
  _G.game.fireballs = {}

  if system.getInfo('environment') == 'simulator' then
    local n = 0
    _G.game.got:iterator(function(t) if t.isCulDeSac then n = n + 1 end end)
    print('---', #_G.game.got.tiles, 'tiles created', n, 'cul-de-sacs ---')
  end

end

function scene:show(event)
  debug_log('Maze scene:show', event.phase)
  assert(event.params.level)

  local sceneGroup = self.view
  local phase = event.phase

  if phase == 'will' then
    -- Code here runs when the scene is still off screen (but is about to come on screen)
  elseif phase == 'did' then
    -- Code here runs when the scene is entirely on screen
    assert(_G.game)
    assert(_G.game.pixie)
    _G.game.pixie:animateToStart()

    _G.game:startTimers()

    Runtime:addEventListener('key', scene)
    Runtime:addEventListener('system', scene)
    Runtime:addEventListener('enterFrame', _G.game)

    if profileThreshold > 0 then
      debug.sethook(hook, "c")  -- turn on the hook
    end
  end
end

function scene:hide(event)
  debug_log('Maze scene:hide', event.phase)

  local sceneGroup = self.view
  local phase = event.phase

  if phase == 'will' then
    -- Code here runs when the scene is on screen (but is about to go off screen)
    _G.game:pauseTimers()

    assert(Runtime:removeEventListener('key', scene))
    assert(Runtime:removeEventListener('system', scene))
    assert(Runtime:removeEventListener('enterFrame', _G.game))

  elseif phase == 'did' then
    -- Code here runs immediately after the scene goes entirely off screen
    if _G.game then
      _G.game:cancelTimers()
    end

    if profileThreshold > 0 then
      debug.sethook()   -- turn off the hook
      for func, count in pairs(Counters) do
        if count > profileThreshold then
          print(getname(func), count)
        end
      end
    end
    -- https://forums.coronalabs.com/topic/69373-question-about-removing-scene/
    composer.removeScene('Maze')
  end
end

function scene:destroy(event)
  debug_log('Maze scene:destroy')

  local sceneGroup = self.view

  -- don't destroy game, status or knapsack, they persist across levels
  -- if we go back to Menu.lua, _G.game gets destroyed

  if _G.game then
    if _G.game.got then
      _G.game.got:destroy()
      _G.game.got = nil
    end

    if _G.game.pixie then
      _G.game.pixie:destroy()
    end
    _G.game.pixie = nil

    _G.game.ghosts = nil
  end

  do
    local last_using = composer.getVariable('last_using')
    if not last_using then
      last_using = 0
    end
    local before = collectgarbage('count')
    collectgarbage('collect')
    local after = collectgarbage('count')
    print('collected', math.floor(before - after), 'KBytes, using', math.floor(after), 'KBytes', 'leaked', after-last_using)
    composer.setVariable('last_using', after)
  end

end

function scene:key(event)

  local phase = event.phase

  if phase == 'up' then
    if event.keyName == 'back' or event.keyName == 'deleteBack' then
      if not _G.game.paused then
        _G.game.paused = true
        _G.game:pauseTimers()
        _G.game:showResumeButton()
      else
        composer.gotoScene('Menu', {effect='fade'})
      end
      return true -- override the key
    elseif event.keyName == 'd' then
      _G.game:darkness()
    elseif event.keyName == 'f' then
      _G.game:fireball()
    elseif event.keyName == 'i' then
      _G.game:illumination()
    elseif event.keyName == 'k' then
      _G.game.knapsack:report()
    elseif event.keyName == 'q' then
      _G.game.pixie.invulnerable = true
      debug_log('pixie now invulnerable', _G.game.pixie.invulnerable)
      _G.game.pixie:setDestination(_G.game.got.exit)
    elseif event.keyName == 't' then
      _G.game.pixie:setMagic({type='teleport', color=_G.colors.wall, slot=2})
    end
  end
end

function scene:system(event)
  -- print( "System event name and type: " .. event.name, event.type )
  if event.type == 'applicationExit' then
  elseif event.type == 'applicationSuspend' then
    if not _G.game.paused then
      _G.game.paused = true
      _G.game:pauseTimers()
      _G.game:showResumeButton()
    end
  elseif event.type == 'applicationResume' then
    -- let the user press RESUME button (maybe bubble them?)
  end
end

-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener('create', scene)
scene:addEventListener('show', scene)
scene:addEventListener('hide', scene)
scene:addEventListener('destroy', scene)
-- -----------------------------------------------------------------------------------

return scene
