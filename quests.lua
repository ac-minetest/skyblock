 

skyblock.quests = {}

skyblock.quests[1] = { -- level 1
	on_dignode = {
		["default:dirt"]={reward = "default:leaves 6", count=10, description = "dig 10 dirt"},
		["default:tree"]={reward = "default:water_source", count=16, description = "dig 16 tree"} 
	},
	
	on_placenode = {
		["default:dirt"]={reward = "default:stick 5", count=10, description = "place 10 dirt"} 
	},
	
	on_craft = {
		["compost:wood_barrel"]={reward = "default:lava_source", count=16, description = "craft 16 composters and produce 32 dirt",
		on_completed = function(pos,name) 
			local player = minetest.get_player_by_name(name);
			local inv = player:get_inventory();
			if not inv:contains_item("main",ItemStack("default:dirt 32")) then
				minetest.chat_send_player(name,"#SKYBLOCK: you need to have 32 dirt in inventory to complete this quest!")
				return false
			end
			return true
		end
		},
		["default:furnace"]={reward = "default:axe_steel", count=4, description = "craft 4 furnace"},
		["default:sapling"]={reward = "default:axe_wood", count=5, description = "craft 5 saplings"}
	},
	
	on_completed = function(name) -- what to do when level completed?
		minetest.chat_send_all("#SKYBLOCK: " .. name .. " completed level 1 !" )
		
		local player = minetest.get_player_by_name(name);
		local inv = player:get_inventory();
		inv:add_item("craft",ItemStack("basic_protect:protector")) 
		minetest.chat_send_player(name,"#SKYBLOCK: congratulations! you get protector as reward.")
		
		skyblock.init_level(name,2); -- start level 2
		
	end,
}
 
 
 skyblock.quests[2] = {
	on_placenode = {
		["default:stone"]={reward = "default:iron_lump", count=100, description = "place 100 stone"} ,
		["default:dirt"]={reward = "", count=1, description = "place 1 dirt after you digged 100 dirt",
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
				return true
			end
		} 
	},
	
	on_dignode = {
		["basic_protect:protector"] = {reward = "default:pick_steel", count=1, description = "place and dig protector"} ,
		["default:jungletree"]={reward = "default:stone_with_copper", count=100, description = "dig 100 jungle tree"},
		["default:dirt"]={reward = "default:coal_lump", count=100, description = "dig 100 dirt"} 
	},
	
	on_craft = {
		["default:stone_with_coal"]={reward = "basic_robot:spawner", count=50, description = "craft 100 stone with coal"},
		["default:stone_with_iron"]={reward = "default:jungleleaves 6", count=50, description = "craft 100 stone with iron"},
	},
	
	on_completed = function(name) -- what to do when level completed?
		minetest.chat_send_all("#SKYBLOCK: " .. name .. " completed level 2 !" )
		
		local player = minetest.get_player_by_name(name);
		local inv = player:get_inventory();
		inv:add_item("craft",ItemStack("default:water_source")) 
		minetest.chat_send_player(name,"#SKYBLOCK: congratulations! you get another water source as reward.")
		
		skyblock.init_level(name,3); -- start level 3
	end,
 }
 
 
skyblock.quests[3] = {
	
	on_craft = {
		["default:bookshelf"]={reward = "farming:rhubarb_3", count=4, description = "craft 4 bookshelves"},
		["farming:rhubarb_pie"]={reward = "default:grass_1", count=1, description = "bake Rhubarb pie"},
		["default:brick"]={reward = "moreores:mineral_tin", count=50, description = "craft 50 Brick"},
		["default:mossycobble"]={reward = "moreores:mineral_silver", count=50, description = "craft 50 Mossy Cobblestone"},
		["darkage:silt"]={reward = "moreores:mineral_mithril", count=50, description = "craft 50 silt"},
		["default:stone_with_copper"]={reward = "default:gold_lump", count=25, description = "craft 50 Stone with Copper"},
		["default:stone_with_mese"]={reward = "default:diamond", count=10, description = "craft 20 Stone with Mese"},
	},
	
	on_placenode = {
		["basic_machines:battery_0"]={reward = "basic_machines:grinder", count=1, description = "place battery"},
		["default:steelblock"]={reward = "default:mese_crystal", count=1, description = "place 1 steelblock while having 4 steelblocks in inventory",
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
	},
	on_craft = {
		["basic_robot:spawner"]={reward = "farming:cocoa_beans", count=1, description = "craft robot spawner"},
	},
	
	on_completed = function(name) -- what to do when level completed?
		minetest.chat_send_all("#SKYBLOCK: " .. name .. " completed level 4 !" )
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
