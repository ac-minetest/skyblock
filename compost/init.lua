-- mod compost by cd2
-- modified for skyblock by rnd

compost = {}
compost.nodes = {}

function compost.register_node(name)
	compost.nodes[name] = true
end

function compost.can_compost(name)
	if compost.nodes[name] then
		return true
	else
		return false
	end
end

-- grass
compost.register_node("default:grass_1")
compost.register_node("default:junglegrass")

-- leaves
compost.register_node("default:leaves")
compost.register_node("default:jungleleaves")


local put_dirt = function(pos,node,ttl)
	pos.y=pos.y+1;
	local nodename = minetest.get_node(pos).name
	if compost.can_compost(nodename) then
		minetest.set_node(pos, {name = "air"}); pos.y=pos.y-1;
		minetest.swap_node(pos, {name = "compost:wood_barrel_1"})
	end
end


update_composter_formspec = function(pos)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory();
	inv:set_size("nutrient",4);
	local list_name = "nodemeta:"..pos.x..','..pos.y..','..pos.z 

	local form  = 
		"size[8,6]"..			
		"list[" .. list_name .. ";nutrient;0,0;2,2;]"..
		"list[current_player;main;0,2;8,4;]"..
		"listring[context;nutrient]"..
		"listring[current_player;main]"
	meta:set_string("formspec", form);
end

minetest.register_node("compost:wood_barrel", {
	description = "Empty Wooden barrel - Make dirt by composting",
	tiles = {"default_wood.png"},
	drawtype = "mesh",
	mesh = "compost_barrel_empty.obj",
	paramtype = "light",
	is_ground_content = false,
	groups = {choppy = 3,mesecon_effector_on = 1},
	sounds =  default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos); meta:set_string("infotext","place leaves on top of it and punch/activate to start composting")
		update_composter_formspec(pos)
	end,

	on_punch = put_dirt,
	mesecons = {effector = {action_on = put_dirt}},
})

minetest.register_node("compost:wood_barrel_1", {
	description = "Wooden Barrel with compost (1)",
	tiles = {
		"default_wood.png",
		"compost_compost.png"
	},
	drawtype = "mesh",
	mesh = "compost_barrel_full.obj",
	paramtype = "light",
	is_ground_content = false,
	groups = {choppy = 3},
	sounds =  default.node_sound_wood_defaults(),
})

minetest.register_node("compost:wood_barrel_2", {
	description = "Wooden Barrel with compost (2)",
	tiles = {
		"default_wood.png",
		"default_dirt.png^(compost_compost.png^[opacity:127)"
	},
	drawtype = "mesh",
	mesh = "compost_barrel_full.obj",
	paramtype = "light",
	is_ground_content = false,
	groups = {choppy = 3},
	sounds =  default.node_sound_wood_defaults(),
})

local get_dirt = function(pos, node,ttl)
	pos.y = pos.y+1
	if minetest.get_node(pos).name ~= "air" then return end
	pos.y = pos.y-1
	
	minetest.swap_node(pos, {name = "compost:wood_barrel"})
	pos.y = pos.y+1;
	minetest.set_node(pos, {name = "default:dirt"})
end

minetest.register_node("compost:wood_barrel_3", {
	description = "Wooden Barrel with compost (3, finished)",
	tiles = {
		"default_wood.png",
		"default_dirt.png"
	},
	drawtype = "mesh",
	mesh = "compost_barrel_full.obj",
	paramtype = "light",
	is_ground_content = false,
	groups = {choppy = 3,mesecon_effector_on = 1},
	sounds =  default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos);
		update_composter_formspec(pos)
	end,
	
	on_punch = get_dirt,
	mesecons = {effector = {action_on = get_dirt}},
})

minetest.register_abm({
	nodenames = {"compost:wood_barrel_1"},
	interval = 40,
	chance = 5,
	action = function(pos, node, active_object_count, active_object_count_wider)
		minetest.swap_node(pos, {name = "compost:wood_barrel_2"})
	end,
})

minetest.register_abm({
	nodenames = {"compost:wood_barrel_2"},
	interval = 40,
	chance = 5,
	action = function(pos, node, active_object_count, active_object_count_wider)
		minetest.swap_node(pos, {name = "compost:wood_barrel_3"})
		local meta = minetest.get_meta(pos);
		meta:set_string("infotext","Composter ready. Punch to get dirt or use it for farming - right click to insert nutrients.")
	end,
})

minetest.register_craft({
	output = "compost:wood_barrel",
	recipe = {
		{"default:wood", "", "default:wood"},
		{"default:wood", "", "default:wood"},
		{"default:wood", "stairs:slab_wood", "default:wood"}
	}
})
