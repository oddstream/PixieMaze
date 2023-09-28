
-- Passge.lua

local composer = require('composer')
local scene = composer.newScene()

local widget = require('widget')
widget.setTheme('widget_theme_android_holo_dark')

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via 'composer.removeScene()'
-- -----------------------------------------------------------------------------------

local circle
local xFrom, xTo

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

function scene:create(event)
  debug_log('Passage scene:create')

  local sceneGroup = self.view
  -- Code here runs when the scene is first created but has not yet appeared on screen

  assert(_G.game.status)
  assert(event.params.level)

end

function scene:show(event)
  debug_log('Passage scene:show', event.phase)
  local sceneGroup = self.view
  local phase = event.phase

  if phase == 'will' then
    -- Code here runs when the scene is still off screen (but is about to come on screen)
    if event.params.dir == 'forward' then
      xFrom = -(_G.Q * 2)
      xTo = display.contentWidth + (_G.Q * 2)
    else
      xFrom = display.contentWidth + (_G.Q * 2)
      xTo = -(_G.Q * 2)
    end

    circle = display.newCircle(sceneGroup, xFrom, display.contentCenterY, _G.Q)
    circle:setFillColor(unpack(_G.colors.pixie))

    -- display.newText(sceneGroup, string.format('PASSAGE TO LEVEL %u', event.params.level), display.contentCenterX, display.contentCenterY, native.systemFontBold, 72)
  elseif phase == 'did' then
    -- Code here runs when the scene is entirely on screen
    _G.game:sound('passage')
    transition.moveTo(circle, {x=xTo, y=display.contentCenterY, time=1000, onComplete=function(obj)
      display.remove(obj)
      composer.gotoScene('Maze', {effect='fade', params={level=event.params.level, dir=event.params.dir}})
    end})

  end
end

function scene:hide(event)
  debug_log('Passage scene:hide', event.phase)
  local sceneGroup = self.view
  local phase = event.phase

  if phase == 'will' then
    -- Code here runs when the scene is on screen (but is about to go off screen)
  elseif phase == 'did' then
    -- Code here runs immediately after the scene goes entirely off screen
    composer.removeScene('Passage')
  end
end

function scene:destroy(event)
  debug_log('Passage scene:destroy')
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
