-- idea: explore button + require lot of essence to 'discover' certain items: sapling, iron, copper, tin, gold, mese, diamond, mithril

-- ALCHEMY by rnd (2017)

-- combine ingredients into new outputs


alchemy = {};

dofile(minetest.get_modpath("alchemy").."/items.lua")


local get_change = function( money ) -- returns change in greedy way
	local values = alchemy.essence;
	local p = {};
	for i = #values,1,-1 do
		p[i] = math.floor(money/values[i][2]);
		money = money - p[i]*values[i][2]
	end
	
	return p
end

	
local lab_make = function(pos) --try to 'make' more material in 1st slot of 'in' using essences in 'out'
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory();
	local stack = inv:get_stack("in", 1);
	local item = stack:get_name();
	if item == "" then return end
	local essence = 0;
	for i = 1,4 do
		local stack = inv:get_stack("out", i);
		local count = stack:get_count()
		local eitem = stack:get_name();
		--how much essence
		essence = essence + (alchemy.essence_values[eitem] or 0)*count;
	end
	
	local cost = alchemy.items[item]; if not cost then return end
	--adjust cost depending on upgrades
	local upgrade = 0 
	if inv:get_stack("upgrade", 1):get_name() == "alchemy:essence_upgrade" then
		upgrade = inv:get_stack("upgrade", 1):get_count();
	end
	cost = cost*math.max(1,(0.2 + 4.8/(1 + 0.05*upgrade)))  -- 1 for upgrade 100, 5 for upgrade 0
	
	local out_count = math.floor(essence/cost);
	if out_count < 1 then return end
	
	local remainder = essence - cost*out_count;
	
	inv:add_item("in",ItemStack(item.. " " ..  out_count))
	local p = get_change( remainder );
	
	-- set inventory to containt remainder of essence
	local values = alchemy.essence;
	for i = 1, #values do
		if p[i]>0 then
			inv:set_stack("out",i,ItemStack(values[i][1].. " " ..  p[i]))
		else
			inv:set_stack("out",i,ItemStack(""))
		end
	end
	
	for i = #values+1,4 do
		inv:set_stack("out",i,ItemStack(""))
	end
	
	
end


local lab_break = function(pos) -- break down materials in 'in'
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory();
	for j = 1,4 do
		local stack = inv:get_stack("in", j);
		local item = stack:get_name();
		if item~="" then
			local essence = (alchemy.items[item] or 1)*stack:get_count();
			local p = get_change(essence ); -- essence of item in spot j
			-- require 1 energy to break 1 gold (250 essence)
			local fuel_cost = math.floor(essence/250); if fuel_cost<1 then fuel_cost = 1 end
			local fuel_stack = ItemStack("alchemy:essence_energy " .. fuel_cost);
			if not inv:contains_item("fuel", fuel_stack) then
				local text = "not enough energy, need " .. fuel_cost .. " cells."
				meta:set_string("infotext", text)
				minetest.show_formspec(
					meta:get_string("owner"),"alchemy_help","size[5.5,5]".."textarea[0.,0;6.1,6;alchemy_help;ALCHEMY;" .. minetest.formspec_escape(text) .. "]"
				)
				return
			else
				inv:remove_item("fuel", fuel_stack)
				meta:set_string("infotext","")
			end
			
			inv:set_stack("in",j,ItemStack(""))
			
			local values = alchemy.essence;
			for i = 1, #values do
				if p[i]>0 then
					inv:add_item("out",ItemStack(values[i][1].. " " ..  p[i]))
				end
			end
		end
	end
end


minetest.register_abm({ -- very slowly create energy
	nodenames = {"alchemy:lab"},
	neighbors = {},
	interval = 30,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local meta = minetest.get_meta(pos);

		local inv = meta:get_inventory();
		local upgrade = 0;
		if inv:get_stack("upgrade", 1):get_name() == "alchemy:essence_upgrade" then
			upgrade = inv:get_stack("upgrade", 1):get_count();
		end
		
		local count = 1 + upgrade
		local stack = ItemStack("alchemy:essence_energy " .. count)
		inv:add_item("fuel", stack)
	end
})


local lab_update_meta = function(pos)
		local meta = minetest.get_meta(pos);
		local list_name = "nodemeta:"..pos.x..','..pos.y..','..pos.z 
	
		local form  = 
			"size[8,6.75]"..			
			"button[0,2;2.,0.75;ibreak;BREAK]"..
			"button[6,2;2.,0.75;fuel;FUEL]"..
			"button[3,2;2.,0.75;make;MAKE]"..
			"label[0,-0.4.;MATERIAL]"..
			"list[" .. list_name .. ";in;0,0;2,2;]"..
			"label[3,-0.4.;ESSENCE]"..
			"list[" .. list_name .. ";out;3,0;2,2;]"..
			"image[2,0.;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
			"image[2,1.;1,1;gui_furnace_arrow_bg.png^[transformR90]"..
			"label[6,-0.4.;UPGRADE]"..
			"list[" .. list_name .. ";upgrade;6,0;1,1;]"..
			"button[6.,1;2,1;upgrade;".. minetest.colorize("red","HELP") .. "]"..
			"list[current_player;main;0,3;8,4;]"..
			"listring[context;in]"..
			"listring[current_player;main]"..
			"listring[context;out]"..
			"listring[current_player;main]"
		meta:set_string("formspec", form);
end


minetest.register_node("alchemy:lab", {
	description = "Alchemy laboratory",
	tiles = {"default_steel_block.png","default_steel_block.png","alchemy_lab.png","alchemy_lab.png","alchemy_lab.png","alchemy_lab.png"},
	groups = {cracky=3, mesecon_effector_on = 1},
	sounds = default.node_sound_wood_defaults(),
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos);
		meta:set_string("infotext", "Alchemy: To operate it insert materials or essences.")
		meta:set_string("owner", placer:get_player_name());
		local inv = meta:get_inventory();
		inv:set_size("in",4);
		inv:set_size("out",4); -- dusts here
		inv:set_size("upgrade",1);
		inv:set_size("fuel",32);
	end,
	
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos);
		local privs = minetest.get_player_privs(player:get_player_name());
		if minetest.is_protected(pos, player:get_player_name()) and not privs.privs then return end -- only owner can interact with recycler
		lab_update_meta(pos);
	end,
	
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos);
		local privs = minetest.get_player_privs(player:get_player_name());
		if meta:get_string("owner")~=player:get_player_name() and not privs.privs then return 0 end
		return stack:get_count();
	end,
	
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local privs = minetest.get_player_privs(player:get_player_name());
		if minetest.is_protected(pos, player:get_player_name()) and not privs.privs then return 0 end 
		return stack:get_count();
	end,
	
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0;
	end,
	
	mesecons = {effector = { 
		action_on = function (pos, node,ttl) 
			if type(ttl)~="number" then ttl = 1 end
			if ttl<0 then return end -- machines_TTL prevents infinite recursion
			local meta = minetest.get_meta(pos);
			if meta:get_int("mode") == 2 then 
				lab_make(pos)
			else
				lab_break(pos)
			end
		end
		}
	},
	
	on_receive_fields = function(pos, formname, fields, sender) 
		
		if minetest.is_protected(pos, sender:get_player_name())  then return end 
		local meta = minetest.get_meta(pos);
		
		if fields.make then
			lab_make(pos);
			meta:set_int("mode",2)
			return
		end
		
		if fields.ibreak then
			lab_break(pos);
			meta:set_int("mode",1)
			return
		end
		
		if fields.fuel then
			local meta = minetest.get_meta(pos);
		local list_name = "nodemeta:"..pos.x..','..pos.y..','..pos.z 
	
			local form  = 
			"size[8,8]"..
			"label[0,-0.4;INSERT ENERGY ESSENCE AS FUEL]"..
			"list[" .. list_name .. ";fuel;0,0;8,4;]"..
			"list[current_player;main;0,4.25;8,4;]"..
			"listring[context;fuel]"..
			"listring[current_player;main]"..
			"listring[context;fuel]"
		
			minetest.show_formspec(
				sender:get_player_name(),"alchemy_fuel",form
			)
			return
		end
		
		if fields.upgrade then
			local text = minetest.colorize("yellow","1.BREAK") .."\nPlace items in left window (MATERIALS) and use 'break' to transmute them into essences.\n\n"..
			minetest.colorize("yellow","2.MADE") .."\nPlace essences in right window (ESSENCES), place item to be created in left window (1st position) and use 'make'.\n\n"..
			minetest.colorize("red","3.DISCOVER") .."\nif you insert enough essence you can discover new materials.\n\n"..
			"Make process will be more effective if you place upgrade essences in upgrade window. cost factor is 0.2 + 4.8/(1 + 0.05*upgrade)\n\n" ..
			"To break materials you need 1 energy essence for every 250 essence. Energy essence is produced at rate (1+upgrade) by alchemy lab every 1/2 minute\n\n"..
			"There are 4 kinds of essences: low (1), medium (50), high(2500) and upgrade(125000)."
			
			local meta = minetest.get_meta(pos);
			local level = meta:get_int("level");-- discovery level
			local discovery = alchemy.discoveries[level] or alchemy.discoveries[0]
			
			minetest.show_formspec(
				sender:get_player_name(),"alchemy_help:" .. minetest.pos_to_string(pos), "size[5.5,5]".."textarea[0.,0;6.1,5.5;alchemy_help;ALCHEMY HELP;" .. minetest.formspec_escape(text) .. "]"..
				"button_exit[0,4.75;5.5,0.75;discover;" .. minetest.colorize("red","DISCOVER " .. level .. " : ".. discovery.item .. " (cost " .. discovery.cost .. ")") .."]"
			)
			return
		end
		
	end,

})


minetest.register_on_player_receive_fields(
	function(player, formname, fields)
			
		local fname = "alchemy_help:";
		if string.sub(formname,1, string.len(fname)) ~= fname then return end
		
		if fields.discover then
			local pos = minetest.string_to_pos(string.sub(formname, string.len(fname)+1));
			local meta = minetest.get_meta(pos);
			local level = meta:get_int("level") or 0;-- discovery level
			local discovery = alchemy.discoveries[level] or alchemy.discoveries[0];
			local cost = discovery.cost;
			
			
			local inv = meta:get_inventory();
			local item = discovery.item;

			local essence = 0;
			for i = 1,4 do
				local stack = inv:get_stack("out", i);
				local count = stack:get_count()
				local eitem = stack:get_name();
				--how much essence
				essence = essence + (alchemy.essence_values[eitem] or 0)*count;
			end
			
			if essence<cost then 
				minetest.chat_send_player(player:get_player_name(),"#ALCHEMY: you need at least " .. cost .. " essence, you have only " .. essence)
				return 
			end
			
			local remainder = essence - cost;
	
			inv:add_item("in",ItemStack(item))
			level = level+1;
			if alchemy.discoveries[level] then meta:set_int("level",level);minetest.chat_send_player(player:get_player_name(),"#ALCHEMY: successfuly discovered " .. item .. "!") end
			
			local p = get_change( remainder );
			
			-- set inventory to containt remainder of essence
			local values = alchemy.essence;
			for i = 1, #values do
				if p[i]>0 then
					inv:set_stack("out",i,ItemStack(values[i][1].. " " ..  p[i]))
				else
					inv:set_stack("out",i,ItemStack(""))
				end
			end
			
			for i = #values+1,4 do
				inv:set_stack("out",i,ItemStack(""))
			end
		
			return;
		end
	end)


minetest.register_craft({
	output = "alchemy:lab",
	recipe = {
		{"default:steel_ingot","default:goldblock","default:steel_ingot"},
		{"default:steel_ingot","default:diamondblock","default:steel_ingot"},
		{"default:steel_ingot","default:steel_ingot","default:steel_ingot"},
		
	}
})


-- ESSENCES

minetest.register_craftitem("alchemy:essence_low", {
	description = "Low essence",
	inventory_image = "alchemy_essence_low.png",
	stack_max = 30000,
})

minetest.register_craftitem("alchemy:essence_medium", {
	description = "Medium essence",
	inventory_image = "alchemy_essence_medium.png",
	stack_max = 30000,	
})

minetest.register_craftitem("alchemy:essence_high", {
	description = "High essence",
	inventory_image = "alchemy_essence_high.png",
	stack_max = 30000,
})

minetest.register_craftitem("alchemy:essence_upgrade", {
	description = "Upgrade essence",
	inventory_image = "alchemy_essence_upgrade.png",
	stack_max = 30000,
})

minetest.register_craftitem("alchemy:essence_energy", {
	description = "energy essence",
	inventory_image = "energy_essence.png",
	stack_max = 64000,
})