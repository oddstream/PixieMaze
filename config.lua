--
-- For more information on config.lua see the Project Configuration Guide at:
-- https://docs.coronalabs.com/guide/basics/configSettings
--

_G.application =
{
  content =
  {
    --[[
      16:9 – This is the HDTV standard or 720p (1280×720) or 1080p (1920×1080).
      This is very common to many modern phones too. This works out to 1:1.777778
      if you want to measure it based on a 1 point scale.
    ]]
    width = 1080,
    height = 1920,
    -- width = 720,
    -- height = 1280,
    -- The scaling method of the content area is determined by the scale value.
    -- If you omit this (not recommended), the width and height values will be ignored and the content area will be set to the device's actual pixel width and height.
    scale = 'letterbox',
    -- scale = 'zoomEven',
    -- scale = 'adaptive',
    xAlign = 'center',
    yAlign = 'center',
    fps = 30,
  },
}
