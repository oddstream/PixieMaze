-- Status (singleton) class

local Status = {
  -- class constants
  height = 128,
  width = display.contentWidth,

  -- class data
  level = 0,
  -- time = 0,
  levelName = '',
  score = 0,

  -- display objects
  group = nil,
  rect = nil,
  levelText = nil,
  -- timeText = nil,
  levelNameText = nil,
  scoreText = nil,

  ghostsGroup = nil,
}

function Status:new()
  local o = {}
  self.__index = self
  setmetatable(o, self)
  return o
end

function Status:setGroup(group)
  self.group = group
  self.rect = display.newRect(self.group, self.width/2, self.height/2, self.width, self.height)
  self.rect:setFillColor(unpack(_G.colors.black))
  self.rect.alpha = 0.5

  self.levelText = display.newText(self.group, 'LEVEL', 128, self.height/2, native.systemFontBold, 72)
  -- default color is white
  self.levelText.anchorX = 0.1  -- align left-ish

  -- self.timeText = display.newText(self.group, 'TIME', display.contentCenterX, self.height/2, native.systemFontBold, 72)
  -- default color is white
  -- self.timeText.anchorX = 0.5  -- align center
  self.levelNameText = display.newText(self.group, 'NAME', display.contentCenterX, self.height/2, native.systemFontBold, 72)
  self.levelNameText.anchorX = 0.5  -- align center

  self.scoreText = display.newText(self.group, 'SCORE', display.contentWidth - 128, self.height/2, native.systemFontBold, 72)
  -- default color is white
  self.scoreText.anchorX = 0.9  -- align right-ish
end

function Status:setLevel(level)
  self.level = level
  self.levelText.text = string.format('%u of %u', self.level, _G.game:numberOfLevels())
end

function Status:setLevelName(name)
  self.levelNameText.text = name
end

-- function Status:incTime()
--   self.time = self.time + 1
--   self.timeText.text = string.format('%u:%02u', self.time / 60, self.time % 60)
-- end

function Status:incScore(amt)
  amt = amt or 1
  local diff = _G.game.difficulty
  if diff == 'normal' then
    amt = amt * 1.1
  elseif diff == 'hard' then
    amt = amt * 1.2
  elseif diff == 'evil' then
    amt = amt * 1.3
  end
  self.score = self.score + amt
  self.scoreText.text = tostring(math.floor(self.score))
end

function Status:decScore(amt)
  self.score = self.score - amt
  self.scoreText.text = tostring(math.floor(self.score))
end

return Status