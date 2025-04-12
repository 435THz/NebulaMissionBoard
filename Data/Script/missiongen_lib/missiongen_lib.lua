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
    data = require("missiongen_settings")
}

-- ----------------------------------------------------------------------------------------- --
-- DATA GENERATORS
-- ----------------------------------------------------------------------------------------- --
-- Here at the top for easy access and reference, so that it is possible for modders to
-- quickly understand how the data is structured.
function library:load()
    local rootpath = self.data.sv_root_name
    if type(root) ~= "table" then
        rootpath = {self.data.sv_root_name}
    end
    self.root = SV
    for _, id in ipairs(rootpath) do
        SV[id] = SV[id] or {}
        self.root = SV[id]
    end
end

--- Returns a new empty job template
function library:job_template()
    return {
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
		BonusReward = ""
	}
end

return library