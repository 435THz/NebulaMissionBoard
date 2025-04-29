
local menus = {
    LINE_HEIGHT = 12,
    VERT_SPACE = 14,
    TITLE_HEIGHT = 12 + RogueEssence.Content.GraphicsManager.MenuBG.TileHeight,
    SCREEN_HEIGHT = RogueEssence.Content.GraphicsManager.ScreenHeight,
    SCREEN_WIDTH = RogueEssence.Content.GraphicsManager.ScreenWidth,
    BORDER_HEIGHT = RogueEssence.Content.GraphicsManager.MenuBG.TileHeight,
    BORDER_WIDTH = RogueEssence.Content.GraphicsManager.MenuBG.TileWidth
}

--- Given a segment name string, return a colored segment.
--- This is obtained by removing the part containing the string "{0}" and wrapping yellow around everything else
local createColoredSegmentString = function(segment_name)
    local split_name = {}
    for str in string.gmatch(segment_name, "([^%s]+)") do
        table.insert(split_name, str)
    end

    local final_name = ''

    for i = 1, #split_name, 1 do
        local cur_word = split_name[i]

        --discard the "floor number" part
        if not string.find(cur_word, '{0}', 1, true) then
            if i > 1 then
                final_name = final_name..' '
            end
            final_name = final_name..cur_word
        end
    end
    return '[color=#FFC663]'..final_name..'[color]'
end

--- Menu that allows the player to open either a specific board or the taken job list
local BoardSelectionMenu = Class('BoardSelectionMenu')

--- Creates the menu, using the provided data and callback
--- @param library table the entire job library structure
--- @param board_id string the id of the board to be prompted
--- @param callback function that handles the menu's output. The value is equal to the index selected
function BoardSelectionMenu:initialize(library, board_id, callback)
    assert(self, "BoardSelectionMenu:initialize(): Error, self is nil!")
    self.callback = callback

    local choices = {
        {STRINGS:FormatKey(library.data.boards[board_id].display_key), library:IsBoardEmpty(board_id), self:choose(1)},
        {STRINGS:FormatKey("BOARD_TAKEN_TITLE"), library:IsTakenListEmpty(), self:choose(2)},
        {STRINGS:FormatKey("MENU_EXIT"), true, self:choose(3)}
    }
    self.menu = RogueEssence.Menu.ScriptableSingleScriptMenu(24, 22, 100, choices, 1, self:choose(3))
end

--- Confirmation function that runs the stored callback and closes the menu.
--- @param i number the index of the selected choice
function BoardSelectionMenu:choose(i)
    _MENU:RemoveMenu()
    self.callback(i)
end

--- Runs a BoardSelectionMenu instance and returns its selected index
--- @param library table the entire job library structure
--- @param board_id string the id of a board. It will be used to display the first option.
function BoardSelectionMenu.run(library, board_id)
    local ret = 3
    local cb = function(choice) ret = choice end
    local menu = BoardSelectionMenu:new(library, board_id, cb)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret
end



--- Menu that displays the contents of a board and allows the player to interact with them.
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
        self.board_title = self.library.globals.keys.taken_board
    end

    self.choices = self:GenerateOptions()
    self.pages = math.ceil(#self.choices / self.MAX_ENTRIES)
    self.taken_count = MISSION_GEN.GetTakenCount()
    if self.pages <=0 then
        --TODO move this check in the library function so that logError can be accessed
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

        local zone = _DATA:GetZone(job.Zone).Segments[job.Segment]:ToString()
        zone = createColoredSegmentString(zone)
        local floor =  MISSION_GEN.GetStairsType(job.Zone) ..'[color=#00FFFF]' .. tostring(job.Floor) .. "[color]F"
        local difficulty = self.library.data.difficulty_data[self.library.data.num_to_difficulty[job.Difficulty]].display_key
        --TODO Oh, so THIS is why we need a shallowcopy function for the mission data. Noted. It's because we can't guarantee the structures point to the same job after save and load
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
        local location = zone .. " " .. floor

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
    self.menu.Elements:Add(RogueEssence.Menu.MenuText(STRINGS:FormatKey("MISSION_BOARD_ACCEPTED") .. tostring(#self.library.root.taken) .. "/"..self.library.data.taken_limit, RogueElements.Loc(96, self.menu.Bounds.Height - 20)))
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
--- @param board_id string the id of a board. It will be used to display the first option.
--- @param start_choice number the choice that should be selected first. Defaults to 1
function BoardMenu.run(library, board_id, start_choice)
    local ret = -1
    local cb = function(choice) ret = choice end
    local menu = BoardMenu:new(library, board_id, cb, start_choice or 1)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret
end


menus.BoardSelection = BoardSelectionMenu
menus.Board = BoardMenu



--- Menu that allows the player to choose what to do with a specific job
local JobMenu = Class('JobMenu')

--- Creates the menu, using the provided data and callback
--- @param library table the entire job library structure
--- @param board_id string the id of the board to be prompted
--- @param callback function that handles the menu's output. The value is equal to the index selected
function JobMenu:initialize(library, board_id, callback)
    assert(self, "BoardSelectionMenu:initialize(): Error, self is nil!")
    self.callback = callback

    local choices = { { Text.FormatKey("MISSION_BOARD_CANCEL"), true, function() self:choose(3) end } }
    if board_id then
        choices = {	{choice_str, not take_job or not COMMON.HasSidequestInZone(self.zone_name), function() self:FlipTakenStatus() _MENU:RemoveMenu() _MENU:RemoveMenu() end},
                       {Text.FormatKey("MISSION_BOARD_DELETE"), true, function() self:DeleteJob() _MENU:RemoveMenu() end},
        }
    else
        choices = {{Text.FormatKey("MISSION_BOARD_TAKE_JOB"), MISSION_GEN.IsBoardFull(SV.TakenBoard) == false and not self.taken, function() self:FlipTakenStatus()
            self:AddJobToTaken() _MENU:RemoveMenu() end },
                   {Text.FormatKey("MISSION_BOARD_CANCEL"), true, function() _MENU:RemoveMenu() _MENU:RemoveMenu() end} }
    end
    self.menu = RogueEssence.Menu.ScriptableSingleScriptMenu(24, 22, 100, choices, 1, self:choose(3))
end

--- Confirmation function that runs the stored callback and closes the menu.
--- @param i number the index of the selected choice
function JobMenu:choose(i)
    _MENU:RemoveMenu()
    self.callback(i)
end

--- Runs a BoardSelectionMenu instance and returns its selected index
--- @param library table the entire job library structure
--- @param board_id string the id of a board. It will be used to display the first option.
function JobMenu.run(library, board_id)
    local ret = 3
    local cb = function(choice) ret = choice end
    local menu = JobMenu:new(library, board_id, cb)
    UI:SetCustomMenu(menu.menu)
    UI:WaitForChoice()
    return ret
end
