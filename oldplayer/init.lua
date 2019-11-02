-- OLD PLAYER : keep only serious players data on server
--(c) 2015-2016 rnd

oldplayer = {}

-- SETTINGS 

oldplayer.requirement = {"default:dirt 1", "default:steel_ingot 1"};
oldplayer.welcome = "Welcome to ROBOTS SKYBLOCK! Open inventory and do the quests to get more stuff and progress\n" ..
"You can use /quest, /sethome, /home and /spawn to move around and /skin to change appearance."..
"\n\n*** IMPORTANT *** get to level 2 when leaving for first time to register as serious player. If not, your player data (inventory,location) will be deleted.";

-- END OF SETTINGS 


oldplayer.players = {};
local worldpath = minetest.get_worldpath();


minetest.register_on_joinplayer(function(player) 
	local name = player:get_player_name(); if name == nil then return end 
	
	-- read player inventory data
	local inv = player:get_inventory();
	local isoldplayer = inv:get_stack("oldplayer", 1):get_count();
	inv:set_size("oldplayer", 2);
	local ip = minetest.get_player_ip(name); if not ip then return end
	inv:set_stack("oldplayer", 2, ItemStack("IP".. ip)) -- string.gsub(ip,".","_")));
	
	if isoldplayer > 0 then
		oldplayer.players[name] = 1
		minetest.chat_send_player(name, "#OLDPLAYER: welcome back");
	else
		local privs = minetest.get_player_privs(name);
		if privs.kick then
			inv:set_stack("oldplayer", 1, ItemStack("oldplayer"));
			minetest.chat_send_player(name, "#OLDPLAYER: welcome moderator. setting as old player.");
			oldplayer.players[name] = 1
		else
			oldplayer.players[name] = 0
			local form = "size [6,4] textarea[0,0;6.6,5.5;help;OLDPLAYER WELCOME;".. oldplayer.welcome.."]"
			minetest.show_formspec(name, "oldplayer:welcome", form)
	--		minetest.chat_send_player(name, oldplayer.welcome);
		end
	end
	
	
end)

minetest.register_on_leaveplayer(function(player, timed_out)
	local name = player:get_player_name(); if name == nil then return end
	if oldplayer.players[name] == 1 then return end -- already old, do nothing

	local delete = false; -- should we delete player?
	
	-- read player inventory data
	local inv = player:get_inventory();

	--does player have all the required items in inventory?
	-- for _,item in pairs(oldplayer.requirement) do
		-- if not inv:contains_item("main", item)	then 
			-- delete = true
		-- end
	-- end
	
	local pdata = skyblock.players[name];
	local level = pdata.level or 1;
	if level<2 then delete = true end
	
	if not delete then -- set up oldplayer inventory so we know player is old next time
		inv:set_size("oldplayer", 2);
		inv:set_stack("oldplayer", 1, ItemStack("oldplayer"));
	else -- delete player profile
		
		local filename = worldpath .. "/players/" .. name;
		
		-- PROBLEM: deleting doesnt always work? seems minetest itself is saving stuff.
		-- so we wait a little and then delete
		minetest.after(10,function() 
			print("[oldplayer] removing player filename " .. filename)
			local err,msg = os.remove(filename) 
			if err==nil then 
				print ("[oldplayer] error removing player data " .. filename .. " error message: " .. msg) 
			end
			-- TO DO: how to remove players from auth.txt easily without editing file manually like below
		end);
	end
end
)

-- delete file if not old player
local function remove_non_old_player_file(name)
	local filename = worldpath.."/players/"..name;
	local f=io.open(filename,"r")
	local s = f:read("*all"); f:close();
	if string.find(s,"Item oldplayer") then return false else os.remove(filename) return true end
end

-- deletes data with no corresponding playerfiles from auth.txt and creates auth_new.txt
local function player_file_exists(name)
	local f=io.open(worldpath.."/players/"..name,"r")
	if f~=nil then io.close(f) return true else return false end
end

local function remove_missing_players_from_auth()
	
	local playerfilelist = minetest.get_dir_list(worldpath.."/players", false);
	
	local f = io.open(worldpath.."/auth.txt", "r");
	if not f then return end
	local s = f:read("*a");f:close();
	local p1,p2;

	f = io.open(worldpath.."/auth_new.txt", "w");
	if not f then return end
	
	local playerlist = {};
	for _,name in ipairs(playerfilelist) do
		playerlist[name]=true;
	end
	
	local i=0;
	local j=0; local k=0;
	local name;
	local count = 0;
	-- parse through auth and remove missing players data
	

	while j do
		j=string.find(s,":",i);
		if j then
			if i ~= 1 then
				name = string.sub(s,i+1,j-1) 
			else
				name = string.sub(s,1,j-1)
			end
			if j then 
				k=string.find(s,"\n",i+1);
				if not k then 
					j = nil
					if playerlist[name] then 
						f:write(string.sub(s,i+1)) 
					else 
						count = count+1 
					end
				else
					if playerlist[name] then 
						f:write(string.sub(s,i+1,k)) 
					else 
						count = count + 1 
					end
					i=k;
				end
			end
		end
	end
	f:close();
	print("#OLD PLAYER : removed " .. count .. " entries from auth.txt. Replace auth.txt with auth_new.txt");
end

local function remove_non_old_player_files()
	local playerfilelist = minetest.get_dir_list(worldpath.."/players", false);

	local count = 0;
	for _,name in ipairs(playerfilelist) do
		if remove_non_old_player_file(name) then
			count = count + 1
		end
	end
	print("#OLD PLAYER:  removed " .. count .. " non oldplayer player files");
end

minetest.register_on_shutdown(function() remove_non_old_player_files();remove_missing_players_from_auth() end)