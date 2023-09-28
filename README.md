# PIXIE · MAZE

## changes

- tap on Pixie when there are no more pups now sends Pixie to exit
- changed spore sound

- wallpasser magic now teleport

- added settings scene, to turn off white/green ghosts, set tile size
- dynamic scaling of tile size
- level tweaks
- scalaing of menu, status bar, knapsack

- added spore and power up sounds
- changes to launcher icons
- added knapsack gauges
- new pup walk (pixie path is sticky)

- bug fix: Pixie tap was only in simulator
- ghosts now don't change color
- retired shockwave
- added visible pause button

- added Hotel level
- power ups are now slightly attracted to Pixie and her ball
- removed timer from wallpasser power up; it now allows one move (which may be >1 wall)
- tap Pixie to go to nearest power up
- level and gameplay tweaks

- added easy/hard hardest to Menu.lua

- ghosts and power ups now have same alpha as the tile they're on

- The 'get off the path' edition:
- power ups now walk randomly
- removed need to collect all power ups
- 100 points for killing a ghost
- added more snakes to discourage sticking to the path
- occasionally use Prim's algorithm to generate maze, instead of recursive backtracker

- replaced shield power up with health
- replaced navigation power up with fireball
- path to exit is now always marked (with yellow spores)

- only aqua ghosts on level one
- bug fix: green ghosts were not changing when reaching entrance
- added blanks to level data to allow more shapes
- added corner check before creating automatic spawn tiles

- removed pink ghosts (too like purple)
- bug fix: shield degrading on harmless ghost
- bug fix: changed stupid knapsack code

- added white ghosts
- glyph moved from knapsack to magic item
- only one of each colored ghost allowed at once

- added pink ghosts
- retired status.permadeath, replace with Game:isPixieAlive()
- removed a level to make game shorter
- optimize wall placement when adding graphics to tiles (use multi wall colors to guide this)

- path marked to exit when picking up key

- clear level six (10 tiles wide) to win the game and record a high score
- invulnerable magic item replaced with pixie shield
- magic items now indicate how many of that type there are in the knapsack
- bottom ghosts spawn at the start, top ghosts now spawn from the entrance, but only after pixie has collected the exit key
- ghosts keep spawning to a fixed number (maze width * 2), even if pixie kills some off, so there will always be ghosts in the maze. So, pixie will run out of ammo and die if she stays too long on a level
- light reduction now happens all the time, taking one minute to gradually go from full bright to near darkness
- start using a graphic for ghosts rather than a a plain circle (work in progess, needs some animation)
- ghosts get faster as level increases, until they're same speed as pixie

- find the key to unlock the exit
- fireballs
- proper collision detection

- better collision detection

- defined entrance and exit tiles
- pause/resume now works on pixie and ghost timers
- retired Edge class, replaced with faster Tile link members
- limit the number of dynamically pathfinding ghosts

- caps now have correct alpha when tile created

- juddering after level 5 on phone, so limit ghosts to four (one per corner)

- application suspend now displays resume button
- white ghosts now hostile
- spacing of knapsack items