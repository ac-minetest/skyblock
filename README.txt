SkyBlock - lightweight version
minetest 0.4.16+
(c) 2018 rnd

Includes economic island management - players must reach level 2 before they truly own island - or it will be recycled and used by another player.

needs: 
	default minetest game

	optional:
	sfinv (included with minetest) for gui
	'craft guide' by jp
	moreores (for more interesting quests)
	
Instructions:
	create new world with 'skyblock' enabled


---------------------------------------------------------------------
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
----------------------------------------------------------------------

EXPLANATION OF PLAYER DATA:

1) all player data (progress) is saved in player file /WORLDS/../skyblock/playername. For example:
	
	return {["level"] = 2, 
		["on_craft"] = {["default:stone_with_coal"] = 0, ["default:stone_with_iron"] = 0}, 
		["on_placenode"] = {["default:dirt"] = 0, ["default:stone"] = 0}, 
		["id"] = 0, ["completed"] = 1, ["total"] = 7, 
		["on_dignode"] = {["default:jungletree"] = 0, ["default:dirt"] = 9, ["basic_protect:protector"] = 1}, 
		["stats"] = {["on_placenode"] = 4325, ["on_craft"] = 38, ["on_dignode"] = 1867, ["last_login"] = 5646821, ["time_played"] = 867221}
		}
		
	so players current level is 2, then achievement for "on_craft" quest,.. id = players current island, 
	total = how many quest to complete on current level,
	completed = how many completed quests on current level,
	stats = all time statistics for this player
	
2) once loaded in memory players data is stored inside skyblock.players[playername]	variable.