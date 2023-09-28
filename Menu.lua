
-- Menu.lua

local composer = require('composer')
local scene = composer.newScene()

local widget = require('widget')
widget.setTheme('widget_theme_android_holo_dark')

local Game = require 'Game'

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via 'composer.removeScene()'
-- -----------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create(event)
  debug_log('Menu scene:create')
  local sceneGroup = self.view
  -- Code here runs when the scene is first created but has not yet appeared on screen

  local buttonFillColor = { default=_G.colors.button, over=_G.colors.buttonOver }
  local buttonLabelColor = { default=_G.colors.label, over=_G.colors.labelOver }

  local function createPlayButton(difficulty, color, y)
    local playButton = widget.newButton({
      id = difficulty,
      x = display.contentCenterX,
      y = y,
      onRelease = function()
        _G.game = Game:new()
        composer.gotoScene('Maze', {effect='fade', params={level=1, difficulty=difficulty, dir='forward'}})
      end,

      shape = 'circle',
      radius = 128,
      fillColor = { default=color, over=color },
      label = string.upper(difficulty),
      labelColor = buttonLabelColor,
      font = native.systemFontBold,
      fontSize = 128 / 3,
    })
    sceneGroup:insert(playButton)
  end

  local function createIconButton(gotoScene, iconNumber, x, y)
    local button = widget.newButton({
      id = gotoScene,
      x = x,
      y = y,
      onRelease = function()
        composer.gotoScene(gotoScene, {effect='fade'})
      end,

      shape = 'circle',
      radius = 128 / 2,
      fillColor = buttonFillColor,
    })

    sceneGroup:insert(button)

    local buttonIcon
    buttonIcon = display.newImage(_G.iconImageSheet, iconNumber)
    buttonIcon.x = x
    buttonIcon.y = y
    buttonIcon.width = 128 / 2
    buttonIcon.height = 128 / 2

    sceneGroup:insert(buttonIcon)
    end

  _G.game = nil

  display.newText(sceneGroup, 'P I X I E · M A Z E', display.contentCenterX, 128, native.systemFontBold, 72)

  local gap = 128 * 2.2

  createPlayButton('easy', _G.colors.green, display.contentCenterY - gap - gap)
  createPlayButton('normal', _G.colors.pixie, display.contentCenterY - gap)
  createPlayButton('hard', _G.colors.orange, display.contentCenterY)
  createPlayButton('evil', _G.colors.red, display.contentCenterY + gap)

  local xgap = 128 * 1.2

  createIconButton('HighScores', 10, display.contentCenterX - xgap, display.contentCenterY + gap + gap)
  createIconButton('About', 11, display.contentCenterX, display.contentCenterY + gap + gap)
  createIconButton('Settings', 12, display.contentCenterX + xgap, display.contentCenterY + gap + gap)
end

-- show()
function scene:show(event)
  debug_log('Menu scene:show', event.phase)
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
  debug_log('Menu scene:hide', event.phase)
  local sceneGroup = self.view
  local phase = event.phase

  if phase == 'will' then
    -- Code here runs when the scene is on screen (but is about to go off screen)
  elseif phase == 'did' then
    -- Code here runs immediately after the scene goes entirely off screen
    composer.removeScene('Menu')
  end
end

-- destroy()
function scene:destroy(event)
  debug_log('Menu scene:destroy')
  local sceneGroup = self.view
  -- Code here runs prior to the removal of scene's view
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
