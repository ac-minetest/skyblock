local S = farming.intllib

-- beans
minetest.register_craftitem("farming:orange", {
	description = S("Oranges"),
	inventory_image = "farming_orange.png",
	on_use = minetest.item_eat(4),

	on_place = function(itemstack, placer, pointed_thing)

		if minetest.is_protected(pointed_thing.under, placer:get_player_name()) then
			return
		end

		local nodename = minetest.get_node(pointed_thing.under).name
		minetest.set_node(pointed_thing.above, {name = "farming:orange_plant_1"})
		minetest.sound_play("default_place_node", {pos = pointed_thing.above, gain = 1.0})
		
		return itemstack:take_item(1)
	end
})




-- banana crop definition
local crop_def = {
	drawtype = "plantlike",
	tiles = {"orange_plant.png"},
	visual_scale = 0.25,
	paramtype = "light",
	walkable = false,
	buildable_to = true,
	sunlight_propagates = true,
	drop = {
		items = {
			{items = {'farming:orange_plant_1'}, rarity = 1},
		}
	},
	selection_box = farming.select,
	groups = {
		snappy = 3, flammable = 3, not_in_creative_inventory = 1,
		attached_node = 1, growing = 1
	},
	sounds = default.node_sound_leaves_defaults()
}

-- stages
minetest.register_node("farming:orange_plant_1", table.copy(crop_def))
crop_def.visual_scale = 0.5
minetest.register_node("farming:orange_plant_2", table.copy(crop_def))
crop_def.visual_scale = 1
minetest.register_node("farming:orange_plant_3", table.copy(crop_def))
crop_def.visual_scale = 1.5
minetest.register_node("farming:orange_plant_4", table.copy(crop_def))

-- stage 5 (final)
crop_def.visual_scale = 1.75
crop_def.groups.growing = 0
crop_def.drop = {
	items = {
		{items = {'farming:orange'}, rarity = 1},
		{items = {'farming:orange 3'}, rarity = 1},
		{items = {'farming:orange 2'}, rarity = 2},
		{items = {'farming:orange 2'}, rarity = 3},
	}
}
minetest.register_node("farming:orange_plant_5", table.copy(crop_def))
