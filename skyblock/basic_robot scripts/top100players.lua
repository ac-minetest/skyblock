-- show top 100 players

if not init then	init = true  n=100	  turn.angle(0); self.label("")		local filepath = minetest.get_worldpath()..'/skyblock';	local get_data = function(name)		local file,err = _G.io.open(filepath..'/'..name, 'rb')		local pdata = {};		if not err then -- load from file			local pdatastring = file:read("*a");			file:close()			pdata = minetest.deserialize(pdatastring) or {};				if pdata.stats then 								local level = pdata.level;				if pdata.total~=0 then level = level + pdata.completed/pdata.total end				--pdata.time_played				return level, pdata.id or -1			end		end		return 0			end			local plist = minetest.get_dir_list(filepath,false);	--say(serialize(plist))		local players = {}	local sortf = function(a,b) return a[2]>b[2] end	islands = {};	for _,pname in pairs(plist) do		local stat, id = get_data(pname)		if id then 			players[#players+1] = {pname, stat, id} 			islands[#islands+1]=id		end	end	table.sort(islands);	table.sort(players,sortf)	local ret =  {}	for i = 1,math.min(#players,n) do		ret[i] = string.format("%02d %15s %d",i, players[i][1] .. " " .. math.floor(players[i][2]*100)/100, players[i][3])	end
	
	local msg = "\n TOP PRO SKYBLOCK\n\n   " .. table.concat(ret,"\n   ")	self.label(msg)
	
	-- get all players with level < 3
	ret = {};
	for i = 1,#players do
		if players[i][2]<3 then ret[#ret+1] = players[i][3] end  
	end
	book.write(1,"",table.concat(ret,",")) -- write output to book
	
			end