-- Bubble class

local json = require('json')

local Bubble = {
  x = nil,
  y = nil,
  rect = nil,
  text = nil,
  removeTimer = nil,
}

local filePath = system.pathForFile('bubbles.json', system.DocumentsDirectory)

function Bubble:new(msg)
  local o = {}
  self.__index = self
  setmetatable(o, self)

  o.x, o.y = display.contentCenterX, display.contentHeight * 0.8

  -- _G.game:pauseTimers()

  local width = _G.Q * 8
  local height = _G.Q * 1

  o.rect = display.newRoundedRect(_G.groups.bubbles, o.x, o.y, width, height, height / 5)
  o.rect:setFillColor(0,0,0.2, 0.8)
  o.rect:setStrokeColor(0,0,1, 0.2)
  o.rect.strokeWidth = 4

  -- the text x,y corresponds to the top center of the rect
  o.text = display.newText({
    parent = _G.groups.bubbles,
    text = msg,
    x = o.x,
    y = o.y,
    width = width,
    height = 0, -- to get text vertically aligned https://forums.coronalabs.com/topic/36558-is-the-new-text-alignment-always-top-aligned/
    align = 'center',
    font = native.systemFont,
    fontSize = _G.Q3,
  })

  o.rect:addEventListener('tap', o, 1)

  o.removeTimer = timer.performWithDelay(2500, o, 1)

  return o
end

function Bubble:remove()
  -- Maze scene may have been removed if puck died while bubble showing
  -- so use display.remove() rather than object:removeSelf()
  display.remove(self.text)
  display.remove(self.rect)
end

function Bubble:tap(event)
  -- print('bubble tap event')
  -- for k,_ in pairs(event) do print(k) end
  -- event contains y, x, time, target, numTaps, name
  -- _G.game:resumeTimers()
  timer.cancel(self.removeTimer)
  self:remove()
  return true
end

function Bubble:timer(event)
  -- print('bubble timer event')
  -- for k,_ in pairs(event) do print(k) end
  -- event contains count, source, time, name
  -- _G.game:resumeTimers()
  self:remove()
end

local bubbles = {
  {score=-1, msg='Tap where you want Pixie to move to'},
  {score=50, msg='Collect the power ups on each level'},
  {score=100, msg='Tap the back button to pause the game'},
  {ghostColor=_G.colors.aqua, msg='Hide from cyan ghosts in cul-de-sacs'},
  {ghostColor=_G.colors.red, msg='Red ghosts hunt you down'},
  {ghostColor=_G.colors.purple, msg='Purple ghosts try and find you'},
  {ghostColor=_G.colors.green, msg='Green ghosts go between the start and exit'},
  {ghostColor=_G.colors.white, msg='White ghosts lay new spores'},
  {magicType='health', msg='Tap on red to restore your health'},
  {magicType='teleport', msg='Tap on blue to teleport'},
  {magicType='illumination', msg='Tap on white to turn the lights back up'},
  {magicType='navigation', msg='Tap on green to show the path to the exit'},
}

--[[
  colors gets saved in json as {"ghostColor":[0,0,1],"msg":"Blue ghosts will not hurt you"}
]]
local function compareColors(a,b)
  -- assert(#a==3)
  -- assert(#b==3)
  local ar, ag, ab = unpack(a)
  local br, bg, bb = unpack(b)
  return ar == br and ag == bg and ab == bb
end

function Bubble.tryToDisplay()

  -- for k,v in ipairs(bubbles) do
  --   debug_log(k,v)
  -- end

  local iFound = nil

    for i,bubi in ipairs(bubbles) do
    if bubi.score and _G.game.status.score > bubi.score then
      iFound = i
    elseif bubi.level and _G.game.status.level == bubi.level then
      iFound = i
    elseif bubi.ghostColor then
      for g = 1, #_G.game.ghosts do
        if compareColors(_G.game.ghosts[g].color, bubi.ghostColor) then
          iFound = i
          break
        end
      end
    elseif bubi.magicType and _G.game.knapsack:contains(bubi.magicType) then
      iFound = i
    end

    if iFound then
      Bubble:new(bubbles[iFound].msg)
      table.remove(bubbles, iFound)
      Bubble.save()
      break -- only show one each time
    end

  end

end

function Bubble.more()
  return bubbles ~= nil and #bubbles > 0
end

function Bubble.load()
  -- try to load bubbles from bubbles.json
  -- create bubbles.json from bubbles if it does not exist

  local file = io.open(filePath, 'r')
  if not file then
    file = io.open(filePath, 'w')
    if file then
      file:write(json.encode(bubbles))
      io.close(file)
      debug_log(filePath, 'created')
    else
      debug_log('cannot create', filePath)
    end
  else  -- bubbles.json exists
    local contents = file:read('*a')
    io.close(file)
    bubbles = json.decode(contents)
    debug_log(#bubbles, 'bubbles loaded from', filePath)
  end
end

function Bubble.save()
  local file = io.open(filePath, 'w')
  if file then
    if 0 == #bubbles then
      file:write('[]')
    else
      file:write(json.encode(bubbles))
    end
    io.close(file)
  else
    debug_log('cannot create', filePath)
  end
end

return Bubble