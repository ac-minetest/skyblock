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
		minetest.set_node(pos, {name = "compost:wood_barrel_1"})
	end
end

minetest.register_node("compost:wood_barrel", {
	description = "Make dirt with composting",
	tiles = {"default_wood.png"},
	drawtype = "nodebox",
	selection_box = {type = "fixed", fixed = {-0.5,-0.5,-0.5,0.5,0.5,0.5}},
	
	node_box = {
		type = "fixed",
		fixed = {{-1/2, -1/2, -1/2, 1/2, -3/8, 1/2},
			{-1/2, -1/2, -1/2, -3/8, 1/2, 1/2},
			{3/8, -1/2, -1/2, 1/2, 1/2, 1/2},
			{-1/2, -1/2, -1/2, 1/2, 1/2, -3/8},
			{-1/2, -1/2, 3/8, 1/2, 1/2, 1/2}},
	},
	paramtype = "light",
	is_ground_content = false,
	groups = {choppy = 3,mesecon_effector_on = 1},
	sounds =  default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos); meta:set_string("infotext","place leaves on top of it and punch/activate to start composting")
	end,

	on_punch = put_dirt,
	mesecons = {effector = {action_on = put_dirt}},
})

minetest.register_node("compost:wood_barrel_1", {
	description = "Wood Barrel with compost",
	tiles = {"default_wood.png^compost_compost_1.png", "default_wood.png"},
	drawtype = "nodebox",
	
	node_box = {
		type = "fixed",
		fixed = {{-1/2, -1/2, -1/2, 1/2, -3/8, 1/2},
			{-1/2, -1/2, -1/2, -3/8, 1/2, 1/2},
			{3/8, -1/2, -1/2, 1/2, 1/2, 1/2},
			{-1/2, -1/2, -1/2, 1/2, 1/2, -3/8},
			{-1/2, -1/2, 3/8, 1/2, 1/2, 1/2},
			{-3/8, -1/2, -3/8, 3/8, 3/8, 3/8}},
	},
	paramtype = "light",
	is_ground_content = false,
	groups = {choppy = 3},
	sounds =  default.node_sound_wood_defaults(),
})

minetest.register_node("compost:wood_barrel_2", {
	description = "Wood Barrel with compost",
	tiles = {"default_wood.png^compost_compost_2.png", "default_wood.png"},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {{-1/2, -1/2, -1/2, 1/2, -3/8, 1/2},
			{-1/2, -1/2, -1/2, -3/8, 1/2, 1/2},
			{3/8, -1/2, -1/2, 1/2, 1/2, 1/2},
			{-1/2, -1/2, -1/2, 1/2, 1/2, -3/8},
			{-1/2, -1/2, 3/8, 1/2, 1/2, 1/2},
			{-3/8, -1/2, -3/8, 3/8, 3/8, 3/8}},
	},
	paramtype = "light",
	is_ground_content = false,
	groups = {choppy = 3},
	sounds =  default.node_sound_wood_defaults(),
})

local get_dirt = function(pos, node,ttl)
	minetest.set_node(pos, {name = "compost:wood_barrel"})
	pos.y = pos.y+1;
	minetest.set_node(pos, {name = "default:dirt"})
end

minetest.register_node("compost:wood_barrel_3", {
	description = "Wood Barrel",
	tiles = {"default_wood.png^compost_compost_3.png", "default_wood.png"},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {{-1/2, -1/2, -1/2, 1/2, -3/8, 1/2},
			{-1/2, -1/2, -1/2, -3/8, 1/2, 1/2},
			{3/8, -1/2, -1/2, 1/2, 1/2, 1/2},
			{-1/2, -1/2, -1/2, 1/2, 1/2, -3/8},
			{-1/2, -1/2, 3/8, 1/2, 1/2, 1/2},
			{-3/8, -1/2, -3/8, 3/8, 3/8, 3/8}},
	},
	paramtype = "light",
	is_ground_content = false,
	groups = {choppy = 3,mesecon_effector_on = 1},
	sounds =  default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos); meta:set_string("infotext","compost ready. punch to get dirt")
	end,
	
	on_punch = get_dirt,
	mesecons = {effector = {action_on = get_dirt}},
})

minetest.register_abm({
	nodenames = {"compost:wood_barrel_1"},
	interval = 40,
	chance = 5,
	action = function(pos, node, active_object_count, active_object_count_wider)
		minetest.set_node(pos, {name = "compost:wood_barrel_2"})
	end,
})

minetest.register_abm({
	nodenames = {"compost:wood_barrel_2"},
	interval = 40,
	chance = 5,
	action = function(pos, node, active_object_count, active_object_count_wider)
		minetest.set_node(pos, {name = "compost:wood_barrel_3"})
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