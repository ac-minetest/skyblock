skyblock.players = {};
 

-- QUEST MANAGEMENT: init
local quest_types = skyblock.quest_types;
 
skyblock.init_level = function(name,level) -- inits/resets player achievements on level
	if not skyblock.quests[level] then return end -- nonexistent quests
	
	local pdata = skyblock.players[name];
	if not pdata then
		skyblock.players[name] = { 
			level = level, 
			completed = 0,
			time_played = 0,
		};
		pdata = skyblock.players[name];
	end
	
	--reset current quests
	for k,_ in pairs(quest_types) do pdata[k] = nil	end
	pdata.completed = 0
	pdata.level = level
	
	local total = 0;
	
	for k,v in pairs( skyblock.quests[level] ) do -- init all achievements to 0
		if quest_types[k] then
			local w = {};
			for k_,v_ in pairs(v) do
				w[k_] = 0; 
				total =  total + 1;
			end
			pdata[k] = w; -- for example: pdata.on_dignode = {["default:dirt"]=0}
			
		end
	end
	pdata.total =  total;
 end
 
  -- QUESTS TRACKING --
  
 local track_quest = function(pos, item, digger, quest_type)
	
	local name = digger:get_player_name();
	local pdata = skyblock.players[name];
	local level = pdata.level;
	
	local data = skyblock.quests[level][quest_type];
	if not data or not data[item] then return end -- is there quest of this type and quest for this item?
	
	local count = pdata[quest_type][item]; 
	
	if count < data[item].count then -- only if quest not yet completed
		count = count + 1
		pdata[quest_type][item] = count;
		if count >= data[item].count then-- did we just complete the quest?
			if data[item].on_completed and not data[item].on_completed(pos,name) then 
				pdata[quest_type][item] = data[item].count - 1 -- reset count to just below limit
				return 
			end
			minetest.chat_send_all("#SKYBLOCK: " .. name .. " completed '" .. data[item].description .. "' on level " .. level)
			digger:get_inventory():add_item("craft", ItemStack(data[item].reward)) -- give reward to player
			
			pdata.completed = pdata.completed + 1 -- one more quest completed
			if pdata.completed >= pdata.total then skyblock.quests[level].on_completed(name) end -- did we complete level?
		end
	end
	
 end
 
 -- track node dig
 minetest.register_on_dignode(
	function(pos, oldnode, digger)	track_quest(pos,oldnode.name, digger, "on_dignode") end
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
	if err then return nil end
	local pdatastring = file:read("*a");
	file:close()
	local pdata = minetest.deserialize(pdatastring);

	if pdata and pdata.level then
		skyblock.players[name] = pdata; return
	end
end 
 
function save_player_data(name)
	local file,err = io.open(filepath..'/'..name, 'wb')
	if err then return nil end
	local pdata = skyblock.players[name];
	if not pdata then return end

	local t = minetest.get_gametime();
	pdata.time_played = pdata.time_played + (t-pdata.last_login) -- update total play time
	local pdatastring = minetest.serialize(pdata)
	file:write(pdatastring)
	file:close()
end

function save_data(name) -- on shutdown
	local file,err = io.open(filepath..'/_SKYBLOCK_', 'wb')
	if err then return nil end
	
	local ids = skyblock.id_queue;
	for _,player in ipairs(minetest.get_connected_players()) do -- save connected players if their level enough
		local name = player:get_player_name();
		local pdata = skyblock.players[name];
		if pdata.level>1 then -- save players
			save_player_data(name)
		else -- free id
			ids[#ids+1] = pdata.id
		end
	end
	
	local pdatastring = minetest.serialize({skyblock.max_id,skyblock.id_queue})
	file:write(pdatastring)
	file:close()
	
end

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
minetest.register_on_shutdown(save_data) -- when server stops

-- MANAGE player data when connecting/leaving
  
 minetest.register_on_joinplayer( -- LOAD data, init
	function(player)
		local name = player:get_player_name();
		load_player_data(name); -- attempt to load previous data
		local pdata = skyblock.players[name];
		
		local level = 1;
		local id = -1;
		
		if not pdata then -- init for new player
			skyblock.init_level(name,1)
			pdata = skyblock.players[name];
			minetest.chat_send_player(name, "#SKYBLOCK: welcome to skyblock. Open inventory and check the quests.")
		else
			level = pdata.level
			id = pdata.id
		end
		pdata.last_login = minetest.get_gametime()
		pdata.time_played = pdata.time_played or 0
		
		-- set island, set id
		if level == 1 then -- new player only
			local ids = skyblock.id_queue;
			
			if #ids == 0 then 
				skyblock.max_id = skyblock.max_id + 1 -- out of free islands,make new island
				--minetest.chat_send_all("D max_id increased to " .. skyblock.max_id )
				id = skyblock.max_id;
				
				if id>=0 then 
					local pos = skyblock.get_island_pos(id)
					minetest.chat_send_all("#SKYBLOCK: spawning new island " .. id .. " for " .. name .. " at " .. pos.x .. " " .. pos.y .. " " .. pos.z )
					skyblock.spawn_island(pos, name)
					player:setpos({x=pos.x,y=pos.y+4,z=pos.z}) -- teleport player to island
					pdata.id = id
				else
					minetest.chat_send_all("#SKYBLOCK ERROR: skyblock.max_id is <0")
					return
				end
			else 
				id = ids[#ids]; ids[#ids] = nil; -- pop stack, reuse island
				pdata.id = id;
				local pos = skyblock.get_island_pos(id)
				minetest.after(5, function() skyblock.delete_island(pos, true) end) -- check for trash and delete it
			end
			
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
		
		skyblock.init_level(name,pdata.level or 1)
		if pdata.level == 1 then 
			skyblock.spawn_island(pos, name)
		end
		
		pos.y=pos.y+4; player:setpos(pos) -- teleport player to island
		--minetest.chat_send_all("#SKYBLOCK: respawning player " .. name .. " to " .. pos.x .. " " .. pos.y .. " " .. pos.z)
end

local timer = 0;
minetest.register_globalstep(
	function(dtime)
		timer = timer + dtime;
		if timer > 1 then
			timer = 0
			local bottom = skyblock.bottom;
			for _,player in ipairs(minetest.get_connected_players()) do -- MINETEST BUG: why we get huge lag if 'pairs' here?
				if player:getpos().y < bottom then 
					player:get_inventory():set_list("main",{}) -- empty inventory
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
	local t = minetest.get_gametime();
	t = pdata.time_played + t-pdata.last_login
	t=math.floor(t/60*100)/100
	
	local formspec = "size[8,8]";		
	
	local form  = 
		"size[8,8]"..
		"label[0,0;".. minetest.colorize("red","SKYBLOCK QUESTS: " .. name .. ", level " .. level) .. "]"..
		"label[0,0.4;".. "play time : " ..  t .. " min]"..
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
					
					local count = pdata[qtype][item];
					local tcount = qdef.count;
					local desc = qdef.description;
					if count>=tcount then 
						desc = minetest.colorize("Green", desc) 
					else 
						desc = minetest.colorize("Orange", desc) 
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


-- add gui tab using sfinv
if sfinv then
	sfinv.register_page("sfinv:skyblock", {
		title = "Skyblock",
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