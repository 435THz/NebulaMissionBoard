
local menus = {
    LINE_HEIGHT = 12,
    VERT_SPACE = 14,
    TITLE_HEIGHT = 12 + RogueEssence.Content.GraphicsManager.MenuBG.TileHeight,
    SCREEN_HEIGHT = RogueEssence.Content.GraphicsManager.ScreenHeight,
    SCREEN_WIDTH = RogueEssence.Content.GraphicsManager.ScreenWidth,
    BORDER_HEIGHT = RogueEssence.Content.GraphicsManager.MenuBG.TileHeight,
    BORDER_WIDTH = RogueEssence.Content.GraphicsManager.MenuBG.TileWidth
}




--- @class BoardSelectionMenu Menu that allows the player to open either a specific board or the taken job list
local BoardSelectionMenu = Class('BoardSelectionMenu')

--- Creates the menu, using the provided data and callback
--- @param library table the entire job library structure
--- @param board_id string the id of the board to be prompted
--- @param callback function that handles the menu's output. The value is equal to the index selected
function BoardSelectionMenu:initialize(library, board_id, callback)
    assert(self, "BoardSelectionMenu:initialize(): Error, self is nil!")
    self.callback = callback

    local choices = {
        {STRINGS:FormatKey(library.data.boards[board_id].display_key), library:IsBoardEmpty(board_id), function() self:choose(1) end},
        {STRINGS:FormatKey(library.globals.keys.TAKEN_TITLE), library:IsTakenListEmpty(), function() self:choose(2) end},
        {STRINGS:FormatKey("MENU_EXIT"), true, function() self:choose(-1) end}
    }
    self.menu = RogueEssence.Menu.ScriptableSingleScriptMenu(24, 22, 100, choices, 1, function() self:choose(-1) end)
end

--- Confirmation function that runs the stored callback and closes the menu.
--- @param i number the index of the selected choice, or -1 if either the exit option was selected or nothing was.
function BoardSelectionMenu:choose(i)
    _MENU:RemoveMenu()
    self.callback(i)
end

--- Runs a BoardSelectionMenu instance and returns its selected index
--- @param library table the entire job library structure
--- @param board_id string the id of a board. It will be used to display the first option.
--- @return integer #the index of the chosen option, or -1 if the menu was exited without selecting anything.
function BoardSelectionMenu.run(library, board_id)
    local ret = -1
    local cb = function(choice) ret = choice end
    local menu = BoardSelectionMenu:new(library, board_id, cb)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret
end



--- @class BoardMenu Menu that displays the contents of a board and allows the player to interact with it.
local BoardMenu = Class('BoardMenu')

--- Creates the menu, using the provided data and callback
--- @param library table the entire job library structure
--- @param board_id string the id of the board to be prompted
--- @param callback function that handles the menu's output. The value is equal to the index selected
--- @param start_choice number the choice that should be selected first. Defaults to 1
function BoardMenu:initialize(library, board_id, callback, start_choice)
    assert(self, "BoardMenu:initialize(): Error, self is nil!")
    self.MAX_ENTRIES = 4

    start_choice = start_choice or 1
    self.library = library
    self.board_id =  board_id --if nil, then taken board
    self.callback = callback
    if board_id then
        self.board_content = self.library.root.boards[board_id]
        self.board_title = self.library.data.boards[board_id].display_key
    else
        self.board_content = self.library.root.taken
        self.board_title = self.library.globals.keys.TAKEN_TITLE
    end

    self.choices = self:GenerateOptions()
    self.pages = math.ceil(#self.choices / self.MAX_ENTRIES)
    self.taken_count = MISSION_GEN.GetTakenCount()
    if self.pages <=0 then
        _MENU:RemoveMenu()
    end

    self.menu = RogueEssence.Menu.ScriptableMenu(32, 32, 256, 176, function(input) self:Update(input) end)

    self:DrawBoardStatic()
    self:Select(start_choice)
end

function BoardMenu:GenerateOptions()
    local choices = {}
    for i, job in pairs(self.board_content) do
        job = job
        local title = STRINGS:FormatKey(job.Title)
        local taken_string = 'false'

        if job.Taken then
            taken_string = 'true'
        end

        local zone_str, floor_pattern = self.library:CreateColoredSegmentString(job.Zone, job.Segment)
        local floor_str =  STRINGS:Format(floor_pattern, tostring(job.Floor))
        local difficulty = self.library.data.difficulty_data[self.library.data.num_to_difficulty[job.Difficulty]].display_key
        -- This is the whole reason why we need a shallowcopy function for the mission data: we can't guarantee the structures point to the same job after save and load
        local icon = ""
        if not self.board_id then
            if job.Taken then icon = STRINGS:Format("\\uE10F")--open letter
            else icon = STRINGS:Format("\\uE10E")--closed letter
            end
        else
            if job.Taken then icon = STRINGS:Format("\\uE10E")--closed letter
            else icon = STRINGS:Format("\\uE110")--paper
            end
        end
        local location = zone_str .. " " .. floor_str

        local color = Color.White
        --color everything red if job is taken and this is a job board
        local enabled = not (self.board_type and job.Taken)
        if not enabled then
            color = Color.Red
        end


        --modulo the iterator so that if we're on the 2nd page it goes to the right spot
        local choice = RogueEssence.Menu.MenuElementChoice(function() self:choose(i) end)
        local x, y0 = 17, menus.TITLE_HEIGHT
        choice.Bounds = RogueElements.Rect(x, y0 + (menus.VERT_SPACE*2) + ((i-1) % self.MAX_ENTRIES), self.menu.Bounds.Width-x*2, menus.VERT_SPACE*2)

        choice.Elements:Add(RogueEssence.Menu.MenuText(icon, RogueElements.Loc(4, 8)), color)
        choice.Elements:Add(RogueEssence.Menu.MenuText(title, RogueElements.Loc(16, 8)), color)
        choice.Elements:Add(RogueEssence.Menu.MenuText(location, RogueElements.Loc(16, 8 + menus.LINE_HEIGHT)), color)
        choice.Elements:Add(RogueEssence.Menu.MenuText(difficulty, RogueElements.Loc(choice.Bounds.Width - 4, 8 + menus.LINE_HEIGHT)), RogueElements.DirV.Up, RogueElements.DirH.Right, color)
        table.insert(choices, choice)
    end
    return choices
end

function BoardMenu:choose(i)
    _MENU:RemoveMenu()
    self.callback(i)
end

function BoardMenu:DrawBoardStatic()
    --Standard menu divider
    self.menu.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(menus.BORDER_WIDTH, menus.TITLE_HEIGHT), self.menu.Bounds.Width - menus.BORDER_WIDTH * 2))
    --Standard title
    self.menu.Elements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey(self.board_title), RogueElements.Loc(16, 8)))
    --page number
    self.menu.Elements:Add(RogueEssence.Menu.MenuText("(" .. tostring(self.page) .. "/" .. tostring(self.pages) .. ")", RogueElements.Loc(self.menu.Bounds.Width - 17, menus.BORDER_HEIGHT), RogueElements.DirH.Right))
    --Another divider, plus accepted counter
    self.menu.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(8, self.menu.Bounds.Height - 24), self.menu.Bounds.Width - 8 * 2))
    self.menu.Elements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey(self.library.globals.keys.JOB_ACCEPTED, #self.library.root.taken, self.library.data.taken_limit), RogueElements.Loc(96, self.menu.Bounds.Height - 20)))
    --Cursor
    self.cursor = RogueEssence.Menu.MenuCursor(self.menu)
    self.menu.Elements:Add(self.cursor)
    --In total, 6 elements. Remember this for menu refresh
end

function BoardMenu:Select(index)
    self.current = math.max(1, math.max(index, #self.choices))
    self.cursor_pos = (index-1) % self.MAX_ENTRIES +1
    self.page = (index-1) // self.MAX_ENTRIES +1
    self:SelectPage(self.page)
end

function BoardMenu:SelectPage(num)
    num = (num-1) % self.pages +1
    if self.menu.Elements.Count > 6 then
        for i=6, self.menu.Elements.Count-1, 1 do
            self.menu.Elements:RemoveAt(i)
        end
    end
    local start = (num-1) * self.MAX_ENTRIES +1
    local finish = math.min(start+3, #self.choices)
    for i = start, finish, 1 do
        self.menu.Elements:Add(self.choices[i])
    end
    self.page_choices = finish-start+1
    self.page = num
    self:MoveCursor(math.min(self.cursor_pos, self.page_choices))
end

function BoardMenu:MoveCursor(index)
    self.cursor_pos = (index-1) % self.MAX_ENTRIES +1
    self.current = index + (self.page-1) * self.MAX_ENTRIES

    self.cursor:ResetTimeOffset()
    self.cursor.Loc = RogueElements.Loc(9, 28 * self.cursor_pos -1)
end

function BoardMenu:Update(input)
    assert(self, "BaseState:Begin(): Error, self is nil!")
    if input:JustPressed(RogueEssence.FrameInput.InputType.Confirm) then
        --open the selected job menu
        self.choices[self.current]:OnConfirm()
    elseif input:JustPressed(RogueEssence.FrameInput.InputType.Cancel) or input:JustPressed(RogueEssence.FrameInput.InputType.Menu) then
        self:choose(-1)
    else
        local start = self.current
        if RogueEssence.Menu.InteractableMenu.IsInputting(input, LUA_ENGINE:MakeLuaArray(Dir8, { Dir8.Down, Dir8.DownLeft, Dir8.DownRight })) then
            self:MoveCursor(self.cursor_pos+1)
        elseif RogueEssence.Menu.InteractableMenu.IsInputting(input, LUA_ENGINE:MakeLuaArray(Dir8, { Dir8.Up, Dir8.UpLeft, Dir8.UpRight })) then
            self:MoveCursor(self.cursor_pos-1)
        elseif RogueEssence.Menu.InteractableMenu.IsInputting(input, LUA_ENGINE:MakeLuaArray(Dir8, {Dir8.Right})) then
            self:SelectPage(self.page+1)
        elseif RogueEssence.Menu.InteractableMenu.IsInputting(input, LUA_ENGINE:MakeLuaArray(Dir8, {Dir8.Left})) then
            self:SelectPage(self.page-1)
        end

        if start ~= self.current then
            _GAME:SE("Menu/Select")
        end
    end
end

--- Runs a BoardMenu instance and returns its selected index
--- @param library table the entire job library structure
--- @param board_id string|nil the id of the board to visualize. Set to nil to select the taken list.
--- @param start_choice|nil number the choice that should be selected first. Defaults to 1
--- @return integer #the index of the chosen option, or -1 if the menu was exited without selecting anything.
function BoardMenu.run(library, board_id, start_choice)
    local ret = -1
    local cb = function(choice) ret = choice end
    local menu = BoardMenu:new(library, board_id, cb, start_choice or 1)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret
end

--- Adds a BoardMenu instance to the menu stack and then runs the given callback.
--- @param library table the entire job library structure.
--- @param board_id string|nil the id of the board to visualize. Set to nil to select the taken list.
--- @param callback fun(i:number):nil the callback to run when the menu needs to close. It will have a number passed to it that is equal to the selected index, or -1 if nothing was selected.
--- @param start_choice number|nil the choice that should be selected first. Defaults to 1
function BoardMenu.add(library, board_id, callback, start_choice)
    local menu = BoardMenu:new(library, board_id, callback, start_choice or 1)
    UI:AddMenu(menu.menu)
end




--- @class JobMenu Menu that allows the player to choose what to do with a specific job
local JobMenu = Class('JobMenu')

--- Creates the menu, using the provided data and callback
--- @param library table the entire job library structure
--- @param board_id string the id of the board to be prompted
--- @param job_index number the index of the job to visualize
--- @param callback function that handles the menu's output. The value is equal to the index selected
function JobMenu:initialize(library, board_id, job_index, callback)
    assert(self, "BoardSelectionMenu:initialize(): Error, self is nil!")
    self.library = library
    self.board = self.library.root.taken
    if board_id then self.board = self.library.root.boards[board_id] end
    self.job = self.board[job_index]
    self.callback = callback

    local choices = { { STRINGS:FormatKey("MENU_CANCEL"), true, function() self:choose(-1) end } }
    local choice_str = STRINGS:FormatKey(self.library.globals.keys.BUTTON_TAKE)
    if board_id then --TODO decide how to handle this: COMMON.HasSidequestInZone(self.job.Zone)
        local enabled = true
        if self.job.Taken then choice_str, enabled = STRINGS:FormatKey(self.library.globals.keys.BUTTON_SUSPEND), true end
        table.insert(choices, 1, {choice_str, enabled, function() self:choose(1) end})
        table.insert(choices, 2, {STRINGS:FormatKey(self.library.globals.keys.BUTTON_DELETE), true, function() self:choose(2) end})
    else
        table.insert(choices, 1, {STRINGS:FormatKey(self.library.globals.keys.BUTTON_TAKE), library:IsTakenListFull() and not self.job.Taken, function() self:choose(1) end })
    end
    self.menu = RogueEssence.Menu.ScriptableSingleScriptMenu(232, 138, 24, choices, 1, function() self:choose(-1) end)

    self.job_window = self:GenerateSummary()
    self.menu.LowerSummaryMenus:Add(self.job_window)
end

--- Confirmation function that runs the stored callback and closes the menu.
--- @param i number the index of the selected choice, or -1 if nothing was selected.
function JobMenu:choose(i)
    _MENU:RemoveMenu()
    self.callback(i)
end

function JobMenu:GenerateSummary()
    local summary = RogueEssence.Menu.SummaryMenu(RogueElements.Rect(32, 32, 256, 176))
    --Standard menu divider. Reuse this whenever you need a menu divider at the top for a title.
    summary.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(8, 8 + 12), summary.Bounds.Width - 8 * 2))

    --Standard title. Reuse this whenever a title is needed.
    summary.Elements:Add(RogueEssence.Menu.MenuText(Text.FormatKey(self.library.globals.keys.JOB_SUMMARY), RogueElements.Loc(16, 8)))

    --Accepted element
    summary.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(8, summary.Bounds.Height - 24), summary.Bounds.Width - 8 * 2))
    summary.Elements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey(self.library.globals.keys.JOB_ACCEPTED, #self.library.root.taken, self.library.data.taken_limit), RogueElements.Loc(96, summary.Bounds.Height - 20)))

    summary.Elements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey(self.job.Flavor[1]), RogueElements.Loc(16, 24)))
    summary.Elements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey(self.job.Flavor[2]), RogueElements.Loc(16, 36)))
    summary.Elements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey(self.library.globals.keys.JOB_CLIENT), RogueElements.Loc(16, 54)))
    summary.Elements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey(self.library.globals.keys.JOB_OBJECTIVE), RogueElements.Loc(16, 68)))
    summary.Elements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey(self.library.globals.keys.JOB_PLACE), RogueElements.Loc(16, 82)))
    summary.Elements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey(self.library.globals.keys.JOB_DIFFICULTY), RogueElements.Loc(16, 96)))
    summary.Elements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey(self.library.globals.keys.JOB_REWARD), RogueElements.Loc(16, 110)))

    summary.Elements:Add(RogueEssence.Menu.MenuText(getCharacterName(self.job.Client), RogueElements.Loc(68, 54)))
    summary.Elements:Add(RogueEssence.Menu.MenuText(getObjectiveString(self.library, self.job), RogueElements.Loc(68, 68)))
    summary.Elements:Add(RogueEssence.Menu.MenuText(self:GetZoneString(), RogueElements.Loc(68, 82)))
    summary.Elements:Add(RogueEssence.Menu.MenuText(self:GetDifficultyString(), RogueElements.Loc(68, 96)))
    summary.Elements:Add(RogueEssence.Menu.MenuText(self:GetRewardString(), RogueElements.Loc(68, 110)))

    return summary
end

function JobMenu:GetZoneString()
    local zone_string, floor_string = "", ""
    if self.job.Zone ~= "" then
        zone_string = _DATA:GetZone(self.job.Zone).Segments[self.job.Segment]:ToString()
        zone_string, floor_string = self.library:CreateColoredSegmentString(zone_string)
        floor_string = STRINGS:Format(floor_string, tostring(self.job.Floor))
    else
        --TODO log error
        zone_string, floor_string = self.job.Zone.."["..self.job.Segment.."]", self.job.Floor.."F"
    end

    if self.job.HideFloor then
        return zone_string
    else
        return zone_string .. " " .. floor_string
    end
end

function JobMenu:GetDifficultyString()
    local diff_id = self.library.data.num_to_difficulty[self.job.Difficulty]
    local key = self.library.data.difficulty_data[diff_id].display_key
    STRINGS:FormatKey(key) --TODO write all the strings for the various difficulties
end

function JobMenu:GetRewardString()
    local reward1 = ""
    if self.library.globals.reward_types[self.job.RewardType][1] then
        reward1 = JobMenu:GetItemName(self.job.Rewards[1])
    else
        local diff_id = self.library.data.num_to_difficulty[self.job.Difficulty]
        local money = self.library.data.difficulty_data[diff_id].money_reward
        reward1 = STRINGS:FormatKey("MONEY_AMOUNT", money)
    end
    local key_pointer = self.library.globals.reward_types[self.job.RewardType][4]
    local key = self.library.globals.keys[key_pointer]
    STRINGS:FormatKey(key, reward1)
end

--- Runs a JobMenu instance and returns its selected index.
--- @param library table the entire job library structure.
--- @param board_id string|nil the id of the board this job is in. Set to nil to select the taken list.
--- @param job_index number the index of the job to visualize.
--- @return integer #the index of the chosen option, or -1 if the menu was exited without selecting anything.
function JobMenu.run(library, board_id, job_index)
    local ret = -1
    local cb = function(choice) ret = choice end
    local menu = JobMenu:new(library, board_id, job_index, cb)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret
end

--- Adds a JobMenu instance to the menu stack and then runs the given callback.
--- @param library table the entire job library structure
--- @param board_id string|nil the id of the board this job is in. Set to nil to select the taken list.
--- @param job_index number the index of the job to visualize.
--- @param callback fun(i:number):nil the callback to run when the menu needs to close. It will have a number passed to it that is equal to the selected index, or -1 if either the exit option was selected or nothing was.
function JobMenu.add(library, board_id, job_index, callback)
    local menu = JobMenu:new(library, board_id, job_index, callback)
    UI:AddMenu(menu.menu)
end


--- @class DungeonJobList Menu that allows the player to see what jobs are in the current dungeon.
local DungeonJobList = Class('DungeonJobList')

--Used to see what jobs are in this dungeon
--- Creates the menu, using the provided data if required
--- @param library table the entire job library structure
--- @param dungeon string|nil Optional. A dungeon id to display the jobs of. It will be ignored unless this menu is opened from a ground map.
--- @param segment string|nil Optional. A section id to display the jobs of. It will be ignored unless this menu is opened from a ground map.
function DungeonJobList:initialize(library, dungeon, segment)
    self.library = library
    assert(self, "DungeonJobList:initialize(): Error, self is nil!")
    self.MAX_ENTRIES = 10

    self.dungeon = ""
    self.section = -1

    if RogueEssence.GameManager.Instance.CurrentScene == RogueEssence.Dungeon.DungeonScene.Instance then
        self.dungeon = _ZONE.CurrentZoneID
        self.section = _ZONE.CurrentMapID.Segment
    elseif dungeon and segment then
        self.dungeon = dungeon
        self.segment = segment
    end

    self.entries = self:GenerateEntries()
    self.pages = math.max(0, self.entries-1)//self.MAX_ENTRIES +1
    self.page = 1
    self:DrawMenu() --TODO
    self.menu = RogueEssence.Menu.ScriptableMenu(32, 32, 256, 176, function(input) self:Update(input) end)
end

function DungeonJobList:GenerateEntries()
    local list = {}
    local oth_segments = {}
    local oth_segments_list = {}

    local jobs = self.root.taken
    for _, job in ipairs(jobs) do
        if job.Taken and job.Zone == self.dungeon then
            if job.Segment == self.section then
                local icon = STRINGS:Format("\\uE10F") --open letter
                if job.Completed then icon = STRINGS:Format("\\uE10A") end --check mark

                local floor = ""
                if not self.job.HideFloor then
                    local _, floor_pattern = self.library:CreateColoredSegmentString(self.dungeon, self.section)
                    floor = STRINGS:Format(floor_pattern, job.Floor)
                end

                local message = getObjectiveString(self.library, self.job)

                table.insert(list, {icon = icon, floor = floor, message = message})
            elseif self.section and oth_segments[job.Segment] then
                table.insert(oth_segments_list, job.Segment)
                oth_segments[job.Segment] = true
            end
        end
    end
    if #oth_segments_list>0 then
        table.sort(oth_segments_list)
        for _, segment in ipairs(oth_segments_list) do
            local seg_name = self.library:CreateColoredSegmentString(self.dungeon, segment)
            local message = STRINGS:FormatKey(self.library.globals.keys.MISSION_OBJECTIVES_SIDE, seg_name)
            table.insert(list, {icon = nil, floor = nil, message = message})
        end
    end
    if #list <= 0 then
        if _DATA.Save.Rescue ~= nil and _DATA.Save.Rescue.Rescuing then
            if self.section ~= _DATA.Save.Rescue.SOS.Goal.StructID.Segment then
                local seg_name = self.library:CreateColoredSegmentString(self.dungeon, _DATA.Save.Rescue.SOS.Goal.StructID.Segment)
                local message = STRINGS:FormatKey(self.library.globals.keys.MISSION_OBJECTIVES_SIDE, seg_name)
                table.insert(list, {icon = nil, floor = nil, message = message})
            else
                local team_to_save = _DATA.Save.Rescue.SOS.TeamName --TODO test or add colors
                local message = STRINGS:FormatKey(self.library.globals.keys.RESCUE_SELF, team_to_save)
                table.insert(list, {icon = nil, floor = nil, message = message})
            end
        elseif false then
            --TODO make external conditions table and check for them. Use "Rescue" key and team name
        else -- default
            table.insert(list, {icon = nil, floor = nil, message = STRINGS:FormatKey(self.library.globals.keys.MISSION_OBJECTIVES_DEFAULT)})
        end
    end
    return list
end

function DungeonJobList:DrawMenu()
    self.menu.Elements:Clear()

    --Standard menu divider. Reuse this whenever you need a menu divider at the top for a title.
    self.menu.Elements:Add(RogueEssence.Menu.MenuDivider(RogueElements.Loc(8, 8 + 12), self.menu.Bounds.Width - 8 * 2))

    --Standard title. Reuse this whenever a title is needed.
    self.menu.Elements:Add(RogueEssence.Menu.MenuText("Mission Objectives", RogueElements.Loc(16, 8))) --TODO turn into key

    --page number
    if self.pages > 1 then
        self.menu.Elements:Add(RogueEssence.Menu.MenuText("(" .. tostring(self.page) .. "/" .. tostring(self.pages) .. ")", RogueElements.Loc(self.menu.Bounds.Width - 17, menus.BORDER_HEIGHT), RogueElements.DirH.Right))
    end

    --how many jobs have we populated so far
    local side_dungeon_mission = false
    local zone_string = ''

    --populate jobs that are in this dungeon
    local start  = (self.page-1) * self.MAX_ENTRIES + 1
    local finish = math.min(self.page * self.MAX_ENTRIES, #self.entries)
    for i = start, finish, -1 do
        local count = start % self.MAX_ENTRIES - 1
        local entry = self.entries[i]

        if entry.icon    then self.menu.Elements:Add(RogueEssence.Menu.MenuText(entry.icon, RogueElements.Loc(16, 24 + 14 * count)))    end
        if entry.floor   then self.menu.Elements:Add(RogueEssence.Menu.MenuText(entry.floor, RogueElements.Loc(28, 24 + 14 * count)))   end
        if entry.message then self.menu.Elements:Add(RogueEssence.Menu.MenuText(entry.message, RogueElements.Loc(60, 24 + 14 * count))) end
    end
end

--TODO add page handling
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
    elseif self.pages>1 and RogueEssence.Menu.InteractableMenu.IsInputting(input, LUA_ENGINE:MakeLuaArray(Dir8, {Dir8.Right})) then
        self.page = (self.page)   % self.pages + 1
        --TODO SE
        self:DrawMenu()
    elseif self.pages>1 and RogueEssence.Menu.InteractableMenu.IsInputting(input, LUA_ENGINE:MakeLuaArray(Dir8, {Dir8.Left})) then
        self.page = (self.page-2) % self.pages + 1
        --TODO SE
        self:DrawMenu()
    end
end

--- Runs a DungeonJobList instance.
--- @param library table the entire job library structure.
--- @param dungeon string|nil Optional. A dungeon id to display the jobs of. It will be ignored unless this menu is opened from a ground map.
--- @param segment string|nil Optional. A section id to display the jobs of. It will be ignored unless this menu is opened from a ground map.
function DungeonJobList.run(library, dungeon, segment)
    local menu = DungeonJobList:new(library, dungeon, segment)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
end

--- Adds a DungeonJobList instance to the menu stack.
--- @param library table the entire job library structure
--- @param dungeon string|nil Optional. A dungeon id to display the jobs of. It will be ignored unless this menu is opened from a ground map.
--- @param segment string|nil Optional. A section id to display the jobs of. It will be ignored unless this menu is opened from a ground map.
function DungeonJobList.add(library, dungeon, segment)
    local menu = DungeonJobList:new(library, dungeon, segment)
    UI:AddMenu(menu.menu)
end

menus.BoardSelection = BoardSelectionMenu
menus.Board = BoardMenu
menus.Job = JobMenu
menus.Objectives = DungeonJobList

return menus



-- TODO this will instead be a service just like in Dungeon Recruitment List
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