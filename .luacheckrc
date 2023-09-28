local coronaAPI = {
  'audio',
  'display',
  'easing',
  'graphics',
  'lfs',
  'media',
  'native',
  'network',
  'Runtime',
  'system',
  'timer',
  'transition',
  'print',
  'require',
  'package',
 }

max_line_length = false

stds.corona = {
   read_globals = coronaAPI   -- these globals can only be accessed.
}

-- https://luacheck.readthedocs.io/en/stable/config.html
read_globals = {
  "debug_log",
  "colors",
}

globals = {
  "Q",
  "game",
}

std = "lua51+corona"
