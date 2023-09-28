
-- Settings.lua

local composer = require('composer')
local scene = composer.newScene()

local widget = require('widget')
widget.setTheme('widget_theme_android_holo_dark')

local Util = require 'Util'

local settings

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via 'composer.removeScene()'
-- -----------------------------------------------------------------------------------

local function q2label(q)
  if q == 7 then
    return 'Large'
  elseif q == 9 then
    return 'Normal'
  elseif q == 11 then
    return 'Small'
  end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create(event)

  local sceneGroup = self.view
  -- Code here runs when the scene is first created but has not yet appeared on screen

  settings = Util.loadSettings()

  local gap = 128 + 16
  local y = gap
  local highScoresBanner = display.newText(sceneGroup, 'SETTINGS', display.contentCenterX, y, native.systemFontBold, 72)

  y = y + gap

  local qText = display.newText({
    text = 'Tile size',
    x = 128,
    y = y,
    font = native.systemFontBold,
    fontSize = 64,
  })
  qText.anchorX = 0
  sceneGroup:insert(qText)

  local qButton
  qButton = widget.newButton({
    id = 'qButton',
    x = display.contentWidth - 128,
    y = y,
    width = 256,
    height = 128,
    shape = 'roundedRect',
    fillColor = { default={ 0, 0, 0.5, 1 }, over={ 0, 0, 0.5, 0.5 } },
    label = q2label(settings.qFactor),
    font = native.systemFontBold,
    fontSize = 64,
    emboss = true,

    onRelease = function()
      -- cycle through 'small', 'normal', 'large'
      if settings.qFactor == 7 then
        settings.qFactor = 11
      elseif settings.qFactor == 9 then
        settings.qFactor = 7
      elseif settings.qFactor == 11 then
        settings.qFactor = 9
      else
        settings.qFactor = 9
      end
      qButton:setLabel(q2label(settings.qFactor))
    end
  })
  qButton.anchorX = 1
  sceneGroup:insert(qButton)

  y = y + gap

  local whiteText = display.newText({
    text = 'White ghosts',
    x = 128,
    y = y,
    font = native.systemFontBold,
    fontSize = 64,
  })
  whiteText.anchorX = 0
  sceneGroup:insert(whiteText)

  local whiteSwitch
  whiteSwitch = widget.newSwitch({
    id = 'whiteGhosts',
    x = display.contentWidth - 128,
    y = y,
    width = 128,
    height = 128,
    initialSwitchState = settings.whiteGhosts,
    style = 'checkbox',
    onRelease = function()
      settings.whiteGhosts = whiteSwitch.isOn
    end,
  })
  whiteSwitch.anchorX = 1
  sceneGroup:insert(whiteSwitch)

  y = y + gap

  local greenText = display.newText({
    text = 'Green ghosts',
    x = 128,
    y = y,
    font = native.systemFontBold,
    fontSize = 64,
  })
  greenText.anchorX = 0
  sceneGroup:insert(greenText)

  local greenSwitch
  greenSwitch = widget.newSwitch({
    id = 'greenGhosts',
    x = display.contentWidth - 128,
    y = y,
    width = 128,
    height = 128,
    initialSwitchState = settings.greenGhosts,
    style = 'checkbox',
    onRelease = function()
      settings.greenGhosts = greenSwitch.isOn
    end,
  })
  greenSwitch.anchorX = 1
  sceneGroup:insert(greenSwitch)

  local exitButton = widget.newButton({
    id = 'return',
    x = display.contentCenterX,
    y = display.contentHeight - 200,
    onRelease = function()
      Util.saveSettings(settings)
      _G.calculateQ(settings.qFactor)
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
    composer.removeScene('Settings')
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
      Util.saveSettings(settings)
      _G.calculateQ(settings.qFactor)
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
