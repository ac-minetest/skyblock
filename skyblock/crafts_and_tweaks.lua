-- RECIPE TWEAKS
-- few borrowed from cornernote Skyblock


-- COOKING mechanics
local adjust_stone_with_ore = function(input,output,cooktime)
	minetest.register_craft({
		type = 'cooking',
		output = output,
		recipe = input,
        cooktime = cooktime
	})

	minetest.override_item(input, {drop=input})
end

if minetest.registered_nodes["moreores:mineral_mithril"] then
	adjust_stone_with_ore("moreores:mineral_mithril","moreores:mithril_lump",1500)
	adjust_stone_with_ore("moreores:mineral_silver","moreores:silver_lump",30)
	
	minetest.register_craft({
		output = 'moreores:mineral_silver 2',
		recipe = {
			{'moreores:silver_lump'},
			{'default:stone'},
		}
	})

end

adjust_stone_with_ore("default:stone_with_diamond","default:diamond",1000)
adjust_stone_with_ore("default:stone_with_mese","default:mese_crystal",500)
adjust_stone_with_ore("default:stone_with_gold","default:gold_lump",50)
adjust_stone_with_ore("default:stone_with_copper","default:copper_lump",16)
adjust_stone_with_ore("default:stone_with_iron","default:iron_lump",16)

-- WARNING: this line causes SILENT NO ERROR SERVER CRASH on minetest 0.4.16
if minetest.clear_craft then minetest.clear_craft({output = "moreblocks:coal_stone"}) end -- remove possibly conflicting recipe

adjust_stone_with_ore("default:stone_with_coal","default:coal_lump",8)
adjust_stone_with_ore("default:stone_with_tin","default:tin_lump",16)
	



-- DIGGING speeds
local function adjust_dig_speed(name,factor)
	local table = minetest.registered_items[name];
	if not table then return end
	local table2 = {};
	for i,v in pairs(table) do table2[i] = v end
		
	for i,v in pairs(table2.tool_capabilities.groupcaps.cracky.times) do
		table2.tool_capabilities.groupcaps.cracky.times[i] = v*factor
	end	
	
	minetest.register_tool(":"..name, table2)	
end



minetest.after(1,
function()
	adjust_dig_speed("default:pick_wood",5)
	adjust_dig_speed("default:pick_stone",3)
	adjust_dig_speed("default:pick_steel", 3)
	adjust_dig_speed("default:pick_bronze",2)
	adjust_dig_speed("default:pick_mese",2)
	adjust_dig_speed("default:pick_diamond",1)
	adjust_dig_speed("moreores:pick_silver",2)
	adjust_dig_speed("moreores:pick_mithril",1)
end
)

-- UNBUILDABLE LIQUIDS

local function make_it_unbuildable(name)
	
	local table = minetest.registered_nodes[name]; if not table then return end
	local table2 = {}
	for i,v in pairs(table) do
		table2[i] = v
	end
	table2.buildable_to = false
	minetest.register_node(":"..name, table2)
end 

minetest.after(0, function()
	make_it_unbuildable("default:water_source")
	make_it_unbuildable("default:water_flowing")
	make_it_unbuildable("default:lava_source")
	make_it_unbuildable("default:lava_flowing")
end
)


-- desert_stone
minetest.register_craft({
	output = 'default:desert_stone',
	recipe = {
		{'default:desert_sand', 'default:desert_sand'},
		{'default:desert_sand', 'default:desert_sand'},
	}
})

-- mossycobble
minetest.register_craft({
	output = 'default:mossycobble',
	recipe = {
		{'group:flora'},
		{'default:cobble'},
	}
})

-- stone_with_coal
minetest.register_craft({
	output = 'default:stone_with_coal 2',
	recipe = {
		{'default:coal_lump'},
		{'default:wood'},
		{'default:stone'},
	}
})

-- stone_with_iron
minetest.register_craft({
	output = 'default:stone_with_iron 2',
	recipe = {
		{'basic_machines:iron_extractor'},
		{'default:stone'},
	}
})


-- stone_with_copper
minetest.register_craft({
	output = 'default:stone_with_copper 2',
	recipe = {
		{'basic_machines:copper_extractor'},
		{'default:stone'},
	}
})


minetest.register_craft({
	output = 'default:stone_with_tin 2',
	recipe = {
		{'basic_machines:tin_extractor'},
		{'default:stone'},
	}
})


-- stone_with_gold
minetest.register_craft({
	output = 'default:stone_with_gold 2',
	recipe = {
		{'basic_machines:gold_extractor'},
		{'default:stone'},
	}
})


-- stone_with_mese
minetest.register_craft({
	output = 'default:stone_with_mese 2',
	recipe = {
		{'basic_machines:mese_extractor'},
		{'default:stone'},
	}
})



-- stone_with_diamond
minetest.register_craft({
	output = 'default:stone_with_diamond 2',
	recipe = {
		{'basic_machines:diamond_extractor'},
		{'default:stone'},
	}
})


-- VARIOUS SKYBLOCK CRAFTS


-- locked_chest from chest
minetest.register_craft({
	output = 'default:chest_locked',
	recipe = {
		{'default:steel_ingot'},
		{'default:chest'},
	}
})

-- sapling from leaves and sticks
minetest.register_craft({
	output = 'default:sapling',
	recipe = {
		{'default:leaves', 'default:leaves', 'default:leaves'},
		{'default:leaves', 'default:leaves', 'default:leaves'},
		{'', 'default:stick', ''},
	}
})

-- junglesapling from jungleleaves and sticks
minetest.register_craft({
	output = 'default:junglesapling',
	recipe = {
		{'default:jungleleaves', 'default:jungleleaves', 'default:jungleleaves'},
		{'default:jungleleaves', 'default:jungleleaves', 'default:jungleleaves'},
		{'', 'default:stick', ''},
	}
})

-- pine_sapling from pine_needles and sticks
minetest.register_craft({
	output = 'default:pine_sapling',
	recipe = {
		{'default:pine_needles', 'default:pine_needles', 'default:pine_needles'},
		{'default:pine_needles', 'default:pine_needles', 'default:pine_needles'},
		{'', 'default:stick', ''},
	}
})

-- desert_cobble from dirt and gravel
minetest.register_craft({
	output = 'default:desert_cobble 2',
	recipe = {
		{'default:dirt'},
		{'default:gravel'},
	}
})

-- desert_sand from desert_stone
minetest.register_craft({
	output = 'default:desert_sand 4',
	recipe = {
		{'default:desert_stone'},
	}
})


-- ice from snowblock
minetest.register_craft({
	output = 'default:ice',
	recipe = {
		{'default:snowblock', 'default:snowblock'},
		{'default:snowblock', 'default:snowblock'},
	}
})

-- snowblock from ice
minetest.register_craft({
	output = 'default:snowblock 4',
	recipe = {
		{'default:ice'},
	}
})

-- glass from desert_sand
minetest.register_craft({
	type = 'cooking',
	output = 'default:glass',
	recipe = 'default:desert_sand',
})

-- TWEAKS

-- trees
local trees = {'default:tree','default:jungletree','default:pine_tree',"default:wood","default:junglewood","default:pine_wood",
"default:acacia_tree", "default:acacia_wood", "default:aspen_tree", "default:aspen_wood"}

for k,node in ipairs(trees) do
	local groups = minetest.registered_nodes[node].groups
	groups.oddly_breakable_by_hand = 0
	minetest.override_item(node, {groups = groups})
end

-- leaves
local leaves = {'default:leaves','default:jungleleaves','default:pine_needles'}
for k,node in ipairs(leaves) do
	minetest.override_item(node, {climbable = true,	walkable = false})
end

-- quickly grow sapling if there is light

local skyblock_grow_sapling = function (pos)

	local bnode = minetest.get_node({x=pos.x,y=pos.y-1,z=pos.z}).name;
	if bnode == "default:dirt" or bnode == "default:dirt_with_grass" then else 
		minetest.set_node(pos,{name = "air"})
	return end
	
	local mg_name = minetest.get_mapgen_setting("mg_name")
	local node = minetest.get_node(pos)
	if node.name == "default:sapling" then
		--minetest.log("action", "A sapling grows into a tree at "..
			--minetest.pos_to_string(pos))
		if mg_name == "v6" then
			default.grow_tree(pos, random(1, 4) == 1)
		else
			default.grow_new_apple_tree(pos)
		end
	elseif node.name == "default:junglesapling" then
		--minetest.log("action", "A jungle sapling grows into a tree at "..
			--minetest.pos_to_string(pos))
		if mg_name == "v6" then
			default.grow_jungle_tree(pos)
		else
			default.grow_new_jungle_tree(pos)
		end
	elseif node.name == "default:pine_sapling" then
		--minetest.log("action", "A pine sapling grows into a tree at "..
			--minetest.pos_to_string(pos))
		local snow = false --is_snow_nearby(pos)
		if mg_name == "v6" then
			default.grow_pine_tree(pos, snow)
		elseif snow then
			default.grow_new_snowy_pine_tree(pos)
		else
			default.grow_new_pine_tree(pos)
		end
	elseif node.name == "default:acacia_sapling" then
		--minetest.log("action", "An acacia sapling grows into a tree at "..
			--minetest.pos_to_string(pos))
		default.grow_new_acacia_tree(pos)
	elseif node.name == "default:aspen_sapling" then
		--minetest.log("action", "An aspen sapling grows into a tree at "..
			--minetest.pos_to_string(pos))
		default.grow_new_aspen_tree(pos)
	end
end


minetest.override_item('default:sapling', {
	on_construct = function(pos) minetest.get_node_timer(pos):start(60)	end,
	on_timer = skyblock_grow_sapling,
})

minetest.override_item('default:junglesapling', {
	on_construct = function(pos) minetest.get_node_timer(pos):start(600) end,
	on_timer = skyblock_grow_sapling,
})

minetest.override_item('default:pine_sapling', {
	on_construct = function(pos) minetest.get_node_timer(pos):start(600) end,
	on_timer = skyblock_grow_sapling,
})

minetest.override_item('default:acacia_sapling', {
	on_construct = function(pos) minetest.get_node_timer(pos):start(600) end,
	on_timer = skyblock_grow_sapling,
})

minetest.override_item('default:aspen_sapling', {
	on_construct = function(pos) minetest.get_node_timer(pos):start(600) end,
	on_timer = skyblock_grow_sapling,
})




-- flora spawns on dirt_with_grass
minetest.register_abm({
	nodenames = {'default:dirt_with_grass'},
	interval = 300,
	chance = 100,
	action = function(pos, node)
		pos.y = pos.y+1

		local light = minetest.get_node_light(pos)
		if not light or light < 13 then
			return
		end

		-- check for nearby
		if minetest.env:find_node_near(pos, 2, {'group:flora'}) ~= nil then
			return
		end

		if minetest.env:get_node(pos).name == 'air' then
			local rand = math.random(1,8);
			local node
			if rand==1 then
				node = 'default:junglegrass'
			elseif rand==2 then
				node = 'default:grass_1'
			elseif rand==3 then
				node = 'flowers:dandelion_white'
			elseif rand==4 then
				node = 'flowers:dandelion_yellow'
			elseif rand==5 then
				node = 'flowers:geranium'
			elseif rand==6 then
				node = 'flowers:rose'
			elseif rand==7 then
				node = 'flowers:tulip'
			elseif rand==8 then
				node = 'flowers:viola'
			end
			minetest.env:set_node(pos, {name=node})
		end
	end
})

-- remove bones
minetest.register_abm({
	nodenames = {'bones:bones'},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		minetest.env:remove_node(pos)
	end,
})


minetest.override_item('default:cobble', {
	drop = "default:gravel 2"
})



-- needed for stone generator
-- gloopblocks: pumice + gravel = 2 gravel

if minetest.get_modpath("gloopblocks") then -- special stone making if gloopblocks mod installed
	
	minetest.register_craft({
		output = 'default:cobble',
		recipe = {
			{'default:gravel','','default:gravel'},
			{'default:gravel','default:gravel','default:gravel'},
			{'default:gravel','default:gravel','default:gravel'}
		}
	})
		
	minetest.register_craft({
			type = 'cooking',
			output = "default:cobble",
			recipe = "default:gravel",
			cooktime = 1
		})
	
	--adjust cobble->stone cooktime	..
	
	minetest.clear_craft({
		type = "cooking",
		output = "default:stone",
		recipe = "default:cobble",
	})
	
	
	minetest.register_craft({
		type = "cooking",
		output = "default:stone",
		recipe = "default:cobble",
		cooktime = 4
	})
	

	minetest.register_craft({
		output = 'default:gravel 2',
		recipe = {
			{'default:gravel','gloopblocks:pumice'},
		}
	})
	
	minetest.register_craft({
		output = 'default:gravel',
		recipe = {
			{'gloopblocks:pumice','gloopblocks:pumice','gloopblocks:pumice'},
			{'gloopblocks:pumice','default:dirt','gloopblocks:pumice'},
			{'gloopblocks:pumice','gloopblocks:pumice','gloopblocks:pumice'},
		}
	})
	
	
	
	-- minetest.override_item('default:gravel', {
	-- drop = {
		-- max_items = 1,
		-- items = {
			-- {items = {'default:flint'}, rarity = 16},
			-- {items = {'default:gravel'}}
		-- }
	-- }
	-- })

end