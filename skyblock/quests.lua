skyblock.quests = {}

skyblock.quests[1] = { -- level 1
	on_dignode = {
		["default:dirt"]={reward = "default:leaves 6", count=1, description = "dig 1 dirt"},
		["default:tree"]={reward = "default:water_source", count=16, description = "dig 16 tree",
			on_completed = function(pos,name) 
				skyblock.tutorial.change_text(name,"Keep making more composters and more dirt.\nKeep water for later.")
				return true
			end
		
		} 
	},
	
	on_placenode = {
		["default:dirt"]={reward = "default:stick 5", count=1, description = "place 1 dirt",
			on_completed = function(pos,name) 
				skyblock.tutorial.change_text(name,"You can make tree sapling now, open craft guide and search\nfor sapling recipe ( right one ).Plant tree, wait 1 minute\nand make more saplings from leaves.")
				return true
			end
		} 
	},
	
	on_craft = {
		["compost:wood_barrel"]={reward = "default:lava_source", count=16, description = "hold 32 dirt in hand and craft 16 composters",
		on_completed = function(pos,name) 
			local player = minetest.get_player_by_name(name);
			local inv = player:get_inventory();
			if not inv:contains_item("main",ItemStack("default:dirt 32")) then
				minetest.chat_send_player(name,"#SKYBLOCK: you need to have 32 dirt in inventory to complete this quest! Try again.")
				return false
			end
			minetest.chat_send_player(name,
			"#SKYBLOCK: if water meets flowing lava it will create pumice. Mix 8 pumice and 1 dirt to get 1 gravel, later you can mix 1 pumice and 1 gravel to make 2 gravel. Craft 1 cobble from 8 gravel, later smelt 1 gravel to make 1 cobble.\n"..
			minetest.colorize("red","IMPORTANT! keep water away from lava source!"))
			skyblock.tutorial.change_text(name,"Place lava (AWAY FROM WATER!) and make your\nown pumice generator. You can dig pumice with wooden\npick and use it to make stone (search craft guide)")
			return true
		end
		},
		["default:furnace"]={reward = "default:axe_steel", count=4, description = "craft 4 furnace",
			on_completed = function(pos,name) 
				skyblock.tutorial.change_text(name,"")
				return true
			end
		},
		["default:sapling"]={reward = "default:axe_wood", count=5, description = "craft 5 saplings",
			on_completed = function(pos,name) 
				minetest.chat_send_player(name,"#SKYBLOCK: you can craft 'composter' from wood planks and use it to make more dirt. Look in craft guide for craft recipe.")
				skyblock.tutorial.change_text(name,"Use axe to cut tree and get wood.\nFrom wood you can craft composter and use it with leaves\nto make more dirt for your island.")
				return true
			end
		}
	},
	
	on_completed = function(name) -- what to do when level completed?
		minetest.chat_send_all("#SKYBLOCK: " .. name .. " completed level 1 !" )
		
		local player = minetest.get_player_by_name(name);
		local inv = player:get_inventory();
		inv:add_item("craft",ItemStack("basic_protect:protector")) 
		minetest.chat_send_player(name,"#SKYBLOCK: congratulations! you get protector as reward. When you place it it goes 4 blocks below center of your island.")
		
		skyblock.init_level(name,2); -- start level 2
		
		local pdata = skyblock.players[name];
		local id = pdata.id; local pos = skyblock.get_island_pos(id); local meta = minetest.get_meta(pos);
		meta:set_string("infotext","ISLAND " .. id .. ": " .. name) -- ITS PLAYERS ISLAND NOW
		
		skyblock.save_data(false) --save id_queue data so that this players island is safe even if crash
	end,
}
 
 
 skyblock.quests[2] = {
	on_placenode = {
		["default:stone"]={reward = "default:iron_lump", count=100, description = "place 100 stone"} ,
		["default:dirt"]={reward = "default:papyrus", count=1, description = "place 1 dirt after you digged 100 dirt",
			on_completed = function(pos,name) 
				local player = minetest.get_player_by_name(name);
				local pdata = skyblock.players[name];
				local step = pdata["on_dignode"]["default:dirt"];
				if step<100 and step>10 then  -- so allow up to 10 dig dirts abuses before complaining
					pdata["on_dignode"]["default:dirt"] = 0 
					minetest.chat_send_player(name,"#SKYBLOCK: nice try - what you think this is? dumb skyblock? your dig dirt quest has been resetted, you noob.")
					return false 
				elseif step<100 then 
					return false
				end
				minetest.chat_send_player(name,"#SKYBLOCK: plant papyrus on dirt 3 blocks near water to grow more.")
				return true
			end
		} 
	},
	
	on_dignode = {
		["basic_protect:protector"] = {reward = "default:pick_steel", count=1, description = "place and dig protector"} ,
		["default:jungletree"]={reward = "default:stone_with_copper", count=100, description = "dig 100 jungle tree"},
		["default:dirt"]={reward = "default:coal_lump", count=100, description = "produce and dig 100 dirt without placing it",
			on_completed = function(pos,name) 
				minetest.chat_send_player(name,"#SKYBLOCK: To make more coal first craft stone_with_coal and then smelt it.")
				return true
			end
		},
	},
	
	on_craft = {
		["default:stone_with_coal"]={reward = "basic_robot:spawner", count=50, description = "craft 100 stone with coal",
			on_completed = function(pos,name) 
				minetest.chat_send_player(name,"#SKYBLOCK: You can use robot to automate your tasks ( requires programming skills). Or you can use alchemy lab.")
				local player = minetest.get_player_by_name(name);
				local inv = player:get_inventory();
				inv:add_item("craft",ItemStack("alchemy:lab")) 
				return true
			end
		
		},
		["default:stone_with_iron"]={reward = "default:jungleleaves 6", count=50, description = "craft 100 stone with iron"},
	},
	
	on_completed = function(name) -- what to do when level completed?
		minetest.chat_send_all("#SKYBLOCK: " .. name .. " completed level 2 !" )
		
		local player = minetest.get_player_by_name(name);
		local inv = player:get_inventory();
		inv:add_item("craft",ItemStack("default:water_source")) 
		minetest.chat_send_player(name,"#SKYBLOCK: congratulations! you get another water source as reward. place it diagonally to another water to make infinite water source.")
		local privs = core.get_player_privs(name); privs.fast = true; privs.robot = true; core.set_player_privs(name, privs); minetest.auth_reload()
		minetest.chat_send_player(name,"#SKYBLOCK: you got fast and robot privs (you can use up to 4 robots) as reward!")
		skyblock.init_level(name,3); -- start level 3
	end,
 }
 
 
skyblock.quests[3] = {
	
	on_craft = {
		["default:bookshelf"]={reward = "farming:rhubarb_3 3", count=10, description = "craft 10 bookshelves",
		on_completed = function(pos,name)
				minetest.chat_send_player(name,	minetest.colorize("orange", "#SKYBLOCK: FARMING: place rhubarb seed on matured composter. Be careful to insert fertilizer in composter first. Fix any weeds while growing by punching them before 5 minutes elapse."))
				return true
			end,
		},
		["farming:rhubarb_pie"]={reward = "default:diamond", count=10, description = "bake 10 Rhubarb pie"},
		["default:brick"]={reward = "moreores:mineral_silver", count=100, description = "craft 100 Brick"},
		["default:stone_with_copper"]={reward = "default:gold_lump", count=50, description = "craft 100 Stone with Copper"},
		["default:stone_with_mese"]={reward = "default:grass_1", count=25, description = "craft 50 Stone with Mese",
			on_completed = function(pos,name)
				minetest.chat_send_player(name,"#SKYBLOCK: place grass on dirt and wait. You will get green dirt which will spread around and slowly grow more grass and flowers. You can get seeds by digging grass.")
				return true
			end,
		},
	},
	
	on_placenode = {
		["basic_machines:battery_0"]={reward = "basic_machines:grinder", count=1, description = "place battery"},
		["darkage:silt"]={reward = "moreores:mineral_mithril", count=1, description = "place 1 silt while having 100 silt in inventory",
			on_completed = function(pos,name) 
				local player = minetest.get_player_by_name(name);
				local inv = player:get_inventory();
				
				if not inv:contains_item("main",ItemStack("darkage:silt 100")) then
					minetest.chat_send_player(name,"#SKYBLOCK: you need to have 100 silt blocks in inventory. Try again!")
					return false 
				end
				return true
			end
		},
		
		["default:mossycobble"]={reward = "moreores:mineral_tin", count=1, description = "place 1 Mossy Cobblestone while having 100 Mossy Cobblestone in inventory",
			on_completed = function(pos,name) 
				local player = minetest.get_player_by_name(name);
				local inv = player:get_inventory();
				
				if not inv:contains_item("main",ItemStack("default:mossycobble 100")) then
					minetest.chat_send_player(name,"#SKYBLOCK: you need to have 100 mossy cobblestone blocks in inventory. Try again!")
					return false 
				end
				return true
			end
		},
		
		["default:steelblock"]={reward = "farming:cocoa_beans 9", count=1, description = "place 1 steelblock while having 4 steelblocks in inventory",
			on_completed = function(pos,name) 
				local player = minetest.get_player_by_name(name);
				local inv = player:get_inventory();
				
				if not inv:contains_item("main",ItemStack("default:steelblock 4")) then
					minetest.chat_send_player(name,"#SKYBLOCK: you need to have 4 steel blocks in inventory. Try again!")
					return false 
				end
				return true
			end
		},
		["default:goldblock"]={reward = "default:mese_crystal", count=1, description = "place 1 goldblock while having 4 goldblocks in inventory",
			on_completed = function(pos,name) 
				local player = minetest.get_player_by_name(name);
				local inv = player:get_inventory();
				
				if not inv:contains_item("main",ItemStack("default:goldblock 4")) then
					minetest.chat_send_player(name,"#SKYBLOCK: you need to have 4 gold blocks in inventory. Try again!")
					return false 
				end
				return true
			end
		},
	},
	
	on_completed = function(name) -- what to do when level completed?
		minetest.chat_send_all("#SKYBLOCK: " .. name .. " completed level 3 !" )
		skyblock.init_level(name,4); -- start level 4
	end,
 }

 
 skyblock.quests[4] = {
	on_placenode = {
		["basic_machines:mover"]={reward = "farming:corn", count=1, description = "place mover"},
		["basic_machines:generator"]={reward = "farming:grapes", count=1, description = "place generator"},
		["basic_machines:clockgen"]={reward = "farming:blueberries", count=1, description = "place clock generator"},
		["basic_machines:autocrafter"]={reward = "farming:beans", count=1, description = "place autocrafter"},
		["basic_machines:enviro"]={reward = "farming:tomato", count=1, description = "place enviroment block"},
		["default:diamondblock"]={reward = "", count=1, description = "place 1 diamondblock while having 3167 diamondblocks in inventory",
			on_completed = function(pos,name) 
				local player = minetest.get_player_by_name(name);
				local inv = player:get_inventory();
				
				if not inv:contains_item("main",ItemStack("default:diamondblock 3167")) then
					minetest.chat_send_player(name,"#SKYBLOCK: you need to have 3167 diamond blocks in inventory. Try again!")
					return false 
				end
				return true
			end
		},
		
		["default:mese"]={reward = "", count=1, description = "place 1 meseblock while having 1000 mese blocks in inventory",
			on_completed = function(pos,name) 
				local player = minetest.get_player_by_name(name);
				local inv = player:get_inventory();
				
				if not inv:contains_item("main",ItemStack("default:mese 1000")) then
					minetest.chat_send_player(name,"#SKYBLOCK: you need to have 1000 mese blocks in inventory. Try again!")
					return false 
				end
				return true
			end
		},
		
		["default:goldblock"]={reward = "", count=1, description = "place 1 goldblock while having 1000 gold blocks in inventory",
			on_completed = function(pos,name) 
				local player = minetest.get_player_by_name(name);
				local inv = player:get_inventory();
				
				if not inv:contains_item("main",ItemStack("default:goldblock 1000")) then
					minetest.chat_send_player(name,"#SKYBLOCK: you need to have 1000 gold blocks in inventory. Try again!")
					return false 
				end
				return true
			end
		},
	},
	on_craft = {
		["basic_robot:spawner"]={reward = "farming:cocoa_beans", count=1, description = "craft robot spawner"},
	},
	
	on_completed = function(name) -- what to do when level completed?
		minetest.chat_send_all("#SKYBLOCK: " .. name .. " completed level 4 !" )
		local privs = core.get_player_privs(name); privs.puzzle = true; core.set_player_privs(name, privs); minetest.auth_reload()
		minetest.chat_send_player(name,"#SKYBLOCK: you got puzzle privs as reward! You can make your own robot games now and more.")
		skyblock.init_level(name,5); -- start level 5
	end,
}

skyblock.quests[5] = {}
 
 

--ideas: level 5: place generator in space
-- quest: get to ocean below and place block there ( move islands 500 up first)
-- to get past clouds you need to have 5 enviroment blocks in inventory! ( this allows to go through area 100-500)
-- below clouds only players with level >=5 have interact
-- reach -500 depth in ocean ( there is pressure damage in water)
-- add special ingredients you can extract from plants using 'extractor' that can help to produce more metal ores

 
skyblock.quest_types = {on_dignode = true, on_placenode = true, on_craft = true}; -- supported quest types
 
 --[[
 
DETAILED INSTRUCTIONS:

quest table structure:
skyblock.quests = {
	
	quest_type = 
	{
		[item] = 
		{
			{
				reward = ...,
				count = how many, 
				description = ..., 
				on_completed = extra checks and actions before complete, return true to complete quest
			}
		},
	},
}


NOTE: 
- on_completed allows to do more complicated quests like: 'place diamondblock while having 2 buckets of water in inventory'
- if on_completed is missing extra checks are skipped


api player data structure:

	skyblock.players[name] = { completed = how many completed?, total = how many quests to complete, quest_type = { item = {completed = false/true} }}
		
--]]
