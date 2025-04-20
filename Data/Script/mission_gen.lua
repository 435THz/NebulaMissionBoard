require 'enable_mission_board.common'

--Halcyon Custom work ported to PMDO Vanilla:
--Code in this folder is used to generate, display, and handle randomized missions
--and all that goes with that (rewards, rankups, etc)


--A job is saved as a list of variables, where each variable represents an attribute of the job, such as reward, client, destination floor, etc.
--There are 3 sets of lua lists then. One for the missions taken, one for the missions on the job board, and one for the missions on the outlaw board.
--Each of those lists can only have up to 8 jobs.

--List of mission attributes:
--Client (the pokemon in need of escort, rescue, or the person asking for an outlaw capture). Given as species string
--Target (Pokemon in need of rescue, or the one to escort to, or the mon to be arrested). Given as species string
--Escort Species - should be given as a blank if this is not an escort mission.
--Zone (dungeon)
--Segment (part of the dungeon) - this is typically the default segment
--Floor 
--Reward - given as item name's string. If money, should be given as "Money" and the amount will be based off the difficulty.
--Mission Type - outlaw, escort, or rescue
--Completion status - Incomplete or Complete. When a reward is handed out at the end of the day, any missions that are completed should be removed from the taken board.
--Taken - Was the mission on the board taken? This is also used to suspend missions that were taken off the board
--Difficulty - Letter rank that are hardcoded to represent certain number amounts
--Flavor - Flavor text for the mission, should be a string in strings.resx that can potentially be filled in by blanks.

--Hardcoded number values. Adjust those sorts of things here.
--Difficulty's point ranks
MISSION_GEN = {}

--color coding for mission difficulty letters
MISSION_GEN.DIFF_TO_COLOR = {}
MISSION_GEN.DIFF_TO_COLOR[""] = "[color=#000000]"
MISSION_GEN.DIFF_TO_COLOR["F"] = "[color=#A1A1A1]"
MISSION_GEN.DIFF_TO_COLOR["E"] = "[color=#F8F8F8]"
MISSION_GEN.DIFF_TO_COLOR["D"] = "[color=#F8C8C8]"
MISSION_GEN.DIFF_TO_COLOR["C"] = "[color=#40F840]"
MISSION_GEN.DIFF_TO_COLOR["B"] = "[color=#F8C060]"
MISSION_GEN.DIFF_TO_COLOR["A"] = "[color=#00F8F8]"
MISSION_GEN.DIFF_TO_COLOR["S"] = "[color=#F80000]"
MISSION_GEN.DIFF_TO_COLOR["STAR_1"] = "[color=#F8F800]"
MISSION_GEN.DIFF_TO_COLOR["STAR_2"] = "[color=#F8F800]"
MISSION_GEN.DIFF_TO_COLOR["STAR_3"] = "[color=#F8F800]"
MISSION_GEN.DIFF_TO_COLOR["STAR_4"] = "[color=#F8F800]"
MISSION_GEN.DIFF_TO_COLOR["STAR_5"] = "[color=#F8F800]"
MISSION_GEN.DIFF_TO_COLOR["STAR_6"] = "[color=#F8F800]"
MISSION_GEN.DIFF_TO_COLOR["STAR_7"] = "[color=#F8F800]"
MISSION_GEN.DIFF_TO_COLOR["STAR_8"] = "[color=#F8F800]"
MISSION_GEN.DIFF_TO_COLOR["STAR_9"] = "[color=#F8F800]"

MISSION_GEN.SPECIAL_OUTLAW = {

}

--Do the stairs go up or down? Blank string if up, B if down
SV.StairType = {}
SV.StairType[""] = ""

function MISSION_GEN.GetStairsType(zone_id)
    if SV.StairType[zone_id] ~= nil then
        return SV.StairType[zone_id]
    end

    return ''
end


function MISSION_GEN.MissionBoardIsEmpty()
    for k, v in pairs(SV.MissionBoard) do
        if v.Client ~= '' then
            return false
        end
    end

    return true
end


function MISSION_GEN.TakenBoardIsEmpty()
    for k, v in pairs(SV.TakenBoard) do
        if v.Client ~= '' then
            return false
        end
    end

    return true
end

function MISSION_GEN.WeightedRandom(weights)
    local summ = 0
    for i, value in pairs (weights) do
        summ = summ + value[2]
    end
    if summ == 0 then return end
    -- local value = math.random (summ) -- for integer weights only
    local rand = summ*math.random ()
    summ = 0
    for i, value in pairs (weights) do
        summ = summ + value[2]
        if rand <= summ then
            return value[1]--, weight
        end
    end
end


function MISSION_GEN.has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end



function MISSION_GEN.ResetBoards()
    SV.ExpectedLevel = {}
    SV.DungeonOrder = {}
    SV.StairType = {}
end

function MISSION_GEN.GetDifficultyString(difficulty_val)
    local star_icon = STRINGS:Format("\\uE10C") --star icon
    local difficulty_string = ""
    local difficulty_text_strings = {}
    for str in string.gmatch(difficulty_val, "([^_]+)") do
        table.insert(difficulty_text_strings, str)
    end

    if #difficulty_text_strings == 1 then
        difficulty_string = difficulty_text_strings[1]
    elseif #difficulty_text_strings == 2 then
        --STAR
        difficulty_string = difficulty_text_strings[2] .. star_icon
    end

    return difficulty_string
end

--Generate a board. Board_type should be given as "Mission" or "Outlaw".
--Job/Outlaw Boards should be cleared before being regenerated.
function MISSION_GEN.GenerateBoard(result, board_type)
    local jobs_to_make = 8
    local assigned_combos = {}--floor/dungeon combinations that already have had missions genned for it. Need to consider already genned missions and missions on taken board.

    -- All seen Pokemon in the pokedex
    --local seen_pokemon = {}

    --for entry in luanet.each(_DATA.Save.Dex) do
    --	if entry.Value == RogueEssence.Data.GameProgress.UnlockState.Discovered then
    --		table.insert(seen_pokemon, entry.Key)
    --	end
    --end

    --print( seen_pokemon[ math.random( #seen_pokemon ) ] )

    --default to mission.
    local mission_type = COMMON.MISSION_BOARD_MISSION
    if board_type == COMMON.MISSION_BOARD_OUTLAW then mission_type = COMMON.MISSION_BOARD_OUTLAW end


    --generate jobs
    for i = 1, jobs_to_make, 1 do
        --choose a dungeon, client, target, item, etc
        local client = ""
        local item = ""
        local special = ""
        local title = "Default title."
        local flavor = "Default flavor text."


        --generate the objective.
        local objective

        if objective == COMMON.MISSION_TYPE_DELIVERY then
            item = MISSION_GEN.DELIVERABLE_ITEMS[math.random(1, #MISSION_GEN.DELIVERABLE_ITEMS)]
        elseif objective == COMMON.MISSION_TYPE_OUTLAW_ITEM then
            item = MISSION_GEN.STOLEN_ITEMS[math.random(1, #MISSION_GEN.STOLEN_ITEMS)]
        elseif objective == COMMON.MISSION_TYPE_LOST_ITEM then
            item = MISSION_GEN.LOST_ITEMS[math.random(1, #MISSION_GEN.LOST_ITEMS)]
        end

        local difficulty

        --Generate a tier, then the client
        local tier = MISSION_GEN.WeightedRandom(MISSION_GEN.DIFF_POKEMON[difficulty])
        local client_candidates = MISSION_GEN.POKEMON[tier]
        client = client_candidates[math.random(1, #client_candidates)]

        --50% chance that the client and target are the same. Target is the escort if its an escort mission.
        --It is possible for this to roll the same target as the client again, which is fine.
        --Always give a target if objective is escort or a outlaw stole an item.
        --Target should always be client for 
        local target = client
        local target_candidates = MISSION_GEN.POKEMON[tier]
        if math.random(1, 2) == 1 or objective == COMMON.MISSION_TYPE_ESCORT or objective == COMMON.MISSION_TYPE_OUTLAW_ITEM then
            target = target_candidates[math.random(1, #target_candidates)]
            --print(target_candidates[1]) --to give an idea of what tier we rolled
        end

        --if its a generic outlaw mission, or a monster house / fleeing outlaw, Magna is the client. Normal mons only ask you to go after their stolen items.
        if objective == COMMON.MISSION_TYPE_OUTLAW or objective == COMMON.MISSION_TYPE_OUTLAW_FLEE or objective == COMMON.MISSION_TYPE_OUTLAW_MONSTER_HOUSE then
            client = "magna"
        end

        --if it's a delivery, exploration, or lost item, target and client should match.
        if objective == COMMON.MISSION_TYPE_EXPLORATION or objective == COMMON.MISSION_TYPE_DELIVERY or objective == COMMON.MISSION_TYPE_LOST_ITEM then
            target = client
        end


        --Reroll target if target is ghost and target is a fleeing outlaw, that shit would be too obnoxious to deal with
        local target_type_1 = _DATA:GetMonster(target).Forms[0].Element1
        local target_type_2 = _DATA:GetMonster(target).Forms[0].Element2
        while objective == COMMON.MISSION_TYPE_OUTLAW_FLEE and (target_type_1 == "ghost" or target_type_2 == "ghost") do
            print(target .. ": Rerolling cowardly ghost outlaw!!!")
            target = target_candidates[math.random(1, #target_candidates)]
            target_type_1 = _DATA:GetMonster(target).Forms[0].Element1
            target_type_2 = _DATA:GetMonster(target).Forms[0].Element2
            print("new target is " .. target)
        end

        --Roll for genders. Use base form because it PROBABLY won't ever matter.
        --because Scriptvars doesnt like saving genders instead of regular structures, use 1/2/0 for m/f/genderless respectively, and convert when needed
        local client_gender

        local rand = nil

        if _ZONE.CurrentMap ~= nil and _ZONE.CurrentMap.Rand ~= nil then
            rand = _ZONE.CurrentMap.Rand
        else
            rand = GAME.Rand
        end

        if client == "magna" then --Magna is a special exception
            client_gender = 0
        else
            client_gender = _DATA:GetMonster(client).Forms[0]:RollGender(rand)
            client_gender = COMMON.GenderToNum(client_gender)
        end

        local target_gender = _DATA:GetMonster(target).Forms[0]:RollGender(rand)

        target_gender = COMMON.GenderToNum(target_gender)

        --Special cases
        --Roll for the main 3 rescue special cases 
        if objective == COMMON.MISSION_TYPE_RESCUE and math.random(1, 10) <= 2 then
            local special_candidates = {}
            special = MISSION_GEN.SPECIAL_CLIENT_OPTIONS[math.random(1, #MISSION_GEN.SPECIAL_CLIENT_OPTIONS)]
            if special == MISSION_GEN.SPECIAL_CLIENT_CHILD then
                special_candidates = MISSION_GEN.SPECIAL_CHILD_PAIRS[tier]
            elseif special == MISSION_GEN.SPECIAL_CLIENT_LOVER then
                special_candidates = MISSION_GEN.SPECIAL_LOVER_PAIRS[tier]
            elseif special == MISSION_GEN.SPECIAL_CLIENT_RIVAL then
                special_candidates = MISSION_GEN.SPECIAL_RIVAL_PAIRS[tier]
            elseif special == MISSION_GEN.SPECIAL_CLIENT_FRIEND then
                special_candidates = MISSION_GEN.SPECIAL_FRIEND_PAIRS[tier]
            end


            --Set variables with special client/target info
            local special_choice = special_candidates[math.random(1, #special_candidates)]
            client = special_choice[1]
            client_gender = special_choice[2]
            target = special_choice[3]
            target_gender = special_choice[4]

            local special_title_candidates = MISSION_GEN.TITLES[special]
            title = RogueEssence.StringKey(special_title_candidates[math.random(1, #special_title_candidates)]):ToLocal()

            flavor = RogueEssence.StringKey(special_choice[5]):ToLocal()


        end




        --generate reward with hardcoded list of weighted rewards
        local reward = "money"
        --1/4 chance you get money instead of an item

        if math.random(1, 4) > 1 then
            local reward_pool = MISSION_GEN.REWARDS[MISSION_GEN.WeightedRandom(MISSION_GEN.DIFF_REWARDS[difficulty])]
            reward = MISSION_GEN.WeightedRandom(reward_pool)
        end

        --1/3 chance you get a bonus reward. Bonus reward is always an item, never money 
        local bonus_reward = ""

        if math.random(1,3) == 1 then
            local reward_pool = MISSION_GEN.REWARDS[MISSION_GEN.WeightedRandom(MISSION_GEN.DIFF_REWARDS[difficulty])]
            bonus_reward = MISSION_GEN.WeightedRandom(reward_pool)
        end

        --Choose a random title that's appropriate.
        local title_candidates = {}

        if special == "" then -- get title if special didn't already generate it
            if objective == COMMON.MISSION_TYPE_RESCUE and client ~= target then
                title_candidates = MISSION_GEN.TITLES["RESCUE_FRIEND"]
            elseif objective == COMMON.MISSION_TYPE_RESCUE and client == target then
                title_candidates = MISSION_GEN.TITLES["RESCUE_SELF"]
            elseif objective == COMMON.MISSION_TYPE_ESCORT then
                title_candidates = MISSION_GEN.TITLES["ESCORT"]
            elseif objective == COMMON.MISSION_TYPE_EXPLORATION then
                title_candidates = MISSION_GEN.TITLES["EXPLORATION"]
            elseif objective == COMMON.MISSION_TYPE_LOST_ITEM then
                title_candidates = MISSION_GEN.TITLES["LOST_ITEM"]
            elseif objective == COMMON.MISSION_TYPE_DELIVERY then
                title_candidates = MISSION_GEN.TITLES["DELIVERY"]
            elseif objective == COMMON.MISSION_TYPE_OUTLAW then
                title_candidates = MISSION_GEN.TITLES["OUTLAW"]
            elseif objective == COMMON.MISSION_TYPE_OUTLAW_ITEM then
                title_candidates = MISSION_GEN.TITLES["OUTLAW_ITEM"]
            elseif objective == COMMON.MISSION_TYPE_OUTLAW_MONSTER_HOUSE then
                title_candidates = MISSION_GEN.TITLES["OUTLAW_MONSTER_HOUSE"]
            elseif objective == COMMON.MISSION_TYPE_OUTLAW_FLEE then
                title_candidates = MISSION_GEN.TITLES["OUTLAW_FLEE"]
            end
            title = RogueEssence.StringKey(title_candidates[math.random(1, #title_candidates)]):ToLocal()

            --string substitutions, if needed.
            if string.find(title, "%[target%]") then
                title = string.gsub(title, "%[target%]", _DATA:GetMonster(target):GetColoredName())
            end

            if string.find(title, "%[dungeon%]") then
                title = string.gsub(title, "%[dungeon%]", _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Zone]:Get(dungeon):GetColoredName())
            end

            if string.find(title, "%[item%]") then
                title = string.gsub(title, "%[item%]",  _DATA:GetItem(item):GetColoredName())
            end
        end



        --Flavor text generation
        local flavor_top_candidates = {}
        local flavor_bottom_candidates = {}

        if special == "" then -- get flavor if special didn't already generate it 
            if objective == COMMON.MISSION_TYPE_RESCUE and client ~= target then
                flavor_top_candidates = MISSION_GEN.FLAVOR_TOP["RESCUE_FRIEND"]
                flavor_bottom_candidates = MISSION_GEN.FLAVOR_BOTTOM["RESCUE_FRIEND"]
            elseif objective == COMMON.MISSION_TYPE_RESCUE and client == target then
                flavor_top_candidates = MISSION_GEN.FLAVOR_TOP["RESCUE_SELF"]
                flavor_bottom_candidates = MISSION_GEN.FLAVOR_BOTTOM["RESCUE_SELF"]
            elseif objective == COMMON.MISSION_TYPE_ESCORT then
                flavor_top_candidates = MISSION_GEN.FLAVOR_TOP["ESCORT"]
                flavor_bottom_candidates = MISSION_GEN.FLAVOR_BOTTOM["ESCORT"]
            elseif objective == COMMON.MISSION_TYPE_EXPLORATION then
                flavor_top_candidates = MISSION_GEN.FLAVOR_TOP["EXPLORATION"]
                flavor_bottom_candidates = MISSION_GEN.FLAVOR_BOTTOM["EXPLORATION"]
            elseif objective == COMMON.MISSION_TYPE_LOST_ITEM then
                flavor_top_candidates = MISSION_GEN.FLAVOR_TOP["LOST_ITEM"]
                flavor_bottom_candidates = MISSION_GEN.FLAVOR_BOTTOM["LOST_ITEM"]
            elseif objective == COMMON.MISSION_TYPE_DELIVERY then
                flavor_top_candidates = MISSION_GEN.FLAVOR_TOP["DELIVERY"]
                flavor_bottom_candidates = MISSION_GEN.FLAVOR_BOTTOM["DELIVERY"]
            elseif objective == COMMON.MISSION_TYPE_OUTLAW then
                flavor_top_candidates = MISSION_GEN.FLAVOR_TOP["OUTLAW"]
                flavor_bottom_candidates = MISSION_GEN.FLAVOR_BOTTOM["OUTLAW"]
            elseif objective == COMMON.MISSION_TYPE_OUTLAW_ITEM then
                flavor_top_candidates = MISSION_GEN.FLAVOR_TOP["OUTLAW_ITEM"]
                flavor_bottom_candidates = MISSION_GEN.FLAVOR_BOTTOM["OUTLAW_ITEM"]
            elseif objective == COMMON.MISSION_TYPE_OUTLAW_MONSTER_HOUSE then
                flavor_top_candidates = MISSION_GEN.FLAVOR_TOP["OUTLAW_MONSTER_HOUSE"]
                flavor_bottom_candidates = MISSION_GEN.FLAVOR_BOTTOM["OUTLAW_MONSTER_HOUSE"]
            elseif objective == COMMON.MISSION_TYPE_OUTLAW_FLEE then
                flavor_top_candidates = MISSION_GEN.FLAVOR_TOP["OUTLAW_FLEE"]
                flavor_bottom_candidates = MISSION_GEN.FLAVOR_BOTTOM["OUTLAW_FLEE"]
            end
            flavor = RogueEssence.StringKey(flavor_top_candidates[math.random(1, #flavor_top_candidates)]):ToLocal() .. '\n' .. RogueEssence.StringKey(flavor_bottom_candidates[math.random(1, #flavor_bottom_candidates)]):ToLocal()

            --string substitutions, if needed.
            if string.find(flavor, "%[target%]") then
                flavor = string.gsub(flavor, "%[target%]", _DATA:GetMonster(target):GetColoredName())
            end

            if string.find(flavor, "%[dungeon%]") then
                flavor = string.gsub(flavor, "%[dungeon%]", _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Zone]:Get(dungeon):GetColoredName())
            end

            if string.find(flavor, "%[item%]") then
                flavor = string.gsub(flavor, "%[item%]",  _DATA:GetItem(item):GetColoredName())
            end

        end

        --don't generate this particular job slot if no more are available for the dungeon.
        if mission_floor ~= -1 then
            if mission_type == COMMON.MISSION_BOARD_OUTLAW then
                SV.OutlawBoard[i].Client = client
                SV.OutlawBoard[i].Target = target
                SV.OutlawBoard[i].Flavor = flavor
                SV.OutlawBoard[i].Title = title
                SV.OutlawBoard[i].Zone = dungeon
                SV.OutlawBoard[i].Segment = segment
                SV.OutlawBoard[i].Reward = reward
                SV.OutlawBoard[i].Floor = mission_floor
                SV.OutlawBoard[i].Type = objective
                SV.OutlawBoard[i].Completion = MISSION_GEN.INCOMPLETE
                SV.OutlawBoard[i].Taken = false
                SV.OutlawBoard[i].Difficulty = difficulty
                SV.OutlawBoard[i].Item = item
                SV.OutlawBoard[i].Special = special
                SV.OutlawBoard[i].ClientGender = client_gender
                SV.OutlawBoard[i].TargetGender = target_gender
                SV.OutlawBoard[i].BonusReward = bonus_reward
            else
                PrintInfo("Creating new mission for index "..i.." with client "..client.." difficulty "..difficulty.." title "..title.." and dungeon "..dungeon.." and segment "..segment.." and floor "..mission_floor)
                SV.MissionBoard[i].Client = client
                SV.MissionBoard[i].Target = target
                SV.MissionBoard[i].Flavor = flavor
                SV.MissionBoard[i].Title = title
                SV.MissionBoard[i].Zone = dungeon
                SV.MissionBoard[i].Segment = segment
                SV.MissionBoard[i].Reward = reward
                SV.MissionBoard[i].Floor = mission_floor
                SV.MissionBoard[i].Type = objective
                SV.MissionBoard[i].Completion = MISSION_GEN.INCOMPLETE
                SV.MissionBoard[i].Taken = false
                SV.MissionBoard[i].Difficulty = difficulty
                SV.MissionBoard[i].Item = item
                SV.MissionBoard[i].Special = special
                SV.MissionBoard[i].ClientGender = client_gender
                SV.MissionBoard[i].TargetGender = target_gender
                SV.MissionBoard[i].BonusReward = bonus_reward
            end
        end

    end

end

function MISSION_GEN.GetJobExpReward(difficulty)
    return MISSION_GEN.DIFFICULTY[difficulty]
end

function MISSION_GEN.JobSortFunction(j1, j2)
    if (j2 == nil or j2.Zone == nil or j2.Zone == "") then
        return false
    end
    if (j1 == nil or j1.Zone == nil or j1.Zone == "") then
        return true
    end
    --if they're the same dungeon, then check floors. Otherwise, dungeon order takes presidence. 
    if SV.DungeonOrder[j1.Zone] == SV.DungeonOrder[j2.Zone] then
        return j1.Floor > j2.Floor
    else
        return SV.DungeonOrder[j1.Zone] > SV.DungeonOrder[j2.Zone]
    end
end

--used to get the minus of one list minus another list
function MISSION_GEN.array_sub(t1, t2)
    local t = {}
    for i = 1, #t1 do
        t[t1[i]] = true;
    end
    for i = #t2, 1, -1 do
        if t[t2[i]] then
            table.remove(t2, i);
        end
    end
end

--used to get an array of a range. For figuring out floor candidates
function MISSION_GEN.Generate_List_Range(low, up)
    local array = {}
    local count = 1
    for i = low, up, 1 do
        array[count] = i
        count = count + 1
    end
    return array
end

function MISSION_GEN.SortTaken()
    if #SV.TakenBoard > 1 then
        table.sort(SV.TakenBoard, MISSION_GEN.JobSortFunction)
    end
end

function MISSION_GEN.SortMission()
    if #SV.MissionBoard > 1 then
        table.sort(SV.MissionBoard, MISSION_GEN.JobSortFunction)
    end
end

function MISSION_GEN.SortOutlaw()
    if #SV.OutlawBoard > 1 then
        table.sort(SV.OutlawBoard, MISSION_GEN.JobSortFunction)
    end
end

function MISSION_GEN.IsBoardFull(board)
    for i=#board, 1, -1 do
        if board[i].Client == "" then
            return false
        end
    end

    return true
end

--Finds the next free index in the board, returns -1 if it can't be found
function MISSION_GEN.FindFreeSpaceInBoard(board)
    for i=#board, 1, -1 do
        if board[i].Client == "" then
            return i
        end
    end

    return -1
end

--Used to create a shallow copy of a provided table (mainly for taking jobs)
function MISSION_GEN.ShallowCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


JobMenu = Class('JobMenu')

--jobs is a job board 
--job type should be taken, mission, or outlaw
--job number should be 1-8
function JobMenu:initialize(job_type, job_number, parent_board_menu)
    assert(self, "JobMenu:initialize(): Error, self is nil!")
    self.menu = RogueEssence.Menu.ScriptableMenu(32, 32, 256, 176, function(input) self:Update(input) end)
    --self.menu.Elements:Add(RogueEssence.Menu.MenuText(jobs[i], RogueElements.Loc(16, 8 + 14 * (i-1))))

    local job

    self.job_number = job_number

    self.job_type = job_type

    self.parent_board_menu = parent_board_menu

    --get relevant board
    local job
    if job_type == COMMON.MISSION_BOARD_TAKEN then
        job = SV.TakenBoard[job_number]
    elseif job_type == COMMON.MISSION_BOARD_OUTLAW then
        job = SV.OutlawBoard[job_number]
    else --default to mission board
        job = SV.MissionBoard[job_number]
    end

    self.taken = job.Taken

    self.flavor = job.Flavor
    --Magna is the only non-species name that'll show up here. So he is hardcoded in as an exception here.
    --TODO: Unhardcode this by adding in a check if string is not empty and if its not a species name, then add the color coding around it for  proper names.
    self.client = ""
    if job.Client == 'magna' then
        self.client = '[color=#00FFFF]Magna[color]'
    elseif job.Client ~= "" then
        self.client = _DATA:GetMonster(job.Client):GetColoredName()
    end

    self.target = ""
    if job.Target ~= '' then self.target = _DATA:GetMonster(job.Target):GetColoredName() end

    self.item = ""
    if job.Item ~= '' then self.item = _DATA:GetItem(job.Item):GetColoredName() end

    self.objective = ""
    self.type = job.Type
    self.taken_count = MISSION_GEN.GetTakenCount()

    if self.type == COMMON.MISSION_TYPE_RESCUE then
        self.objective = Text.FormatKey("MISSION_OBJECTIVES_RESCUE", self.target)
    elseif self.type == COMMON.MISSION_TYPE_ESCORT then
        self.objective = Text.FormatKey("MISSION_OBJECTIVES_ESCORT", self.client, self.target)
    elseif self.type == COMMON.MISSION_TYPE_EXPLORATION then
        self.objective = Text.FormatKey("MISSION_OBJECTIVES_EXPLORATION", self.client)
    elseif self.type == COMMON.MISSION_TYPE_OUTLAW then
        self.objective = Text.FormatKey("MISSION_OBJECTIVES_OUTLAW", self.target)
    elseif self.type == COMMON.MISSION_TYPE_OUTLAW_FLEE then
        self.objective = Text.FormatKey("MISSION_OBJECTIVES_OUTLAW_FLEE", self.target)
    elseif self.type == COMMON.MISSION_TYPE_OUTLAW_MONSTER_HOUSE then
        self.objective = Text.FormatKey("MISSION_OBJECTIVES_OUTLAW_MONSTER_HOUSE", self.target)
    elseif self.type == COMMON.MISSION_TYPE_LOST_ITEM then
        self.objective = Text.FormatKey("MISSION_OBJECTIVES_LOST_ITEM", self.item, self.client)
    elseif self.type == COMMON.MISSION_TYPE_DELIVERY then
        self.objective = Text.FormatKey("MISSION_OBJECTIVES_DELIVERY", self.item, self.client)
    elseif self.type == COMMON.MISSION_TYPE_OUTLAW_ITEM then
        self.objective = Text.FormatKey("MISSION_OBJECTIVES_OUTLAW_ITEM", self.item, self.target)
    end


    self.zone = ""
    self.zone_name = ""
    if job.Zone ~= "" then
        local zone_string = _DATA:GetZone(job.Zone).Segments[job.Segment]:ToString()
        zone_string = COMMON.CreateColoredSegmentString(zone_string)
        self.zone = zone_string
        self.zone_name = job.Zone
    end

    self.floor = ""
    if job.Floor ~= -1 then self.floor = MISSION_GEN.GetStairsType(job.Zone) .. '[color=#00FFFF]' .. tostring(job.Floor) .. "[color]F" end

    self.difficulty = ""
    if job.Difficulty ~= "" then self.difficulty = MISSION_GEN.DIFF_TO_COLOR[job.Difficulty] .. MISSION_GEN.GetDifficultyString(job.Difficulty) .. "[color]   - " ..  Text.FormatKey("MISSION_EXP_DESCRIPTION", tostring(MISSION_GEN.DIFFICULTY[job.Difficulty])) end




    self.reward = ""
    if job.Reward ~= '' then
        --special case for money
        if job.Reward == "money" then
            self.reward = '[color=#00FFFF]' .. MISSION_GEN.DIFF_TO_MONEY[job.Difficulty] .. '[color]' .. STRINGS:Format("\\uE024")
        else
            local reward_amount = 1
            --Reward amount should be 3 for multi-stack items
            if RogueEssence.Data.DataManager.Instance:GetItem(job.Reward).MaxStack >= 3 then
                reward_amount = 3
            end
            self.reward = RogueEssence.Dungeon.InvItem(job.Reward, false, reward_amount):GetDisplayName()
        end
    end

    --add in the ??? for a bonus reward if one exists
    if job.BonusReward ~= "" then
        self.reward = self.reward .. ' + ?'
    end


    self:DrawJob()


end

function JobMenu:DrawJob()
    --Standard menu divider. Reuse this whenever you need a menu divider at the top for a title.
    self.menu.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(8, 8 + 12), self.menu.Bounds.Width - 8 * 2))

    --Standard title. Reuse this whenever a title is needed.
    self.menu.Elements:Add(RogueEssence.Menu.MenuText(Text.FormatKey("MISSION_JOB_SUMMARY"), RogueElements.Loc(16, 8)))

    --Accepted element 
    self.menu.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(8, self.menu.Bounds.Height - 24), self.menu.Bounds.Width - 8 * 2))
    self.menu.Elements:Add(RogueEssence.Menu.MenuText(Text.FormatKey("MISSION_JOB_ACCEPTED") .. self.taken_count .. "/8", RogueElements.Loc(96, self.menu.Bounds.Height - 20)))



    self.menu.Elements:Add(RogueEssence.Menu.MenuText(self.flavor, RogueElements.Loc(16, 24)))
    self.menu.Elements:Add(RogueEssence.Menu.MenuText(Text.FormatKey("MISSION_JOB_CLIENT"), RogueElements.Loc(16, 54)))
    self.menu.Elements:Add(RogueEssence.Menu.MenuText(Text.FormatKey("MISSION_JOB_OBJECTIVE"), RogueElements.Loc(16, 68)))
    self.menu.Elements:Add(RogueEssence.Menu.MenuText(Text.FormatKey("MISSION_JOB_PLACE"), RogueElements.Loc(16, 82)))
    self.menu.Elements:Add(RogueEssence.Menu.MenuText(Text.FormatKey("MISSION_JOB_DIFFICULTY"), RogueElements.Loc(16, 96)))
    self.menu.Elements:Add(RogueEssence.Menu.MenuText(Text.FormatKey("MISSION_JOB_REWARD"), RogueElements.Loc(16, 110)))

    local client = self.client
    client = string.gsub(client, "Magna", "Magnezone")

    self.menu.Elements:Add(RogueEssence.Menu.MenuText(client, RogueElements.Loc(68, 54)))
    self.menu.Elements:Add(RogueEssence.Menu.MenuText(self.objective, RogueElements.Loc(68, 68)))
    self.menu.Elements:Add(RogueEssence.Menu.MenuText(self.zone .. " " .. self.floor, RogueElements.Loc(68, 82)))
    self.menu.Elements:Add(RogueEssence.Menu.MenuText(self.difficulty, RogueElements.Loc(68, 96)))
    self.menu.Elements:Add(RogueEssence.Menu.MenuText(self.reward, RogueElements.Loc(68, 110)))
end



--for use with submenu
function JobMenu:DeleteJob()
    local mission = SV.TakenBoard[self.job_number]
    local back_ref = mission.BackReference
    PrintInfo("Restoring taken from backref "..back_ref)
    if back_ref > 0 and back_ref ~= nil then
        local outlaw_arr = {
            COMMON.MISSION_TYPE_OUTLAW,
            COMMON.MISSION_TYPE_OUTLAW_ITEM,
            COMMON.MISSION_TYPE_OUTLAW_FLEE,
            COMMON.MISSION_TYPE_OUTLAW_MONSTER_HOUSE
        }

        --Outlaw missions are now part of the normal board
        SV.MissionBoard[back_ref].Taken = false
    end

    SV.TakenBoard[self.job_number] = {
        Client = "",
        Target = "",
        Flavor = "",
        Title = "",
        Zone = "",
        Segment = -1,
        Floor = -1,
        Reward = "",
        Type = -1,
        Completion = -1,
        Taken = false,
        Difficulty = "",
        Item = "",
        Special = "",
        ClientGender = -1,
        TargetGender = -1,
        BonusReward = "",
        BackReference = -1
    }

    MISSION_GEN.SortTaken()
    if self.parent_board_menu ~= nil then
        --redraw board with potentially changed information from job board
        self.parent_board_menu.menu.Elements:Clear()
        self.parent_board_menu:RefreshSelf()
        self.parent_board_menu:DrawBoard()

        --redraw selection board with potentially changed information
        if self.parent_board_menu.parent_selection_menu ~= nil then
            self.parent_board_menu.parent_selection_menu.menu.Elements:Clear()
            self.parent_board_menu.parent_selection_menu:DrawMenu()
        end

    end
    _MENU:RemoveMenu()

    --If we accessed the job via the main menu, then close the main menu if we've deleted our last job. Only need it here because only on total job deletion should the main menu ever need to change.
    if self.parent_board_menu.parent_main_menu ~= nil then
        if self.taken_count == 1 then--1 instead of 0 as the taken_count of the last job that was just deleted would be 1
            _MENU:RemoveMenu()
        end
    end

end

--for use with submenu
--flips taken status of self, and also updates the appropriate SV var's taken value
function JobMenu:FlipTakenStatus()
    self.taken = not self.taken
    if self.job_type == COMMON.MISSION_BOARD_TAKEN then
        SV.TakenBoard[self.job_number].Taken = self.taken
    elseif self.job_type == COMMON.MISSION_BOARD_OUTLAW then
        SV.OutlawBoard[self.job_number].Taken = self.taken
    else
        SV.MissionBoard[self.job_number].Taken = self.taken
    end
    if self.parent_board_menu ~= nil then
        --redraw board with potentially changed information from job board
        self.parent_board_menu.menu.Elements:Clear()
        self.parent_board_menu:RefreshSelf()
        self.parent_board_menu:DrawBoard()
    end
end

--for use with submenu
--adds the current job to the taken board, then sorts it. Then close the menu
function JobMenu:AddJobToTaken()
    --find an empty job slot
    local freeIndex = MISSION_GEN.FindFreeSpaceInBoard(SV.TakenBoard)
    if freeIndex > -1 then
        if self.job_type == COMMON.MISSION_BOARD_OUTLAW then
            --Need to copy the table rather than just pass the pointer, or you can dupe missions which is not good
            SV.TakenBoard[freeIndex] = MISSION_GEN.ShallowCopy(SV.OutlawBoard[self.job_number])
        elseif self.job_type == COMMON.MISSION_BOARD_MISSION then
            SV.TakenBoard[freeIndex] = MISSION_GEN.ShallowCopy(SV.MissionBoard[self.job_number])
        end

        SV.TakenBoard[freeIndex].BackReference = self.job_number

        --Suspend the job if there is currently an active sidequest in that dungeon
        if COMMON.HasSidequestInZone(SV.TakenBoard[freeIndex].Zone) then
            SV.TakenBoard[freeIndex].Taken = false
        end

        MISSION_GEN.SortTaken()
    end

    if self.parent_board_menu ~= nil then
        --redraw board with potentially changed information from job board
        self.parent_board_menu.menu.Elements:Clear()
        self.parent_board_menu:RefreshSelf()
        self.parent_board_menu:DrawBoard()

        --redraw selection board with potentially changed information
        if self.parent_board_menu.parent_selection_menu ~= nil then
            self.parent_board_menu.parent_selection_menu.menu.Elements:Clear()
            self.parent_board_menu.parent_selection_menu:DrawMenu()
        end
    end


    _MENU:RemoveMenu()
end

function JobMenu:OpenSubMenu()
    if self.job_type ~= COMMON.MISSION_BOARD_TAKEN and self.taken then
        --This is a job from the board that was already taken!
    else
        --create prompt menu
        local choices = {}
        --print(self.job_type .. " taken: " .. tostring(self.taken))
        if self.job_type == COMMON.MISSION_BOARD_TAKEN then
            local choice_str = Text.FormatKey("MISSION_BOARD_TAKE_JOB")
            local take_job = true
            if self.taken then
                choice_str = Text.FormatKey("MISSION_BOARD_SUSPEND")
                take_job = false
            end
            choices = {	{choice_str, not take_job or not COMMON.HasSidequestInZone(self.zone_name), function() self:FlipTakenStatus() _MENU:RemoveMenu() _MENU:RemoveMenu() end},
                           {Text.FormatKey("MISSION_BOARD_DELETE"), true, function() self:DeleteJob() _MENU:RemoveMenu() end},
                           {Text.FormatKey("MISSION_BOARD_CANCEL"), true, function() _MENU:RemoveMenu() _MENU:RemoveMenu() end} }

        else --outlaw/mission boards
            --we already made a check above to see if this is a job board and not taken 
            --only selectable if there's room on the taken board for the job, there is no sidequest for the dungeon, and we haven't already taken this mission

            choices = {{Text.FormatKey("MISSION_BOARD_TAKE_JOB"), MISSION_GEN.IsBoardFull(SV.TakenBoard) == false and not self.taken, function() self:FlipTakenStatus()
                self:AddJobToTaken() _MENU:RemoveMenu() end },
                       {Text.FormatKey("MISSION_BOARD_CANCEL"), true, function() _MENU:RemoveMenu() _MENU:RemoveMenu() end} }
        end

        submenu = RogueEssence.Menu.ScriptableSingleStripMenu(232, 138, 24, choices, 0, function() _MENU:RemoveMenu() _MENU:RemoveMenu() end)
        _MENU:AddMenu(submenu, true)

    end
end

function JobMenu:Update(input)
    assert(self, "BaseState:Begin(): Error, self is nil!")
    if input:JustPressed(RogueEssence.FrameInput.InputType.Confirm) then
        if self.job_type ~= COMMON.MISSION_BOARD_TAKEN and self.taken then
            --This is a job from the board that was already taken! Play a cancel noise.
            _GAME:SE("Menu/Cancel")
        else
            --This job has not yet been taken.  This block will never be hit because the submenu will automatically open.
        end
    elseif input:JustPressed(RogueEssence.FrameInput.InputType.Cancel) or input:JustPressed(RogueEssence.FrameInput.InputType.Menu) then
        _GAME:SE("Menu/Cancel")
        _MENU:RemoveMenu()
        --open job menu for that particular job
    else

    end
end



BoardMenu = Class('BoardMenu')

--board type should be taken, mission, or outlaw 
function BoardMenu:initialize(board_type, parent_selection_menu, parent_main_menu)
    assert(self, "BoardMenu:initialize(): Error, self is nil!")

    self.menu = RogueEssence.Menu.ScriptableMenu(32, 32, 256, 176, function(input) self:Update(input) end)
    self.cursor = RogueEssence.Menu.MenuCursor(self.menu)

    self.board_type = board_type

    --For refreshing the parent selection menu
    self.parent_selection_menu = parent_selection_menu

    --for refreshing the main menu (esc menu) if we accessed the board menu via that
    self.parent_main_menu = parent_main_menu

    local source_board = SV.MissionBoard

    print("Debug: Refreshing self!")
    if self.board_type == COMMON.MISSION_BOARD_TAKEN then
        source_board = SV.TakenBoard
    elseif self.board_type == COMMON.MISSION_BOARD_OUTLAW then
        source_board = SV.OutlawBoard
    end
    print("Boardtype: " .. self.board_type)

    self.total_items = 0
    self.jobs = {}
    self.original_menu_index = {}

    --get total job count and add jobs to self.jobs
    for i = #source_board, 1, -1 do
        if source_board[i].Client ~= "" then
            self.total_items = self.total_items + 1
            self.jobs[self.total_items] = source_board[i]
            self.original_menu_index[self.total_items] = i
        end
    end

    self.current_item = 0
    self.cursor.Loc = RogueElements.Loc(9, 27)
    self.page = 1--1 or 2
    self.taken_count = MISSION_GEN.GetTakenCount()
    self.total_pages = math.ceil(self.total_items / 4)


    self:DrawBoard()

end

--refresh information from results of job menu
function BoardMenu:RefreshSelf()
    local source_board = SV.MissionBoard

    if self.board_type == COMMON.MISSION_BOARD_TAKEN then
        source_board = SV.TakenBoard
    elseif self.board_type == COMMON.MISSION_BOARD_OUTLAW then
        source_board = SV.OutlawBoard
    end
    PrintInfo("Boardtype: " .. self.board_type)

    self.total_items = 0
    self.jobs = {}
    self.original_menu_index = {}

    --get total job count and add jobs to self.jobs
    for i = #source_board, 1, -1 do
        if source_board[i].Client ~= "" then
            self.total_items = self.total_items + 1
            self.jobs[self.total_items] = source_board[i]
            self.original_menu_index[self.total_items] = i

            local taken_string = 'false'

            if source_board[i].Taken then
                taken_string = 'true'
            end
            PrintInfo("Debug: Refreshing from source board index "..i)
        end
    end

    --in the event of deleting the last item on the board, move the cursor to accomodate.
    if self:GetSelectedJobIndex() > self.total_items then
        print("On refresh self, needed to adjust current item!")
        self.current_item = (self.total_items - 1) % 4

        --move cursor to reflect new current item location
        self.cursor:ResetTimeOffset()
        self.cursor.Loc = RogueElements.Loc(9, 27 + 28 * self.current_item)
    end

    self.total_pages = math.ceil(self.total_items / 4)

    --go to page 1 if we now only have 1 page
    if self.page == 2 and self.total_pages == 1 then
        self.page = 1
    end

    --refresh taken count
    self.taken_count = MISSION_GEN.GetTakenCount()

    --if there are no more missions and we're on the taken screen, close the menu.  
    if MISSION_GEN.TakenBoardIsEmpty() and self.board_type == COMMON.MISSION_BOARD_TAKEN then
        _MENU:RemoveMenu()
    end
end


--NOTE: Board is hardcoded to have 4 items a page, and only to have up to 8 total items to display.
--If you want to edit this, you'll probably have to change most instances of the number 4 here and some references to page. Sorry!
function BoardMenu:DrawBoard()
    --Standard menu divider. Reuse this whenever you need a menu divider at the top for a title.
    self.menu.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(8, 8 + 12), self.menu.Bounds.Width - 8 * 2))

    --Standard title. Reuse this whenever a title is needed.
    self.menu.Elements:Add(RogueEssence.Menu.MenuText(Text.FormatKey("MISSION_BOARD_NOTICE"), RogueElements.Loc(16, 8)))

    --page element
    self.menu.Elements:Add(RogueEssence.Menu.MenuText("(" .. tostring(self.page) .. "/" .. tostring(self.total_pages) .. ")", RogueElements.Loc(self.menu.Bounds.Width - 35, 8)))


    --Accepted element 
    self.menu.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(8, self.menu.Bounds.Height - 24), self.menu.Bounds.Width - 8 * 2))
    self.menu.Elements:Add(RogueEssence.Menu.MenuText(Text.FormatKey("MISSION_BOARD_ACCEPTED") .. tostring(self.taken_count) .. "/8", RogueElements.Loc(96, self.menu.Bounds.Height - 20)))


    self.menu.Elements:Add(self.cursor)

    --populate 4 self.jobs on a page
    for i = (4 * self.page) - 3, 4 * self.page, 1 do
        if i > #self.jobs then break end

        if self.jobs[i].Client ~= "" then
            local title = self.jobs[i].Title

            local taken_string = 'false'

            if self.jobs[i].Taken then
                taken_string = 'true'
            end

            local zone = _DATA:GetZone(self.jobs[i].Zone).Segments[self.jobs[i].Segment]:ToString()
            zone = COMMON.CreateColoredSegmentString(zone)
            local floor =  MISSION_GEN.GetStairsType(self.jobs[i].Zone) ..'[color=#00FFFF]' .. tostring(self.jobs[i].Floor) .. "[color]F"
            local difficulty = ""

            --create difficulty string
            local difficult_string = MISSION_GEN.GetDifficultyString(self.jobs[i].Difficulty)

            difficulty = MISSION_GEN.DIFF_TO_COLOR[self.jobs[i].Difficulty] .. difficult_string .. "[color]"

            local icon = ""
            if self.board_type == COMMON.MISSION_BOARD_TAKEN then
                if self.jobs[i].Taken then
                    icon = STRINGS:Format("\\uE10F")--open letter
                else
                    icon = STRINGS:Format("\\uE10E")--closed letter
                end
            else
                if self.jobs[i].Taken then
                    icon = STRINGS:Format("\\uE10E")--closed letter
                else
                    icon = STRINGS:Format("\\uE110")--paper
                end
            end

            local location = zone .. " " .. floor


            --color everything red if job is taken and this is a job board
            if self.jobs[i].Taken and self.board_type ~= COMMON.MISSION_BOARD_TAKEN then
                location = string.gsub(location, '%b[]', '')
                title = string.gsub(title, '%b[]', '')
                difficulty = string.gsub(difficulty, '%b[]', '')

                difficulty = "[color=#FF0000]" .. difficulty .. "[color]"
                title = "[color=#FF0000]" .. title .. "[color]"
                location = "[color=#FF0000]" .. location .. "[color]"
            end

            --modulo the iterator so that if we're on the 2nd page it goes to the right spot

            self.menu.Elements:Add(RogueEssence.Menu.MenuText(icon, RogueElements.Loc(21, 26 + 28 * ((i-1) % 4))))
            self.menu.Elements:Add(RogueEssence.Menu.MenuText(title, RogueElements.Loc(33, 26 + 28 * ((i-1) % 4))))
            self.menu.Elements:Add(RogueEssence.Menu.MenuText(location, RogueElements.Loc(33, 38 + 28 * ((i-1) % 4))))
            self.menu.Elements:Add(RogueEssence.Menu.MenuText(difficulty, RogueElements.Loc(self.menu.Bounds.Width - 33, 38 + 28 * ((i-1) % 4))))
        end
    end
end


function BoardMenu:Update(input)
    assert(self, "BaseState:Begin(): Error, self is nil!")
    if input:JustPressed(RogueEssence.FrameInput.InputType.Confirm) then
        --open the selected job menu
        _GAME:SE("Menu/Confirm")
        local job_menu = JobMenu:new(self.board_type, self:GetOriginalSelectedJobIndex(), self)
        _MENU:AddMenu(job_menu.menu, false)
        job_menu:OpenSubMenu()
    elseif input:JustPressed(RogueEssence.FrameInput.InputType.Cancel) or input:JustPressed(RogueEssence.FrameInput.InputType.Menu) then
        _GAME:SE("Menu/Cancel")
        _MENU:RemoveMenu()
        --open job menu for that particular job
    else
        moved = false
        if RogueEssence.Menu.InteractableMenu.IsInputting(input, LUA_ENGINE:MakeLuaArray(Dir8, { Dir8.Down, Dir8.DownLeft, Dir8.DownRight })) then
            moved = true
            self.current_item = (self.current_item + 1) % 4

            --if we try to move the cursor to an empty slot on a down press, then move it to the space for the first job on the page.
            if self:GetSelectedJobIndex() > self.total_items then
                local new_current = 0
                --undo moved flag if we didn't actually move
                if new_current == (self.current_item - 1) % 4 then
                    moved = false
                end
                self.current_item = new_current
            end

        elseif RogueEssence.Menu.InteractableMenu.IsInputting(input, LUA_ENGINE:MakeLuaArray(Dir8, { Dir8.Up, Dir8.UpLeft, Dir8.UpRight })) then
            moved = true
            self.current_item = (self.current_item - 1) % 4

            --if we try to move the cursor to an empty slot on an up press, then move it to the space for the last job on the page.
            if self:GetSelectedJobIndex() > self.total_items then
                local new_current = (self.total_items % 4) - 1
                --undo moved flag if we didn't actually move
                if new_current == (self.current_item + 1 ) % 4 then
                    moved = false
                end
                self.current_item = new_current
            end

        elseif RogueEssence.Menu.InteractableMenu.IsInputting(input, LUA_ENGINE:MakeLuaArray(Dir8, {Dir8.Left, Dir8.Right})) then
            --go to other menu if there are more options on the 2nd menu
            if self.total_pages > 1 then
                --change the page
                if self.page == 1 then self.page = 2 else self.page = 1 end
                moved = true

                --if we try to move the cursor to an empty slot on a side press, then move it to the space for the last job on the page.
                if self:GetSelectedJobIndex() > self.total_items then
                    local new_current = (self.total_items % 4) - 1
                    self.current_item = new_current
                end


                self.menu.Elements:Clear()
                self:DrawBoard()
            end
        end
        if moved then
            _GAME:SE("Menu/Select")
            self.cursor:ResetTimeOffset()
            self.cursor.Loc = RogueElements.Loc(9, 27 + 28 * self.current_item)
        end
    end
end

--gets current job index based on the current item and the page. if self.page is 2, and current item is 0, returned answer should be 5.
function BoardMenu:GetSelectedJobIndex()
    return self.current_item + (4 * (self.page - 1) + 1)
end

--gets current job index based on the current item and the page, then translates it to the correct index in its original menu
function BoardMenu:GetOriginalSelectedJobIndex()
    return self.original_menu_index[self:GetSelectedJobIndex()]
end







------------------------
-- Board Selection Menu
------------------------
BoardSelectionMenu = Class('BoardSelectionMenu')

--Used to choose between viewing the board, your job list, or to cancel
function BoardSelectionMenu:initialize(board_type)
    assert(self, "BoardSelectionMenu:initialize(): Error, self is nil!")

    --I'm bad at this. Need different menu sizes depending on the board 
    if board_type == COMMON.MISSION_BOARD_OUTLAW then
        self.menu = RogueEssence.Menu.ScriptableMenu(24, 22, 128, 60, function(input) self:Update(input) end)
    else
        self.menu = RogueEssence.Menu.ScriptableMenu(24, 22, 119, 60, function(input) self:Update(input) end)

    end
    self.cursor = RogueEssence.Menu.MenuCursor(self.menu)
    self.board_type = board_type

    self.current_item = 0
    self.cursor.Loc = RogueElements.Loc(9, 8)

    self:DrawMenu()

end

--refreshes information and draws to the menu. This is important in case there's a change to the taken board
function BoardSelectionMenu:DrawMenu()

    --color this red if there's no jobs and mark there's no jobs to view.
    self.board_populated = true
    local board_name = ""
    if self.board_type == COMMON.MISSION_BOARD_OUTLAW then
        if SV.OutlawBoard[1].Client == '' then
            board_name = "[color=#FF0000]"..Text.FormatKey("MISSION_BOARD_NAME_OUTLAW").."[color]"
            self.board_populated = false
        else
            board_name = Text.FormatKey("MISSION_BOARD_NAME_OUTLAW")
        end
    else
        if MISSION_GEN.MissionBoardIsEmpty() then
            board_name = "[color=#FF0000]"..Text.FormatKey("MISSION_BOARD_NAME_MISSION").."[color]"
            self.board_populated = false
        else
            board_name = Text.FormatKey("MISSION_BOARD_NAME_MISSION")
        end
    end

    --color this red if there's no jobs, mark there's no jobs taken
    self.job_list = Text.FormatKey("MISSION_BOARD_NAME_TAKEN")
    self.taken_populated = true
    if MISSION_GEN.TakenBoardIsEmpty() then
        self.job_list = "[color=#FF0000]"..Text.FormatKey("MISSION_BOARD_NAME_TAKEN").."[color]"
        self.taken_populated = false
    end

    self.menu.Elements:Add(RogueEssence.Menu.MenuText(board_name, RogueElements.Loc(21, 8)))
    self.menu.Elements:Add(RogueEssence.Menu.MenuText(self.job_list, RogueElements.Loc(21, 22)))
    self.menu.Elements:Add(RogueEssence.Menu.MenuText(Text.FormatKey("MISSION_BOARD_EXIT"), RogueElements.Loc(21, 36)))

    self.menu.Elements:Add(self.cursor)
end


function BoardSelectionMenu:Update(input)

    if input:JustPressed(RogueEssence.FrameInput.InputType.Confirm) then
        if self.current_item == 0 then --open relevant job menu 
            if self.board_populated then
                _GAME:SE("Menu/Confirm")
                local board_menu = BoardMenu:new(self.board_type, self)
                _MENU:AddMenu(board_menu.menu, false)
            else
                _GAME:SE("Menu/Cancel")
            end
        elseif self.current_item == 1 then--open taken missions
            if self.taken_populated then
                _GAME:SE("Menu/Confirm")
                local board_menu = BoardMenu:new(COMMON.MISSION_BOARD_TAKEN, self)
                _MENU:AddMenu(board_menu.menu, false)
            else
                _GAME:SE("Menu/Cancel")
            end
        else
            _GAME:SE("Menu/Cancel")
            _MENU:RemoveMenu()
        end
    elseif input:JustPressed(RogueEssence.FrameInput.InputType.Cancel) or input:JustPressed(RogueEssence.FrameInput.InputType.Menu) then
        _GAME:SE("Menu/Cancel")
        _MENU:RemoveMenu()
        --open job menu for that particular job
    else
        moved = false
        if RogueEssence.Menu.InteractableMenu.IsInputting(input, LUA_ENGINE:MakeLuaArray(Dir8, { Dir8.Down, Dir8.DownLeft, Dir8.DownRight })) then
            moved = true
            self.current_item = (self.current_item + 1) % 3

        elseif RogueEssence.Menu.InteractableMenu.IsInputting(input, LUA_ENGINE:MakeLuaArray(Dir8, { Dir8.Up, Dir8.UpLeft, Dir8.UpRight })) then
            moved = true
            self.current_item = (self.current_item - 1) % 3
        end

        if moved then
            _GAME:SE("Menu/Select")
            self.cursor:ResetTimeOffset()
            self.cursor.Loc = RogueElements.Loc(9, 8 + 14 * self.current_item)
        end
    end
end




------------------------
-- DungeonJobList  Menu
------------------------
DungeonJobList = Class('DungeonJobList')

--Used to see what jobs are in this dungeon
function DungeonJobList:initialize()
    assert(self, "DungeonJobList:initialize(): Error, self is nil!")

    self.menu = RogueEssence.Menu.ScriptableMenu(32, 32, 256, 176, function(input) self:Update(input) end)
    self.dungeon = ""
    self.section = -1

    --This menu should only be accessible from dungeons, but add this as a check just in case we somehow access this menu from outside a dungeon.
    if RogueEssence.GameManager.Instance.CurrentScene == RogueEssence.Dungeon.DungeonScene.Instance then
        self.dungeon = _ZONE.CurrentZoneID
        self.section = _ZONE.CurrentMapID.Segment
    end

    self.jobs = SV.TakenBoard
    self.job_count = 0

    for i = 1, 8, 1 do
        if SV.TakenBoard[i].Client == "" then
            break
        elseif SV.TakenBoard[i].Zone ~= '' and SV.TakenBoard[i].Zone == self.dungeon then
            self.job_count = self.job_count + 1
        end
    end
    self:DrawMenu()

end

--refreshes information and draws to the menu. This is important in case there's a change to the taken board
function DungeonJobList:DrawMenu()
    --Standard menu divider. Reuse this whenever you need a menu divider at the top for a title.
    self.menu.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(8, 8 + 12), self.menu.Bounds.Width - 8 * 2))

    --Standard title. Reuse this whenever a title is needed.
    self.menu.Elements:Add(RogueEssence.Menu.MenuText("Mission Objectives", RogueElements.Loc(16, 8)))

    --how many jobs have we populated so far
    local count = 0
    local side_dungeon_mission = false
    local zone_string = ''

    --populate jobs that are in this dungeon
    for i = 8, 1, -1 do
        --skip all empty jobs
        if self.jobs[i].Client ~= "" then
            --only look at jobs in the current dungeon that aren't suspended
            if self.jobs[i].Zone == self.dungeon and self.jobs[i].Taken then
                if self.jobs[i].Segment == self.section then
                    local floor_num = MISSION_GEN.GetStairsType(self.jobs[i].Zone) ..'[color=#00FFFF]' .. tostring(self.jobs[i].Floor) .. "[color]F"
                    local objective = ""
                    local icon = ""
                    local goal = self.jobs[i].Type

                    local target = _DATA:GetMonster(self.jobs[i].Target):GetColoredName()

                    local client = ""
                    if self.jobs[i].Client == "magna" then
                        client = "[color=#00FFFF]Magna[color]"
                    else
                        client = _DATA:GetMonster(self.jobs[i].Client):GetColoredName()
                    end

                    local item = ""
                    if self.jobs[i].Item ~= "" then
                        item = _DATA:GetItem(self.jobs[i].Item):GetColoredName()
                    end

                    if goal == COMMON.MISSION_TYPE_RESCUE then
                        objective = Text.FormatKey("MISSION_OBJECTIVES_RESCUE", target)
                    elseif goal == COMMON.MISSION_TYPE_ESCORT then
                        objective = Text.FormatKey("MISSION_OBJECTIVES_ESCORT", client, target)
                    elseif goal == COMMON.MISSION_TYPE_OUTLAW then
                        objective = Text.FormatKey("MISSION_OBJECTIVES_OUTLAW", target)
                    elseif goal == COMMON.MISSION_TYPE_EXPLORATION then
                        objective = Text.FormatKey("MISSION_OBJECTIVES_EXPLORATION", client)
                    elseif goal == COMMON.MISSION_TYPE_LOST_ITEM then
                        objective = Text.FormatKey("MISSION_OBJECTIVES_LOST_ITEM", item, client)
                    elseif goal == COMMON.MISSION_TYPE_OUTLAW_ITEM then
                        objective = Text.FormatKey("MISSION_OBJECTIVES_OUTLAW_ITEM", item, target)
                    elseif goal == COMMON.MISSION_TYPE_OUTLAW_FLEE then
                        objective = Text.FormatKey("MISSION_OBJECTIVES_OUTLAW_FLEE", target)
                    elseif goal == COMMON.MISSION_TYPE_OUTLAW_MONSTER_HOUSE then
                        objective = Text.FormatKey("MISSION_OBJECTIVES_OUTLAW_MONSTER_HOUSE", target)
                    elseif goal == COMMON.MISSION_TYPE_DELIVERY then
                        objective = Text.FormatKey("MISSION_OBJECTIVES_DELIVERY", item, client)
                    end

                    if self.jobs[i].Completion == COMMON.MISSION_INCOMPLETE then
                        icon = STRINGS:Format("\\uE10F")--open letter
                    else
                        icon = STRINGS:Format("\\uE10A")--check mark
                    end

                    self.menu.Elements:Add(RogueEssence.Menu.MenuText(icon, RogueElements.Loc(16, 24 + 14 * count)))
                    self.menu.Elements:Add(RogueEssence.Menu.MenuText(floor_num, RogueElements.Loc(28, 24 + 14 * count)))
                    self.menu.Elements:Add(RogueEssence.Menu.MenuText(objective, RogueElements.Loc(60, 24 + 14 * count)))

                    count = count + 1
                else
                    side_dungeon_mission = true
                    zone_string = _DATA:GetZone(self.jobs[i].Zone).Segments[self.jobs[i].Segment]:ToString()
                    zone_string = COMMON.CreateColoredSegmentString(zone_string)
                end

            end

        end


    end


    --put a special message if no jobs dependent on story progression.
    local message = ""
    if side_dungeon_mission == true and self.section == 0 then
        message = Text.FormatKey("MISSION_OBJECTIVES_SIDE", zone_string)
        local yloc = 12 + 14
        if count > 0 then
            yloc = 24 + 14 * count
        end
        self.menu.Elements:Add(RogueEssence.Menu.MenuText(message, RogueElements.Loc(16, yloc)))
    elseif count == 0 then
		if _DATA.Save.Rescue ~= nil and _DATA.Save.Rescue.Rescuing then
			if self.section ~= _DATA.Save.Rescue.SOS.Goal.StructID.Segment then
				zone_string = _DATA:GetZone(_DATA.Save.Rescue.SOS.Goal.ID).Segments[_DATA.Save.Rescue.SOS.Goal.StructID.Segment]:ToString()
				zone_string = COMMON.CreateColoredSegmentString(zone_string)
				
				self.menu.Elements:Add(RogueEssence.Menu.MenuText(message, RogueElements.Loc(16, 12 + 14)))
			else
				local floor_num = MISSION_GEN.GetStairsType(_DATA.Save.Rescue.SOS.Goal.ID) ..'[color=#00FFFF]' .. tostring(_DATA.Save.Rescue.SOS.Goal.StructID.ID) .. "[color]F"
				icon = STRINGS:Format("\\uE10F")--open letter
				objective = Text.FormatKey("MISSION_OBJECTIVES_RESCUE", _DATA.Save.Rescue.SOS.TeamName)
				
				self.menu.Elements:Add(RogueEssence.Menu.MenuText(icon, RogueElements.Loc(16, 12 + 14)))
				self.menu.Elements:Add(RogueEssence.Menu.MenuText(floor_num, RogueElements.Loc(28, 12 + 14)))
				self.menu.Elements:Add(RogueEssence.Menu.MenuText(objective, RogueElements.Loc(60, 12 + 14)))
			end
		else
			message = Text.FormatKey("MISSION_OBJECTIVES_DEFAULT")
			self.menu.Elements:Add(RogueEssence.Menu.MenuText(message, RogueElements.Loc(16, 12 + 14)))
		end
    end
end


function DungeonJobList:Update(input)

    if input:JustPressed(RogueEssence.FrameInput.InputType.Confirm) then
        _GAME:SE("Menu/Cancel")
        _MENU:RemoveMenu()
    elseif input:JustPressed(RogueEssence.FrameInput.InputType.Cancel) then
        _GAME:SE("Menu/Cancel")
        _MENU:RemoveMenu()
    elseif input:JustPressed(RogueEssence.FrameInput.InputType.Menu) then
        _GAME:SE("Menu/Cancel")
        _MENU:RemoveMenu()
    end
end

--How many missions are taken? Probably shoulda just had a variable that kept track, but oh well...
function MISSION_GEN.GetTakenCount()
    local count = 0
    for i = 1, 8, 1 do
        if SV.TakenBoard[i].Client ~= "" then
            count = count + 1
        end
    end

    return count
end

function MISSION_GEN.RemoveMissionBackReference()
    for mission_num, _ in pairs(SV.TakenBoard) do
        SV.TakenBoard[mission_num].BackReference = -1
    end
end

function MISSION_GEN.EndOfDay(result, segmentID)
    --Mark the current dungeon as visited

    local cur_zone_name = _ZONE.CurrentZoneID

    if result == RogueEssence.Data.GameProgress.ResultType.Cleared then
        PrintInfo("Completed zone "..cur_zone_name.." with segment "..segmentID)
        if SV.MissionPrereq.DungeonsCompleted[cur_zone_name] == nil then
            SV.MissionPrereq.DungeonsCompleted[cur_zone_name] = { }
            SV.MissionPrereq.DungeonsCompleted[cur_zone_name][segmentID] = 1
            SV.MissionPrereq.NumDungeonsCompleted = SV.MissionPrereq.NumDungeonsCompleted + 1
        elseif SV.MissionPrereq.DungeonsCompleted[cur_zone_name][segmentID] == nil then
            SV.MissionPrereq.DungeonsCompleted[cur_zone_name][segmentID] = 1
        end
    end

    MISSION_GEN.RegenerateJobs(result)
end

function MISSION_GEN.RegenerateJobs(result)
    --Regenerate jobs
    MISSION_GEN.ResetBoards()
    MISSION_GEN.RemoveMissionBackReference()
    MISSION_GEN.GenerateBoard(result, COMMON.MISSION_BOARD_MISSION)
    --MISSION_GEN.GenerateBoard(COMMON.MISSION_BOARD_OUTLAW)
    MISSION_GEN.SortMission()
    MISSION_GEN.SortOutlaw()
end

function MISSION_GEN.GetDebugMissionInfo(board, slot)
    if board == "outlaw" then
        print("client = " .. SV.OutlawBoard[slot].Client)
        print("target = " .. SV.OutlawBoard[slot].Target)
        print("flavor = " .. SV.OutlawBoard[slot].Flavor)
        print("title = " .. SV.OutlawBoard[slot].Title)
        print("zone = " .. SV.OutlawBoard[slot].Zone)
        print("segment = " .. SV.OutlawBoard[slot].Segment)
        print("floor = " .. SV.OutlawBoard[slot].Floor)
        print("reward = " .. SV.OutlawBoard[slot].Reward)
        print("type = " .. SV.OutlawBoard[slot].Type)
        print("Completion = " .. SV.OutlawBoard[slot].Completion)
        print("Taken = " .. tostring(SV.OutlawBoard[slot].Taken))
        print("Difficulty = " .. SV.OutlawBoard[slot].Difficulty)
        print("item = " .. SV.OutlawBoard[slot].Item)
        print("Special = " .. SV.OutlawBoard[slot].Special)
        local client_gender = SV.OutlawBoard[slot].ClientGender
        if client_gender == 1 then
            print("ClientGender = male")
        elseif client_gender == 2 then
            print("ClientGender = female")
        elseif client_gender == 0 then
            print("ClientGender = genderless")
        else
            print("Non valid gender!!!!!!")
        end

        local target_Gender = SV.OutlawBoard[slot].ClientGender
        if target_Gender == 1 then
            print("TargetGender = male")
        elseif target_Gender == 2 then
            print("TargetGender = female")
        elseif target_Gender == 0 then
            print("TargetGender = genderless")
        else
            print("Non valid gender!!!!!!")
        end
        print("Bonus = " .. SV.OutlawBoard[slot].BonusReward)

    elseif board == "mission" then
        print("client = " .. SV.MissionBoard[slot].Client)
        print("target = " .. SV.MissionBoard[slot].Target)
        print("flavor = " .. SV.MissionBoard[slot].Flavor)
        print("title = " .. SV.MissionBoard[slot].Title)
        print("zone = " .. SV.MissionBoard[slot].Zone)
        print("segment = " .. SV.MissionBoard[slot].Segment)
        print("floor = " .. SV.MissionBoard[slot].Floor)
        print("reward = " .. SV.MissionBoard[slot].Reward)
        print("type = " .. SV.MissionBoard[slot].Type)
        print("Completion = " .. SV.MissionBoard[slot].Completion)
        print("Taken = " .. tostring(SV.MissionBoard[slot].Taken))
        print("Difficulty = " .. SV.MissionBoard[slot].Difficulty)
        print("item = " .. SV.MissionBoard[slot].Item)
        print("Special = " .. SV.MissionBoard[slot].Special)
        local client_gender = SV.MissionBoard[slot].ClientGender
        if client_gender == 1 then
            print("ClientGender = male")
        elseif client_gender == 2 then
            print("ClientGender = female")
        elseif client_gender == 0 then
            print("ClientGender = genderless")
        else
            print("Non valid gender!!!!!!")
        end

        local target_Gender = SV.MissionBoard[slot].ClientGender
        if target_Gender == 1 then
            print("TargetGender = male")
        elseif target_Gender == 2 then
            print("TargetGender = female")
        elseif target_Gender == 0 then
            print("TargetGender = genderless")
        else
            print("Non valid gender!!!!!!")
        end
        print("Bonus = " .. SV.MissionBoard[slot].BonusReward)
    else
        print("client = " .. SV.TakenBoard[slot].Client)
        print("target = " .. SV.TakenBoard[slot].Target)
        print("flavor = " .. SV.TakenBoard[slot].Flavor)
        print("title = " .. SV.TakenBoard[slot].Title)
        print("zone = " .. SV.TakenBoard[slot].Zone)
        print("segment = " .. SV.TakenBoard[slot].Segment)
        print("floor = " .. SV.TakenBoard[slot].Floor)
        print("reward = " .. SV.TakenBoard[slot].Reward)
        print("type = " .. SV.TakenBoard[slot].Type)
        print("Completion = " .. SV.TakenBoard[slot].Completion)
        print("Taken = " .. tostring(SV.TakenBoard[slot].Taken))
        print("Difficulty = " .. SV.TakenBoard[slot].Difficulty)
        print("item = " .. SV.TakenBoard[slot].Item)
        print("Special = " .. SV.TakenBoard[slot].Special)
        print("BackReference = " .. SV.TakenBoard[slot].BackReference)
        local client_gender = SV.TakenBoard[slot].ClientGender
        if client_gender == 1 then
            print("ClientGender = male")
        elseif client_gender == 2 then
            print("ClientGender = female")
        elseif client_gender == 0 then
            print("ClientGender = genderless")
        else
            print("Non valid gender!!!!!!")
        end

        local target_Gender = SV.TakenBoard[slot].ClientGender
        if target_Gender == 1 then
            print("TargetGender = male")
        elseif target_Gender == 2 then
            print("TargetGender = female")
        elseif target_Gender == 0 then
            print("TargetGender = genderless")
        else
            print("Non valid gender!!!!!!")
        end
        print("Bonus = " .. SV.TakenBoard[slot].BonusReward)
    end
end