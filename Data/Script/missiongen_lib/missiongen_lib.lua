-- PMDO Mission Generation Library, by MistressNebula
-- Settings file
-- ----------------------------------------------------------------------------------------- --
-- This is the main library file containing all functions and callbacks.
-- If you need to configure your data, please refer to missiongen_settings.lua
-- ----------------------------------------------------------------------------------------- --
-- You will need to load this file using the require() function, preferably in a global
-- variable. You should never load this file more than once.
-- ----------------------------------------------------------------------------------------- --
-- This file also comes with a pre-installed menu for mission display.

local library = {
	--- Settings data imported from missiongen_settings.lua
    data = require("missiongen_settings"),
	--- shortcut to the root of the saved mission data, made accessible for quick reference.
	--- NEVER. EVER. CHANGE THIS VALUE.
	root = SV, --TODO add redundant safety reference?
}

--- root for global data and enum values.
local globals = {} --TODO populate at the bottom?
--- gender enum
globals.gender = {}
globals.gender.Unknown = -1
globals.gender.Genderless = 0
globals.gender.Male = 1
globals.gender.Female = 2
--- c# types
globals.ctypes = {}
globals.ctypes.LoadGen = luanet.import_type('RogueEssence.LevelGen.LoadGen')
globals.ctypes.ChanceFloorGen = luanet.import_type('RogueEssence.LevelGen.ChanceFloorGen')
globals.ctypes.RarityData = luanet.import_type('PMDC.Data.RarityData')
--- supported reward types enum
globals.reward_types = {} -- hardcoded properties: which reward slot(s) to fill
globals.reward_types.item = {true, false}
globals.reward_types.money = {false, false}
globals.reward_types.item_item = {true, true}
globals.reward_types.money_item = {false, true}
globals.reward_types.client = {false, false}
globals.reward_types.exclusive = {true, false, true} --third value says "activate exclusive item generator"
--- supported job types enum
globals.job_types = {} -- hardcoded properties: req_target, req_target_item, has_guest, target_outlaw, law_enforcement, can_hide_floor
globals.job_types.RESCUE_SELF =			 {false, false, false, false, false, false}
globals.job_types.RESCUE_FRIEND =		 {true,  false, false, false, false, true}
globals.job_types.ESCORT =				 {true,  false, true,  false, false, false}
globals.job_types.EXPLORATION =			 {false, false, true,  false, false, true}
globals.job_types.DELIVERY =			 {false, true,  false, false, false, false}
globals.job_types.LOST_ITEM =			 {false, true,  false, false, false, false}
globals.job_types.OUTLAW =				 {true,  false, false, true,  true,  true}
globals.job_types.OUTLAW_UNK =			 {true,  false, false, true,  true,  true}
globals.job_types.OUTLAW_ITEM =			 {true,  true,  false, false, true,  true}
globals.job_types.OUTLAW_ITEM_UNK =		 {true,  true,  false, false, true,  true}
globals.job_types.OUTLAW_MONSTER_HOUSE = {true,  false, false, true,  true,  false}
globals.job_types.OUTLAW_FLEE =			 {true,  false, false, true,  true,  true}

globals.special_cases = {}
globals.special_cases.RESCUE_FRIEND = {"CHILD", "LOVER", "RIVAL", "FRIEND"}
-- ----------------------------------------------------------------------------------------- --
-- region DATA GENERATORS
-- ----------------------------------------------------------------------------------------- --
-- Here at the top for easy access and reference, so that it is possible for modders to
-- quickly understand how the data is structured.

--- Loads the root of the main data structure, generating the specified nodes if necessary
function library:load()
    local rootpath = self.data.sv_root_name
    if type(rootpath) ~= "table" then
        rootpath = {self.data.sv_root_name}
    end
    for _, id in ipairs(rootpath) do
        SV[id] = SV[id] or {}
        self.root = SV[id]
    end
	self:loadDifficulties()
	self:generateBoards()
	self:loadDungeonTable()
end

function library:loadDifficulties()
	--- The list of all difficulty ranks, in order
	self.data.num_to_difficulty = self.data.difficulty_list
	--- Backwards reference from difficulty rank to number
	self.data.difficulty_to_num = {}
	for i, diff in ipairs(self.data.num_to_difficulty) do
		self.data.difficulty_to_num[diff] = i
	end
end

function library:generateBoards()
	self.root.taken = self.root.taken or {}
	self.root.boards = self.root.boards or {}
	for board_id in pairs(self.data.boards) do
		self.root.boards[board_id] = self.root.boards[board_id] or {}
	end
end

function library:loadDungeonTable()
	self.root.dungeon_progress = self.root.dungeon_progress or {}
	local UnlockState = RogueEssence.Data.GameProgress.UnlockState
	for dungeon in self.data.dungeons do
		if not self.root.dungeon_progress[dungeon] and _DATA.Save.DungeonUnlocks:ContainsKey(dungeon) then
			if _DATA.Save.DungeonUnlocks[dungeon] == UnlockState.Completed then
				self.root.dungeon_progress[dungeon] = {[0] = true} --default to segment 0 completed
			elseif _DATA.Save.DungeonUnlocks[dungeon] == UnlockState.Unlocked then
				self.root.dungeon_progress[dungeon] = {[0] = false} --default to segment 0 unlocked
			end
		end
	end
end

--- Returns a new empty job template
local jobTemplate = function()
    return {
		Client = nil,		-- MonsterID style table describing the client
		Target = nil,		-- MonsterID style table describing the target. Ignored if there is no target
		Flavor = {"", ""},	-- pair of string keys displayed when the job details are displayed
		Title = "",			-- string key displayed when viewing quest boards
		Zone = "",			-- The zone this job takes place in
		Segment = -1,		-- The specific segment this job takes place in
		Floor = -1,			-- The destination floor of this job
		RewardType = "",	-- The type of rewards for this job.
		Reward1 = {},		-- First item awarded by the job. Ignored if the reward type does not include a visible item reward
		Reward2 = {},		-- Second item awarded by the job. Ignored if the reward type does not include a hidden item reward
		Type = "",			-- the type of job
		Completion = -1,	-- the state of the job
		Taken = false,		-- taken list: if true, the job is active. Boards: if true, the job is inside the taken list
		Difficulty = -1,	-- difficulty level of this job
		Item = "",			-- id of the item this job requires. Ignored if the job type requires no items
		Special = "",		-- special jobs can be triggered sometimes. If so, this will contain the special job id
		HideFloor = false	-- some job types have a chance to have their floor hidden. If true, hide the floor TODO add setting for chance
	}
end

-- Returns an empty MonsterID style table
local monsterIdTemplate = function()
	return {
		Nickname = nil, -- optional. If absent or empty, it will go unused
		Species = "", 	-- species of the pokémon
		Form = -1,		-- optional. If absent, it will be rolled
		Skin = "",		-- optional. If absent, it will be normal
		Gender = -1 	-- optional. If absent or -1, it will be rolled
	}
end


-- ----------------------------------------------------------------------------------------- --
-- region DATA CONVERTERS
-- ----------------------------------------------------------------------------------------- --
-- Functions that convert data between C# and lua representation

local numberToGender = function(number)
	local res = Gender.Unknown
	if number == globals.gender.Genderless then
		res = Gender.Genderless
	elseif num == globals.gender.Male then
		res = Gender.Male
	elseif num == globals.gender.Female then
		res = Gender.Female
	end
	return res
end

local genderToNumber = function(gender)
	local res = globals.gender.Unknown
	if gender == Gender.Genderless then
		res = globals.gender.Genderless
	elseif gender == Gender.Male then
		res = globals.gender.Male
	elseif gender == Gender.Female then
		res = globals.gender.Female
	end
	return res
end

local tableToMonsterID = function(table)
	--TODO account for missing data
	return RogueEssence.Dungeon.MonsterID(table.Species, table.Form, table.Skin, numberToGender(table.Gender))
end

local monsterIDToTable = function(monsterId, nickname)
	local table = monsterIdTemplate()
	table.Nickname = nickname
	table.Species = monsterId.Species
	table.Form = monsterId.Form
	table.Skin = monsterId.Skin
	table.Gender = monsterId.Gender
	return table
end

-- ----------------------------------------------------------------------------------------- --
-- region RANDOMIZATION
-- ----------------------------------------------------------------------------------------- --
-- Functions for randomization purposes

--- Returns a random element of the list.
--- Elements must have a "weight" property, otherwise their weight will default to 1.
--- @param list table the list of elements to roll.
--- @param replay_sensitive boolean if true, this function will use a replay-safe rng function. Defaults to false.
--- @return table, number the element extracted and its index in the list, or nil, nil if the list was empty
function library:WeightedRandom(list, replay_sensitive)
	return self:WeightlessRandomExclude(list, {}, replay_sensitive)
end

--- Returns a random element of the list, excluding any key in the exclude table.
--- Elements must have a "weight" property, otherwise their weight will default to 1.
--- @param list table the list of elements to roll.
--- @param exclude table a table whose keys are the ids of the elements to exclude from the roll, and the value can be anything except "nil" and "false"
--- @param replay_sensitive boolean if true, this function will use a replay-safe rng function. Defaults to false.
--- @return table, number the element extracted and its index in the list, or nil, nil if the final list was empty
function library:WeightlessRandomExclude(list, exclude, replay_sensitive)
	local weight = 0
	for _, element in ipairs(list) do
		if not exclude[element.id] then
			if element.weight
			then weight = weight + element.weight
			else weight = weight + 1
			end
		end
	end
	if weight <= 0 then return nil, nil end
	local roll = -1
	if replay_sensitive
	then roll = math.random(1, weight)
	else roll = _DATA.Save.Rand:Next(weight)+1 --this rng getter includes 0 but doesn't include the max value so +1 it is
	end

	weight = 0
	for i, element in ipairs(list) do
		if not exclude[element.id] then
			if element.weight
			then weight = weight + element.weight
			else weight = weight + 1
			end
			if weight >= roll then return element, i end
		end
	end
	return list[#list], #list -- should never hit, but just in case, return last
end

--- Returns a random element of the list.
--- All elements have the same chance of being returned.
--- @param list table the list of elements to roll.
--- @param replay_sensitive boolean if true, this function will use a replay-safe rng function. Defaults to false.
--- @return any, number the element extracted and its index in the list, or nil, nil if the list was empty
function library:WeightlessRandom(list, replay_sensitive)
	if #list == 0 then return nil, nil end
	local roll = -1
	if replay_sensitive
	then roll = math.random(1, #list)
	else roll = _DATA.Save.Rand:Next(#list)+1 --this one includes 0 but doesn't include the max value so +1 it is
	end
	return list[roll], roll
end

--- Returns a random element of the list, excluding any key in the exclude table.
--- All elements have the same chance of being returned.
--- @param list table the list of elements to roll.
--- @param exclude table a table whose keys are the ids of the elements to exclude from the roll, and the value can be anything except "nil" and "false"
--- @param replay_sensitive boolean if true, this function will use a replay-safe rng function. Defaults to false.
--- @return any, number the element extracted and its index in the list, or nil, nil if the final list was empty
function library:WeightlessRandomExclude(list, exclude, replay_sensitive)
	local num = 0
	for _, element in pairs(exclude) do
		if not exclude[element] then
			num = num + 1
		end
	end
	if num <= 0 then return nil, nil end
	local roll = -1
	if replay_sensitive
	then roll = math.random(1, num)
	else roll = _DATA.Save.Rand:Next(num)+1 --this rng getter includes 0 but doesn't include the max value so +1 it is
	end

	num = 0
	for i, element in ipairs(list) do
		if not exclude[element] then
			num= num + 1
			if num >= roll then return element, i end
		end
	end
	return list[#list], #list -- should never hit, but just in case, return last
end

-- ----------------------------------------------------------------------------------------- --
-- region MISC
-- ----------------------------------------------------------------------------------------- --
-- Miscellaneous helper functions only callable from within this file

local cleanUpInvalidFloors = function(zone, dest_list)
	if dest_list.floors_allowed[zone] <= 0 then return end -- nothing to clean up
	local data_zone = _DATA:GetZone(zone)
	local segments = {}
	for i = #dest_list.floors_allowed[zone], 1, -1 do
		local dest = dest_list.floors_allowed[zone][i]
		local segment
		if not segments[dest.segment] then
			segment = data_zone.Segments[dest.segment]
			segments[dest.segment] = segment
		else
			segment = segments[dest.segment]
		end

		local remove = false
		local floor_count = segment.FloorCount
		if dest.floor >= floor_count then remove = true --discard outside floor range
		else
			local map_gen = segment:GetMapGen(dest.floor)
			local type = LUA_ENGINE:TypeOf(map_gen)
			if type:IsAssignableTo(luanet.ctype(globals.ctypes.LoadGen)) or type:IsAssignableTo(luanet.ctype(globals.ctypes.ChanceFloorGen)) then --TODO from here
				PrintInfo("Jobs cannot be generated on "..zone..", "..dest.segment..", "..dest.floor.." because it is of type \""..type.FullName.."\"")
				remove = true --discard fixed floors
			end
		end
		if remove then
			table.remove(dest_list.floors_allowed[zone], i)
		end
	end
end

-- ----------------------------------------------------------------------------------------- --
-- region API
-- ----------------------------------------------------------------------------------------- --
-- Functions meant to be called by modders

--- Resets all boards and regenerates their contents.
--- Recommended to be called on day end.
function library:UpdateBoards()
	self:loadDungeonTable()
	self:FlushBoards()
	self:PopulateBoards()
end

--- Resets all boards.
function library:FlushBoards()
	for board in pairs(self.data.boards) do
		self:FlushBoard(board)
	end
end

--- Fills all empty slots in all boards.
function library:PopulateBoards()
	local destinations = self:GetValidDestinations()
	for board in pairs(self.data.boards) do
		self:PopulateBoard(board, destinations)
	end
end

--- Resets the requested board. It will throw an error if the board does not exist.
--- @param board_id string the id of the board to be flushed
function library:FlushBoard(board_id)
	if self.data.boards[board_id] == nil then
		--TODO log warning
	else
		self.root.boards[board_id] = {}
	end
end

--- Populates a table of valid destinations that is then used by PopulateBoard.
--- @return table a list of valid destination zones and the list of allowed floors for each destination
function library:GetValidDestinations()
	local job_options = {destinations = {}, floors_allowed = {}}
	local floors_occupied = {}
	for _, job in ipairs(self.root.taken) do
		floors_occupied[job.Zone] = floors_occupied[job.Zone] or {}
		floors_occupied[job.Zone][job.Segment] = floors_occupied[job.Zone][job.Segment] or {}
		floors_occupied[job.Zone][job.Segment][job.Floor] = true
	end
	for _, board in self.root.boards do
		for _, job in ipairs(board) do
			floors_occupied[job.Zone] = floors_occupied[job.Zone] or {}
			floors_occupied[job.Zone][job.Segment] = floors_occupied[job.Zone][job.Segment] or {}
			floors_occupied[job.Zone][job.Segment][job.Floor] = true
		end
	end

	for zone, zone_data in pairs(self.data.dungeons) do
		if self.root.dungeon_progress[zone] ~= nil then
			for segment, segment_data in pairs(zone_data) do
				local validSegemnt = true
				if self.root.dungeon_progress[zone][segment] == nil then
					validSegemnt = false					 -- remove segments not unlocked
				elseif self.root.dungeon_progress[zone][segment] == false then
					validSegemnt = not segment_data.must_end -- remove "must_end" segments that are not completed
				elseif self.root.dungeon_progress[zone][segment] == true then
					validSegemnt = true						 -- completed dungeons are always ok
				end
				if validSegemnt then
					for i=segment_data[1].start, segment_data.max_floor, 1 do
						if not floors_occupied[zone][segment][i] then
							if not job_options.floors_allowed[zone] then
								job_options.floors_allowed[zone] = {}
								table.insert(job_options.destinations, zone)
							end
							table.insert(job_options.floors_allowed[zone], {segment = segment, floor = i, difficulty = segment_data.difficulty})
						end
					end
				end
			end
		end
	end
	return job_options
end

--- Tries to fill up as many empty slots as possible in the board. It will keep going from
--- wherever the board was at when this function was called.
--- It is recommended to flush the board beforehand to ensure it is actually generating new jobs.
--- @param board_id string the id of the board to be flushed
--- @param destinations table valid destination table created by "GetValidDestinations()". It also gets updated in-place for coherent and quick reuse. If absent, it will be generated in-place.
function library:PopulateBoard(board_id, destinations)
	local data = self.data.boards[board_id]
	if not destinations then destinations = self:GetValidDestinations() end

	while(#self.root.boards[board_id] < self.data.boards[board_id].size) do
		--TODO compile final job data
		local newJob = jobTemplate()


		-- choose destination
		if #destinations.destinations <= 0 then return end
		local zone, zone_index = self:WeightlessRandom(destinations.destinations)
		cleanUpInvalidFloors(zone, destinations)

		if not destinations.floors_allowed[zone] or #destinations.floors_allowed[zone] <= 0 then
			--clean up and try again if there are no valid destinations in this dungeon
			destinations.floors_allowed[zone] = nil
			table.remove(destinations.destinations, zone_index)
		else
			local dest2, dest2_index = self:WeightlessRandom(destinations.floors_allowed[zone])
			local segment, floor = dest2.segment, dest2.floor
			local difficulty = self.data.difficulty_to_num[dest2.difficulty]
			newJob.Zone = zone
			newJob.Segment = segment
			newJob.Floor = floor

		-- choose job type and finalize difficulty adjustments
			local possible_job_types = {}
			for i = #self.data.boards[board_id].job_types, -1, 1 do
				local job_type_entry = self.data.boards[board_id].job_types[i]
				local job_type_properties = self.data.job_types[job_type_entry.id]
				if not globals.job_types[job_type_entry.id] then
					--TODO log invalid id error
					table.remove(self.data.boards[board_id].job_types, i)
				elseif not job_type_properties then
					--TODO log absent properties error
					table.remove(self.data.boards[board_id].job_types, i)
				else
					local min_rank = job_type_properties.min_rank
					local min_difficulty
					if min_rank then min_difficulty = self.data.difficulty_to_num[min_rank]
					else min_difficulty = 0
					end
					-- TODO weed out jobs based on escort limit
					-- TODO add sanity check on rank values? maybe only active in dev mode? How do you even check if you're in dev mode again? Maybe the sanity check should be on dev mode load, on everything
					min_difficulty = min_difficulty - (job_type_properties.rank_modifier or 0)
					if min_difficulty <= difficulty then
						table.insert(possible_job_types, job_type_entry)
					end
				end
			end
			if #possible_job_types <= 0 then
				--weed out any floor where no jobs can spawn EVER because of the difficulty constraints.
				for i, elem in destinations.floors_allowed[zone] do
					if self.data.difficulty_to_num[elem.difficulty] < difficulty then
						table.remove(destinations.floors_allowed[zone], i)
					end
				end
				if #destinations.floors_allowed[zone] <= 0 then
					--clean up if empty, then try again
					destinations.floors_allowed[zone] = nil
					table.remove(destinations.destinations, zone_index)
				end
			else
				local job_type = self:WeightedRandom(possible_job_types).id
				newJob.Type = job_type
				difficulty = difficulty + self.data.job_types[job_type].rank_modifier
				newJob.Difficulty = difficulty

				-- Roll for floor hide chance
				if globals.job_types[job_type][6] then --if can_hide_floor
					if math.random() < self.data.hidden_floor_chance then newJob.HideFloor = true end
				end

				if globals.job_types[job_type][2] then --if req_target_item
					if self.data.target_items[job_type] and #self.data.target_items[job_type] > 0 then
						newJob.Item = self:WeightlessRandom(self.data.target_items[job_type])
					else
						--TODO log absent list error
						newJob.Item = "food_apple"
					end
				end

				local special
				if globals.special_cases[job_type] then
					special = self:WeightlessRandom(globals.special_cases[job_type])
					newJob.Special = special
				end

				-- choose client and target. this must be done here because exclusive item rewards requires it
				local client, target = nil, ""
				local tier = self:WeightedRandom(self.data.difficulty_to_tier[difficulty]).id
				if special then
					local special_data = self.data.special_data[special][tier]
					client = special_data.client
					target = special_data.target
					newJob.Flavor[1] = special_data.flavor
				else
					local otherPossibleTiers = {}
					for _, tier2 in ipairs(self.data.difficulty_to_tier[difficulty]) do
						if tier ~= tier2.id and tier2.weight > 0 then
							table.insert(otherPossibleTiers, tier2)
						end
					end
					table.sort(otherPossibleTiers, function(a, b) return a.weight < b.weight end)
					local pool = self.data.pokemon[tier]
					local real_pool
					repeat
						real_pool = {}
						for _, mon in ipairs(pool) do
							if _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Monster].Get(mon).Released and
									_DATA.Save.Dex:ContainsKey(mon) and
									_DATA.Save.Dex[mon] ~= RogueEssence.Data.GameProgress.UnlockState.None then
								table.insert(real_pool, mon)
							end
						end
						if #real_pool>0 then break end
						pool = self.data.pokemon[otherPossibleTiers[#otherPossibleTiers].id]
						table.remove(otherPossibleTiers)
					until #otherPossibleTiers <= 0
					if #real_pool <= 0 then
						real_pool = self.data.pokemon[tier]
					end
					if globals.job_types[job_type][5] then --if law_enforcement
						client = "ENFORCER"
					else
						local client_species, index = self:WeightlessRandom(real_pool)
						client = {species = client_species}
						table.remove(real_pool, index)
					end
					if globals.job_types[job_type][1] then --if req_target
						if #real_pool <= 0 then
							real_pool = self.data.pokemon[tier]
						end
						target = {species = self:WeightlessRandom(real_pool)}
					end
				end
				--TODO PARSE LAW ENFORCEMENT
				newJob.Client = client
				newJob.Target = target



				local reward_type
				local possible_reward_types = {}
				for i = #self.data.reward_types, -1, 1 do
					local reward_type_entry = self.data.reward_types[i]
					if not globals.reward_types[reward_type_entry.id] then
						--TODO log invalid id error
						table.remove(globals.reward_types, i)
					elseif not reward_type_entry.min_rank or difficulty >= self.data.difficulty_to_num[reward_type_entry.min_rank] then
						table.insert(possible_reward_types, reward_type_entry)
					end
				end
				if #possible_reward_types <= 0 then
					--TODO log empty list error
					reward_type = "money"
				else
					reward_type = self:WeightedRandom(possible_reward_types).id
				end

				local difficulty_id = self.data.num_to_difficulty[difficulty]
				newJob.RewardType = reward_type

				local rewards = {"", ""}
				for i = 1, 2, 1 do
					if globals.reward_types[reward_type][i] then
						if globals.reward_types[reward_type][3] then -- if reward type specifies exclusive
							local rarityData = _DATA.UniversalData.Get(luanet.ctype(globals.ctypes.RarityData))
							local possibleItems = {}
							local species = client
							if globals.job_types[job_type][4] then -- if target_outlaw
								species = target
							end
							if rarityData.RarityMap:ContainsKey(species) then
								local rarityTable = rarityData.RarityMap[species]
								if rarityTable:ContainsKey(1) then
									for item_id in luanet.each(rarityTable[i]) do
										if _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Item].Get(item_id).Released then
											table.insert(possibleItems, item_id)
										end
										if #possibleItems > 0 then
											rewards[i] = self:WeightlessRandom(possibleItems)
										end
									end
								end
							end
							if i==1 then reward_type = "item"
							else reward_type = "money_item" end
							rewards[i] = {id = "food_apple"}
						else
							if #self.data.rewards_per_difficulty[difficulty_id] <= 0 then
								--TODO log empty list error
								if i==1 then reward_type = "item"
								else reward_type = "money_item" end
								rewards[i] = {id = "food_apple"}
							else
								-- redundant path check
								local checked, result = {}, {}
								local pool = self:WeightedRandom(self.data.rewards_per_difficulty[difficulty_id]).id
								repeat
									if not pool or #self.data.reward_pools[pool] <= 0 then
										--TODO log error depending on case
										reward_type = "money"
										result = nil
										break
									else
										checked[pool] = true
										result = self:WeightedRandomExclude(#self.data.reward_pools[pool], checked)
										pool = result.id
									end
								until not self.data.reward_pools[pool]
								if result then
									rewards[i] = result
								end
							end
						end
					end
				end
				newJob.Reward1 = {id = rewards[1].id, count = rewards[1].count, hidden = rewards[1].hidden}
				newJob.Reward2 = {id = rewards[2].id, count = rewards[2].count, hidden = rewards[2].hidden}


				--TODO Flavor = {"", ""},	-- pair of string keys displayed when the job details are displayed. Only if Flavor[1] is not set already
				--TODO Title = "",			-- string key displayed when viewing quest boards
				--TODO Completion = -1,		-- the state of the job
				--TODO Taken = false,		-- taken list: if true, the job is active. Boards: if true, the job is inside the taken list
				end


			--remove used destination data
			table.remove(destinations.floors_allowed[zone], dest2_index)
			if #destinations.floors_allowed[zone] <= 0 then
				destinations.floors_allowed[zone] = nil
				table.remove(destinations.destinations, zone_index)
			end
		end
	end
end

library:load()
return library