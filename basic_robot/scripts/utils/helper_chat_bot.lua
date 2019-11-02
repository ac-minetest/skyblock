if not init then 
	init = true; self.listen(1);

	_G.minetest.forceload_block(self.pos(),true)
	self.spam(1); self.label("help bot")
	
	talk = function(msg) minetest.chat_send_all("<help bot> " .. msg) end
	keywords = {
		{"tpr", 14},
		{"tpy",19},
		{"help",
			{"robot",6},{"",1}
		},
		{"how",
			{"play",1},{"island",17},{"robot", 6},{"stone",4},{"tree",3},{"wood",3},{"lava",5},{"mossy",16},{"cobble",4},{"dirt",10},
			{"do i get",1},{"do i make",1}, {"to get",1},{"farm",15}, 
		},
		{"i need",
			{"wood",3}
		},

		{"hello",2}, -- words matched must appear at beginning
		{"hi",2},
		{"back",7}, 
		{" hard",{"",9}}, -- word matched can appear anywhere
		{" died", {"",9}},
		{" die",{"",8}}, {" dead",{"",8}},
--		{"rnd",{"",11}},
		{"bye",{"",12}},
		{"!!",{"",9}},
		
		{"calc", 13},
		{"day",18},
	}
	answers = {
		"%s open inventory, click 'Quests' and do them to get more stuff", --1
		"hello %s",
		"do the dirt quest to get sticks then do sapling quest",
		"get pumice from lava and water. then search craft guide how to make cobble",
		"you get lava as compost quest reward or with grinder", -- 5
		"you have to write a program so that robot knows what to do. for list of commands click 'help' button inside robot.",
		"wb %s",
		"dont die, you lose your stuff and it will reset your level on level 1",
		"you suck %s!", -- 9
		"to get dirt craft composter, put leaves on it, punch it and wait until its ready.", -- 10
		"rnd is afk. in the meantime i can answer your questions",
		"bye %s",
		function(speaker,msg)  -- 13, calc
			local expr = string.sub(msg,5); 
			if string.find(expr,"%a") then return end;
			if string.find(expr,"{") then return end;
			local exprfunc = _G.loadstring("return " .. expr);
			local res = exprfunc and exprfunc() or say("error in expression: " .. expr);
			if type(res) == "number" then say(expr .. " = " .. res) end
		end,
		function(speaker,msg) -- 14,tpr
			tpr[1] = speaker
			tpr[2] = string.sub(msg,5) or "";
			minetest.chat_send_player(tpr[2], "#TPR: " .. speaker .. " wants to teleport to you. say \\tpy")
		end,
		"to make farm craft composter, put leaves on it and wait until its ready (it has dirt). Then put composter in it and plant your crops on top.", -- 15
"put cobble near water and wait.", --16
		"you get your own island when you finish all quests on level 1", --17
		function(speaker,msg) -- 18, day
			minetest.set_timeofday(0.25); say("time set to day")
		end,
		function(speaker,msg) -- 19,tpy
			if tpr[2] ~= speaker then return end;
			local p1 = minetest.get_player_by_name(tpr[1]);
			local p2 = minetest.get_player_by_name(tpr[2]);tpr[2] = ""
			if p1 and p2 then
				p1:setpos(p2:getpos())
			end
		end,
	}
	tpr = {"",""} -- used for teleport
end

speaker,msg = self.listen_msg();
if msg then
	--msg = string.lower(msg);
	sel = 0;
	for i = 1, #keywords do
		local k = string.find(msg,keywords[i][1])
		if k then 
			if type(keywords[i][2])~="table" then -- one topic only
				if k == 1 then sel = keywords[i][2] break end
			else
				for j=2,#keywords[i] do -- category of several topics
					if string.find(msg,keywords[i][j][1]) then 
						sel =  keywords[i][j][2]; break;
					end
				end
			end
		end
	end
	
	if sel>0 then
		local response = answers[sel];
		if type(response) == "function" then
			response(speaker,msg)		
		elseif string.find(response,"%%s") then
			talk(string.format(response,speaker))
		else
			talk(response)
		end
	end
	
end