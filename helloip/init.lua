-- rnd 2017
-- helloip country locator

helloip = {};
helloip.db = {}; -- contains world country ip data
helloip.players = {}; -- contains pairs [name] = {ip = ... , country = ... }

local database = helloip.db;

local modpath = minetest.get_modpath("helloip")

-- load csv db
local f = assert(io.open(modpath .. "/dbip-country-2017-03.csv", "r"))
local csv = f:read("*all")
f:close()


local ip2num = function(ip)
        if not ip then return 0 end
	local i1 = string.find(ip,".",1,true)
	local i2 = string.find(ip,".",i1+1,true)
	local i3 = string.find(ip,".",i2+1,true)
	local ip1 = tonumber(string.sub(ip,1,i1-1)) or 0 
	local ip2 = tonumber(string.sub(ip,i1+1,i2-1)) or 0
	local ip3 = tonumber(string.sub(ip,i2+1,i3-1)) or 0
	local ip4 = tonumber(string.sub(ip,i3+1)) or 0
	return ip1*256^3+ip2*256^2+ ip3*256+ ip4
end

local iplookup = function(ip) -- ip is as number, returns index of entry or 0
	local entry = 0
	local i1=1;
	local i3 = #database;
	local step = 0
	
	while i3-i1>0 and step < 100 do
		step = step + 1
		local i2 = math.floor((i1+i3)/2)
		
		local iplow = database[i2][1];
		local iphigh = database[i2][2];
		if ip>=iplow and ip <=iphigh then entry = i2; break; end
		if i3-i1 == 1 then break end
		
		if ip > iphigh then -- right
			i1 = i2
		else -- left
			i3 = i2
		end
	end
	
	return entry
end


print("#helloip: parsing csv")

-- parse csv into db
local step = 0; 
local i = 0
local i1,i2,i3

while i and step < 10^6 do
	step=step+1
	i1 = string.find(csv,",",i+1)
	i2 = string.find(csv,",",i1+1)
	i3 = string.find(csv, "\n", i2+1)
	if not i3 then break end
	
	local ipmin = ip2num(string.sub(csv, i+2,i1-2))
	local ipmax = ip2num(string.sub(csv, i1+2,i2-2))
	local ccode = string.sub(csv, i2+2,i3-2);
	database[step] = {ipmin,ipmax,ccode};
	i=i3
end
print("#helloip: ".. step .. " ip range entries loaded.")



-- load country codelist from ccode.txt 
-- copied as text from https://en.wikipedia.org/wiki/ISO_3166-1

local f = assert(io.open(modpath .. "/ccode.txt", "r"))
local cc = f:read("*all");f:close()
local ccodes = {}

local step = 0; 
local i = 0
local i1,i2,i3

while i and step < 10^3 do
	step=step+1
	i1 = string.find(cc," ",i+1)
	i2 = string.find(cc," ",i1+1)
	i3 = string.find(cc, "\n", i1+1)
	if not i3 then break end
	
	local cname = string.sub(cc, i+1,i1-1)
	local ccode = string.sub(cc, i1+2,i2-1)
	ccodes[ccode] = cname
	i=i3
end

minetest.register_on_joinplayer(
	function(player)
		local name = player:get_player_name();
		local ip = minetest.get_player_ip(name);
		local entry = iplookup(ip2num(ip))
		if entry > 0 then
			local hentry = database[entry] or {0,0,"?"};
			local country = ccodes[hentry[3]] or "unknown";
			local msg = "welcome " .. name .. " from " .. country;
			minetest.chat_send_all(msg); print(msg);
			player:set_nametag_attributes({text = name.." [" .. hentry[3] .. "]"}) -- changes player nametag
			helloip.players[name] = {ip = ip, country = hentry[3]}
		end
	end
)

minetest.register_chatcommand("ip", { 
	description = "",
	privs = {
		kick = true
	},
	func = function(name, param)
		
		local ip = param or "0.0.0.0";
		local _, count = string.gsub(ip, "%.", "") -- how many dots
		if count ~= 3 then ip = "0.0.0.0" end
		
		minetest.chat_send_player(name,"looking up ip " .. ip .. "=" .. ip2num(ip) )
		local entry = iplookup(ip2num(ip)) or 0
		if entry > 0 then
			local hentry = database[entry] or {0,0,"?"};
			minetest.chat_send_player(name, ccodes[hentry[3]] or "unknown")
		end
	end
});

minetest.register_chatcommand("ls", { 
	description = "",
	privs = {
		kick = true
	},
	func = function(name, param)
		
		local out = "";
		local players = minetest.get_connected_players();
		for _,player in pairs(players) do
			local name = player:get_player_name();
			local data = helloip.players[name];
			if data then
				out = out .. " " .. name .. ": " .. data.ip .. "=" .. data.country
			end
		end
		minetest.chat_send_player(name, out)		
	end
});