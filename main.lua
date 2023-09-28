-- main.lua

local composer = require 'composer'

local Util = require 'Util'

-- build for Win32 to test the sound, because playing sounds in the simulator crashes the sound driver
_G.MUTE_AUDIO = system.getInfo('environment') == 'simulator'

function _G.debug_log(...)
  if system.getInfo('environment') == 'simulator' then
    print(...)
  end
end

function _G.debug_table(msg, tbl)
  if system.getInfo('environment') == 'simulator' then
    print(msg)
    for k,v in pairs(tbl) do
      print(k)
    end
  end
end

if system.getInfo('environment') == 'simulator' then
  print(_VERSION)
  print('origin', display.screenOriginX, display.screenOriginY)
  print('content', display.contentWidth, display.contentHeight)
  print('pixels', display.pixelWidth, display.pixelHeight)
  print('actual content', display.contentWidth, display.contentHeight)
  print('viewable content', display.viewableContentWidth, display.viewableContentHeight)

  print('maxTextureSize', system.getInfo('maxTextureSize'))

  print('platformName', system.getInfo('platformName'))
  print('architectureInfo', system.getInfo('architectureInfo'))
  print('model', system.getInfo('model'))

  print('androidDisplayApproximateDpi', system.getInfo('androidDisplayApproximateDpi'))
end

_G.onTablet = system.getInfo('model') == 'iPad'
if not _G.onTablet then
  local approximateDpi = system.getInfo('androidDisplayApproximateDpi')
  if approximateDpi then
    local width = display.pixelWidth / approximateDpi
    local height = display.pixelHeight / approximateDpi
    if width > 4.5 and height > 7 then
      _G.onTablet = true
    end
  end
end

native.setProperty('windowTitleText', 'PIXIE·MAZE') -- Win32

math.randomseed(os.time())

_G.calculateQ = function(scale)
  -- max = 12, min = 6
  scale = scale or 9
  _G.Q = math.round(display.contentWidth / scale)
  _G.Q2 = math.round(_G.Q / 2)
  _G.Q3 = math.round(_G.Q / 3)
  debug_log('Q is', _G.Q)
end

do
  local settings = Util.loadSettings()
  if settings then
    _G.calculateQ(settings.qFactor)
  else
    _G.calculateQ(settings.qFactor)
  end
end

-- ugly globals

_G.game = nil

_G.PIXIE_SPEED = 400
_G.GHOST_SPEED = 900
_G.PUP_SPEED = 1800
_G.PAN_SPEED = 1000
_G.GHOST_CHANGE_SECONDS = 9
_G.GHOST_SPAWN_SECONDS = 5
_G.FIREBALL_SPEED = 200
-- _G.SPORES_PER_ACTION = 25
_G.SHOCKWAVE_RADIUS = _G.Q * 4

_G.colors = {
  wall = {0,0,0.75, 1},
  tileBack = {0,0,0.25},
  tileMarked = {0,0,0.05},
  spore = {1,1,1},
  bubbleBack = {0,0,0.2},
  button = {1,1,0},
  buttonOver = {0.8,0.8,0},
  label = {0,0,0},
  labelOver = {0,0,0},
  pixie = {1,1,0},
  pixieHidden = {0.1,0.1,0},

  white = {1,1,1},
  aqua = {0,1,1},
  red = {1,0,0},
  orange = {1,0.65,0},
  pink = {1,192*4/1020,203*4/1020},
  blue = {0,0,1},
  green = {0,0.75,0},
  purple = {0.5,0,0.5},
  gray = {0.5,0.5,0.5},
  black = {0,0,0},
}

_G.groups = {
  maze = nil,
  spores = nil,
  actors = nil,
  bubbles = nil,
}

-- for k,v in pairs( _G ) do
--   print( k , v )
-- end

if not _G.table.contains then
  function _G.table.contains(tab, val)
    for index, value in ipairs(tab) do
      if value == val then
        return true, index
      end
    end
    return false, 0
  end
end
debug_log('table contains', type(_G.table.contains))

if not _G.table.shuffle then
  function _G.table.shuffle(tbl)
    for i = #tbl, 2, -1 do
      local j = math.random(i)
      tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
  end
end
debug_log('table shuffle', type(_G.table.shuffle))

if not _G.table.length then
  function _G.table.length(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
  end
end
debug_log('table length', type(_G.table.length))

_G.iconImageSheet = graphics.newImageSheet('icons/icons.png', {width=64, height=64, numFrames=12})

composer.gotoScene('Splash', {effect='fade', params={scene='Menu'}})
