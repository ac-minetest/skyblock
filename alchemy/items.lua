-- define essences and their values
alchemy.essence = {
	{"alchemy:essence_low",1},
	{"alchemy:essence_medium",50},
	{"alchemy:essence_high",2500},
	{"alchemy:essence_upgrade",125000}
} -- values of low, medium, high, upgrade essences


-- define item values for BREAK process
alchemy.items = {
["alchemy:essence_energy"]=0.05,
["alchemy:essence_low"]=1,
["alchemy:essence_medium"]=50,
["alchemy:essence_high"]=2500,
["alchemy:essence_upgrade"] = 125000,
["default:cobble"] = 1,
["default:diamond"] = 2500,
["moreores:mithril_ingot"] = 5000,
["default:mese_crystal"] = 1250,
["default:gold_ingot"] = 125,
["default:tree"] = 25,
["default:steel_ingot"] = 25,
["default:copper_ingot"] = 25,
["default:tin_ingot"] = 25,
["default:bronze_ingot"] = 50,
["default:obsidian"] = 500,
["default:dirt"] = 9,
["default:gravel"] = 15,
["default:sand"] = 12,
["default:coal_lump"] = 12
}

-- discovery levels: sequence of items player can discover and cost to do so
alchemy.discoveries = {
	[0] = {item = "default:sapling", cost = 10},
	[1] = {item = "default:cobble", cost = 250}, 
	[2] = {item = "default:papyrus", cost = 300},
	[3] = {item = "default:sand 2", cost = 500},
	[4] = {item = "bucket:bucket_water", cost = 1000},
	[5] = {item = "default:coal_lump", cost = 1250},
	[6] = {item = "default:iron_lump", cost = 1500},
	[7] = {item = "default:pine_needles 6", cost = 2000},
	[8] = {item = "default:copper_lump", cost = 2500},
	[9] = {item = "default:tin_lump", cost = 3000},
	[10] = {item = "default:gold_lump", cost = 3500},
	[11] = {item = "default:mese_crystal", cost = 6250},
	[12] = {item = "default:diamond", cost = 10000},
	[13] = {item = "default:obsidian", cost = 15000},
	[14] = {item = "moreores:mithril_ingot", cost = 20000},
}

alchemy.essence_values = {};
for i=1,#alchemy.essence do alchemy.essence_values[alchemy.essence[i][1]] = alchemy.essence[i][2] end