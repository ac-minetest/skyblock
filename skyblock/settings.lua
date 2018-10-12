skyblock.center = {x=0,y=4,z=0}; -- position of 0-th island
skyblock.islands_gap = 32; -- distance between island centers
skyblock.bottom = -8; -- bottom of world


-- disable static_spawn notice!
if core.settings:get("static_spawnpoint") then
	print("#SKYBLOCK ERROR: disable static_spawnpoint in minetest.conf for correct respawning")
end
	