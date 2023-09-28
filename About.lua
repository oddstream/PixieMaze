
-- About.lua

local composer = require('composer')
local widget = require('widget')
local scene = composer.newScene()

local Bubble = require 'Bubble'
local Util = require 'Util'

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via 'composer.removeScene()'
-- -----------------------------------------------------------------------------------

local myText = [[
P I X I E · M A Z E

A casual puzzle game that happened when a certain classic arcade maze-based game from 1980 got mixed up with another classic 1980 game called Rogue.

You're trying to escape from a series of randomly generated mazes, patrolled by ghosts. The lights keep going out, and things that help you won't stay still.

HOW TO PLAY

The object of the game is to get to the exit, scoring as many points as possible.

You control a yellow blob called Pixie, which you move by touching where in the maze you want it to move to: Pixie 'throws' a small yellow ball to the destination, and Pixie finds the shortest path to the ball.

If you change your mind, throw the ball somewhere else.

Tiles start off marked with a small dot (a 'spore'); this spore gets removed when you pass over it. Like anti-breadcrumbs. Every spore you pick up gives you a point.

Floating around in the maze are power ups with magical properties; when you run over them they get stored in your knapsack, so you can use them later:

- Red ones restore your health;

- Blue ones let you teleport through walls for one move;

- White ones turn the lights back on;

- Orange ones give you a fireball to kill nearby ghosts.

Unfortunately, you are not alone in the maze. There are also a number of ghosts, that will take your health when they touch you:

- Cyan ghosts just patrol around the maze, but they're lazy and won't bother to enter a cul-de-sac (so you can hide from cyan ghosts in a tile with three walls);

- Green ghosts walk between the exit and entrance. They also won't enter cul-de-sacs;

- Purple ghosts go to where you were when they turned purple. They plant a little purple flag to show you where that was;

- White ghosts try to confuse you by dropping new spores;

- Red ghosts are predators and will hunt you down.

According to established scientific principles, if two ghosts of different colors meet, they will kill each other.

TACTICS

Predict where the ghosts are moving to and hide from them in cul-de-sacs.

Collect the power ups and use them effectively.

You can go back and forth between levels.

Take advantage of the ghosts killing each other.

CREDITS

Sound clips from www.pacdv.com, icons from www.flaticon.com/authors/freepik

Special thanks to Little Bear and Cookie

Copyright © 2019 Oddstream. All rights reserved.
]]

local function removeJSON()
  local function alertListener(event)
    if event.action == 'clicked' and event.index == 1 then
      for _,v in ipairs({'bubbles.json','scores.json'}) do
        local filePath = system.pathForFile(v, system.DocumentsDirectory)
        local result, reason = os.remove(filePath)
        if result then
          debug_log(filePath, 'removed')
        else
          debug_log(reason)
        end
        Bubble.load()
      end
    end
  end
  local alert = native.showAlert('PIXIEMAZE', 'Reset high scores and progress?', {'Yes', 'No'}, alertListener)
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create(event)

  local sceneGroup = self.view

  -- Code here runs when the scene is first created but has not yet appeared on screen

  -- https://docs.coronalabs.com/tutorial/system/textBlocks/index.html

  local scrollView = widget.newScrollView({
    top = 0,
    left = 0,
    width = display.contentWidth,
    height = display.contentHeight - 200,
    horizontalScrollDisabled = true,
    backgroundColor = {0,0,0}
  })
  sceneGroup:insert(scrollView)

  local paragraphs = {}
  local paragraph
  local tmpString = myText

  local yStart = 10
  local mainPadding = 20

  repeat
    paragraph, tmpString = string.match(tmpString, '([^\n]*)\n(.*)')
    paragraphs[#paragraphs+1] = display.newText({
      text = paragraph,
      width = scrollView.width-(mainPadding*2),
      fontSize = 32
    })
    -- paragraphs[#paragraphs]:setFillColor(1,1,1)
    paragraphs[#paragraphs].anchorX = 0
    paragraphs[#paragraphs].anchorY = 0
    paragraphs[#paragraphs].x = mainPadding
    paragraphs[#paragraphs].y = yStart
    scrollView:insert( paragraphs[#paragraphs] )
    yStart = yStart + paragraphs[#paragraphs].height
  until tmpString == nil or string.len( tmpString ) == 0

  scrollView:setScrollHeight(scrollView:getView().height + (mainPadding*2))

  local exitButton = widget.newButton({
    id = 'return',
    x = display.contentCenterX,
    y = display.contentHeight - 100,
    onRelease = function()
      composer.gotoScene('Menu', {effect='fade'})
    end,

    -- labelColor = { default={ 0, 0, 0 }, over={ 0, 0, 0, 0 } },
    -- font = native.systemFontBold,
    -- fontSize = 96,

    shape = 'circle',
    radius = 60,
    fillColor = { default={1,1,0}, over={1,1,0} }
  })
  sceneGroup:insert(exitButton)

  local exitTriangle = Util.newTriangleBack(sceneGroup, display.contentCenterX, display.contentHeight - 100, 40)
  exitTriangle:setFillColor(unpack(_G.colors.black))

  local resetButton = widget.newButton({
    id = 'reset',
    label = 'RESET',
    x = display.contentWidth - 100,
    y = display.contentHeight - 100,
    onRelease = removeJSON,

    labelColor = { default={ 1, 1, 1 }, over={ 1, 1, 1 } },
    font = native.systemFontBold,
    fontSize = 16,

    shape = 'circle',
    radius = 40,
    fillColor = { default={1,0,0}, over={1,0,0} }
  })
  sceneGroup:insert(resetButton)

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
    composer.removeScene('About')
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
