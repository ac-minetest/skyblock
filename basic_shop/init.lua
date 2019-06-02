--[[
basic_shop by rnd, gui design by Jozet, 2018

TODO:
buying: /shop opens gui  OK
	gui basics OK
	filter OK
	buy button action OK
	sorting
selling: /sell price adds items in hand to shop OK

--]]

modname = "basic_shop";
basic_shop = {};
basic_shop.data = {}; -- {"item name", quantity, price, time_left, seller, minimal sell quantity}
basic_shop.guidata = {}; -- [name] = {idx = idx, filter = filter, sort = sort } (start index on cur. page, filter item name, sort_coloumn)
basic_shop.bank = {}; -- bank for offline players, [name] = {balance, deposit_time}, 



basic_shop.items_on_page = 8
basic_shop.maxprice = 1000000
basic_shop.time_left = 60*60*24*7; -- 1 week before shop removed/bank account reset

local filepath = minetest.get_worldpath()..'/' .. modname;
minetest.mkdir(filepath) -- create if non existent


save_shops = function()
	local file,err = io.open(filepath..'/shops', 'wb'); 
	if err then minetest.log("#basic_shop: error cant save data") return end
	file:write(minetest.serialize(basic_shop.data));file:close()
end

local player_shops = {}; --[name] = count
load_shops = function()
	local file,err = io.open(filepath..'/shops', 'rb')
	if err then minetest.log("#basic_shop: error cant load data") return end
	
	local told = minetest.get_gametime()  - basic_shop.time_left; -- time of oldest shop before timeout
	local data = minetest.deserialize(file:read("*a")) or {};file:close()
	local out = {}	
	for i = 1,#data do
		if data[i][4]>told then -- shop is recent, not too old
			out[#out+1] = data[i]
			player_shops[data[i][5]] = (player_shops[data[i][5]] or 0) + 1 -- how many shops player has
		end
	end
	basic_shop.data = out
end

local toplist = {};
load_bank = function()
	local file,err = io.open(filepath..'/bank', 'rb')
	if err then minetest.log("#basic_shop: error cant load bank data"); return end
	local data = minetest.deserialize(file:read("*a")) or {}; file:close()
	local out = {};
	local told = minetest.get_gametime() - basic_shop.time_left;
	for k,v in pairs(data) do
		if k~="_top" then
			if v[2]>told then out[k] = v end
		else 
			out[k] = v
		end
	end
	basic_shop.bank = out
	if not basic_shop.bank["_top"] then
		basic_shop.bank["_top"] = {["_min"] = ""} -- [name] = balance
	end
	toplist = basic_shop.bank["_top"];
end

local check_toplist = function(name,balance) -- too small to be on toplist -- attempt to insert possible toplist balance
	local mink = toplist["_min"]; -- minimal element on the list
	local minb = toplist[mink] or 0; -- minimal value
	if balance<minb then 
		if toplist[name] then toplist["_min"] = name; toplist[name] = balance end
		return -- too small to be on toplist
	end 
	
	local n = 0; for k,v in pairs(toplist) do n = n + 1 end
	
	local list = {};
	toplist[name] = balance
	
	if n+1>10 then toplist[mink] = nil end --remove minimal
	--more than 10, have to throw out smallest one
	
	
	minb = 10^9; mink = "" -- find new minimal element
	for k,v in pairs(toplist) do
		if k~="_min" and v<minb then mink = k minb = v end
	end
	toplist["_min"] = mink
end

local display_toplist = function()
	local out = {};
	for k,v in pairs(toplist) do
		if k ~= "_min" then
			out[#out+1] = {k,v}
		end
	end
	table.sort(out, function(a,b) return a[2]>b[2] end)
	local ret = {"TOP RICHEST"};
	for i = 1,#out do
		ret[#ret+1] = i .. ". " .. out[i][1] .. " " .. out[i][2]
	end
	minetest.chat_send_all(table.concat(ret,"\n"))
end


save_bank = function()
	local file,err = io.open(filepath..'/bank', 'wb'); 
	if err then minetest.log("#basic_shop: error cant save bank data") return end
	file:write(minetest.serialize(basic_shop.bank)); file:close()
end

minetest.after(0, function() -- problem: before minetest.get_gametime() is nil
	load_shops()
	load_bank()
end)

minetest.register_on_shutdown(function()
	save_bank()
	save_shops()
end)

get_money = function(player)
	local inv = player:get_inventory();
	local stack = inv:get_stack(modname,1);
	if not stack then return 0 end
	return tonumber(stack:to_string()) or 0
end

set_money = function(player, amount)
	local inv = player:get_inventory();
	if inv:get_size(modname)<1 then inv:set_size(modname, 2) end
	inv:set_stack(modname, 1, ItemStack(amount))
	
	check_toplist(player:get_player_name(),amount)
end


init_guidata = function(name)
	--[name] = {idx = idx, filter = filter, sort = sort } (start index on cur. page, filter item name, sort_coloumn)
	basic_shop.guidata[name] = {idx = 1, filter = "",sort = 0, count = #basic_shop.data};
end

basic_shop.show_shop_gui = function(name)
	
	local guidata = basic_shop.guidata[name];
	if not guidata then init_guidata(name); guidata = basic_shop.guidata[name]; end
	
	local idx = guidata.idx;
	local sort = guidata.sort;
	local filter = guidata.filter;
	
	local data = basic_shop.data; -- whole list of items for sale
	local idxdata = {}; -- list of idx of items for sale
	
	if filter == "" then
		for i = 1,#data do idxdata[i] = i end
	else
		for i = 1,#data do
			if string.find(data[i][1],filter) then
				idxdata[#idxdata+1] = i
			end
		end
	end
		
	if guidata.sort>0 then
		if guidata.sort == 1 then -- sort price increasing
			local sortf = function(a,b) return data[a][3]<data[b][3] end
			table.sort(idxdata,sortf)
		elseif guidata.sort == 2 then
			local sortf = function(a,b) return data[a][3]>data[b][3] end
			table.sort(idxdata,sortf)		
		end
	end
	
	local m = basic_shop.items_on_page; -- default 8 items per page
	local n = #idxdata; -- how many items in current selection
	
	local form = "size[10,8]"..	-- width, height
	"bgcolor[#222222cc; true]" ..
	"background[0,0;8,8;gui_formbg.png;true]" ..

	"label[0.4,-0.1;".. minetest.colorize("#6f6e6e", "Basic ") .. minetest.colorize("#6f6e6e", "Shop") .. "]" ..
	"label[5,-0.1;" .. minetest.colorize("#aaa", "Your money: ".. get_money(minetest.get_player_by_name(name)) .. " $, shops ".. (player_shops[name] or 0)) .. "]" ..

	"label[0.4,0.7;" .. minetest.colorize("#aaa", "item") .. "]" ..
	--"label[3,0.7;" .. minetest.colorize("#aaa", "price") .. "]" ..
	"button[3,0.7;1,0.5;price;" .. minetest.colorize("#aaa", "price") .. "]" ..
	"label[5,0.7;" .. minetest.colorize("#aaa", "time left") .. "]" ..
	"label[6.5,0.7;" .. minetest.colorize("#aaa", "seller") .. "]" ..
	
	"box[0.35,-0.1;9.05,0.65;#111]".."box[5,-0.1;4.4,0.65;#111]"..
	"box[0.35,7.2;9.05,0.15;#111]" ..  -- horizontal lines
	"field[0.65,7.9;2,0.5;search;;".. guidata.filter .."] button[2.5,7.6;1.5,0.5;filter;refresh]"..
	"button[4,7.6;1,0.5;help;help]"..
	"button[6.6,7.6;1,0.5;left;<] button[8.6,7.6;1,0.5;right;>]" ..
	"label[7.6,7.6; " .. math.floor(idx/m)+1 .." / " .. math.floor(n/m)+1 .."]";
	
	
	local tabdata = {};
	local idxhigh = math.min(idx + m,n);
	
	local t = basic_shop.time_left-minetest.get_gametime();
	
	for i = idx, idxhigh do
		local id = idxdata[i];
		local y = 1.3+(i-idx)*0.65
		local ti = tonumber(data[id][4]) or 0; 
		local time_left = ""
		
		ti = (t+ti); 
		if ti> basic_shop.time_left then -- shop by pro player, no time limit
			time_left = "no limit"
		else
			ti = ti/60; -- time left in minutes: time_left - (t-ti) = time_left-t + ti
			if ti<0 then ti = 0 end
			if ti<60 then 
				time_left = math.floor(ti*10)/10 .. "m"
			elseif ti< 1440 then 
				time_left =  math.floor(ti/60*10)/10 .. "h"
			else
				time_left =  math.floor(ti/1440*10)/10 .. "d"
			end
		end
	
		tabdata[i-idx+1] = 
		"item_image[0.4,".. y-0.1 .. ";0.7,0.7;".. data[id][1] .. "]" .. -- image
		"label[1.1,".. y .. ";x ".. data[id][2] .. "/" .. data[id][6] .. "]" .. -- total_quantity
		"label[3,".. y .. ";" .. minetest.colorize("#00ff36", data[id][3].." $") .."]" .. -- price
		"label[5,".. y ..";" .. time_left .."]" .. -- time left
		"label[6.5," .. y .. ";" .. minetest.colorize("#EE0", data[id][5]) .."]" .. -- seller
		"image_button[8.5," .. y .. ";1.25,0.7;wool_black.png;buy".. id ..";buy ".. id .."]"  -- buy button
		.."tooltip[buy".. id ..";".. data[id][1] .. "]"
	end
	
	minetest.show_formspec(name, "basic_shop", form .. table.concat(tabdata,""))	
end

local dout = minetest.chat_send_all;

local make_table_copy = function(tab)
	local out = {};
	for i = 1,#tab do out[i] = tab[i] end
	return out
end

minetest.register_on_player_receive_fields(
	function(player, formname, fields)
		if formname~="basic_shop" then return end
		local name = player:get_player_name()
		if not basic_shop.guidata[name] then init_guidata(name) end
		
		--[[
		if balance < 5 then -- new player
			minetest.chat_send_player(name,"#basic_shop: you need at least 5$ to sell items")
			return
		elseif balance<100 then -- noob
			if shop_count>1 then allow = false end
		elseif balance<1000 then -- medium
			if shop_count>5 then allow = false end
		else -- pro
			if shop_count>25 then allow = false end
		end
		if not allow then 
			minetest.chat_send_player(name,"#basic_shop: you need more money if you want more shops (100 for 5, 1000+ for 25).")
			return
		end
		--]]
		
		if fields.help then
			local name = player:get_player_name();
				local text = "Make a shop using /sell command while holding item to sell in hands. "..
				"As your basic income you get 1 money for each 12 minutes of play, but only up to 100.\n\n"..
				"Depending on how much money you have (/shop_money command) you get ability to create " ..
				"more shops with variable life span:\n\n"..
				"    balance 0-4     : new player, can't create shops yet\n"..
				"    balance 0-99    : new trader, 1 shop\n"..
				"    balance 100-999 : medium trader, 5 shops\n"..
				"    balance 1000+   : pro trader,  25 shops\n\n"..
				"All trader shop lifetime is one week ( after that shop closes down), for pro traders unlimited lifetime."				
				local form = "size [6,7] textarea[0,0;6.5,8.5;help;SHOP HELP;".. text.."]"
				minetest.show_formspec(name, "basic_shop:help", form)
			return
		end
		
		if fields.left then
			local guidata = basic_shop.guidata[name]
			local idx = guidata.idx;
			local n =  guidata.count;
			local m = basic_shop.items_on_page;
			idx = idx - m-1;
			if idx<0 then idx = math.max(n - m,0)+1 end
			guidata.idx = idx;
			basic_shop.show_shop_gui(name)
			return			
		elseif fields.right then
			local guidata = basic_shop.guidata[name]
			local idx = guidata.idx;
			local n =  guidata.count;
			local m = basic_shop.items_on_page;
			idx = idx + m+1;
			if idx>n then idx = 1 end
			guidata.idx = idx;
			basic_shop.show_shop_gui(name)
			return
		elseif fields.filter then
			local guidata = basic_shop.guidata[name]
			guidata.filter = tostring(fields.search or "") or ""
			if guidata.filter == "" then guidata.count = #basic_shop.data end
			guidata.idx = 1
			basic_shop.show_shop_gui(name)
		elseif fields.price then -- change sorting
			local guidata = basic_shop.guidata[name]
			guidata.sort = (guidata.sort+1)%3 --0,1,2
			basic_shop.show_shop_gui(name)
			return
		end
		
		for k,v in pairs(fields) do
			if string.sub(k,1,3) == "buy" then
				local sel = tonumber(string.sub(v,5));
				if not sel then return end
				local shop_item = basic_shop.data[sel];
				if not shop_item then return end
				local balance = get_money(player);
				local price = shop_item[3];
				local seller = shop_item[5]
				
				if seller ~= name then -- owner buys for free
					if balance<price then
						minetest.chat_send_player(name,"#basic_shop : you need " .. price .. " money to buy item " .. sel .. ", you only have " .. balance)
						return
					end
					balance = balance - price;set_money(player,balance) -- change balance for buyer
					local splayer = minetest.get_player_by_name(seller);
					if splayer then
						set_money(splayer, get_money(splayer) + price)
					else
						-- player offline, add to bank instead
						local bank_account = basic_shop.bank[seller] or {}; -- {deposit time, value}
						local bank_balance = bank_account[1] or 0;
						basic_shop.bank[seller] = {bank_balance + price, minetest.get_gametime()} -- balance, time of deposit.
					end
				end
				
				local inv = player:get_inventory();
				inv:add_item("main",shop_item[1] .. " " .. shop_item[2]);
				-- remove item from shop
				
				shop_item[6] = shop_item[6] - shop_item[2];
				shop_item[4] = minetest.get_gametime() -- time refresh
				if shop_item[6]<=0 then --remove shop
					player_shops[seller] = (player_shops[seller] or 1) - 1;
					local data = {};
					-- expensive, but ok for 'small'<1000 number of shops
					for i = 1,sel-1 do data[i] = make_table_copy(basic_shop.data[i]) end
					for i = sel+1,#basic_shop.data do data[i-1] = make_table_copy(basic_shop.data[i]) end
					basic_shop.data = data;
				end
				minetest.chat_send_player(name,"#basic_shop : you bought " .. shop_item[1] .." x " .. shop_item[2] .. ", price " .. price .." $")
				
				basic_shop.show_shop_gui(name)
			end
		end
	end	
)

minetest.register_on_joinplayer( -- if player has money from bank, give him the money
	function(player)
		local name = player:get_player_name();
		local bank_account = basic_shop.bank[name] or {}; -- {deposit time, value}
		local bank_balance = bank_account[1] or 0;
		if bank_balance>0 then
			local balance = get_money(player) + bank_balance;
			set_money(player,balance)
			basic_shop.bank[name] = nil
			minetest.chat_send_player(name,"#basic_shop: you get " .. bank_balance .. "$ from shops, new balance " .. balance .. "$ ")
		end
	end
)

local ts = 0
minetest.register_globalstep(function(dtime) -- time based income
	ts = ts + dtime
	if ts<720 then return end-- 720 = 12*60
	ts = 0
	local players = minetest.get_connected_players()
	for i = 1,#players do
		local balance = get_money(players[i]);
		if balance<100 then -- above 100 no pay
			set_money(players[i],balance+1) -- 5 money/hr
		end
	end
	
end)


-- CHATCOMMANDS

minetest.register_chatcommand("shop", {  -- display shop browser
	description = "",
	privs = {
		privs = interact
	},
	func = function(name, param)
		basic_shop.show_shop_gui(name)
	end
});

minetest.register_chatcommand("shop_top", {  
	description = "",
	privs = {
		privs = interact
	},
	func = function(name, param)
		display_toplist()
	end
});


minetest.register_chatcommand("sell", { 
	description = "",
	privs = {
		privs = interact
	},
	func = function(name, param)
		local words = {};
		for word in param:gmatch("%S+") do words[#words+1]=word end
		local price, count, total_count
		if #words == 0  then
			minetest.chat_send_player(name,"#basic_shop: /sell price, where price must be between 0 and " .. basic_shop.maxprice .."\nadvanced: /sell price count total_sell_count")
			return
		end
		
		price = tonumber(words[1]) or 0
		if price<0 or price>basic_shop.maxprice then
			minetest.chat_send_player(name,"#basic_shop: /sell price, where price must be between 0 and " .. basic_shop.maxprice .."\nadvanced: /sell price count total_sell_count")
			return
		end
		count = tonumber(words[2])
		total_count = tonumber(words[3])
		
		
		local player = minetest.get_player_by_name(name); if not player then return end
		local stack =  player:get_wielded_item()
		local itemname = stack:get_name();
		
		if not count then count = stack:get_count() else count = tonumber(count) or 1 end
		if count<1 then count = 1 end
		if not total_count then total_count = count else total_count = tonumber(total_count) or count end
		if total_count<count then total_count = count end; 
		
		if itemname == "" then return end
		
		local shop_count = (player_shops[name] or 0)+1;
		local balance = get_money(player);
		
		local allow = true
		if balance < 5 then -- new player
			minetest.chat_send_player(name,"#basic_shop: you need at least 5$ to sell items")
			return
		elseif balance<100 then -- noob
			if shop_count>1 then allow = false end
		elseif balance<1000 then -- medium
			if shop_count>5 then allow = false end
		else -- pro
			if shop_count>25 then allow = false end
		end
		if not allow then 
			minetest.chat_send_player(name,"#basic_shop: you need more money if you want more shops (100 for 5, 1000+ for 25).")
			return
		end
		
		if stack:get_wear()>0 then 
			minetest.chat_send_player(name,"#basic_shop: you can't sell used tools/weapons")
			return
		end
		
		local sstack = ItemStack(itemname.. " " .. total_count);
		if not player:get_inventory():contains_item("main", sstack) then 
			minetest.chat_send_player(name,"#basic_shop: you need at least " .. total_count .. " of " .. itemname)
			return
		end
		
		player_shops[name] = shop_count;
		player:get_inventory():remove_item("main", sstack)
		
		local data = basic_shop.data;
		--{"item name", quantity, price, time_left, seller}
		data[#data+1 ] = { itemname, count, price, minetest.get_gametime(), name, total_count};
		
		data[#data][4] = 10^15; -- if player is 'pro' then remove time limit, shop will never be too old
		
		minetest.chat_send_player(name,"#basic_shop : " .. itemname .. " x " .. count .."/"..total_count .." put on sale for the price " .. price .. ". To remove item simply go /shop and buy it (for free).")
		
		
	end
})

minetest.register_chatcommand("shop_money", { 
	description = "",
	privs = {
		privs = interact
	},
	func = function(name, param)
		if not param or param == "" then param = name end
		local player = minetest.get_player_by_name(param)
		if not player then return end
		minetest.chat_send_player(name,"#basic_shop: " .. param .. " has " .. get_money(player) .. " money.")
	end
})

minetest.register_chatcommand("shop_set_money", { 
	description = "",
	privs = {
		privs = kick
	},
	func = function(name, param)
		local pname, amount
		pname,amount = string.match(param,"(%a+) (%d+)");
		if not pname or not amount then minetest.chat_send_player(name,"usage: shop_set_money NAME AMOUNT") return end
		amount = tonumber(amount) or 0;
		local player = minetest.get_player_by_name(pname); if not player then return end
		set_money(player,amount)
		minetest.chat_send_player(name,"#basic_shop: " .. param .. " now has " .. amount .. " money.")
	end
})