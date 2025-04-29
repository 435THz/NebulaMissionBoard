-- PMDO Mission Generation Library, by MistressNebula
-- Settings file
-- ----------------------------------------------------------------------------------------- --
-- This is the main library file containing all functions and callbacks.
-- If you need to configure your data, please refer to missiongen_settings.lua
-- ----------------------------------------------------------------------------------------- --
-- You will need to load this file using the require() function, preferably in a global
-- variable. You should never load this file more than once.
-- ----------------------------------------------------------------------------------------- --
-- This file also comes with a pre-installed set of menus for mission display.

-- List of string keys that must be included in your string files for this library to function correctly:
-- BOARD_TAKEN_TITLE

local library = {
	--- Settings data imported from missiongen_settings.lua
    data = require("missiongen_settings"),
	--- shortcut to the root of the saved mission data, made accessible for quick reference.
	--- NEVER. EVER. CHANGE THIS VALUE.
	root = SV
}
local menus = require("missiongen_menus")

--- root for global data and enum values.
local globals = {}
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
--- Special cases for missions
globals.special_cases = {}
globals.special_cases.RESCUE_FRIEND = {"CHILD", "LOVER", "RIVAL", "FRIEND"}
--- Keywords for client and target generation
globals.keywords = {}
globals.keywords.ENFORCER = "ENFORCER"
globals.keywords.OFFICER = "OFFICER"
globals.keywords.AGENT = "AGENT"
--- Error types
globals.error_types = {}
globals.error_types.DATA = "DataError"
globals.error_types.ID = "IDError"
--- Warning types
globals.warn_types = {}
globals.warn_types.FLOOR_GEN = "InvalidFloor"
globals.warn_types.ID = "MissingID"
--- Default values for various things
globals.defaults = {}
globals.defaults.item = "food_apple"
--- Static display keys
globals.keys = {}
globals.keys.taken_board = "BOARD_TAKEN_TITLE"
-- ----------------------------------------------------------------------------------------- --
-- region DATA GENERATORS
-- ----------------------------------------------------------------------------------------- --
-- Here at the top for easy access and reference, so that it is possible for modders to
-- quickly understand how the data is structured.

--- Loads the root of the main data structure, generating the specified nodes if necessary.
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

--- Loads the difficulty data and generates forward and backwards reference lists.
function library:loadDifficulties()
	self.data.num_to_difficulty = self.data.difficulty_list
	self.data.difficulty_to_num = {}
	for i, diff in ipairs(self.data.num_to_difficulty) do
		self.data.difficulty_to_num[diff] = i
	end
end

--- Generates the job board data structures inside the SV table.
function library:generateBoards()
	self.root.taken = self.root.taken or {}
	self.root.boards = self.root.boards or {}
	for board_id in pairs(self.data.boards) do
		self.root.boards[board_id] = self.root.boards[board_id] or {}
	end
end

--- Loads the dungeon progress table. Any completed dungeons that are missing from this table will have only
--- their segment 0 marked as completed.
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

--- @return table a new empty job template
local jobTemplate = function()
    local job = {
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
		BackReference = nil,-- Contains the name of the board it was in. Safety net for discarding jobs.
		Difficulty = -1,	-- difficulty level of this job, as number
		Item = "",			-- id of the item this job requires. Ignored if the job type requires no items
		Special = "",		-- special jobs can be triggered sometimes. If so, this will contain the special job id
		HideFloor = false	-- some job types have a chance to have their floor hidden. If true, hide the floor
	}
	return job
end

--- @return table an empty MonsterID-style table
local monsterIdTemplate = function()
	return {
		Nickname = nil, -- optional. If absent or empty, it will go unused
		Species = "", 	-- species of the pokémon
		Form = 0,		-- optional. If absent, it will be 0
		Skin = "normal",		-- optional. If absent, it will be "normal"
		Gender = -1 	-- optional. If absent or -1, it will be rolled
	}
end

-- ----------------------------------------------------------------------------------------- --
-- region LOGGING
-- ----------------------------------------------------------------------------------------- --
-- Functions that write to the output log

--- Prints a message prefixed with an error type.
local logError = function(error_type, message)
	PrintInfo("["..error_type.."] "..message)
end

--- Same as "logError" but does not print anything outside of dev mode.
--- Used for out-of-box events that may or may not be intentional, or for
--- low-priority problems that the system can handle by itself without much issue.
local logWarn = function(warn_type, message)
	if _DIAG.DevMode then logError(warn_type, message) end
end

--- Debug function that prints an entire table to console.
--- @param table table the table to print
function library:printall(table)
	local printall = function(table, level, root)
		if root == nil then print(" ") end

		if table == nil then print("<nil>") return end
		if level == nil then level = 0 end
		for key, value in pairs(table) do
			local spacing = ""
			for _=1, level*2, 1 do
				spacing = " "..spacing
			end
			if type(value) == 'table' then
				print(spacing..tostring(key).." = {")
				self:printall(value,level+1, false)
				print(spacing.."}")
			else
				print(spacing..tostring(key).." = "..tostring(value))
			end
		end

		if root == nil then print(" ") end
	end
	printall(table)
end

-- ----------------------------------------------------------------------------------------- --
-- region MISC
-- ----------------------------------------------------------------------------------------- --
-- Miscellaneous helper functions only callable from within this file

--- Rolls a MonsterForm's gender and returns it as a number
--- @param species string the id of the species to roll the gender of
--- @param form number the index of the form to roll the gender of
--- @return number a gender index number
local rollMonsterGender = function(species, form)
	return self:GenderToNumber(_DATA:GetMonster(species).Forms[form]:RollGender(_DATA.Save.Rand))
end

--- Removes invalid floors of a zone from the destination list
--- Invalid floors are those with static floor gen and those outside their segment's floor range
--- @param zone string the id of the zone to clean up
--- @param dest_list table the already compiled destination list
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
		if dest.floor >= floor_count then
			remove = true --discard outside floor range
			logWarn(globals.warn_types.FLOOR_GEN, "Floor "..dest.floor.." out of range. "..zone..", "..dest.segment.." Has only "..floor_count.." floors.")

		else
			local map_gen = segment:GetMapGen(dest.floor)
			local type = LUA_ENGINE:TypeOf(map_gen)
			if type:IsAssignableTo(luanet.ctype(globals.ctypes.LoadGen)) or type:IsAssignableTo(luanet.ctype(globals.ctypes.ChanceFloorGen)) then
				logWarn(globals.warn_types.FLOOR_GEN, "Jobs cannot be generated on "..zone..", "..dest.segment..", "..dest.floor.." because it is of type \""..type.FullName.."\"")
				remove = true --discard fixed floors
			end
		end
		if remove then
			table.remove(dest_list.floors_allowed[zone], i)
		end
	end
end

--- Creates a shallow copy of a table
--- @param tbl table the table to copy
--- @return table a shallow copy of the table
local shallowCopy = function(tbl)
	local copy = {}
	for key, value in pairs(tbl) do
		copy[key] = value
	end
	return copy
end

--- Sorting function used for job lists
--- @param j1 table a job table
--- @param j2 table another job table
--- @return boolean true if j1 goes after j2, false otherwise
local sortJobs = function(j1, j2)
	-- If one is nil and the other is not, put the nil one at the end
	if not library.data.dungeon_order[j1.Zone] and library.data.dungeon_order[j2.Zone] then return true end
	if library.data.dungeon_order[j1.Zone] and not library.data.dungeon_order[j2.Zone] then return false end
	-- Sort by dungeon order first and foremost
	if library.data.dungeon_order[j1.Zone] == library.data.dungeon_order[j2.Zone] then
		-- Sort by zone alphabetically
		if j1.Zone == j2.Zone then
			-- Sort by segment
			if j1.Segment == j2.Segment then
				-- Sort by floor
				return j1.Floor > j2.Floor
			else
				return j1.Segment > j2.Segment
			end
		else
			return j1.Zone < j2.Zone
		end
	else
		return library.data.dungeon_order[j1.Zone] > library.data.dungeon_order[j2.Zone]
	end
end

-- ----------------------------------------------------------------------------------------- --
-- region GETTERS
-- ----------------------------------------------------------------------------------------- --
-- Quickly get specific data regarding jobs or boards

--- Checks if a board is empty or not
--- @param board_id string the id of the board to check
--- @return boolean true if there are 0 jobs inside the board, false otherwise. Returns nil if the board does not exist
function library:IsBoardEmpty(board_id)
	if self.data.boards[board_id] then return #self.root.boards[board_id]<=0 else return end
end

--- Checks if the player's taken job list is empty or not
--- @return boolean true if there are 0 jobs inside the taken list, false otherwise.
function library:IsTakenListEmpty() return #self.root.taken<=0 end

--- Checks if a board is full or not
--- @param board_id string the id of the board to check
--- @return boolean true if there are no more free job slots inside the board, false otherwise. Returns nil if the board does not exist
function library:IsBoardFull(board_id)
	if self.data.boards[board_id] then return #self.root.boards[board_id]>=self.data.boards[board_id].size
	else return end
end

--- Checks if the player's taken job list is full or not
--- @return boolean true if there are no more free job slots inside the taken list, false otherwise.
function library:IsTakenListFull() return #self.root.taken>=self.data.taken_limit end

--- Checks if two jobs are equal. It compares location, job type, client and target data to do so.
--- @param j1 table a job
--- @param j2 table another job
--- @return boolean true if the objects are considered equal, false otherwise
function library:JobsEqual(j1, j2)
	if j1.Zone == j2.Zone and
			j1.Segment == j2.Segment and
			j1.Floor == j2.Floor and
			j1.Type == j2.Type and
			j1.Client == j2.Client and
			j1.Target == j2.Target and
			j1.Item == j2.Item then
		return true
	end
	return false
end

--- Looks for a job inside a specific board
--- @param job table the job to look for
--- @param board_id table the table to look in. If nil, the job will be searched for in the taken list
--- @return number the index of the job, or -1 if it was not found.
function library:FindJobInBoard(job, board_id)
	local board = self.root.boards[board_id]
	if not board_id then board = self.root.taken end

	for i, job2 in ipairs(board) do
		if self:JobsEqual(job, job2) then return i end
	end
	return -1
end

-- ----------------------------------------------------------------------------------------- --
-- region DATA CONVERTERS
-- ----------------------------------------------------------------------------------------- --
-- Functions that convert data between C# and lua representation

--- Converts a number to the Gender it represents. Invalid numbers will be marked as Unknown.
--- @param number number a number from -1 to 2.
--- @return userdata a RogueEssence.Data.Gender object
function library:NumberToGender(number)
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

--- Converts a Gender object to its number representation.
--- @param gender userdata a RogueEssence.Data.Gender object
--- @return number a number between -1 and 2
function library:GenderToNumber(gender)
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

--- Converts a table formatted like a MonsterID object into its c# equivalent.
--- Form, String and Gender are optional. If absent, Gender is rolled randomly, while the others will be set to 0 and "normal" respectively.
--- @param table table a table formatted like so: {Species = string, [Form = int], [Skin = string], [Gender = int]}
--- @return userdata a fully formed RogueEssence.Data.MonsterID object
function library:TableToMonsterID(table)
	table.Form = table.Form or 0
	table.Skin = table.Skin or "normal"
	table.Gender = table.Gender or rollMonsterGender(table.Species, table.Form)
	return RogueEssence.Dungeon.MonsterID(table.Species, table.Form, table.Skin, self:NumberToGender(table.Gender))
end

--- Converts a RogueEssence.Data.MonsterID object to a format that is more compatible with lua and the SV table.
--- You can include a nickname property if you so wish.
--- @param monsterId userdata a fully formed RogueEssence.Data.MonsterID object
--- @param nickname string Optional. A nickname to store with the MonsterId data
--- @return table a table formatted like so: {Nickname = string, Species = string, Form = int, Skin = string, Gender = int}
function library:MonsterIDToTable(monsterId, nickname)
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
--- @param alt_id string name of the id property, in case "id" isn't good enough. Use an empty string to require the object itself to be equal instead.
--- @return table, number the element extracted and its index in the list, or nil, nil if the final list was empty
function library:WeightedRandomExclude(list, exclude, replay_sensitive, alt_id)
	local id = alt_id or "id"
	local weight = 0
	for _, element in ipairs(list) do
		local match = element
		if id ~= "" then match = element[id] end
		if not exclude[match] then
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
		local match = element
		if id ~= "" then match = element[id] end
		if not exclude[match] then
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
-- region API
-- ----------------------------------------------------------------------------------------- --
-- Functions meant to be called by modders

--- Sorts the taken jobs list
function library:SortTaken() table.sort(self.root.taken, sortJobs) end

--- Sorts all job boards
function library:SortBoards() for board in pairs(self.root.boards) do self:SortBoard(board) end end

--- Sorts a specific job board
--- @param board_id string the id of the board to be sorted
function library:SortBoard(board_id)
	if not self.root.boards[board_id] then
		logWarn(globals.warn_types.ID, "Board table of id \""..board_id.."\" does not exist. Cannot sort")
	else
		table.sort(self.root.boards[board_id], sortJobs)
	end
end

--- Resets all boards and regenerates their contents.
--- Recommended to be called on day end.
function library:UpdateBoards()
	self:loadDungeonTable()
	self:FlushBoards()
	self:PopulateBoards()
	self:SortBoards()
end

--- Resets all boards. Boards that are not supposed to exist will be deleted.
function library:FlushBoards()
	for board in pairs(self.root.boards) do
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
	for _, job in self.root.boards do
		if job.BackReference == board_id then
			job.BackReference = nil
		end
	end
	if self.data.boards[board_id] == nil then
		--delete because it shouldn't exist
		self.root.boards[board_id] = nil
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

--- Counts how many jobs with guests have been generated for each dungeon.
--- It counts jobs in the taken list and in all boards.
--- @return table a table whose keys are zone ids and whose values are the number of guest jobs present in that dungeon
function library:GetDungeonsGuestCount()
	local guest_count = {}
	for _, job in ipairs(self.root.taken) do
		if globals.job_types[job.Type][3] then
			guest_count[job.Zone] = guest_count[job.Zone] or 0
			guest_count[job.Zone] = guest_count[job.Zone] +1
		end
	end
	for _, board in self.root.boards do
		for _, job in ipairs(board) do
			--taken jobs are gonna be in the taken list above already, so they shouldn't be counted again
			if not job.Taken and globals.job_types[job.Type][3] then
				guest_count[job.Zone] = guest_count[job.Zone] or 0
				guest_count[job.Zone] = guest_count[job.Zone] +1
			end
		end
	end
end

--- Tries to fill up as many empty slots as possible in the board. It will keep going from
--- wherever the board was at when this function was called.
--- It is recommended to flush the board beforehand to ensure it is actually generating new jobs.
--- @param board_id string the id of the board to generate jobs for
--- @param destinations table valid destination table created by "GetValidDestinations()". It also gets updated in-place for coherent and quick reuse. If absent, it will be generated in-place.
function library:PopulateBoard(board_id, destinations)
	local data = self.data.boards[board_id]
	if not data then
		logError(globals.error_types.ID, "Board with id \""..board_id.."\" does not exist. Cannot generate quests.")
		return
	end
	self.root.boards[board_id] = self.root.boards[board_id] or {}
	if not destinations then destinations = self:GetValidDestinations() end
	local guest_count = self:GetDungeonsGuestCount()

	while(#self.root.boards[board_id] < self.data.boards[board_id].size) do
		local newJob = jobTemplate()
		newJob.BackReference = board_id


		-- choose destination
		if #destinations.destinations <= 0 then break end
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
					logError(globals.error_types.DATA, "\""..job_type_entry.id.."\" in job board \""..board_id.."\" is not a valid job type and will be ignored.")
					table.remove(self.data.boards[board_id].job_types, i)
				elseif not job_type_properties then
					logError(globals.error_types.DATA, "\""..job_type_entry.id.."\" in job board \""..board_id.."\" has no settings associated to it and will be ignored.")
					table.remove(self.data.boards[board_id].job_types, i)
				else
					local min_rank = job_type_properties.min_rank
					local min_difficulty
					if min_rank then min_difficulty = self.data.difficulty_to_num[min_rank]
					else min_difficulty = 0
					end
					-- TODO add sanity check on rank values? maybe only active in dev mode? How do you even check if you're in dev mode again? Maybe the sanity check should be on dev mode load, on everything
					min_difficulty = min_difficulty - (job_type_properties.rank_modifier or 0)
					local add = true
					if min_difficulty > difficulty then add = false end
					if globals.job_types[job_type_entry.id][3]
							and guest_count[zone] and guest_count[zone] >= self.data.max_guests then add = false end
					if add then
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
						logError(globals.error_types.DATA, "No target items associated to job type \""..job_type.."\". Setting target to \""..globals.defaults.item.."\"")
						newJob.Item = globals.defaults.item
					end
				end

				local special
				if globals.special_cases[job_type] and math.random() < self.data.special_chance then
					special = self:WeightlessRandom(globals.special_cases[job_type])
					newJob.Special = special or ""
				end

				-- choose client and target. this must be done here because exclusive item rewards require it
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
						client = globals.keywords.ENFORCER
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
				-- parse law enforcement keywords
				if client == globals.keywords.ENFORCER then
					local roll = self:WeightedRandom(self.data.enforcer_chance[tier])
					if roll.id == globals.keywords.AGENT and roll.index and roll.index>0 and roll.index<=#self.data.law_enforcement.AGENT then
						client = self.data.law_enforcement.AGENT[roll.index]
					else
						client = roll.id
					end
				end
				if target == globals.keywords.ENFORCER then
					local roll = self:WeightedRandom(self.data.enforcer_chance[tier])
					if roll.id == globals.keywords.AGENT and roll.index and roll.index>0 and roll.index<=#self.data.law_enforcement.AGENT then
						target = self.data.law_enforcement.AGENT[roll.index]
					else
						target = roll.id
					end
				end
				if client == globals.keywords.OFFICER then
					client = self.data.law_enforcement.OFFICER
				end
				if target == globals.keywords.OFFICER then
					target = self.data.law_enforcement.OFFICER
				end
				if client == globals.keywords.AGENT then
					client = self:WeightedRandom(self.data.law_enforcement.AGENT)
				end
				if target == globals.keywords.AGENT then
					target = self:WeightedRandomExclude(self.data.law_enforcement.AGENT, client, false, "")
				end

				newJob.Client = client
				newJob.Target = target



				local reward_type
				local possible_reward_types = {}
				for i = #self.data.reward_types, -1, 1 do
					local reward_type_entry = self.data.reward_types[i]
					if not globals.reward_types[reward_type_entry.id] then
						logError(globals.error_types.DATA, "\""..reward_type_entry.id.."\" is not a valid reward type and will be ignored.")
						table.remove(globals.reward_types, i)
					elseif not reward_type_entry.min_rank or difficulty >= self.data.difficulty_to_num[reward_type_entry.min_rank] then
						table.insert(possible_reward_types, reward_type_entry)
					end
				end
				if #possible_reward_types <= 0 then
					logError(globals.error_types.DATA, "No possible reward types for quest difficulty \""..self.data.num_to_difficulty[difficulty].."\". Setting to \"money\"")
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
							rewards[i] = {id = globals.defaults.item}
						else
							if not self.data.rewards_per_difficulty or #self.data.rewards_per_difficulty[difficulty_id] <= 0 then
								logError(globals.error_types.DATA, "No possible rewards for quest difficulty \""..difficulty_id.."\". Setting to \""..globals.defaults.item.."\"")
								if i==1 then reward_type = "item"
								else reward_type = "money_item" end
								rewards[i] = {id = globals.defaults.item}
							else
								-- redundant path check
								local checked, result = {}, {}
								local pool = self:WeightedRandom(self.data.rewards_per_difficulty[difficulty_id]).id
								repeat
									if not pool or not self.data.reward_pools[pool] or #self.data.reward_pools[pool] <= 0 then
										if not pool then
											logError(globals.error_types.DATA, "No reward pools defined for quest difficulty \""..difficulty_id.."\". Setting reward type to \"money\"")
										else
											logError(globals.error_types.DATA, "Reward pool \""..pool.."\" does not exist. Setting reward type to \"money\"")
										end
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
								end -- no else because it only happens if the loop fails
							end
						end
					end
				end
				newJob.Reward1 = {id = rewards[1].id, count = rewards[1].count, hidden = rewards[1].hidden}
				newJob.Reward2 = {id = rewards[2].id, count = rewards[2].count, hidden = rewards[2].hidden}

				if newJob.Flavor[1] == "" then
					for i=1, 2, 1 do
						newJob.Flavor[i] = self:WeightlessRandom(self.data.job_flavor[job_type][i])
					end
				end

				local title_group = job_type
				if special ~= "" then
					title_group = special
				end
				newJob.Title = self:WeightlessRandom(self.data.job_titles[title_group])

				-- add finished product
				table.insert(self.root.boards[board_id], newJob)
				--increment guest count if necessary
				if globals.job_types[job_type][3] then
					guest_count[zone] = guest_count[zone] or 0
					guest_count[zone] = guest_count[zone] +1
				end

				-- remove used destination data
				table.remove(destinations.floors_allowed[zone], dest2_index)
				if #destinations.floors_allowed[zone] <= 0 then
					destinations.floors_allowed[zone] = nil
					table.remove(destinations.destinations, zone_index)
				end
			end
		end
	end
end

function library:BoardInteract(board_id)
	local loop = true
	while loop do
		local job_selected = 1
		local choice = menus.BoardSelection.run(self, board_id)
		if choice == 1 then
			while true do
				job_selected = menus.Board.run(self, board_id, job_selected)
				if job_selected > 0 then
					--TODO
				else break end
			end
		elseif choice == 2 then
			while true do
				job_selected = menus.Board.run(self, nil, job_selected)
				if job_selected > 0 then
					--TODO
				else break end
			end
		else
			loop = false
		end
	end
end

library.globals = globals
library:load()
return library