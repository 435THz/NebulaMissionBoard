-- PMDO Mission Generation Library, by MistressNebula
-- Settings file
-- ----------------------------------------------------------------------------------------- --
-- This file exists as a way to separate the library's configurable data frim its functions.
-- If you are looking for the latter, please refer to missiongen_lib.lua
-- ----------------------------------------------------------------------------------------- --
-- This file is already loaded by missiongen_lib.lua. You don't need to require it
-- explicitly in your project.

local settings = {
    --- Name of the SV table that will contain all stored data. Use a table to specify a deper path.
    --- If absent, these tables will be generated automatically.
    --- Example: "jobs" would use SV.jobs as its root.
    --- {"adventure", "jobs"} would use SV.adventure.jobs as its root.
    sv_root_name = "jobs",
    --- The maximum number of jobs that can be taken from job boards at a time
    taken_limit = 8,
    --- a list of job boards
    boards = {}

}

return settings