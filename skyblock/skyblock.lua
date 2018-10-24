skyblock.players = {};
 

-- QUEST MANAGEMENT: init
local quest_types = skyblock.quest_types;
 
skyblock.init_level = function(name,level) -- inits/resets player achievements on level
	if not skyblock.quests[level] then return end -- nonexistent quests
	local pdata = skyblock.players[name];
	
	--reset current quests
	for k,_ in pairs(quest_types) do pdata[k] = nil	end

	pdata.data = {}; -- various extra data that can be used for more complex quests
	pdata.completed = 0
	pdata.level = level
	
	local total = 0;
	
	for k,v in pairs( skyblock.quests[level] ) do -- init all achievements to 0
		if quest_types[k] then
			local w = {};
			for k_,v_ in pairs(v) do
				w[k_] = 0; 
				if not v_.hidden then total =  total + 1 end -- hidden quests dont count towards goal
			end
			pdata[k] = w; -- for example: pdata.on_dignode = {["default:dirt"]=0}
			
		end
	end
	pdata.total =  total; -- how many quests on this level
 end
 
  -- QUESTS TRACKING --
  
 local track_quest = function(pos, item, digger, quest_type)
	
	local name = digger:get_player_name();
	local pdata = skyblock.players[name]; -- all player data
	
	local stats = pdata.stats;--update stats 
	stats[quest_type] = (stats[quest_type] or 0) + 1
	
	local qdata =  pdata[quest_type]; -- quest data for this player
	if qdata and qdata[item] then else return end -- player has no such quest in progress!
	
	local level = pdata.level;
	local data = skyblock.quests[level][quest_type];
	if data and data[item] then data = data[item] else return end -- is there quest of this type and quest for this item?

	local count = qdata[item]; 
	
	if count < data.count then -- only if quest not yet completed
		if data.hidden then -- quest is hidden, doesnt count toward progress
			if data.on_progress then  -- optionally do something extra
				if data.on_progress(pdata.data) then qdata[item] = data.count end -- if on_progress returns true we are done, stop tracking
				return
			end
		end
		
		count = count + 1
		qdata[item] = count;
		if data.on_progress then  -- optionally do something extra
			if data.on_progress(pdata.data) then count = data.count end -- if on_progress returns true we are done
		end
		if count >= data.count then-- did we just complete the quest?
			if data.on_completed and not data.on_completed(pos,name) then 
				qdata[item] = data.count - 1 -- reset count to just below limit
				return 
			end
			minetest.chat_send_all("#SKYBLOCK: " .. name .. " completed '" .. data.description .. "' on level " .. level)
			local diginv = digger:get_inventory(); local rewardstack = ItemStack(data.reward)
			if diginv:room_for_item("craft", rewardstack) then
				diginv:add_item("craft", rewardstack)  -- give reward to players craft inventory
			else
				minetest.add_item(pos,rewardstack) -- drop reward
			end
			pdata.completed = pdata.completed + 1 -- one more quest completed
			if pdata.completed >= pdata.total then skyblock.quests[level].on_completed(name) end -- did we complete level?
		end
	end
	
 end
 
 -- track node dig: NOTE: some crazy minetest mods actually call on_dignode with nil digger! (like builtin/falling.lua)
 minetest.register_on_dignode( 
	function(pos, oldnode, digger) if digger then track_quest(pos,oldnode.name, digger, "on_dignode") end end
 )
 
-- track node place
minetest.register_on_placenode( -- TODO: maybe check if we can really place node to prevent 'cloud place abuse' ?
function(pos, newnode, placer, oldnode)	track_quest(pos,newnode.name, placer, "on_placenode") end
)

-- track craft item
minetest.register_on_craft(
function(itemstack, player, old_craft_grid, craft_inv)	track_quest(nil, itemstack:get_name(), player, "on_craft") end
)
 
-- SAVING/LOADING DATA: player data, skyblock data
 
 local function mkdir(path)
	if minetest.mkdir then
		minetest.mkdir(path)
	else
		os.execute('mkdir "' .. path .. '"')
	end
end
 
local filepath = minetest.get_worldpath()..'/skyblock';
mkdir(filepath) -- create if non existent
 
function load_player_data(name)
	local file,err = io.open(filepath..'/'..name, 'rb')
	local pdata = {};
	if not err then -- load from file
		local pdatastring = file:read("*a");
		file:close()
		pdata = minetest.deserialize(pdatastring) or {};
	end
	
	pdata.stats = pdata.stats or {};  -- init
	pdata.stats.time_played = pdata.stats.time_played or 0
	pdata.stats.last_login = minetest.get_gametime() -- update
	skyblock.players[name] = pdata; return
end 
 
function save_player_data(name)
	local file,err = io.open(filepath..'/'..name, 'wb')
	if err then return nil end
	local pdata = skyblock.players[name];
	if not pdata then return end

	local t = minetest.get_gametime();
	pdata.stats.time_played = pdata.stats.time_played + (t-pdata.stats.last_login) -- update total play time
	local pdatastring = minetest.serialize(pdata)
	file:write(pdatastring)
	file:close()
end

function save_data(is_shutdown) -- on shutdown save free island ids too
	local file,err = io.open(filepath..'/_SKYBLOCK_', 'wb')
	if err then return nil end
	
	local ids = skyblock.id_queue;
	if is_shutdown then -- save all player data
		for _,player in ipairs(minetest.get_connected_players()) do -- save connected players if their level enough
			local name = player:get_player_name();
			local pdata = skyblock.players[name] or {};
			if pdata then
				if pdata.level~=1 then -- save players
					save_player_data(name)
				else -- player was level 1, make id available again
					ids[#ids+1] = pdata.id
				end
			end
		end
	end
	
	local pdatastring = minetest.serialize({skyblock.max_id,skyblock.id_queue})
	file:write(pdatastring)
	file:close()
end
skyblock.save_data = save_data;

-- SKYBLOCK ISLAND MANAGEMENT
--[[
	skyblock.max_id = -1; -- largest id in use so far - init
	skyblock.id_queue = {}; -- available id's, when player who is not 'old' leaves, his id is put here, when new non-old player joins, he takes id from here. Player is 'old' if he reaches level 2
--]]

skyblock.max_id = -1;
skyblock.id_queue = {};

function load_data(name)
	local file,err = io.open(filepath..'/_SKYBLOCK_', 'rb')
	if err then return nil end
	local pdatastring = file:read("*a");
	file:close()
	local data = minetest.deserialize(pdatastring) or {};
	skyblock.max_id = data[1] or -1;
	skyblock.id_queue = data[2] or {};
end

load_data(); -- when server starts
minetest.register_on_shutdown(function() save_data(true) end) -- when server shuts down

-- MANAGE player data when connecting/leaving
  
 minetest.register_on_joinplayer( -- LOAD data, init
	function(player)
		local name = player:get_player_name();
		load_player_data(name); -- attempt to load previous data
		local pdata = skyblock.players[name];
		local level = 1;
		local id = -1;
		if not pdata.level then -- init for new player
			skyblock.init_level(name,1)
			pdata = skyblock.players[name];
			minetest.chat_send_player(name, "#SKYBLOCK: welcome to skyblock. Open inventory and check the quests.")
		else
			level = pdata.level
			id = pdata.id
		end
		-- set island, set id for player
		if level == 1 then -- new player only
			local ids = skyblock.id_queue;
			
			if #ids == 0 then 
				skyblock.max_id = skyblock.max_id + 1 -- out of free islands,make new island
				id = skyblock.max_id;
				
				if id>=0 then 
					local pos = skyblock.get_island_pos(id)
					minetest.chat_send_all(minetest.colorize("LawnGreen","#SKYBLOCK: spawning new island " .. id .. " for " .. name .. " at " .. pos.x .. " " .. pos.y .. " " .. pos.z ))
					pdata.id = id
					skyblock.spawn_island(pos, name)
					player:setpos({x=pos.x,y=pos.y+4,z=pos.z}) -- teleport player to island
					
				else
					minetest.chat_send_all("#SKYBLOCK ERROR: skyblock.max_id is <0")
					return
				end
			else 
				id = ids[#ids]; ids[#ids] = nil; -- pop stack, reuse island
				local pos = skyblock.get_island_pos(id)
				minetest.chat_send_all(minetest.colorize("LawnGreen","#SKYBLOCK: reusing island " .. id .. " for " .. name .. " at " .. pos.x .. " " .. pos.y .. " " .. pos.z ))
				pdata.id = id;
				player:setpos({x=pos.x,y=pos.y+4,z=pos.z}) -- teleport player to island
				
				minetest.after(5, function() skyblock.delete_island(pos, true);skyblock.spawn_island(pos, name) end) -- check for trash and delete it
			end
		else
			minetest.chat_send_all(minetest.colorize("LawnGreen","#SKYBLOCK: welcome back " .. name .. " from island " .. id))
		end
	end
)

minetest.register_on_leaveplayer(
	function(player, timed_out)
		local name = player:get_player_name();
		local pdata = skyblock.players[name];
		
		if pdata.level == 1 then -- new players id is recycled, player must be level >=2 to keep his island
			local ids = skyblock.id_queue;
			ids[#ids+1] = pdata.id;
		else -- save data if player level >= 2!
			save_player_data(name)
		end
		
		skyblock.players[name]=nil
	end
)

-- RESPAWN PLAYERS BELOW THE BOUNDARY

local respawn_player = function(player)
		local name = player:get_player_name();
		local pdata = skyblock.players[name];
		
		local pos = skyblock.get_island_pos(pdata.id);
		if not pos then minetest.chat_send_all("#SKYBLOCK ERROR: spawnpos for " .. name .. " nonexistent") return end
		
		if pdata.level == 1 then 
			skyblock.init_level(name,1)
			if not minetest.find_node_near(pos, 5, "default:dirt") then
				skyblock.spawn_island(pos, name)
			end
		end
		pos.y=pos.y+4; player:setpos(pos) -- teleport player to island
end

local timer = 0;
minetest.register_globalstep(
	function(dtime)
		timer = timer + dtime;
		local t;
		if timer > 1 then
			timer = 0
			local bottom = skyblock.bottom;
			for _,player in ipairs(minetest.get_connected_players()) do -- MINETEST BUG: why huge lag if 'pairs' here?
				if player:getpos().y < bottom then 
					local name = player:get_player_name();
					local pdata = skyblock.players[name];
					t = t or minetest.get_gametime();
					if pdata and t-pdata.stats.last_login>10 then -- only reset inventory if player online for more than 10s to prevent spawn kills when falling through unloaded island
						player:get_inventory():set_list("main",{}) -- empty inventory
						player:get_inventory():set_list("craft",{})
					end
					respawn_player(player)
				end
			end
		end
	end
)

-- GUI STUFF using sfinv ---

 local get_quest_form = function(name) -- quest gui formspec
	local pdata = skyblock.players[name];
	if not pdata then return end
	local level = pdata.level;
	local formspec = "size[8,8]";		
	
	local form  = 
		"size[8,8]"..
		"label[0,0;".. minetest.colorize("orange","SKYBLOCK QUESTS - LEVEL " .. level .. "]")..
		"label[-0.25,0.5;________________________________________________________________________________]";
	local y = 0;
	for qtype,quest in pairs(skyblock.quests[level]) do
		if quest_types[qtype] and quest then
			for item, qdef in pairs(quest) do
				if qdef.count and qdef.description and pdata[qtype] then
					y=y+1;
					local tex;
					local def = minetest.registered_items[item] or {};
					tex =  def.inventory_image or "bubble.png";
					
					if not string.find(tex,".png") then
						if def.tiles then
							tex = def.tiles[1] or def.tiles
						end
					end
					
					local count = pdata[qtype][item] or -1;
					local tcount = qdef.count or -1;
					local desc = qdef.description or "ERROR!";
					if count>=tcount then 
						desc = minetest.colorize("Green", desc) 
					--else 
						--desc = minetest.colorize("Orange", desc) 
					end
					
					form = form .. 
					"label[0,".. (0.75*y+0.25) .. ";".. desc .. "]"..
					"image[6,".. 0.75*y+0.2 .. ";0.75,0.75;".. tex .. "]"..
					"label[7,".. (0.75*y+0.25) .. ";" .. count .. "/" .. tcount .. "]"
				end
			end
		end
	end

	return form
 	
end

 local get_stats_form = function(name) -- quest gui formspec
	local pdata = skyblock.players[name];
	if not pdata then return end
	local stats = pdata.stats;
	local t = minetest.get_gametime();
	t = stats.time_played + t-stats.last_login -- s
	local t_ = {math.floor(t/3600),math.floor((t-math.floor(t/3600)*3600)/60)};
	t=t-t_[1]*3600-t_[2]*60;
	local form  = 
		"size[8,8]"..
		"label[0,0..;".. minetest.colorize("orange","STATISTICS for " .. name) .. "]"..
		"label[-0.25,0.5;________________________________________________________________________________]"..
		"label[0,1.;".."play time        : " ..  t_[1] .. " hour " .. t_[2] .. " min " .. t .. "s]"..
		"label[0,1.5;"..   "blocks digged : " ..  (stats.on_dignode or 0) .. "]" ..
		"label[0,2;".. "blocks placed : " ..  (stats.on_placenode or 0) .. "]" ..
		"label[0,2.5;"..   "items crafted  : " ..  (stats.on_craft or 0) .. "]"
 return form
 end


-- add gui tab using sfinv
if sfinv then
	sfinv.register_page("sfinv:skyblock", {
		title = "Quests",
		get = function(self, player, context)
			
			local content = get_quest_form(player:get_player_name());
			
			local tmp = {
			"size[8,8.6]",
			"bgcolor[#080808BB;true]" .. default.gui_bg .. default.gui_bg_img,
			sfinv.get_nav_fs(player, context, context.nav_titles, context.nav_idx),
			content,
			"button[6,0.;2,1;skyblock_update;REFRESH]"
			}
			return table.concat(tmp, "")
		end,
		
		on_player_receive_fields = function(self, player, context, fields)
		if fields.skyblock_update then -- refresh
			local fs = sfinv.get_formspec(player,
				context or sfinv.get_or_create_context(player))
			player:set_inventory_formspec(fs)
		end
	end,
	})
	
	sfinv.register_page("sfinv:skystats", {
		title = "Stats",
		get = function(self, player, context)
			
			local content = get_stats_form(player:get_player_name()); 
		
			local tmp = {
			"size[8,8.6]",
			"bgcolor[#080808BB;true]" .. default.gui_bg .. default.gui_bg_img,
			sfinv.get_nav_fs(player, context, context.nav_titles, context.nav_idx),
			content,
			"button[6,0.;2,1;skystats_update;REFRESH]"
			}
			return table.concat(tmp, "")
		end,
		
		on_player_receive_fields = function(self, player, context, fields)
		if fields.skystats_update then -- refresh
			local fs = sfinv.get_formspec(player,
				context or sfinv.get_or_create_context(player))
			player:set_inventory_formspec(fs)
		end
	end,
	})
end

 
 minetest.register_chatcommand('quest', {
	description = 'Show quests for current level',
	privs = {},
	params = "",
	func = function(name, param)
		if param and param~= "" then
			local form = get_quest_form(param);
			if form then minetest.show_formspec(name, "skyblock_quests",form) end
		else
			minetest.show_formspec(name, "skyblock_quests",get_quest_form(name))
		end
	end,
})

minetest.register_chatcommand('stats', {
	description = 'Show stats for skyblock player',
	privs = {},
	params = "",
	func = function(name, param)
		if param and param~= "" then
			local form = get_stats_form(param);
			if form then minetest.show_formspec(name, "skyblock_stats",form) end
		else
			minetest.show_formspec(name, "skyblock_stats",get_stats_form(name))
		end
	end,
})