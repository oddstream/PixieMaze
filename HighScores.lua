
-- HighScores.lua
-- https://docs.coronalabs.com/guide/programming/06/index.html

local composer = require('composer')
local scene = composer.newScene()

local widget = require('widget')
local json = require('json')

local Util = require 'Util'

local scoresTable = {}

local filePath = system.pathForFile('scores.json', system.DocumentsDirectory)
-- win32 c:\Users\oddst\AppData\Roaming\Wychwood Paddocks\Puckmaze\Documents
-- print(filePath)

local function loadScores()
  local file = io.open(filePath, 'r')

  if file then
    local contents = file:read('*a')
    io.close(file)
    scoresTable = json.decode(contents)
  end

  if scoresTable == nil or #scoresTable == 0 then
    scoresTable = { 2000, 1800, 1600, 1400, 1200, 1000, 800, 600, 400, 200 }
  end
end

local function saveScores()
  for i = #scoresTable, 11, -1 do
    table.remove(scoresTable, i)
  end

  local file = io.open(filePath, 'w')

  if file then
    debug_log('write', filePath, json.encode(scoresTable))
    file:write(json.encode(scoresTable))
    io.close(file )
  end
end

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via 'composer.removeScene()'
-- -----------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create(event)

  local sceneGroup = self.view
  -- Code here runs when the scene is first created but has not yet appeared on screen

  loadScores()

  local score = nil

  if event.params then
    score = event.params.score
    if score then
      table.insert(scoresTable, score)
      local function comp(a, b)
        return a > b
      end
      table.sort(scoresTable, comp) -- default comp uses <

      if score > scoresTable[#scoresTable] then
        -- debug_log('writing scores')
        saveScores()
      else
        -- debug_log('not writing scores')
      end

    end
  end

  local bannerText = 'HIGH SCORES'
  if event.params and event.params.banner then
    bannerText = event.params.banner
  end

  local y = 120
  local highScoresBanner = display.newText(sceneGroup, bannerText, display.contentCenterX, y, native.systemFontBold, 72)
  y = y + 120

  if score then
    local infoText1 = tostring(event.params.score)
    local displayText1 = display.newText(sceneGroup, infoText1, display.contentCenterX, y, native.systemFontBold, 72)
    displayText1:setFillColor(1,1,0)
    y = y + 120
  end

  for i = 1, 10 do
    if ( scoresTable[i] ) then
      local rankNum = display.newText(sceneGroup, i .. '.', display.contentCenterX-50, y, native.systemFontBold, 48)
      rankNum.anchorX = 1

      local thisScore = display.newText(sceneGroup, scoresTable[i], display.contentCenterX-30, y, native.systemFontBold, 48)
      thisScore.anchorX = 0

      if score and scoresTable[i] == score then
        rankNum:setFillColor(1,1,0)
        thisScore:setFillColor(1,1,0)
      end

      y = y + 60
    end
  end

  local exitButton = widget.newButton({
    id = 'return',
    x = display.contentCenterX,
    y = display.contentHeight - 200,
    onRelease = function()
      composer.gotoScene('Menu', {effect='fade'})
    end,

    shape = 'circle',
    radius = 60,
    fillColor = { default={1,1,0}, over={0.5,0.5,0} }
  })
  sceneGroup:insert(exitButton)

  local exitTriangle = Util.newTriangleBack(sceneGroup, display.contentCenterX, display.contentHeight - 200, 40)
  exitTriangle:setFillColor(0,0,0)

end


-- show()
function scene:show(event)
  local sceneGroup = self.view
  local phase = event.phase

  if phase == 'will' then
    -- Code here runs when the scene is still off screen (but is about to come on screen)
  elseif phase == 'did' then
    -- Code here runs when the scene is entirely on screen
  end
end

-- hide()
function scene:hide(event)
  local sceneGroup = self.view
  local phase = event.phase

  if phase == 'will' then
    -- Code here runs when the scene is on screen (but is about to go off screen)
  elseif phase == 'did' then
    -- Code here runs immediately after the scene goes entirely off screen
    composer.removeScene('HighScores')
  end
end

-- destroy()
function scene:destroy(event)
  local sceneGroup = self.view
  -- Code here runs prior to the removal of scene's view
  assert(Runtime:removeEventListener('key', scene))
end

function scene:key(event)
  local phase = event.phase
  if phase == 'up' then
    if event.keyName == 'back' or event.keyName == 'deleteBack' then
      composer.gotoScene('Menu', {effect='fade'})
      return true -- override the key
    end
  end
end

-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener('create', scene)
scene:addEventListener('show', scene)
scene:addEventListener('hide', scene)
scene:addEventListener('destroy', scene)

Runtime:addEventListener('key', scene)
-- -----------------------------------------------------------------------------------

return scene
