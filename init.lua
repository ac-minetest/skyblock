--[[

Skyblock Redo
(rewrite from scratch)

Copyright (c) 2018 rnd
License: GPLv3

]]--

skyblock = {}
local modpath = minetest.get_modpath('skyblock')

dofile(modpath..'/settings.lua')
dofile(modpath..'/quests.lua') -- quest definitions

dofile(modpath..'/world.lua') -- set mapgen, spawn island functions, island positions
dofile(modpath..'/crafts_and_tweaks.lua') -- various crafts and tweaks needed for skyblock
dofile(modpath..'/skyblock.lua') -- handles quest tracking, load/save player data, island id management



print('[MOD]'.. " SKY BLOCK v2 loaded.")