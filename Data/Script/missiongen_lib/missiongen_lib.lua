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

--- @alias LibraryRootStruct {boards:table<string,jobTable[]>,taken:jobTable[],dungeon_progress:table<string,table<integer, boolean>>,previous_limit:integer}
--- @alias jobTable {Client:monsterIDTable, Target:monsterIDTable|nil, Flavor:{[1]:string, [2]:string}, Title:string, Zone:string, Segment:integer,
--- Floor:integer, RewardType:string, Reward1:itemTable|nil, Reward2:itemTable|nil, Type:string, Completion:integer, Taken:boolean, BackReference:string|nil,
--- Difficulty:integer, Item:string|nil, Special:string|nil, HideFloor:boolean} A table containing all properties of a job
--- @alias itemTable {id:string, count:integer|nil, hidden:string|nil}
--- @alias monsterIDTable {Species:string, Form:integer|nil, Skin:string|nil, Gender:integer|nil, Nickname:string|nil} A table that can be converted into a MonsterID object
--- @alias MonsterID {Species:string, Form:integer, Skin:string, Gender:userdata} A MonsterID object

-- Below is the list of string keys that must be included in your string files for this library to function correctly.
-- BOARD_TAKEN_TITLE - strings.resx - The title of the Taken list when viewing the menu

local library = {
	--- Settings data imported from missiongen_settings.lua
    data = require("missiongen_settings"),
	--- shortcut to the root of the saved mission data, made accessible for quick reference.
	--- NEVER. EVER. CHANGE THIS VALUE.
	---@type LibraryRootStruct
    root = SV
}
local menus = require("missiongen_menus")

--- Root for global data and enum values.
local globals = {}
---@type table<string,integer> Gender values
globals.gender = {}
globals.gender.Unknown = -1
globals.gender.Genderless = 0
globals.gender.Male = 1
globals.gender.Female = 2
---@type table<string,integer> Completion values
globals.completion = {}
globals.completion.Failed = -1
globals.completion.NotCompleted = 0
globals.completion.Completed = 1
---@type table<string,userdata> C# types
globals.ctypes = {}
globals.ctypes.LoadGen = luanet.import_type('RogueEssence.LevelGen.LoadGen')
globals.ctypes.ChanceFloorGen = luanet.import_type('RogueEssence.LevelGen.ChanceFloorGen')
globals.ctypes.RarityData = luanet.import_type('PMDC.Data.RarityData')
globals.ctypes.FloorNameIDZoneStep = luanet.import_type('RogueEssence.LevelGen.FloorNameIDZoneStep')
---Supported reward types data
---Hardcoded properties: item1, item2, exclusive, display_key_pointer
---@type table<string,{[1]:boolean,[2]:boolean,[3]:boolean,[4]:string}>
globals.reward_types = {}
globals.reward_types.item = 	  {true,  false, false, "MENU_JOB_REWARD_SINGLE"}
globals.reward_types.money = 	  {false, false, false, "MENU_JOB_REWARD_SINGLE"}
globals.reward_types.item_item =  {true,  true,  false, "MENU_JOB_REWARD_DOUBLE"}
globals.reward_types.money_item = {false, true,  false, "MENU_JOB_REWARD_DOUBLE"}
globals.reward_types.client = 	  {false, false, false, "MENU_JOB_REWARD_UNKNOWN"}
globals.reward_types.exclusive =  {true,  false, true,  "MENU_JOB_REWARD_UNKNOWN"}
--- Supported job types data
--- Hardcoded properties: req_target, req_target_item, has_guest, target_outlaw, law_enforcement, can_hide_floor
---@type table<string,{[1]:boolean,[2]:boolean,[3]:boolean,[4]:boolean,[5]:boolean,[6]:boolean}>
globals.job_types = {}
globals.job_types.RESCUE_SELF =			 {false, false, false, false, false, false}
globals.job_types.RESCUE_FRIEND =		 {true,  false, false, false, false, true}
globals.job_types.ESCORT =				 {true,  false, true,  false, false, false}
globals.job_types.EXPLORATION =			 {false, false, true,  false, false, true}
globals.job_types.DELIVERY =			 {false, true,  false, false, false, false}
globals.job_types.LOST_ITEM =			 {false, true,  false, false, false, false}
globals.job_types.OUTLAW =				 {true,  false, false, true,  true,  true}
globals.job_types.OUTLAW_ITEM =			 {true,  true,  false, false, true,  true}
globals.job_types.OUTLAW_ITEM_UNK =		 {true,  true,  false, false, true,  true}
globals.job_types.OUTLAW_MONSTER_HOUSE = {true,  false, false, true,  true,  false}
globals.job_types.OUTLAW_FLEE =			 {true,  false, false, true,  true,  true}
--- Special cases for missions
---@type table<string,string[]>
globals.special_cases = {}
globals.special_cases.RESCUE_FRIEND = {"CHILD", "LOVER", "RIVAL", "FRIEND"}
--- Keywords for client and target generation
---@type table<string,string>
globals.keywords = {}
globals.keywords.ENFORCER = "ENFORCER"
globals.keywords.OFFICER = "OFFICER"
globals.keywords.AGENT = "AGENT"
--- Error types
---@type table<string,string>
globals.error_types = {}
globals.error_types.DATA = "DataError"
globals.error_types.ID = "IDError"
--- Warning types
---@type table<string,string>
globals.warn_types = {}
globals.warn_types.DATA = "MissingData"
globals.warn_types.FLOOR_GEN = "InvalidFloor"
globals.warn_types.ID = "MissingID"
--- Default values for various things
---@type table<string,string>
globals.defaults = {}
globals.defaults.item = "food_apple"
--- Static display keys
---@type table<string,string>
globals.keys = {}
globals.keys.RESCUE_SELF = "MENU_JOB_OBJECTIVE_RESCUE_SELF"
globals.keys.RESCUE_FRIEND = "MENU_JOB_OBJECTIVE_RESCUE_FRIEND"
globals.keys.ESCORT = "MENU_JOB_OBJECTIVE_ESCORT"
globals.keys.EXPLORATION = "MENU_JOB_OBJECTIVE_EXPLORATION"
globals.keys.DELIVERY = "MENU_JOB_OBJECTIVE_DELIVERY"
globals.keys.LOST_ITEM = "MENU_JOB_OBJECTIVE_LOST_ITEM"
globals.keys.OUTLAW = "MENU_JOB_OBJECTIVE_OUTLAW"
globals.keys.OUTLAW_ITEM = "MENU_JOB_OBJECTIVE_OUTLAW_ITEM"
globals.keys.OUTLAW_ITEM_UNK = "MENU_JOB_OBJECTIVE_OUTLAW_ITEM_UNK"
globals.keys.OUTLAW_MONSTER_HOUSE = "MENU_JOB_OBJECTIVE_OUTLAW_MONSTER_HOUSE"
globals.keys.OUTLAW_FLEE = "MENU_JOB_OBJECTIVE_OUTLAW_FLEE"
globals.keys.OBJECTIVE_DEFAULT = "MENU_JOB_OBJECTIVE_DEFAULT"
globals.keys.REACH_SEGMENT = "MENU_JOB_OBJECTIVE_REACH_SEGMENT"
globals.keys.TAKEN_TITLE = "BOARD_TAKEN_TITLE"
globals.keys.OBJECTIVES_TITLE = "MENU_JOB_OBJECTIVES_TITLE"
globals.keys.JOB_ACCEPTED = "MENU_JOB_ACCEPTED"
globals.keys.JOB_SUMMARY = "MENU_JOB_SUMMARY"
globals.keys.JOB_CLIENT = "MENU_JOB_CLIENT"
globals.keys.JOB_OBJECTIVE = "MENU_JOB_OBJECTIVE"
globals.keys.JOB_PLACE = "MENU_JOB_PLACE"
globals.keys.JOB_DIFFICULTY = "MENU_JOB_DIFFICULTY"
globals.keys.JOB_REWARD = "MENU_JOB_REWARD"
globals.keys.BUTTON_TAKE = "MENU_JOB_TAKE"
globals.keys.BUTTON_DELETE = "MENU_JOB_DELETE"
globals.keys.BUTTON_SUSPEND = "MENU_JOB_SUSPEND"

-- ----------------------------------------------------------------------------------------- --
-- region DATA GENERATORS
-- ----------------------------------------------------------------------------------------- --
-- Here at the top for easy access and reference, so that it is possible for modders to
-- quickly understand how the data is structured.

--- Loads the root of the main data structure, generating the specified nodes if necessary.
function library:load()
    local rootpath = self.data.sv_root_name
    if type(rootpath) ~= "table" then
    ---@cast rootpath string[]
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

--- @return jobTable #a new empty job template
local jobTemplate = function()
    return {
        ---@type monsterIDTable MonsterID style table describing the client
		Client = nil,
		---@type monsterIDTable|nil MonsterID style table describing the target. Ignored if the job type expects no target
		Target = nil,
        ---@type {[1]:string, [2]:string} Pair of string keys displayed when the job details are displayed. The second key is optional
		Flavor = {"", ""},
		---@type string String key displayed when browsing quest boards
		Title = "",
		---@type string The id of the zone this job takes place in
		Zone = "",
		---@type integer The specific segment this job takes place in
		Segment = -1,
		---@type integer The destination floor of this job
		Floor = -1,
		---@type string The id of the combination of rewards that will be awarded by this job
		RewardType = "",
		---@type itemTable|nil Data of the first item awarded by the job. Ignored if the reward type does not include a visible item reward
		Reward1 = {},
		---@type itemTable|nil Data of the second item awarded by the job. Ignored if the reward type does not include a hidden item reward
		Reward2 = {},
		---@type string The id of the type of this job
		Type = "",
		---@type integer the state of the job. -1 means failed. 0 means not completed. 1 means completed. This is always reset to 0 on day end if the job rewards are not claimed (like when an adventure is failed).
		Completion = 0, --TODO
		---@type boolean Taken list: if true, the job is active. Boards: if true, the job is inside the taken list
		Taken = false,
		---@type string|nil Contains the name of the board it was in. It is used only in the taken list for discarding jobs.
		BackReference = nil,
		---@type integer The difficulty index of this job.
		Difficulty = -1,
		---@type string|nil The id of the item this job requires. Ignored if the job type requires no items.
		Item = "",
		---@type string|nil special jobs can be triggered sometimes. If so, this will contain the special job category id.
		Special = "",
		---@type boolean Some job types have a chance to have their floor hidden. If this is true, hide the floor.
		HideFloor = false
	}
end

--- @return monsterIDTable #an empty MonsterID-style table
local monsterIdTemplate = function()
    ---@type monsterIDTable
    return {
        ---@type string|nil Optional. The nickname to apply to the character
        Nickname = nil,
        ---@type string The species of the character
        Species = "",
        ---@type integer|nil Optional. The form of the character. Defaults to 0
        Form = 0,
        ---@type string|nil Optional. The skin to apply to the character. Defaults to "normal"
        Skin = "normal",
        ---@type integer|nil Optional. The gender of the character. If absent or equal to -1, it will be rolled upon job generation
        Gender = -1
    }
end

-- ----------------------------------------------------------------------------------------- --
-- region LOGGING
-- ----------------------------------------------------------------------------------------- --
-- Functions that write to the output log

--- Prints a message prefixed with an error type.
--- @param error_type string the error type prefix
--- @param message string the message of the error itself
local logError = function(error_type, message)
	PrintInfo("["..error_type.."] "..message)
end

--- Same as "logError" but does not print anything outside of dev mode.
--- Used for out-of-box events that may or may not be intentional, or for
--- low-priority problems that the system can handle by itself without much issue.
--- @param warn_type string the error type prefix
--- @param message string the message of the error itself
local logWarn = function(warn_type, message)
	if _DIAG.DevMode then logError(warn_type, message) end
end

--- Debug function that prints an entire table to console.
--- @param tabl table the table to print
function library:printall(tabl)
    ---@type function
    local printall
	printall = function(tbl, level, root)
		if root == nil then print(" ") end

		if tbl == nil then print("<nil>") return end
		if level == nil then level = 0 end
		for key, value in pairs(tbl) do
			local spacing = ""
			for _=1, level*2, 1 do
				spacing = " "..spacing
			end
			if type(value) == 'table' then
				print(spacing..tostring(key).." = {")
				printall(value, level+1, false)
				print(spacing.."}")
			else
				print(spacing..tostring(key).." = "..tostring(value))
			end
		end

		if root == nil then print(" ") end
	end
	printall(tabl)
end

-- ----------------------------------------------------------------------------------------- --
-- region MISC
-- ----------------------------------------------------------------------------------------- --
-- Miscellaneous helper functions only callable from within this file

--- Rolls a MonsterForm's gender and returns it as a number
--- @param species string the id of the species to roll the gender of
--- @param form integer the index of the form to roll the gender of
--- @return integer #a gender index number
local rollMonsterGender = function(species, form)
	return library:GenderToNumber(_DATA:GetMonster(species).Forms[form]:RollGender(_DATA.Save.Rand))
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

--- Creates a shallow copy of a table by simply creating a new table and copying
--- all surface level key-value pairs into it from the original.
---@generic T : table
---@param tbl T
---@return T
local shallowCopy = function(tbl)
	local copy = {}
	for key, value in pairs(tbl) do
		copy[key] = value
	end
	return copy
end

--- Sorting function used for job lists
--- @param j1 jobTable a job table
--- @param j2 jobTable another job table
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
--- @return boolean|nil #true if there are 0 jobs inside the board, false otherwise. Returns nil if the board does not exist
function library:IsBoardEmpty(board_id)
	if self.data.boards[board_id] then return #self.root.boards[board_id]<=0 else return end
end

--- Checks if a board is full or not
--- @param board_id string the id of the board to check
--- @return boolean|nil #true if there are no more free job slots inside the board, false otherwise. Returns nil if the board does not exist
function library:IsBoardFull(board_id)
	if self.data.boards[board_id] then return #self.root.boards[board_id]>=self.data.boards[board_id].size
	else return end
end

--- Checks if the player's taken job list is empty or not
--- @return boolean #true if there are 0 jobs inside the taken list, false otherwise.
function library:IsTakenListEmpty() return #self.root.taken<=0 end

--- Checks if the player's taken job list is full or not
--- @return boolean true if there are no more free job slots inside the taken list, false otherwise.
function library:IsTakenListFull() return #self.root.taken>=self.data.taken_limit end

--- Checks if the given board has a job in the requested slot
--- @param board_id string the id of the board to check
--- @param index integer|nil The index of the job to check. If omitted, defaults to job 1 of the board.
--- @return boolean #true if the job exists, false otherwise
function library:BoardJobExists(board_id, index)
    return #self.root.boards[board_id] >= (index or 1)
end

--- Checks if two jobs are equal. It compares location, job type, client and target data to do so.
--- @param j1 jobTable a job
--- @param j2 jobTable another job
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
--- @param job jobTable the job to look for
--- @param board_id string the table to look in. If nil, the job will be searched for in the taken list
--- @return integer #the index of the job, or -1 if it was not found.
function library:FindJobInBoard(job, board_id)
	local board = self.root.boards[board_id]
	if not board_id then board = self.root.taken end

	for i, job2 in ipairs(board) do
		if self:JobsEqual(job, job2) then return i end
	end
	return -1
end

--- Given a segment index, return a colored segment.
--- This is obtained by removing the part containing the string "{0}" and wrapping everything else in orange
--- The string containing "{0}" is then returned separately, with the floor placeholder specifically wrapped in cyan
--- @param zone_id string the id of the zone to generate the string of
--- @param segment_index number the index of the segment to generate the string of
--- @return string, string #the name of the zone and the string format containing the floor string
function library:CreateColoredSegmentString(zone_id, segment_index)
	local segment_name = zone_id.." {0}F"
	local segment = _DATA:GetZone(zone_id).Segments[segment_index]

	for step in luanet.each(segment.ZoneSteps) do
		if LUA_ENGINE:TypeOf(step):IsAssignableTo(luanet.ctype(globals.ctypes.FloorNameIDZoneStep)) then
			segment_name = step.Name:ToLocal()
			break
		end
	end

	local split_name = {}
	for str in string.gmatch(segment_name, "([^%s]+)") do
		table.insert(split_name, str)
	end

	local final_name, floor_part = '', ''

	for i = 1, #split_name, 1 do
		local cur_word = split_name[i]

		--save the "floor number" part somewhere else, reconstruct the rest
		local s = string.find(cur_word, '{0}', 1, true)
		if s then
			floor_part = cur_word
			-- assume the string is done if we found the floor part
			break
		else
			if i > 1 then
				final_name = final_name..' '
			end
			final_name = final_name..cur_word
		end
	end

	--Attach color to floor number
	if floor_part ~= "" then
		floor_part = string.gsub(floor_part, '{0}', '[color=#00FFFF]{0}[color]', 1)
	end

	return '[color=#FFC663]'..final_name..'[color]', floor_part
end

--- Given a monsterIDTable, return a colored string.
--- If the monsterIDTable contains a Nickname, it will be used to generate the name, and will always be in cyan.
--- @param char monsterIDTable the character data to generate the string of
--- @return string #the display name of the character
function library:GetCharacterName(char)
	if char then
		if char.Nickname then
			return '[color=#00FFFF]'..char.Nickname..'[color]'
		elseif char.Species ~= "" then
			return _DATA:GetMonster(char.Species):GetColoredName()
		end
	end
	local errorCause = " nil"
	if char then errorCause = "n invalid" end
	logError(globals.error_types.DATA, "GetCharacterName was called using a"..errorCause.." monsterIDTable.")
	return "[color=#FF0000]???[color]"
end

--- Given an item id or table, it returns its colored display name
--- @param item string|itemTable the id of the item to generate the string of
--- @return string #the display name of the item
function library:GetItemName(item)
    if type(item) =="string" then item = {id = item} end
    if not _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Item]:ContainsKey(item.id) then
        return STRINGS:Format("[color=#FF0000]{0}[color]", item.id);
    else
        item.count = item.count or 1
        local data = _DATA:GetItem(item.id)
        local itemname = data:GetColoredName()

        if (data.MaxStack > 1) then itemname = itemname.." (" + item.count + ")" end
        if (data.UsageType == RogueEssence.Data.ItemData.UseType.Treasure) then
            return STRINGS:Format("[color=#6384E6]{0}[color]", itemname);
        else
            return STRINGS:Format("[color=#FFCEFF]{0}[color]", itemname);
        end
    end
end

--- Given a job, it returns its objective string
--- @param job jobTable the job to generate the objective string of
--- @return string #the objective string for the job
function library:GetObjectiveString(job)
	return STRINGS:FormatKey(self.globals.keys[job.Type], self:GetCharacterName(job.Client), self:GetCharacterName(job.Target), self:GetItemName(job.Item))
end

--- Given a job, it returns its location string, complete with floor if the job doesn't hide it
--- @param job jobTable the job to generate the location string of
--- @return string #the location string for the job
function library:GetZoneString(job)
    local zone_string, floor_string = "", ""
    if job.Zone ~= "" and job.Segment>=0 then
        zone_string, floor_string = self:CreateColoredSegmentString(job.Zone, job.Segment)
        floor_string = STRINGS:Format(floor_string, tostring(job.Floor))
    else
        logWarn(globals.warn_types.DATA, "Could not generate loction string for segment "..tostring(job.Segment).." of "..job.Zone.." because it has no display name")
        zone_string, floor_string = job.Zone.."["..tostring(job.Segment).."]", tostring(job.Floor).."F"
    end

    if job.HideFloor then
        return zone_string
    else
        return zone_string .. " " .. floor_string
    end
end

--- Given a job, it returns its difficulty string
--- @param job jobTable the job to generate the difficulty string of
--- @return string #the difficulty string for the job
function library:GetDifficultyString(job)
    local diff_id = self.data.num_to_difficulty[job.Difficulty]
    local key = self.data.difficulty_data[diff_id].display_key
    return STRINGS:FormatKey(key)
end

--- Given a job, it returns its reward string
--- @param job jobTable the job to generate the reward string of
--- @return string #the reward string for the job
function library:GetRewardString(job)
    local reward1 = ""
    if globals.reward_types[job.RewardType][1] then
        reward1 = self:GetItemName(job.Reward1)
    else
        local diff_id = self.data.num_to_difficulty[self.job.Difficulty]
        local money = self.data.difficulty_data[diff_id].money_reward
        reward1 = STRINGS:FormatKey("MONEY_AMOUNT", money)
    end
    local key = globals.reward_types[job.RewardType][4]
    return STRINGS:FormatKey(key, reward1)
end

---Checks if there is at least one external event happening in the specified zone.
---@param zone string the zone to run the checks on
---@return boolean #true if any check returns true, false oterwise
function library:HasExternalEvents(zone)
    for _, condition_data in ipairs(self.data.external_events) do
        if condition_data.condition(zone) then return true end
    end
    return false
end

---Checks for all external events and returns a list of all events that returned true
---@param zone string the zone to run the checks on
---@return {condition:fun(zone:string):(boolean), message_key:string|nil, message_args:fun(zone:string):(string[])|nil, icon:string|nil}[] #a list of all checks whose condition is fulfilled
function library:GetExternalEvents(zone)
    local conditions = {}
    for _, condition_data in ipairs(self.data.external_events) do
        if condition_data.condition(zone) then table.insert(conditions, condition_data) end
    end
    return conditions
end

-- ----------------------------------------------------------------------------------------- --
-- region DATA CONVERTERS
-- ----------------------------------------------------------------------------------------- --
-- Functions that convert data between C# and lua representation

--- Converts a number to the Gender it represents. Invalid numbers will be marked as Unknown.
--- @param number integer a number from -1 to 2.
--- @return userdata a RogueEssence.Data.Gender object
function library:NumberToGender(number)
	local res = Gender.Unknown
	if number == globals.gender.Genderless then
		res = Gender.Genderless
	elseif number == globals.gender.Male then
		res = Gender.Male
	elseif number == globals.gender.Female then
		res = Gender.Female
	end
	return res
end

--- Converts a Gender object to its number representation.
--- @param gender userdata a RogueEssence.Data.Gender object
--- @return integer a number between -1 and 2
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

--- Fills out a MonsterIDTable's missing properties
--- Form, String and Gender are optional. If absent, Gender is rolled randomly, while the others will be set to 0 and "normal" respectively.
--- @param table monsterIDTable a table formatted like so: {Species = string, [Form = int], [Skin = string], [Gender = int]}
--- @return monsterIDTable #the same table, but with all required data filled out
function library:NormalizeMonsterIDTable(table)
	table.Form = table.Form or 0
	table.Skin = table.Skin or "normal"
	table.Gender = table.Gender or rollMonsterGender(table.Species, table.Form)
	return table
end

--- Converts a table formatted like a MonsterID object into its c# equivalent.
--- Form, String and Gender are optional. If absent, Gender is rolled randomly, while the others will be set to 0 and "normal" respectively.
--- @param table monsterIDTable a table formatted like so: {Species = string, [Form = int], [Skin = string], [Gender = int]}
--- @return MonsterID a fully formed RogueEssence.Data.MonsterID object
function library:TableToMonsterID(table)
	table.Form = table.Form or 0
	table.Skin = table.Skin or "normal"
	table.Gender = table.Gender or rollMonsterGender(table.Species, table.Form)
	return RogueEssence.Dungeon.MonsterID(table.Species, table.Form, table.Skin, self:NumberToGender(table.Gender))
end

--- Converts a RogueEssence.Data.MonsterID object to a format that is more compatible with lua and the SV table.
--- You can include a nickname property if you so wish.
--- @param monsterId MonsterID a fully formed RogueEssence.Data.MonsterID object
--- @param nickname? string Optional. A nickname to store with the MonsterId data
--- @return monsterIDTable #a table formatted like so: {Nickname = string, Species = string, Form = int, Skin = string, Gender = int}
function library:MonsterIDToTable(monsterId, nickname)
	local table = monsterIdTemplate()
	table.Nickname = nickname
	table.Species = monsterId.Species
	table.Form = monsterId.Form
	table.Skin = monsterId.Skin
	table.Gender = self:GenderToNumber(monsterId.Gender)
	return table
end

-- ----------------------------------------------------------------------------------------- --
-- region RANDOMIZATION
-- ----------------------------------------------------------------------------------------- --
-- Functions for randomization purposes

--- Returns a random element of the list.
--- Elements must have a "weight" property, otherwise their weight will default to 1.
--- @generic T:table
--- @param list T[] the list of elements to roll.
--- @param replay_sensitive? boolean if true, this function will use a replay-safe rng function. Defaults to false.
--- @return T|nil, number|nil #the element extracted and its index in the list, or nil, nil if the list was empty
function library:WeightedRandom(list, replay_sensitive)
    local entry, index = self:WeightlessRandomExclude(list, {}, replay_sensitive)
	return entry, index
end

--- Returns a random element of the list, excluding any key in the exclude table.
--- Elements must have a "weight" property, otherwise their weight will default to 1.
--- @generic T:table
--- @param list T[] the list of elements to roll.
--- @param exclude any[] a table whose keys are the ids of the elements to exclude from the roll, and the value can be anything except "nil" and "false"
--- @param replay_sensitive? boolean if true, this function will use a replay-safe rng function. Defaults to false.
--- @param alt_id? string name of the id property, in case "id" isn't good enough. Use an empty string to require the object itself to be equal instead.
--- @return T|nil, number|nil #the element extracted and its index in the list, or nil, nil if the final list was empty
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
	if weight <= 0 then return end
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
--- @generic T:any
--- @param list T[] the list of elements to roll.
--- @param replay_sensitive? boolean if true, this function will use a replay-safe rng function. Defaults to false.
--- @return T|nil, number|nil #the element extracted and its index in the list, or nil, nil if the list was empty
function library:WeightlessRandom(list, replay_sensitive)
	if #list == 0 then return end
	local roll = -1
	if replay_sensitive
	then roll = math.random(1, #list)
	else roll = _DATA.Save.Rand:Next(#list)+1 --this one includes 0 but doesn't include the max value so +1 it is
	end
	return list[roll], roll
end

--- Returns a random element of the list, excluding any key in the exclude table.
--- All elements have the same chance of being returned.
--- @generic T:any
--- @param list T[] the list of elements to roll.
--- @param exclude T[] a table whose keys are the the elements to exclude from the roll, and the value can be anything except "nil" and "false"
--- @param replay_sensitive? boolean if true, this function will use a replay-safe rng function. Defaults to false.
--- @return T|nil, number|nil #the element extracted and its index in the list, or nil, nil if the final list was empty
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
-- Core library functions

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
	for board, board_data in pairs(self.data.boards) do
	    if not board_data.condition or board_data.condition(self) then
		    self:PopulateBoard(board, destinations)
		end
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
--- @return {destinations:string[], floors_allowed:{segment:integer, floor:integer, difficulty:string}[]} #a list of valid destination zones and the list of allowed floors for each destination
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
			    if not self:HasExternalEvents(zone) then --skip segments that are locked by external conditons
                    local validSegemnt = true
                    if self.root.dungeon_progress[zone][segment] == nil then
                        validSegemnt = false					 -- remove segments not unlocked
                    elseif self.root.dungeon_progress[zone][segment] == false then
                        validSegemnt = not segment_data.must_end -- remove "must_end" segments that are not completed
                    elseif self.root.dungeon_progress[zone][segment] == true then
                        validSegemnt = true						 -- completed dungeons are always ok
                    end
                    if validSegemnt then
                    local section = segment_data.sections
                        for i=section[1].start, segment_data.max_floor, 1 do
                            if not floors_occupied[zone][segment][i] then
                                if not job_options.floors_allowed[zone] then
                                    job_options.floors_allowed[zone] = {}
                                    table.insert(job_options.destinations, zone)
                                end
                                table.insert(job_options.floors_allowed[zone], {segment = segment, floor = i, difficulty = section.difficulty})
                            end
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
--- @return table<string,integer> #a table whose keys are zone ids and whose values are the number of guest jobs present in that dungeon
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
	return guest_count
end

--- Tries to fill up as many empty slots as possible in the board. It will keep going from
--- wherever the board was at when this function was called.
--- It is recommended to flush the board beforehand to ensure it is actually generating new jobs.
--- @param board_id string the id of the board to generate jobs for
--- @param destinations {destinations:string[], floors_allowed:{segment:integer, floor:integer, difficulty:string}[]} valid destination table created by "GetValidDestinations()". It also gets updated in-place for coherent and quick reuse. If absent, it will be generated in-place.
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
		---@cast zone string because we already checked there is at least 1 possible result
		cleanUpInvalidFloors(zone, destinations)

		if not destinations.floors_allowed[zone] or #destinations.floors_allowed[zone] <= 0 then
			--clean up and try again if there are no valid destinations in this dungeon
			destinations.floors_allowed[zone] = nil
			table.remove(destinations.destinations, zone_index)
		else
			local dest2, dest2_index = self:WeightlessRandom(destinations.floors_allowed[zone])
			---@cast dest2 {segment:integer, floor:integer, difficulty:string} because we already checked there is at least 1 possible result
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
				local job_type = self:WeightedRandom(possible_job_types).id --[[@as string]] --it is safe because we already checked there is at least 1 possible result
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
				local client, target = nil, nil
				local tier = self:WeightedRandom(self.data.difficulty_to_tier[difficulty]).id
				if special then
					local special_data = self.data.special_data[special][tier]
					---@cast special_data {client:monsterIDTable|string, target:monsterIDTable|string, flavor:string}
					client = special_data.client
					target = special_data.target
					newJob.Flavor[1] = special_data.flavor
				else
				    -- Change tier if the currently picked one has no seen mons, choosing the most common
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
					-- choose any from the originally picked list if there are no options anywhere
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
					if not roll then
					    logError(globals.error_types.DATA, "Setting \"enforcer_chance\" has no possible value for tier \"..tier..\"")
					    break
					end
					if roll.id == globals.keywords.AGENT and roll.index and roll.index>0 and roll.index<=#self.data.law_enforcement.AGENT then
						client = self.data.law_enforcement.AGENT[roll.index]
					else
						client = roll.id
					end
				end
				if target == globals.keywords.ENFORCER then
					local roll = self:WeightedRandom(self.data.enforcer_chance[tier])
					if not roll then
					    logError(globals.error_types.DATA, "Setting \"enforcer_chance\" has no possible value for tier \"..tier..\"")
					    break
					end
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
					---@cast client monsterIDTable
				end
				if target == globals.keywords.AGENT then
                    target = self:WeightedRandomExclude(self.data.law_enforcement.AGENT, {client}, false, "")
					---@cast target monsterIDTable
				end
				local abort = false
                if type(client) ~= "table" then
                    logError(globals.error_types.DATA, "Could not generate job client. Its final value was: "..tostring(client))
                    abort = true
                end
                if target and type(target) ~= "table" then
                    logError(globals.error_types.DATA, "Could not generate job target. Its final value was: "..tostring(target))
                    abort = true
                end
                if abort then break end
				newJob.Client = self:NormalizeMonsterIDTable(client)
				if target then newJob.Target = self:NormalizeMonsterIDTable(target) end



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
					reward_type = self:WeightedRandom(possible_reward_types).id --[[@as string]] --it is safe because we already checked there is at least 1 possible result
				end

				local difficulty_id = self.data.num_to_difficulty[difficulty]
				newJob.RewardType = reward_type

                ---@type {[1]:string|table, [2]:string|table}
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
								local checked = {}
								---@type table|nil
								local result = {}
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
										result = self:WeightedRandomExclude(self.data.reward_pools[pool], checked)
										if result then pool = result.id
										else result = nil end
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
				if not newJob.Flavor[1] then
				    logError(globals.error_types.DATA, "No possible flavor text for job type \""..job_type.."\"")
				    newJob.Flavor = {"", ""}
				end

				local title_group = job_type
				if special ~= "" then
					title_group = special
				end
				local title = self:WeightlessRandom(self.data.job_titles[title_group])
				if not title then
				    logError(globals.error_types.DATA, "No possible titles for quest category \""..title_group.."\"")
				end
				newJob.Title = title or ""

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

--- Runs the script responsible for interacting with a quest board.
--- It will first display a menu where players can choose to check either the board or the taken list.
--- @param board_id string the id of the board to interact with
function library:BoardInteract(board_id)
	local loop = true
	while loop do
		local job_selected = 1
		local choice = menus.BoardSelection.run(self, board_id)
		if choice == 1 then
			while true do
				job_selected = menus.Board.run(self, board_id, job_selected)
				if job_selected > 0 then
					while true do
						local action = menus.Job.run(self, board_id, job_selected)
						if action == 1 then
							self:TakeJob(board_id, job_selected)
						else break end
					end
				else break end
			end
		elseif choice == 2 then
			--exit board menu if the taken list is empty
			while not self:IsTakenListEmpty() do
				job_selected = menus.Board.run(self, nil, job_selected)
				if job_selected > 0 then
					while true do
						local action = menus.Job.run(self, nil, job_selected)
						if action == 1 then
							self:ToggleTakenJob(job_selected)
						elseif action == 2 then
							self:RemoveTakenJob(job_selected)
							break
						else break end
					end
				else break end
			end
		else
			loop = false
		end
	end
end

--- Runs the callback script responsible for interacting with the taken list.
--- This function is built as a callback stack and only works if used while already inside a menu handling routine.
function library:OpenTakenMenuFromMain()
	local exit_menu = false
	local job_selected = 1
	local continue = true

	local job_cb = function(index)
		if index == 1 then
			self:ToggleTakenJob(job_selected)
		elseif index == 2 then
			self:RemoveTakenJob(job_selected)
			continue = false
		else continue = false end
	end
	local board_cb = function(index)
		job_selected = index
		if job_selected > 0 then
			continue = true
			while continue do menus.Job.add(self, nil, job_selected, job_cb) end
		else exit_menu = true end
	end

	while not self:IsTakenListEmpty() do
		if exit_menu then break end
		menus.Board.add(self, nil, board_cb, job_selected)
	end
	if self:IsTakenListEmpty() then _MENU:ClearMenus() end
end


--- Runs the script responsible for displaying one specific job.
--- It will skip all previous menus and go to the job interaction menu directly.
--- This function does not check if the job exists. Please call library:BoardJobExists before this.
--- @param board_id string the id of the board to interact with
--- @param index integer|nil The index of the job to show. If omitted, defaults to job 1 of the board.
--- @return boolean #true if the job was taken, false otherwise
function library:ShowSingularJob(board_id, index)
	index = index or 1
	local action = menus.Job.run(self, board_id, index)
	if action == 1 then
	    self:TakeJob(board_id, index)
	    return true
	end
	return false
end

--- Runs the callback script responsible for displaying the list of current objectives.
--- This function only works if used while already inside a menu handling routine.
function library:OpenObjectivesMenu()
	menus.Objectives.add(self)
end

--- Marks the job as taken and adds a copy of it to the taken board.
--- The copy will have its BackReference set to board_id.
--- @param board_id string the id of the board the job is in
--- @param index integer The index of the job to take
function library:TakeJob(board_id, index)
	local job = self.root.boards[board_id][index]
	local taken = shallowCopy(job)
	job.Taken = true
	taken.BackReference = board_id
	taken.Taken = self.data.taken_jobs_start_active
	table.insert(self.root.taken, taken)
	self:SortTaken()
end

--- Removes a job from the taken list.
--- The original job, if it still exists, will be marked as not Taken.
--- @param index integer The index of the job to delete
function library:RemoveTakenJob(index)
	local job = self.root.taken[index]
	if job.BackReference then
		local bRefIndex = self:FindJobInBoard(job, job.BackReference)
		if bRefIndex > 0 then
			self.root.boards[job.BackReference][bRefIndex].Taken = false
		end
	end
	table.remove(self.root.taken, index)
	-- no need to sort here because they are guaranteed to be in order thanks to sorting every time a job is taken
end

--- Changes a taken job's active status.
--- @param index integer The index of the job to toggle
function library:ToggleTakenJob(index)
	self.root.taken[index].Taken = not self.root.taken[index].Taken
end

-- ----------------------------------------------------------------------------------------- --
-- region COMMON support
-- ----------------------------------------------------------------------------------------- --
-- API specific for functions that are meant for common.lua

--- Meant to be called in COMMON.ShowDestinantonMenu
--- Creates a reference table whose keys are all the zones with at least one job in them.
---@return table<string|boolean>
function library:LoadJobDestinations()
    local mission_dests = {}
    for _, job in ipairs(self.root.taken) do
        if job.Taken then
            if not self:HasExternalEvents(job.Zone) then
                mission_dests[job.Zone] = true
            else
                job.Taken = false
            end
        end
    end
    return mission_dests
end

--- Meant to be called in COMMON.ShowDestinantonMenu
--- Takes a zone name and its id and returns a name string that also contains any related job and event icons.
--- @param mission_dests table<string,boolean> the set of job destinations
--- @param zone_id string the zone id string to format the name of
--- @param zone_name string the starting name of the zone, as extracted from its ZoneEntrySummary
--- @return string #the zone name string containing all the icons related to it.
function library:FormatDestinationMenuZoneName(mission_dests, zone_id, zone_name)
	local mission_icon, external_icons, ext_set = "", "", {}
    -- add open letter icon to dungeons with jobs
    if mission_dests[zone_id] then mission_icon = "\\" end --open letter
    -- add external icon to dungeons with external events
    local ext_conds = self:GetExternalEvents(zone_id)
    for _, ext in ipairs(ext_conds) do
        if ext.icon and ext.icon ~= "" and not ext_set[ext.icon] then
            ext_set[ext.icon] = true
            external_icons = external_icons .. (ext.icon)
            if self.data.external_events_icon_mode == "FIRST" then break end
        end
    end
    return STRINGS:Format(self.data.dungeon_list_pattern, zone_name, STRINGS:Format(mission_icon), STRINGS:Format(external_icons))
end

--- Meant to be called in COMMON:EnterDungeonMissionCheck
--- Prepares the list of guests to be spawned and reduces the team limit accordingly if missiongen_settings.guests_take_up_space is set.
--- @param zone_id string the zone id string to prepare the guest data for
--- @return jobTable[], string[] #the list of indexes for jobs that have guests and the list of removed ally names.
function library:EnterDungeonPrepareParty(zone_id)
    local escort_jobs = {}

    for _, job in ipairs(library.root.taken) do
        if job.Taken and job.Completion < 1 and zone_id == job.Zone and globals.job_types[job.Type][3] then --has escort
            --check to see if an escort is already in the team for this job. If so, don't include it in the guest list
            local guest_found = false
            for i = 0, _DATA.Save.ActiveTeam.Guests.Count - 1, 1 do
                local guest_tbl = GAME:GetPlayerGuestMember(i).LuaData
                if library:JobsEqual(guest_tbl.JobReference, job) then
                    guest_found = true
                end
            end
            if not guest_found then
                table.insert(escort_jobs, job)
            end
        end
    end

    UI:ResetSpeaker()
    -- if set to do so, remove as many characters from the team as necessary and reduce the team limit accordingly
    local removed_names = {}
    if self.data.guests_take_up_space then --TODO handle dungeons that reduce the team limit
        self.root.previous_limit = RogueEssence.Dungeon.ExplorerTeam.MAX_TEAM_SLOTS
        RogueEssence.Dungeon.ExplorerTeam.MAX_TEAM_SLOTS = math.max(1, self.data.min_party_limit,
            self.root.previous_limit - #escort_jobs)
        for i = RogueEssence.Dungeon.ExplorerTeam.MAX_TEAM_SLOTS, _DATA.Save.ActiveTeam.Players.Count - 1, 1 do
            table.insert(removed_names, _DATA.Save.ActiveTeam.Players[i].Name)
            _GAME.CurrentScene:SilentSendHome(i)
        end
    end
    return escort_jobs, removed_names
end

--- Generates the clients of the provided jobs and adds them as guests.
--- @param zone_id string the zone id string to generate the guests for
--- @param escort_jobs jobTable[] the list of jobs to generate guests from
--- @return string[] #the list list of added guest names.
function library:EnterDungeonAddJobEscorts(zone_id, escort_jobs)
    local zone_summary = _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Zone]:Get(zone_id)

    -- calculate party-related level parameters
    local party_tot, party_avg, party_hst, party_count = 0, 0, 0, _DATA.Save.ActiveTeam.Players.Count
    for i = 0, party_count - 1, 1 do
        local char_lvl = _DATA.Save.ActiveTeam.Players[i].Level
        party_tot = party_tot + char_lvl
        party_hst = math.max(char_lvl, party_hst)
    end
    party_avg = party_tot // party_count

    -- add escorts to team
    local added_names = {}
    for _, job in ipairs(escort_jobs) do
        local nickname = job.Client.Nickname or ""
        local mId = self:TableToMonsterID(job.Client)
        local diff = self.data.num_to_difficulty[job.Difficulty]
        local level = self.data.difficulty_data[diff].escort_level
        local dungeon_default = not level
        if dungeon_default then level = zone_summary.Level end
        level = self.data.guest_level_scaling(level, dungeon_default, party_avg, party_hst, self.data)

        local new_mob = _DATA.Save.ActiveTeam:CreatePlayer(_DATA.Save.Rand, mId, level, "", -1)
        new_mob.Nickname = nickname
        local tactic = _DATA:GetAITactic("stick_together")
        new_mob.Tactic = RogueEssence.Data.AITactic(tactic);
        _DATA.Save.ActiveTeam.Guests:Add(new_mob)
        local talk_evt = RogueEssence.Dungeon.BattleScriptEvent("EscortInteract") --TODO
        new_mob.ActionEvents:Add(talk_evt)
        local tbl = new_mob.LuaData
        tbl.JobReference = job
        table.insert(added_names, "[color=#00FF00]" .. new_mob.Name .. "[color]")
    end
    return added_names
end

--- Prints a SENT_HOME message using the provided list of formatted character display names.
--- @param removed_list string[] a list of character display names
function library:PrintSentHome(removed_list)
	if #removed_list<1 then return end
    UI:ResetSpeaker()
    local list_removed = STRINGS:CreateList(removed_list) --[[@as string]]
    if #removed_list > 1 then
        UI:WaitShowDialogue(STRINGS:FormatKey("MSG_TEAM_SENT_HOME_PLURAL", list_removed))
    elseif #removed_list == 1 then
        UI:WaitShowDialogue(STRINGS:FormatKey("MSG_TEAM_SENT_HOME", list_removed))
    end
end

--- Prints an ESCORT_ADD message using the provided list of formatted character display names.
--- @param added_list string[] a list of character display names
function library:PrintEscortAdd(added_list)
    if #added_list < 1 then return end
    UI:ResetSpeaker()
    local list_removed = STRINGS:CreateList(added_list) --[[@as string]]
    if #added_list > 1 then
        UI:WaitShowDialogue(STRINGS:FormatKey("MISSION_ESCORT_ADD_PLURAL", list_removed))
    elseif #added_list == 1 then
        UI:WaitShowDialogue(STRINGS:FormatKey("MISSION_ESCORT_ADD", list_removed)) --TODO make globals
    end
end

library.globals = globals
library:load() --TODO migrate load routine to OnSaveLoad
return library