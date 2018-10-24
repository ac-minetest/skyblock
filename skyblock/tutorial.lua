skyblock.tutorial = { huds = {}};
local tutorial = skyblock.tutorial; -- {[playername] = hud idx}

local dout = minetest.chat_send_all

tutorial.change_text = function(name, text)
	local player = minetest.get_player_by_name(name);
	if not player then return end
	local id = tutorial.huds[name];
	if not id then -- init hud for player
		local idx = 
		player:hud_add({
			hud_elem_type = "text",
			position  = {x = 0.5, y = 1},
			offset    = {x = 0, y = -100},
			text      = text,
			--alignment = -1,
			--scale     = { x = 50, y = 10},
			number    = 0xFF0000,
		})
		tutorial.huds[name] = idx;
		return
	end -- error
	player:hud_change(id,"text", text)
	
end

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name();
	local pdata = skyblock.players[name];
	if pdata.level and pdata.level < 2 then
		tutorial.change_text(name,"Welcome to S K Y B L O C K !\nYou need to expand island by doing Quests (open inventory)\nFirst quest is digging and placing dirt 10x.")
	end
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name();
	tutorial.huds[name] = nil
end)