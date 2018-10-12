settings = {};
settings.spawnpos = {x=0,y=501,z=0}

minetest.register_chatcommand("spawn", {
	description = "Move player back to spawn",
	privs = {
		interact = true
	},
	
	func = function(name, param)
		local player = minetest.get_player_by_name(name); --if player then player:set_hp(0) end
		player:setpos(settings.spawnpos)
	end
})