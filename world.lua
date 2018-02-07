-- set mapgen to singlenode
minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({mgname='singlenode', water_level=-32000})
end)

-- empty world
--TODO: maybe set transparent floor + skybox to some earth theme when player joins


local id2pos = function(id) -- given id return island position
	local g =  3/8 + math.sqrt(1/4*id+9/64)
	local g0 = math.floor(g); -- what spiral are we in?
	local ssid = 4*g0^2 - 3*g0; -- spiral start id
	local sid = id - ssid ; -- what id in that spiral?
	local h = 2*g0+1; -- spiral diameter
	local d = (h-1)/2; 
	local dp;
	if sid<d then -- which side of spiral are we in?
		dp = {0,sid};
	elseif sid<3*d then
		dp = {-(sid-d),d}
	elseif sid < 5*d then
		dp = {-2*d, d - (sid - 3*d)}
	elseif sid <= 7*d then
		dp = {-2*d+(sid-5*d),-d}
	else
		dp = {1,-d + (sid - 7*d)-1}
	end
	return {g0+dp[1], dp[2]}; -- starting position of g0-th spiral is {g0,0}
end
	

local pos2id = function(pos) -- given position in plane return island id
	local g = math.max(math.abs(pos[1]), math.abs(pos[2]));
	local id = 0; 
	local h = 2*g+1; local d = (h-1)/2;
	
	if pos[2]<0 and pos[1]>0 and math.abs(pos[1])> math.abs(pos[2]) then 
		g=g-1; h=h-2; d=d-1; id = (pos[2]+d)+ 1+ 7*d 
	elseif pos[2] == -d then
		id = (pos[1]+d)+5*d
	elseif pos[1] == -d then
		id = d-pos[2]+ 3*d
	elseif pos[2] == d then
		id = d-pos[1] + d
	else
		id = pos[2]			
	end
	return 4*g^2 - 3*g + id
end

minetest.register_chatcommand('get_id', {
	description = 'Get id for current location',
	privs = {interact = true},
	params = "",
	func = function(name, param)
		local player =  minetest.get_player_by_name(name); if not player then return end
		local pos = player:get_pos();
		local gap = skyblock.islands_gap
		local ppos = {math.floor((pos.x-skyblock.center.x)/gap+0.5),math.floor((pos.z-skyblock.center.z)/gap+0.5)};
		local id = pos2id(ppos)
		minetest.chat_send_player(name, "#SKYBLOCK: island id = " .. id)
	end,
})

skyblock.get_island_pos = function(id) -- rnd
	if not id then return end
	local p = id2pos(id);
	local gap = skyblock.islands_gap;
	return {x=skyblock.center.x + p[1]*gap,y=skyblock.center.y, z=skyblock.center.z+p[2]*gap}
end

--islands spawn


function skyblock.spawn_island(pos, player_name)
	minetest.set_node({x=pos.x, y=pos.y, z = pos.z}, {name = "default:desert_stonebrick"})
	minetest.set_node({x=pos.x+1, y=pos.y, z = pos.z}, {name = "default:dirt"})
	local meta = minetest.get_meta(pos);meta:set_string("infotext","ISLAND OF " .. player_name)
end

-- delete island near pos if there is more than 2 blocks placed 5 around spawn pos
	
skyblock.delete_island = function(pos, is_check) -- is_check: do we check for nodes, if false delete without checking
	local r = skyblock.islands_gap*0.5;	local round = math.floor;
	local ppos = {x=round(pos.x/r+0.5)*r,y=skyblock.center.y,z=round(pos.z/r+0.5)*r}
	
	local delete = true;
	
	if is_check then
		local count = #minetest.find_nodes_in_area({x=ppos.x-5,y=ppos.y-5,z=ppos.z-5}, {x=ppos.x+5,y=ppos.y+5,z=ppos.z+5}, {"default:dirt","default:dirt_with_grass"});
		if is_check and count<=1 then delete = false end -- we only have 1	dirt block!
		--minetest.chat_send_all("#SKYBLOCK: detected " .. count .. " dirt near " .. ppos.x .. " " .. ppos.y .. " " .. ppos.z)
	end
	
	if delete then
		local pos1 = {x=ppos.x-r,y=_G.skyblock.bottom+1,z=ppos.z-r}
		local pos2 = {x=ppos.x+r-1,y=ppos.y+4,z=ppos.z+r-1}
		minetest.delete_area(pos1, pos2)
	end
end


-- MAPGEN: generate floor

local vdata = {}; -- prevent unnecessary memory allocation

minetest.register_on_generated(function(minp, maxp, seed)

	if( minp.y > 0 or maxp.y < 0) then return end -- ignore mapchunks too far away from floor

	local vm, area, emin, emax

	vm, emin, emax = minetest.get_mapgen_object('voxelmanip')
	if not(vm) then	return end
	
	area = VoxelArea:new{
		MinEdge={x=emin.x, y=emin.y, z=emin.z},
		MaxEdge={x=emax.x, y=emax.y, z=emax.z},
	}
	vdata = vm:get_data()

	local cloud_y = skyblock.bottom-2
	if minp.y<=cloud_y and maxp.y>=cloud_y then -- only if mapchunk contains floor
		local id_cloud = minetest.get_content_id('default:cloud')
		for x=minp.x,maxp.x do
			for z=minp.z,maxp.z do
				vdata[area:index(x,cloud_y,z)] = id_cloud
			end
		end
	end
	
	vm:set_data(vdata)
	vm:calc_lighting(emin,emax)
	vm:write_to_map(vdata)
	vm:update_liquids()
end) 