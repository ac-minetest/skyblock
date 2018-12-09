--Basic protect by rnd, 2016 -- adapted for skyblock!

-- features: 
-- super fast protection checks with caching
-- no slowdowns due to large protection radius or larger protector counts
-- shared protection: just write players names in list, separated by spaces

--local protector = {};
basic_protect = {};
basic_protect.radius = 32; -- by default protects 20x10x20 chunk, protector placed in center at positions that are multiplier of 20,20 (x,y,z)
local enable_craft = true; -- enable crafting of protector


-- GHOST TOWN: OLD AREAS SWAPPING
local enable_swapping = false
basic_protect.swap = {}; -- swap area for old houses that are not "nice", data is as table {owner_name, timestamp}
-- after 1 week if build area inside -200,200 around spawn is not rated nice it gets moved to swap area and original area is flattened
-- if this is full oldest build there gets replaced by new one
-- implementation details:
-- insertion : by looping and selecting first free to insert, if none it selects oldest one
-- removal: just replace swap data with {"",0}

basic_protect.swap_size = 15 -- 15x15 = 225 free positions in swap area (ghost town)
basic_protect.swap_pos = {x=380,y=0,z=80}; -- where first protector in swap area will be positioned, coordinates should be multiples of protect radius (default 20), vertically 2x20 = 40
basic_protect.swap_range = 200; -- all protectors inside this around 0 0 are subject to this
basic_protect.swap_timeout = 2*3600*24*7; -- time after which protector is considered "old", default 2 weeks
--------


basic_protect.cache = {};
local round = math.floor;
local protector_position = function(pos) 
	local r = basic_protect.radius;
	local ry = 2*r;
	return {x=round(pos.x/r+0.5)*r,y=round(pos.y/ry+0.5)*ry,z=round(pos.z/r+0.5)*r};
end


local function check_protector (p, digger) -- is it protected for digger at this protector?

	local meta = minetest.get_meta(p);
	local owner = meta:get_string("owner");
	if digger~=owner then 
		--check for shared protection
		local shares = meta:get_string("shares");
		for word in string.gmatch(shares, "%S+") do
			if digger == word then
				return false;
			end
		end
		minetest.chat_send_player(digger,"#PROTECTOR: this area is owned by " .. owner);
		return true;
	else
		return false;
	end

end

--check if position is protected
local old_is_protected = minetest.is_protected
function minetest.is_protected(pos, digger)
	local p = protector_position(pos);
	local is_protected = true;
	
	if not basic_protect.cache[digger] then -- cache current check for faster future lookups
		
		local updatecache = true;
		
		if minetest.get_node(p).name == "basic_protect:protector" then 
			is_protected = check_protector (p, digger)
		else
			if minetest.get_node(p).name == "ignore" then 
				is_protected=true
				updatecache = false
			else
				is_protected = old_is_protected(pos, digger);
			end
		end
		if updatecache then
			basic_protect.cache[digger] = {pos = {x=p.x,y=p.y,z=p.z}, is_protected = is_protected} 
		end
	
	else -- look up cached result
	
		local p0 = basic_protect.cache[digger].pos;
		if (p0.x==p.x and p0.y==p.y and p0.z==p.z) then -- already checked, just lookup
			is_protected = basic_protect.cache[digger].is_protected;
		else -- another block, we need to check again
			
			local updatecache = true;
			if minetest.get_node(p).name == "basic_protect:protector" then 
				is_protected = check_protector (p, digger)
			else
				if minetest.get_node(p).name == "ignore" then  -- area not yet loaded
					is_protected=true; updatecache = false;
					minetest.chat_send_player(digger,"#PROTECTOR: chunk " .. p.x .. " " .. p.y .. " " .. p.z .. " is not yet completely loaded");
				else
					is_protected = old_is_protected(pos, digger);
				end
			end
			if updatecache then 
				basic_protect.cache[digger] = {pos = {x=p.x,y=p.y,z=p.z}, is_protected = is_protected}; -- refresh cache;
			end
		end
	end

	if is_protected then -- DEFINE action for trespassers here
		
		--teleport offender
		if basic_protect.cache[digger] then
			local tpos = basic_protect.cache[digger].tpos;
			if not tpos then 
				local meta = minetest.get_meta(p);
				local xt = meta:get_int("xt"); local yt = meta:get_int("yt"); local zt = meta:get_int("zt");
				tpos = {x=xt,y=yt,z=zt};
			end
			
			
			if (tpos.x~=p.x or tpos.y~=p.y or tpos.z~=p.z) then
				local player = minetest.get_player_by_name(digger);
				if minetest.get_node(p).name == "basic_protect:protector" then
					if player then player:setpos(tpos) end;
				end
			end
		end
		
	end
	
	return is_protected;
end

local update_formspec = function(pos)
	local meta = minetest.get_meta(pos);
	local shares = meta:get_string("shares");
	local tpos = meta:get_string("tpos");
	--local subfree = meta:get_string("subfree");
	--if subfree == "" then subfree = "0 0 0 0 0 0" end
	
	if tpos == "" then 
		tpos = "0 0 0" 
	end
	meta:set_string("formspec",
					"size[5,5]"..
					"label[-0.25,-0.25; PROTECTOR]"..
					"field[0.25,1;5,1;shares;Write in names of players you want to add in protection ;".. shares .."]"..
					"field[0.25,2;5,1;tpos;where to teleport intruders - default 0 0 0 ;".. tpos .."]"..
					--"field[0.25,3;5,1;subfree;specify free to dig sub area x1 y1 z1 x2 y2 z2 - default 0 0 0 0 0 0;".. subfree .."]"..
					"button_exit[4,4.5;1,1;OK;OK]"
					);
end

basic_protect.protect_new = function(p,name)	
	
	--skyblock by rnd, check if player tries to protect other ppl island
	if skyblock and skyblock.players and skyblock.get_island_pos then
		local skyid = skyblock.players[name].id;
		local skypos = skyblock.get_island_pos(skyid);
		local dist = math.max(math.abs(p.x-skypos.x),math.abs(p.z-skypos.z));
		if dist>=skyblock.islands_gap or p.y<500 then 
			local privs = minetest.get_player_privs(name);
			if not privs.kick then 
				minetest.chat_send_player(name, "#PROTECTOR: you can only protect empty space or your island or above it OR above height 500")
				minetest.set_node(p,{name = "air"}) -- clear protector
				return
			end
		end
	end

	local meta = minetest.get_meta(p);
	meta:set_string("owner",name);
	meta:set_int("xt",p.x);meta:set_int("yt",p.y);meta:set_int("zt",p.z);
	meta:set_string("tpos", "0 0 0");
	meta:set_int("timestamp", minetest.get_gametime());
	-- yyy testing!
	--if minetest.get_player_privs(name).kick then meta:set_int("nice",1) end -- moderator buildings are automatically "nice"
	
	minetest.chat_send_player(name, "#PROTECTOR: protected new area, protector placed at(" .. p.x .. "," .. p.y .. "," .. p.z .. "), area size " .. basic_protect.radius .. "x" .. basic_protect.radius .. " , 2x more in vertical direction.  Say /unprotect to unclaim area.. ");
	if p.y == 0 and  math.abs(p.x) < basic_protect.swap_range and math.abs(p.z) < basic_protect.swap_range then
		minetest.chat_send_player(name, "** WARNING ** you placed protector inside ( limit " .. basic_protect.swap_range .. " ) spawn area. Make a nice building and tell moderator about it or it will be moved to ghost town after long time. ");
	end
	
	meta:set_string("infotext", "property of " .. name);
	
	if #minetest.get_objects_inside_radius(p, 1)==0 then 
		minetest.add_entity({x=p.x,y=p.y,z=p.z}, "basic_protect:display")
	end
	local shares = "";
	update_formspec(p);
	basic_protect.cache = {}; -- reset cache
end

minetest.register_node("basic_protect:protector", {
	description = "Protects a rectangle area of size " .. basic_protect.radius,
	tiles = {"basic_protector.png","basic_protector_down.png","basic_protector_down.png","basic_protector_down.png","basic_protector_down.png","basic_protector_down.png"},
	--drawtype = "allfaces",
	--paramtype = "light",
	param1=1,
	groups = {oddly_breakable_by_hand=2},
	sounds = default.node_sound_wood_defaults(),
	on_place = function(itemstack, placer, pointed_thing)
		local pos = pointed_thing.under;
		local name = placer:get_player_name();
		local r = basic_protect.radius;
		local p = protector_position(pos);
		if minetest.get_node(p).name == "basic_protect:protector" then
			local meta = minetest.get_meta(p);
			minetest.chat_send_player(name,"#PROTECTOR: protector already at " .. minetest.pos_to_string(p) .. ", owned by " .. meta:get_string("owner"));
			local obj = minetest.add_entity({x=p.x,y=p.y,z=p.z}, "basic_protect:display");
			local luaent = obj:get_luaentity();	luaent.timer = 15; -- just 15 seconds display
			return itemstack
		end
		
		minetest.set_node(p, {name = "basic_protect:protector"});
		basic_protect.protect_new(p,name);
		
		pos.y=pos.y+1;
		minetest.set_node(pos, {name = "air"});
		itemstack:take_item(); return itemstack
	end,
	
	on_punch = function(pos, node, puncher, pointed_thing) -- for unknown reason texture is unknown
		local meta = minetest.get_meta(pos);
		local owner = meta:get_string("owner");
		local name = puncher:get_player_name();
		if owner == name or not minetest.is_protected(pos, name) then
			if #minetest.get_objects_inside_radius(pos, 1)==0 then 
				minetest.add_entity({x=pos.x,y=pos.y,z=pos.z}, "basic_protect:display")
			end
		end
	end,
	
	
	on_use = function(itemstack, user, pointed_thing)
		local ppos = pointed_thing.under;
		if not ppos then return end
		local pos = protector_position(ppos);
		local meta = minetest.get_meta(pos);
		local owner = meta:get_string("owner");
		local name = user:get_player_name();
		
		if owner == name then
			if #minetest.get_objects_inside_radius(pos, 1)==0 then 
				minetest.add_entity({x=pos.x,y=pos.y,z=pos.z}, "basic_protect:display")
			end
			minetest.chat_send_player(name,"#PROTECTOR: this is your area, protector placed at(" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ". say /unprotect to unclaim area. ");
		elseif owner~=name and minetest.get_node(pos).name=="basic_protect:protector" then
			minetest.chat_send_player(name,"#PROTECTOR: this area is owned by " .. owner .. ", protector placed at(" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ")");
		else
			minetest.chat_send_player(name,"#PROTECTOR: this area is FREE. place protector to claim it. Center is at (" .. pos.x .. "," .. pos.y .. "," .. pos.z.. ")");
		end
	end,
	
	mesecons = {effector = { 
		action_on = function (pos, node,ttl) 
			local meta = minetest.get_meta(pos);
			meta:set_int("space",0)
		end,
		
		action_off = function (pos, node,ttl) 
			local meta = minetest.get_meta(pos);
			meta:set_int("space",1)
		end,
		}
	},
	
	
    on_receive_fields = function(pos, formname, fields, player)
		local meta = minetest.get_meta(pos);
		local owner = meta:get_string("owner");
		local name = player:get_player_name();
		local privs = minetest.get_player_privs(name);
		
		if owner~= name and not privs.privs then return end
		
		if fields.OK then
			if fields.shares then
				meta:set_string("shares",fields.shares);
				basic_protect.cache = {}
			end
			
			if fields.tpos then
				meta:set_string("tpos", fields.tpos)
			    local words = {}
				for word in string.gmatch(fields.tpos, "%S+") do
					words[#words+1] = tonumber(word) or 0
				end
				
				local xt = (words[1] or 0); if math.abs(xt)>basic_protect.radius then xt = 0 end
				local yt = (words[2] or 0); if math.abs(yt)>basic_protect.radius then yt = 0 end
				local zt = (words[3] or 0); if math.abs(zt)>basic_protect.radius then zt = 0 end
				
				meta:set_int("xt", xt+pos.x)
				meta:set_int("yt", yt+pos.y)
				meta:set_int("zt", zt+pos.z)
			end
			
			update_formspec(pos)
		end
    end,
	
	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos);
		local owner = meta:get_string("owner");
		local name = player:get_player_name();
		local privs = minetest.get_player_privs(name)
		if owner~= player:get_player_name() and not privs.privs then return false end
		return true
	end
});



-- entities used to display area when protector is punched

local x = basic_protect.radius/2;
local y = 2*x;
minetest.register_node("basic_protect:display_node", {
	tiles = {"area_display.png"},
	use_texture_alpha = false,
	walkable = false,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			
			{-(x+.55), -(y+.55), -(x+.55), -(x+.45), (y-1+.55), (x-1+.55)},-- sides
			{-(x+.55), -(y+.55), (x-1+.45), (x-1+.55), (y-1+.55), (x-1+.55)},
			{(x-1+.45), -(y+.55), -(x+.55), (x-1+.55), (y-1+.55), (x-1+.55)},
			{-(x+.55), -(y+.55), -(x+.55), (x-1+.55), (y-1+.55), -(x+.45)},
			
			{-(x+.55), (y-1+.45), -(x+.55), (x-1+.55), (y-1+.55), (x-1+.55)},-- top
			
			{-(x+.55), -(y+.55), -(x+.55), (x-1+.55), -(y+.45), (x-1+.55)},-- bottom
			
			{-.55,-.55,-.55, .55,.55,.55},-- middle (surround protector)
		},
	},
	selection_box = {
		type = "regular",
	},
	paramtype = "light",
	groups = {dig_immediate = 3, not_in_creative_inventory = 1},
	drop = "",
})



minetest.register_entity("basic_protect:display", {
	physical = false,
	collisionbox = {0, 0, 0, 0, 0, 0},
	visual = "wielditem",
	visual_size = {x = 1.0 / 1.5, y = 1.0 / 1.5},
	textures = {"basic_protect:display_node"},
	timer = 30,
	
	on_step = function(self, dtime)

		self.timer = self.timer - dtime

		if self.timer < 0 then
			self.object:remove()
		end
	end,
})

-- CRAFTING
if enable_craft then
	minetest.register_craft({
		output = "basic_protect:protector",
		recipe = {
			{"default:stone", "default:stone","default:stone"},
			{"default:stone", "default:steel_ingot","default:stone"},
			{"default:stone", "default:stone", "default:stone"}
		}
	})
end


minetest.register_chatcommand("unprotect", { 
	description = "Unprotects current area",
	privs = {
		interact = true
	},
	func = function(name, param)
		local privs = minetest.get_player_privs(name);
		local player = minetest.get_player_by_name(name);
		local pos = player:getpos();
		local ppos = protector_position(pos);
		
		if minetest.get_node(ppos).name == "basic_protect:protector" then
			local meta = minetest.get_meta(ppos);
			local owner = meta:get_string("owner");
			if owner == name then
				minetest.set_node(ppos,{name = "air"});
				local inv = player:get_inventory();
				inv:add_item("main",ItemStack("basic_protect:protector"));
				minetest.chat_send_player(name, "#PROTECTOR: area unprotected ");
			end
		end
	end
})

minetest.register_chatcommand("protect", { 
	description = "Protects current area",
	privs = {
		interact = true
	},
	func = function(name, param)
		local privs = minetest.get_player_privs(name);
		local player = minetest.get_player_by_name(name);
		if not player then return end
		local pos = player:getpos();
		local ppos = protector_position(pos);
		
		if minetest.get_node(ppos).name == "basic_protect:protector" then
			local meta = minetest.get_meta(ppos);
			local owner = meta:get_string("owner");
			if owner == name then
				if #minetest.get_objects_inside_radius(ppos, 1)==0 then 
					minetest.add_entity({x=ppos.x,y=ppos.y,z=ppos.z}, "basic_protect:display")
				end
				minetest.chat_send_player(name,"#PROTECTOR: this is your area, protector placed at(" .. ppos.x .. "," .. ppos.y .. "," .. ppos.z .. "). say /unprotect to unclaim area. ");
			end
		else
			local inv = player:get_inventory();
			local item = ItemStack("basic_protect:protector");
			if inv:contains_item("main",item) then
				minetest.set_node(ppos,{name = "basic_protect:protector"})
				basic_protect.protect_new(ppos,name);
				inv:remove_item("main",item)

			end
		end
	end
})



-- GHOST TOWN : swapping of older areas

local swap = {};
swap.manip = {};

--TODO: perhaps use buffer with voxelmanip to prevent memory leaks?
--local swap_buffer = {};

swap.paste = function(pos_start,pos_end, reset) -- copy area around start and paste at end position. if reset = true then reset original area too
	-- place area to new location
	local r = basic_protect.radius*0.5; local ry = 2*r; 
	local ppos = protector_position(pos_start);
	local pos1 = {x=ppos.x-r,y=ppos.y-2*r,z=ppos.z-r}
	local pos2 = {x=ppos.x+r-1,y=ppos.y+2*r-1,z=ppos.z+r-1}
	
	-- load area data
	local manip1 = minetest.get_voxel_manip() -- VoxelManip object
	local emerged_pos1, emerged_pos2 = manip1:read_from_map(pos1, pos2) -- --Reads a chunk of map from the map containing the region formed by pos1 and pos2 
	local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2}) -- create new VoxelArea instance, needed for iterating over area in loop
	
	local data = manip1:get_data() -- Gets the data read into the VoxelManip object
	local param2data = manip1:get_param2_data();
	local cdata = {}; -- copy data used for pasting later
	local c_air = minetest.get_content_id("air");local c_dirt = minetest.get_content_id("default:dirt");

	-- copy
	local count=0;
	for i in area:iterp(pos1, pos2) do -- returns an iterator that returns indices inside VoxelArea
			local p = area:position(i); 
			count = count+1; cdata[count] =  {data[i],param2data[i],minetest.get_meta(p):to_table()}
			if reset then
				if p.y>ppos.y+1 then data[i] = c_air else data[i] = c_dirt end -- flatten original area
			end
	end
	manip1:set_data(data);manip1:write_to_map();manip1:update_map() 
	
	-- PASTING
	
	ppos = protector_position(pos_end);
	pos1 = {x=ppos.x-r,y=ppos.y-2*r,z=ppos.z-r}
	pos2 = {x=ppos.x+r-1,y=ppos.y+2*r-1,z=ppos.z+r-1}
	
	local manip2 = minetest.get_voxel_manip() -- VoxelManip object
	emerged_pos1, emerged_pos2 = manip2:read_from_map(pos1, pos2) 
	area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})
	data = manip2:get_data(); param2data = manip2:get_param2_data();
	
	-- paste
	count = 0;
	for i in area:iterp(pos1, pos2) do 
		local p = area:position(i); 
		count = count +1; local cdataentry = cdata[count];
		if cdataentry then 
			data[i] = cdataentry[1]
			param2data[i] = cdataentry[2]
			minetest.get_meta(p):from_table(cdataentry[3])
		end
		
	end
	manip2:set_data(data); manip2:set_param2_data(param2data)
	manip2:write_to_map(); manip2:update_map() 
end

		
swap.get_free_idx = function()
	local data = basic_protect.swap;
	if data == {} then return 1 end
	if #data< basic_protect.swap_size^2 then return 1+#data end -- not yet full, select next one
	
	local t=minetest.get_gametime(); local idx=1;
	for i = 1,#data do
		--  owner, timestamp, start_pos, end_pos
		if data[i] == {} then return i end
		if data[i][2]<t then t = data[i][2]; idx = i end -- select oldest
	end
	return idx
end

swap.idx2pos = function(idx) -- return position in ghosttown, idx from 1..n^2
	local i,j;
	local r = basic_protect.radius; local n = basic_protect.swap_size;
	idx = idx - 1; i = idx % n; j = (idx-i)/n;
	return {x = basic_protect.swap_pos.x + i*r, y = basic_protect.swap_pos.y, z = basic_protect.swap_pos.z + (j)*r};
end

swap.insert = function(pos,idx) -- copy area to new position & flatten original area
	local r = basic_protect.radius;	local ry = 2*r;
	local ppos = {x=round(pos.x/r+0.5)*r,y=round(pos.y/ry+0.5)*ry,z=round(pos.z/r+0.5)*r}; -- protector position
	 -- protected area is coordinates in [ppos, ppos+r), 2r for vertical
	-- determine paste position
	--TODO
	if not idx then idx = swap.get_free_idx() else idx = idx % (basic_protect.swap_size^2) end
	local n = swap.swap_size; -- n x n
	local pos_end = swap.idx2pos(idx);
	
	local meta = minetest.get_meta(ppos); local owner = meta:get_string("owner");
	if owner == "" then return end
	
	basic_protect.swap[idx] = {owner, meta:get_int("timestamp"), pos, pos_end}
	swap.paste(pos,pos_end, true)
	minetest.chat_send_all("#protector: "  .. owner .. "'s area at " .. ppos.x .. " " .. ppos.y .. " " .. ppos.z .. " moved to ghost town at " .. pos_end.x .. " " .. pos_end.y .. " " .. pos_end.z )
	
end

-- load data on server start	
--local modpath = minetest.get_modpath("basic_protect")
local modpath = minetest.get_worldpath();
local f = io.open(modpath .. "\\swap.dat", "r"); local swapstring = "";
if f then swapstring = f:read("*all") or "";f:close() end

basic_protect.swap = minetest.deserialize(swapstring) or {};

minetest.register_on_shutdown(function() -- save swap data on shutdown
	local f = assert(io.open(modpath .. "\\swap.dat", "w"))
	local swapstring = f:write(minetest.serialize(basic_protect.swap))
	f:close()
end
)

-- lbm without run_at_every_load = true didnt run at all.. weird

if enable_swapping then
	minetest.register_abm({
		name = "basic_protect:swap",
		nodenames = {"basic_protect:protector"},
		interval = 60,
		chance = 1,
		--run_at_every_load = true,
		action = function(pos, node)
			--minetest.chat_send_all("D lbm swap attempt at " .. pos.x .. " " .. pos.y .. " " .. pos.z)
			if pos.y ~= 0 then return end -- only at ground level
			local absx = math.abs(pos.x); local absz = math.abs(pos.z);
			if absx > basic_protect.swap_range or absz > basic_protect.swap_range then return end -- no swap far from spawn
			if absx < 50 and absz <  50 then return end -- skip for central spawn
			
			
			-- check the "age" of protector and do swap if its old and not "nice" 
			local meta = minetest.get_meta(pos);
			local timestamp = meta:get_int("timestamp");
			
			local nice = meta:get_int("nice");
			local t = minetest.get_gametime();
			if nice == 0 and t-timestamp> basic_protect.swap_timeout then
				local owner = meta:get_string("owner");
				if minetest.get_player_privs(owner).kick then -- skip moving moderator's area
					minetest.chat_send_all("#protector: skipped moving non-nice area at " .. pos.x .. " " .. pos.y .. " " .. pos.z .. " to ghost town, owner is moderator " .. owner)
					meta:set_int("nice",1)
					return 
				end 
				minetest.chat_send_all("#protector: moving non-nice old (age " .. (t-timestamp)/basic_protect.swap_timeout .. " timeouts, owner " .. owner ..  ") into ghost town");
				swap.insert(pos);
				return;
			end
		end,
	})
end

minetest.register_chatcommand("mark_nice", { 
	description = "Mark nearby protector as nice",
	privs = {
		kick = true
	},
	func = function(name, param)
		local player = minetest.get_player_by_name(name); if not player then return end
		local pos = player:getpos(); 
		local r = basic_protect.radius;	local ry = 2*r;
		local ppos = protector_position(pos); -- protector position
		if minetest.get_node(ppos).name ~= "basic_protect:protector" then return end
		local meta = minetest.get_meta(ppos); meta:set_int("nice", 1)
		minetest.chat_send_player(name,"#protector: area " .. ppos.x .. " " .. ppos.y .. " " .. ppos.z .. " marked as nice.");
	end
	}
)

minetest.register_chatcommand("swap_insert", { 
	description = "swap_insert idx, Insert nearby protector into swap area at position idx and reset original area",
	privs = {
		privs = true
	},
	func = function(name, param)
		local player = minetest.get_player_by_name(name); if not player then return end
		local pos = player:getpos(); 
		local r = basic_protect.radius;	local ry = 2*r;
		local ppos = protector_position(pos)
		if minetest.get_node(ppos).name ~= "basic_protect:protector" then return end
		swap.insert(pos, tonumber(param));
	end
	}
)


minetest.register_chatcommand("swap_paste", { 
	description = "swap_paste x y z, Paste nearby area to location containing x y z",
	privs = {
		privs = true
	},
	func = function(name, param)
		local player = minetest.get_player_by_name(name); if not player then return end
		local words = {};
		for word in string.gmatch(param, "%S+") do words[#words+1] = tonumber(word) end
		if words[1] and words[2] and words[3] then else return end
		local pos1 = player:getpos();
		local pos2 = {x = words[1], y = words[2], z= words[3]}
		swap.paste(pos1,pos2);
		minetest.chat_send_all("#protector: area at " .. pos1.x .. " " .. pos1.y .. " " .. pos2.z .. " pasted to " .. pos2.x .. " " .. pos2.y .. " " .. pos2.z )
	end
	}
)


minetest.register_chatcommand("swap_restore", { 
	description = "swap_restore, regenerate nearby area with mapgen",
	privs = {
		privs = true
	},
	func = function(name, param)
		local player = minetest.get_player_by_name(name); if not player then return end
		local r = basic_protect.radius*0.5; local ry = 2*r; 
		local pos = player:getpos();
		local ppos = protector_position(pos);
		local pos1 = {x=ppos.x-r,y=ppos.y-2*r,z=ppos.z-r}
		local pos2 = {x=ppos.x+r-1,y=ppos.y+2*r-1,z=ppos.z+r-1}
		minetest.delete_area(pos1, pos2)
		--minetest.emerge_area(pos1, pos2)
	end
	}
)






--TODO
-- minetest.register_chatcommand("restore_nice", { 
	-- description = "Restore nearby area from swap back to the world",
	-- privs = {
		-- interact = true
	-- },
	-- func = function(name, param)
	-- end
	-- }
-- )