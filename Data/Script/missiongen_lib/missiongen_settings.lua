-- PMDO Mission Generation Library, by MistressNebula
-- Settings file
-- ----------------------------------------------------------------------------------------- --
-- This file exists as a way to separate the library's configurable data frim its functions.
-- If you are looking for the latter, please refer to missiongen_lib.lua
-- ----------------------------------------------------------------------------------------- --
-- This file is already loaded by missiongen_lib.lua. You don't need to require it
-- explicitly in your project.

local enums = {}
enums.extra_reward = {}
enums.extra_reward["none"] = 0
enums.extra_reward["rank"] = 1
enums.extra_reward["exp"] = 2

local settings = {
    --- Name of the SV table that will contain all stored data. Use a table to specify a deper path.
    --- If absent, these tables will be generated automatically.
    --- "jobs" would use SV.jobs as its root.
    --- {"adventure", "jobs"} would use SV.adventure.jobs as its root.
    sv_root_name = "jobs",
    --- The maximum number of jobs that can be taken from job boards at a time
    taken_limit = 8,
    --  Define here, in order, the list of all difficulty rank ids you want to use
    difficulty_list = {"F", "E", "D", "C", "B", "A", "S", "STAR_1", "STAR_2", "STAR_3", "STAR_4", "STAR_5", "STAR_6", "STAR_7", "STAR_8", "STAR_9"},
    --- All the data required for difficulty ranks. There must be an entry for every rank defined in difficulty_list:
    --- id = {display_key, money_reward, extra_reward, outlaw_level, escort_level}
    --- display_key: string key used when displaying the name of the rank
    --- money_reward: the amount of money awarded at the end of the job. If set to 0, money rewards will be removed from the pool of reward types
    --- extra_reward: the points of extra reward awarded at the end of the job. What these points are depends on extra_reward_type. If set to 0, extra_reward_type will be considered to be "none"
    --- outlaw_level: the base level of all outlaws spawned by jobs with this difficulty.
    --- escort_level: the level of all guests spawned by jobs with this difficulty
    difficulty_data = { --TODO set levels
        F = {"RANK_STRING_F", 100,  0},
        E = {"RANK_STRING_E", 200, 100},
        D = {"RANK_STRING_D", 400, 200},
        C = {"RANK_STRING_C", 600, 400},
        B = {"RANK_STRING_B", 700, 1250},
        A = {"RANK_STRING_A", 1500, 2500},
        S = {"RANK_STRING_S", 3000, 5000},
        STAR_1 = {"RANK_STRING_STAR_1", 6000, 10000},
        STAR_2 = {"RANK_STRING_STAR_2", 10000, 20000},
        STAR_3 = {"RANK_STRING_STAR_3", 15000, 30000},
        STAR_4 = {"RANK_STRING_STAR_4", 20000, 40000},
        STAR_5 = {"RANK_STRING_STAR_5", 25000, 50000},
        STAR_6 = {"RANK_STRING_STAR_6", 30000, 60000},
        STAR_7 = {"RANK_STRING_STAR_7", 35000, 70000},
        STAR_8 = {"RANK_STRING_STAR_8", 40000, 80000},
        STAR_9 = {"RANK_STRING_STAR_9", 45000, 90000}
    },
    --- A list of all types of rewards to be offered to players.
    --- format: {id = string, weight = number, min_rank = string}
    --- id: one of the supported quest types. You can use duplicate values to alter odds depending on job rank.
    --- weight: Chance of appearing. Set to 0 or delete altogether to stop a type of reward from being offered.
    --- min_rank: optional. If set, this type of reward will only be offered if the job is this rank or higher.
    --- Supported quest types are: item, money, item_item, money_item
    reward_types = {
        {id = "item", weight = 6},
        {id = "money", weight = 2},
        {id = "item_item", weight = 3},  -- second item hidden
        {id = "money_item", weight = 1}, -- item is hidden
        {id = "client", weight = 1, min_rank = "STAR_1"},     -- appears as ???
        {id = "exclusive", weight = 1, min_rank = "STAR_4"}   -- appears as ???. Award a 1* of client, or of target if outlaw. TODO don't pick if impossible for target/outlaw
    },
    --- The type of extra reward for all quests. It can be "none", "rank" or "exp". Any other value will result in "none"
    extra_reward_type = "exp",
    --- Function that changes the level of guests based on the player's level. It must return the new level for the guest, or it will have no effect.
    --- arg1: base level of the guest.
    --- arg2: average level of the player team. It may or may not be an integer.
    --- arg3: highest level in the player team.
    --- arg4: the settings data structure itself
    guest_level_scaling = function(lvl, avg_team_lvl, hst_team_level, settings)
        local add = 0
        if avg_team_lvl > lvl then add = (avg_team_lvl - lvl) / 10 end -- add 10% of the level difference between guest and average
        return lvl + add
    end,
    --- Function that changes the level of outlaws based on the player's level. It must return the new level for the outlaw, or it will have no effect.
    --- arg1: base level of the outlaw.
    --- arg2: average level of the player team. It may or may not be an integer.
    --- arg3: highest level in the player team.
    --- arg4: the settings data structure itself
    outlaw_level_scaling = function(lvl, avg_team_lvl, hst_team_level, settings)
        local add = 0
        if avg_team_lvl > lvl then add = (avg_team_lvl - lvl) / 10 end -- add 10% of the level difference between outlaw and average
        add = add + (hst_team_level - avg_team_lvl) / 4 -- add 25% of the level difference between average and highest in the team
        return lvl + add
    end,
    --- Use this to assign different weights to reward pools depending on the difficulty rank of the mission.
    --- rank = {{id = pool_id, weight = number}}
    rewards_per_difficulty = {
        F = {
            {id = "NECESSITIES", weight = 10}, --Basic stuff (i.e. reviver seeds, escape orbs, leppa berries) *
            {id = "AMMO_LOW", weight = 0},
            {id = "AMMO_MID", weight = 0},
            {id = "AMMO_HIGH", weight = 0},
            {id = "APRICORN_GENERIC", weight = 0},
            {id = "APRICORN_TYPED", weight = 0},
            {id = "FOOD_LOW", weight = 0},
            {id = "FOOD_MID", weight = 0},
            {id = "FOOD_HIGH", weight = 0},
            {id = "MEDICINE_LOW", weight = 0},
            {id = "MEDICINE_HIGH", weight = 0},
            {id = "SEED_LOW", weight = 0},
            {id = "SEED_MID", weight = 0},
            {id = "SEED_HIGH", weight = 0},
            {id = "HELD_LOW", weight = 0},
            {id = "HELD_MID", weight = 0},
            {id = "HELD_HIGH", weight = 0},
            {id = "HELD_TYPE", weight = 0},
            {id = "HELD_PLATES", weight = 0},
            {id = "LOOT_LOW", weight = 0},
            {id = "LOOT_HIGH", weight = 0},
            {id = "EVO_ITEMS", weight = 0},
            {id = "ORBS_LOW", weight = 0},
            {id = "ORBS_MID", weight = 0},
            {id = "ORBS_HIGH", weight = 0},
            {id = "WANDS_LOW", weight = 0},
            {id = "WANDS_MID", weight = 0},
            {id = "WANDS_HIGH", weight = 0},
            {id = "TM_LOW", weight = 0},
            {id = "TM_MID", weight = 0},
            {id = "TM_HIGH", weight = 0},
            {id = "SPECIAL", weight = 0}
        },
        E = {
            {id = "NECESSITIES", weight = 10},  --Basic stuff (i.e. reviver seeds, escape orbs, leppa berries) *
            {id = "AMMO_LOW", weight = 0},
            {id = "AMMO_MID", weight = 0},
            {id = "AMMO_HIGH", weight = 0},
            {id = "APRICORN_GENERIC", weight = 10}, --Generic (non-typed) apricorns with a max catch bonus below 35 *
            {id = "APRICORN_TYPED", weight = 0},
            {id = "FOOD_LOW", weight = 10}, --Basic food, small chance of gummis *
            {id = "FOOD_MID", weight = 0},
            {id = "FOOD_HIGH", weight = 0},
            {id = "MEDICINE_LOW", weight = 0},
            {id = "MEDICINE_HIGH", weight = 0},
            {id = "SEED_LOW", weight = 10}, --Basic seeds, berries, white herbs *
            {id = "SEED_MID", weight = 0},
            {id = "SEED_HIGH", weight = 0},
            {id = "HELD_LOW", weight = 3}, --Basic stat boosting held items and ones with a net drawback (Iron Ball, Flame Orb, etc.)
            {id = "HELD_MID", weight = 0},
            {id = "HELD_HIGH", weight = 0},
            {id = "HELD_TYPE", weight = 0},
            {id = "HELD_PLATES", weight = 0},
            {id = "LOOT_LOW", weight = 3}, --Keys, pearls, assembly boxes
            {id = "LOOT_HIGH", weight = 0},
            {id = "EVO_ITEMS", weight = 1}, --Evolution items, high chance of link cables
            {id = "ORBS_LOW", weight = 0},
            {id = "ORBS_MID", weight = 0},
            {id = "ORBS_HIGH", weight = 0},
            {id = "WANDS_LOW", weight = 10}, --Weak wands *
            {id = "WANDS_MID", weight = 0},
            {id = "WANDS_HIGH", weight = 0},
            {id = "TM_LOW", weight = 0},
            {id = "TM_MID", weight = 0},
            {id = "TM_HIGH", weight = 0},
            {id = "SPECIAL", weight = 0}
        },
        D = {
            {id = "NECESSITIES", weight = 5},  --Basic stuff (i.e. reviver seeds, escape orbs, leppa berries)
            {id = "AMMO_LOW", weight = 10}, --Mostly iron thorns, with some weaker ammo *
            {id = "AMMO_MID", weight = 0},
            {id = "AMMO_HIGH", weight = 0},
            {id = "APRICORN_GENERIC", weight = 10}, --Generic (non-typed) apricorns with a max catch bonus below 35 *
            {id = "APRICORN_TYPED", weight = 2}, --Type and glitter apricorns
            {id = "FOOD_LOW", weight = 4}, --Basic food, small chance of gummis
            {id = "FOOD_MID", weight = 0},
            {id = "FOOD_HIGH", weight = 0},
            {id = "MEDICINE_LOW", weight = 0},
            {id = "MEDICINE_HIGH", weight = 0},
            {id = "SEED_LOW", weight = 4}, --Basic seeds, berries, white herbs
            {id = "SEED_MID", weight = 10}, --Advanced seeds and type berries *
            {id = "SEED_HIGH", weight = 0},
            {id = "HELD_LOW", weight = 10}, --Basic stat boosting held items and ones with a net drawback (Iron Ball, Flame Orb, etc.) *
            {id = "HELD_MID", weight = 0},
            {id = "HELD_HIGH", weight = 0},
            {id = "HELD_TYPE", weight = 3}, --Held items that boost a specific type
            {id = "HELD_PLATES", weight = 0},
            {id = "LOOT_LOW", weight = 10}, --Keys, pearls, assembly boxes *
            {id = "LOOT_HIGH", weight = 0},
            {id = "EVO_ITEMS", weight = 2}, --Evolution items, high chance of link cables
            {id = "ORBS_LOW", weight = 2}, --Weak wonder orbs
            {id = "ORBS_MID", weight = 0},
            {id = "ORBS_HIGH", weight = 0},
            {id = "WANDS_LOW", weight = 4}, --Weak wands
            {id = "WANDS_MID", weight = 10}, --Medium wands *
            {id = "WANDS_HIGH", weight = 0},
            {id = "TM_LOW", weight = 0},
            {id = "TM_MID", weight = 0},
            {id = "TM_HIGH", weight = 0},
            {id = "SPECIAL", weight = 0}
        },
        C = {
            {id = "NECESSITIES", weight = 4},  --Basic stuff (i.e. reviver seeds, escape orbs, leppa berries)
            {id = "AMMO_LOW", weight = 4}, --Mostly iron thorns, with some weaker ammo
            {id = "AMMO_MID", weight = 2}, --Stronger generic ammo that you find in most dungeons
            {id = "AMMO_HIGH", weight = 0},
            {id = "APRICORN_GENERIC", weight = 4}, --Generic (non-typed) apricorns with a max catch bonus below 35
            {id = "APRICORN_TYPED", weight = 10}, --Type and glitter apricorns *
            {id = "FOOD_LOW", weight = 4}, --Basic food, small chance of gummis
            {id = "FOOD_MID", weight = 10}, --Big food, medium chance of gummis *
            {id = "FOOD_HIGH", weight = 0},
            {id = "MEDICINE_LOW", weight = 0},
            {id = "MEDICINE_HIGH", weight = 0},
            {id = "SEED_LOW", weight = 4}, --Basic seeds, berries, white herbs
            {id = "SEED_MID", weight = 4}, --Advanced seeds and type berries
            {id = "SEED_HIGH", weight = 0},
            {id = "HELD_LOW", weight = 4}, --Basic stat boosting held items and ones with a net drawback (Iron Ball, Flame Orb, etc.)
            {id = "HELD_MID", weight = 0},
            {id = "HELD_HIGH", weight = 0},
            {id = "HELD_TYPE", weight = 3}, --Held items that boost a specific type
            {id = "HELD_PLATES", weight = 10}, --Held items that reduce damage from a specific type *
            {id = "LOOT_LOW", weight = 4}, --Keys, pearls, assembly boxes
            {id = "LOOT_HIGH", weight = 0},
            {id = "EVO_ITEMS", weight = 4}, --Evolution items, high chance of link cables
            {id = "ORBS_LOW", weight = 10}, --Weak wonder orbs *
            {id = "ORBS_MID", weight = 2}, --Medium wonder orbs, many can shut down a monster house
            {id = "ORBS_HIGH", weight = 0},
            {id = "WANDS_LOW", weight = 4}, --Weak wands
            {id = "WANDS_MID", weight = 4}, --Medium wands
            {id = "WANDS_HIGH", weight = 0},
            {id = "TM_LOW", weight = 10}, --TMs for weak moves *
            {id = "TM_MID", weight = 0},
            {id = "TM_HIGH", weight = 0},
            {id = "SPECIAL", weight = 0}
        },
        B = {
            {id = "NECESSITIES", weight = 3},  --Basic stuff (i.e. reviver seeds, escape orbs, leppa berries)
            {id = "AMMO_LOW", weight = 0},
            {id = "AMMO_MID", weight = 10}, --Stronger generic ammo that you find in most dungeons *
            {id = "AMMO_HIGH", weight = 2}, --Rare ammo that are hard to find in dungeons
            {id = "APRICORN_GENERIC", weight = 0},
            {id = "APRICORN_TYPED", weight = 10}, --Type and glitter apricorns *
            {id = "FOOD_LOW", weight = 3}, --Basic food, small chance of gummis
            {id = "FOOD_MID", weight = 5}, --Big food, medium chance of gummis
            {id = "FOOD_HIGH", weight = 0},
            {id = "MEDICINE_LOW", weight = 2}, --Weaker medicine that can't heal all PP or HP at once
            {id = "MEDICINE_HIGH", weight = 0},
            {id = "SEED_LOW", weight = 0},
            {id = "SEED_MID", weight = 4}, --Advanced seeds and type berries
            {id = "SEED_HIGH", weight = 3}, --Includes rare seeds and berries, skews to Pure Seeds
            {id = "HELD_LOW", weight = 3}, --Basic stat boosting held items and ones with a net drawback (Iron Ball, Flame Orb, etc.)
            {id = "HELD_MID", weight = 10}, --Held items very useful for a specific strategy *
            {id = "HELD_HIGH", weight = 0},
            {id = "HELD_TYPE", weight = 3}, --Held items that boost a specific type
            {id = "HELD_PLATES", weight = 3}, --Held items that reduce damage from a specific type
            {id = "LOOT_LOW", weight = 4}, --Keys, pearls, assembly boxes
            {id = "LOOT_HIGH", weight = 0},
            {id = "EVO_ITEMS", weight = 5}, --Evolution items, high chance of link cables
            {id = "ORBS_LOW", weight = 4}, --Weak wonder orbs
            {id = "ORBS_MID", weight = 10}, --Medium wonder orbs, many can shut down a monster house *
            {id = "ORBS_HIGH", weight = 0},
            {id = "WANDS_LOW", weight = 0},
            {id = "WANDS_MID", weight = 3}, --Medium wands
            {id = "WANDS_HIGH", weight = 10}, --Rare, specialty wands *
            {id = "TM_LOW", weight = 4}, --TMs for weak moves
            {id = "TM_MID", weight = 2}, --TMs for moderate moves
            {id = "TM_HIGH", weight = 0},
            {id = "SPECIAL", weight = 0}
        },
        A = {
            {id = "NECESSITIES", weight = 2},  --Basic stuff (i.e. reviver seeds, escape orbs, leppa berries)
            {id = "AMMO_LOW", weight = 0},
            {id = "AMMO_MID", weight = 3}, --Stronger generic ammo that you find in most dungeons
            {id = "AMMO_HIGH", weight = 10}, --Rare ammo that are hard to find in dungeons *
            {id = "APRICORN_GENERIC", weight = 0},
            {id = "APRICORN_TYPED", weight = 10}, --Type and glitter apricorns *
            {id = "FOOD_LOW", weight = 0},
            {id = "FOOD_MID", weight = 4}, --Big food, medium chance of gummis
            {id = "FOOD_HIGH", weight = 2}, --Huge food with a high chance of wonder gummis and a chance for vitamins
            {id = "MEDICINE_LOW", weight = 10}, --Weaker medicine that can't heal all PP or HP at once *
            {id = "MEDICINE_HIGH", weight = 0},
            {id = "SEED_LOW", weight = 0},
            {id = "SEED_MID", weight = 3}, --Advanced seeds and type berries
            {id = "SEED_HIGH", weight = 10}, --Includes rare seeds and berries, skews to Pure Seeds *
            {id = "HELD_LOW", weight = 0},
            {id = "HELD_MID", weight = 5}, --Held items very useful for a specific strategy
            {id = "HELD_HIGH", weight = 2}, --Held items useful for anyone
            {id = "HELD_TYPE", weight = 3}, --Held items that boost a specific type
            {id = "HELD_PLATES", weight = 3}, --Held items that reduce damage from a specific type
            {id = "LOOT_LOW", weight = 3}, --Keys, pearls, assembly boxes
            {id = "LOOT_HIGH", weight = 10}, --Rare loot, skews towards heart scales *
            {id = "EVO_ITEMS", weight = 10}, --Evolution items, high chance of link cables *
            {id = "ORBS_LOW", weight = 0},
            {id = "ORBS_MID", weight = 4}, --Medium wonder orbs, many can shut down a monster house
            {id = "ORBS_HIGH", weight = 4}, --Rare, powerful wonder orbs often with map wide effects
            {id = "WANDS_LOW", weight = 0},
            {id = "WANDS_MID", weight = 2}, --Medium wands
            {id = "WANDS_HIGH", weight = 5}, --Rare, specialty wands
            {id = "TM_LOW", weight = 2}, --TMs for weak moves
            {id = "TM_MID", weight = 10}, --TMs for moderate moves *
            {id = "TM_HIGH", weight = 0},
            {id = "SPECIAL", weight = 0}
        },
        S = {
            {id = "NECESSITIES", weight = 2},  --Basic stuff (i.e. reviver seeds, escape orbs, leppa berries)
            {id = "AMMO_LOW", weight = 0},
            {id = "AMMO_MID", weight = 2}, --Stronger generic ammo that you find in most dungeons
            {id = "AMMO_HIGH", weight = 5}, --Rare ammo that are hard to find in dungeons
            {id = "APRICORN_GENERIC", weight = 0},
            {id = "APRICORN_TYPED", weight = 5}, --Type and glitter apricorns
            {id = "FOOD_LOW", weight = 0},
            {id = "FOOD_MID", weight = 2}, --Big food, medium chance of gummis
            {id = "FOOD_HIGH", weight = 10}, --Huge food with a high chance of wonder gummis and a chance for vitamins *
            {id = "MEDICINE_LOW", weight = 4}, --Weaker medicine that can't heal all PP or HP at once
            {id = "MEDICINE_HIGH", weight = 10}, --Powerful medicine that can heal everything *
            {id = "SEED_LOW", weight = 0},
            {id = "SEED_MID", weight = 0},
            {id = "SEED_HIGH", weight = 5}, --Includes rare seeds and berries, skews to Pure Seeds
            {id = "HELD_LOW", weight = 0},
            {id = "HELD_MID", weight = 3}, --Held items very useful for a specific strategy
            {id = "HELD_HIGH", weight = 10}, --Held items useful for anyone *
            {id = "HELD_TYPE", weight = 3}, --Held items that boost a specific type
            {id = "HELD_PLATES", weight = 3}, --Held items that reduce damage from a specific type
            {id = "LOOT_LOW", weight = 2}, --Keys, pearls, assembly boxes
            {id = "LOOT_HIGH", weight = 10}, --Rare loot, skews towards heart scales *
            {id = "EVO_ITEMS", weight = 10}, --Evolution items, high chance of link cables *
            {id = "ORBS_LOW", weight = 0},
            {id = "ORBS_MID", weight = 2}, --Medium wonder orbs, many can shut down a monster house
            {id = "ORBS_HIGH", weight = 5}, --Rare, powerful wonder orbs often with map wide effects
            {id = "WANDS_LOW", weight = 0},
            {id = "WANDS_MID", weight = 2}, --Medium wands
            {id = "WANDS_HIGH", weight = 4}, --Rare, specialty wands
            {id = "TM_LOW", weight = 0},
            {id = "TM_MID", weight = 4}, --TMs for moderate moves
            {id = "TM_HIGH", weight = 10}, --TMs for very powerful moves *
            {id = "SPECIAL", weight = 0}
        },
        STAR_1 = {
            {id = "NECESSITIES", weight = 0},
            {id = "AMMO_LOW", weight = 0},
            {id = "AMMO_MID", weight = 2}, --Stronger generic ammo that you find in most dungeons
            {id = "AMMO_HIGH", weight = 5}, --Rare ammo that are hard to find in dungeons
            {id = "APRICORN_GENERIC", weight = 0},
            {id = "APRICORN_TYPED", weight = 5}, --Type and glitter apricorns
            {id = "FOOD_LOW", weight = 0},
            {id = "FOOD_MID", weight = 0},
            {id = "FOOD_HIGH", weight = 5}, --Huge food with a high chance of wonder gummis and a chance for vitamins
            {id = "MEDICINE_LOW", weight = 2}, --Weaker medicine that can't heal all PP or HP at once
            {id = "MEDICINE_HIGH", weight = 5}, --Powerful medicine that can heal everything
            {id = "SEED_LOW", weight = 0},
            {id = "SEED_MID", weight = 0},
            {id = "SEED_HIGH", weight = 2}, --Includes rare seeds and berries, skews to Pure Seeds
            {id = "HELD_LOW", weight = 0},
            {id = "HELD_MID", weight = 2}, --Held items very useful for a specific strategy
            {id = "HELD_HIGH", weight = 5}, --Held items useful for anyone
            {id = "HELD_TYPE", weight = 0},
            {id = "HELD_PLATES", weight = 0},
            {id = "LOOT_LOW", weight = 2}, --Keys, pearls, assembly boxes
            {id = "LOOT_HIGH", weight = 5}, --Rare loot, skews towards heart scales
            {id = "EVO_ITEMS", weight = 5}, --Evolution items, high chance of link cables
            {id = "ORBS_LOW", weight = 0},
            {id = "ORBS_MID", weight = 2}, --Medium wonder orbs, many can shut down a monster house
            {id = "ORBS_HIGH", weight = 5}, --Rare, powerful wonder orbs often with map wide effects
            {id = "WANDS_LOW", weight = 0},
            {id = "WANDS_MID", weight = 0},
            {id = "WANDS_HIGH", weight = 3}, --Rare, specialty wands
            {id = "TM_LOW", weight = 0},
            {id = "TM_MID", weight = 4}, --TMs for moderate moves
            {id = "TM_HIGH", weight = 5}, --TMs for very powerful moves
            {id = "SPECIAL", weight = 1} --Very rare, powerful treasures (Amber Tears, Ability Capsules, Golden Apples, etc.)
        },
        STAR_2 = {
            {id = "NECESSITIES", weight = 0},
            {id = "AMMO_LOW", weight = 0},
            {id = "AMMO_MID", weight = 0},
            {id = "AMMO_HIGH", weight = 5}, --Rare ammo that are hard to find in dungeons
            {id = "APRICORN_GENERIC", weight = 0},
            {id = "APRICORN_TYPED", weight = 0},
            {id = "FOOD_LOW", weight = 0},
            {id = "FOOD_MID", weight = 0},
            {id = "FOOD_HIGH", weight = 5}, --Huge food with a high chance of wonder gummis and a chance for vitamins
            {id = "MEDICINE_LOW", weight = 0},
            {id = "MEDICINE_HIGH", weight = 5}, --Powerful medicine that can heal everything
            {id = "SEED_LOW", weight = 0},
            {id = "SEED_MID", weight = 0},
            {id = "SEED_HIGH", weight = 0},
            {id = "HELD_LOW", weight = 0},
            {id = "HELD_MID", weight = 0},
            {id = "HELD_HIGH", weight = 5}, --Held items useful for anyone
            {id = "HELD_TYPE", weight = 0},
            {id = "HELD_PLATES", weight = 0},
            {id = "LOOT_LOW", weight = 0},
            {id = "LOOT_HIGH", weight = 5}, --Rare loot, skews towards heart scales
            {id = "EVO_ITEMS", weight = 5}, --Evolution items, high chance of link cables
            {id = "ORBS_LOW", weight = 0},
            {id = "ORBS_MID", weight = 0},
            {id = "ORBS_HIGH", weight = 5}, --Rare, powerful wonder orbs often with map wide effects
            {id = "WANDS_LOW", weight = 0},
            {id = "WANDS_MID", weight = 0},
            {id = "WANDS_HIGH", weight = 0},
            {id = "TM_LOW", weight = 0},
            {id = "TM_MID", weight = 2}, --TMs for moderate moves
            {id = "TM_HIGH", weight = 5}, --TMs for very powerful moves
            {id = "SPECIAL", weight = 2} --Very rare, powerful treasures (Amber Tears, Ability Capsules, Golden Apples, etc.)
        },
        STAR_3 = {
            {id = "NECESSITIES", weight = 0},
            {id = "AMMO_LOW", weight = 0},
            {id = "AMMO_MID", weight = 0},
            {id = "AMMO_HIGH", weight = 5}, --Rare ammo that are hard to find in dungeons
            {id = "APRICORN_GENERIC", weight = 0},
            {id = "APRICORN_TYPED", weight = 0},
            {id = "FOOD_LOW", weight = 0},
            {id = "FOOD_MID", weight = 0},
            {id = "FOOD_HIGH", weight = 5}, --Huge food with a high chance of wonder gummis and a chance for vitamins
            {id = "MEDICINE_LOW", weight = 0},
            {id = "MEDICINE_HIGH", weight = 5}, --Powerful medicine that can heal everything
            {id = "SEED_LOW", weight = 0},
            {id = "SEED_MID", weight = 0},
            {id = "SEED_HIGH", weight = 0},
            {id = "HELD_LOW", weight = 0},
            {id = "HELD_MID", weight = 0},
            {id = "HELD_HIGH", weight = 5}, --Held items useful for anyone
            {id = "HELD_TYPE", weight = 0},
            {id = "HELD_PLATES", weight = 0},
            {id = "LOOT_LOW", weight = 0},
            {id = "LOOT_HIGH", weight = 5}, --Rare loot, skews towards heart scales
            {id = "EVO_ITEMS", weight = 5}, --Evolution items, high chance of link cables
            {id = "ORBS_LOW", weight = 0},
            {id = "ORBS_MID", weight = 0},
            {id = "ORBS_HIGH", weight = 0},
            {id = "WANDS_LOW", weight = 0},
            {id = "WANDS_MID", weight = 0},
            {id = "WANDS_HIGH", weight = 0},
            {id = "TM_LOW", weight = 0},
            {id = "TM_MID", weight = 0},
            {id = "TM_HIGH", weight = 5}, --TMs for very powerful moves
            {id = "SPECIAL", weight = 3} --Very rare, powerful treasures (Amber Tears, Ability Capsules, Golden Apples, etc.)
        },
        STAR_4 = {
            {id = "NECESSITIES", weight = 0},
            {id = "AMMO_LOW", weight = 0},
            {id = "AMMO_MID", weight = 0},
            {id = "AMMO_HIGH", weight = 0},
            {id = "APRICORN_GENERIC", weight = 0},
            {id = "APRICORN_TYPED", weight = 0},
            {id = "FOOD_LOW", weight = 0},
            {id = "FOOD_MID", weight = 0},
            {id = "FOOD_HIGH", weight = 5}, --Huge food with a high chance of wonder gummis and a chance for vitamins
            {id = "MEDICINE_LOW", weight = 0},
            {id = "MEDICINE_HIGH", weight = 0},
            {id = "SEED_LOW", weight = 0},
            {id = "SEED_MID", weight = 0},
            {id = "SEED_HIGH", weight = 0},
            {id = "HELD_LOW", weight = 0},
            {id = "HELD_MID", weight = 0},
            {id = "HELD_HIGH", weight = 5}, --Held items useful for anyone
            {id = "HELD_TYPE", weight = 0},
            {id = "HELD_PLATES", weight = 0},
            {id = "LOOT_LOW", weight = 0},
            {id = "LOOT_HIGH", weight = 5}, --Rare loot, skews towards heart scales
            {id = "EVO_ITEMS", weight = 5}, --Evolution items, high chance of link cables
            {id = "ORBS_LOW", weight = 0},
            {id = "ORBS_MID", weight = 0},
            {id = "ORBS_HIGH", weight = 0},
            {id = "WANDS_LOW", weight = 0},
            {id = "WANDS_MID", weight = 0},
            {id = "WANDS_HIGH", weight = 0},
            {id = "TM_LOW", weight = 0},
            {id = "TM_MID", weight = 0},
            {id = "TM_HIGH", weight = 5}, --TMs for very powerful moves
            {id = "SPECIAL", weight = 4} --Very rare, powerful treasures (Amber Tears, Ability Capsules, Golden Apples, etc.)
        },
        STAR_5 = {
            {id = "NECESSITIES", weight = 0},
            {id = "AMMO_LOW", weight = 0},
            {id = "AMMO_MID", weight = 0},
            {id = "AMMO_HIGH", weight = 0},
            {id = "APRICORN_GENERIC", weight = 0},
            {id = "APRICORN_TYPED", weight = 0},
            {id = "FOOD_LOW", weight = 0},
            {id = "FOOD_MID", weight = 0},
            {id = "FOOD_HIGH", weight = 5}, --Huge food with a high chance of wonder gummis and a chance for vitamins
            {id = "MEDICINE_LOW", weight = 0},
            {id = "MEDICINE_HIGH", weight = 0},
            {id = "SEED_LOW", weight = 0},
            {id = "SEED_MID", weight = 0},
            {id = "SEED_HIGH", weight = 0},
            {id = "HELD_LOW", weight = 0},
            {id = "HELD_MID", weight = 0},
            {id = "HELD_HIGH", weight = 0},
            {id = "HELD_TYPE", weight = 0},
            {id = "HELD_PLATES", weight = 0},
            {id = "LOOT_LOW", weight = 0},
            {id = "LOOT_HIGH", weight = 0},
            {id = "EVO_ITEMS", weight = 0},
            {id = "ORBS_LOW", weight = 0},
            {id = "ORBS_MID", weight = 0},
            {id = "ORBS_HIGH", weight = 0},
            {id = "WANDS_LOW", weight = 0},
            {id = "WANDS_MID", weight = 0},
            {id = "WANDS_HIGH", weight = 0},
            {id = "TM_LOW", weight = 0},
            {id = "TM_MID", weight = 0},
            {id = "TM_HIGH", weight = 5}, --TMs for very powerful moves
            {id = "SPECIAL", weight = 5} --Very rare, powerful treasures (Amber Tears, Ability Capsules, Golden Apples, etc.)
        },
        STAR_6 = {
            {id = "NECESSITIES", weight = 0},
            {id = "AMMO_LOW", weight = 0},
            {id = "AMMO_MID", weight = 0},
            {id = "AMMO_HIGH", weight = 0},
            {id = "APRICORN_GENERIC", weight = 0},
            {id = "APRICORN_TYPED", weight = 0},
            {id = "FOOD_LOW", weight = 0},
            {id = "FOOD_MID", weight = 0},
            {id = "FOOD_HIGH", weight = 4}, --Huge food with a high chance of wonder gummis and a chance for vitamins
            {id = "MEDICINE_LOW", weight = 0},
            {id = "MEDICINE_HIGH", weight = 0},
            {id = "SEED_LOW", weight = 0},
            {id = "SEED_MID", weight = 0},
            {id = "SEED_HIGH", weight = 0},
            {id = "HELD_LOW", weight = 0},
            {id = "HELD_MID", weight = 0},
            {id = "HELD_HIGH", weight = 0},
            {id = "HELD_TYPE", weight = 0},
            {id = "HELD_PLATES", weight = 0},
            {id = "LOOT_LOW", weight = 0},
            {id = "LOOT_HIGH", weight = 0},
            {id = "EVO_ITEMS", weight = 0},
            {id = "ORBS_LOW", weight = 0},
            {id = "ORBS_MID", weight = 0},
            {id = "ORBS_HIGH", weight = 0},
            {id = "WANDS_LOW", weight = 0},
            {id = "WANDS_MID", weight = 0},
            {id = "WANDS_HIGH", weight = 0},
            {id = "TM_LOW", weight = 0},
            {id = "TM_MID", weight = 0},
            {id = "TM_HIGH", weight = 4}, --TMs for very powerful moves
            {id = "SPECIAL", weight = 6} --Very rare, powerful treasures (Amber Tears, Ability Capsules, Golden Apples, etc.)
        },
        STAR_7 = {
            {id = "NECESSITIES", weight = 0},
            {id = "AMMO_LOW", weight = 0},
            {id = "AMMO_MID", weight = 0},
            {id = "AMMO_HIGH", weight = 0},
            {id = "APRICORN_GENERIC", weight = 0},
            {id = "APRICORN_TYPED", weight = 0},
            {id = "FOOD_LOW", weight = 0},
            {id = "FOOD_MID", weight = 0},
            {id = "FOOD_HIGH", weight = 3}, --Huge food with a high chance of wonder gummis and a chance for vitamins
            {id = "MEDICINE_LOW", weight = 0},
            {id = "MEDICINE_HIGH", weight = 0},
            {id = "SEED_LOW", weight = 0},
            {id = "SEED_MID", weight = 0},
            {id = "SEED_HIGH", weight = 0},
            {id = "HELD_LOW", weight = 0},
            {id = "HELD_MID", weight = 0},
            {id = "HELD_HIGH", weight = 0},
            {id = "HELD_TYPE", weight = 0},
            {id = "HELD_PLATES", weight = 0},
            {id = "LOOT_LOW", weight = 0},
            {id = "LOOT_HIGH", weight = 0},
            {id = "EVO_ITEMS", weight = 0},
            {id = "ORBS_LOW", weight = 0},
            {id = "ORBS_MID", weight = 0},
            {id = "ORBS_HIGH", weight = 0},
            {id = "WANDS_LOW", weight = 0},
            {id = "WANDS_MID", weight = 0},
            {id = "WANDS_HIGH", weight = 0},
            {id = "TM_LOW", weight = 0},
            {id = "TM_MID", weight = 0},
            {id = "TM_HIGH", weight = 3}, --TMs for very powerful moves
            {id = "SPECIAL", weight = 7} --Very rare, powerful treasures (Amber Tears, Ability Capsules, Golden Apples, etc.)
        },
        STAR_8 = {
            {id = "NECESSITIES", weight = 0},
            {id = "AMMO_LOW", weight = 0},
            {id = "AMMO_MID", weight = 0},
            {id = "AMMO_HIGH", weight = 0},
            {id = "APRICORN_GENERIC", weight = 0},
            {id = "APRICORN_TYPED", weight = 0},
            {id = "FOOD_LOW", weight = 0},
            {id = "FOOD_MID", weight = 0},
            {id = "FOOD_HIGH", weight = 0},
            {id = "MEDICINE_LOW", weight = 0},
            {id = "MEDICINE_HIGH", weight = 0},
            {id = "SEED_LOW", weight = 0},
            {id = "SEED_MID", weight = 0},
            {id = "SEED_HIGH", weight = 0},
            {id = "HELD_LOW", weight = 0},
            {id = "HELD_MID", weight = 0},
            {id = "HELD_HIGH", weight = 0},
            {id = "HELD_TYPE", weight = 0},
            {id = "HELD_PLATES", weight = 0},
            {id = "LOOT_LOW", weight = 0},
            {id = "LOOT_HIGH", weight = 0},
            {id = "EVO_ITEMS", weight = 0},
            {id = "ORBS_LOW", weight = 0},
            {id = "ORBS_MID", weight = 0},
            {id = "ORBS_HIGH", weight = 0},
            {id = "WANDS_LOW", weight = 0},
            {id = "WANDS_MID", weight = 0},
            {id = "WANDS_HIGH", weight = 0},
            {id = "TM_LOW", weight = 0},
            {id = "TM_MID", weight = 0},
            {id = "TM_HIGH", weight = 3}, --TMs for very powerful moves
            {id = "SPECIAL", weight = 8} --Very rare, powerful treasures (Amber Tears, Ability Capsules, Golden Apples, etc.)
        },
        STAR_9 = {
            {id = "NECESSITIES", weight = 0},
            {id = "AMMO_LOW", weight = 0},
            {id = "AMMO_MID", weight = 0},
            {id = "AMMO_HIGH", weight = 0},
            {id = "APRICORN_GENERIC", weight = 0},
            {id = "APRICORN_TYPED", weight = 0},
            {id = "FOOD_LOW", weight = 0},
            {id = "FOOD_MID", weight = 0},
            {id = "FOOD_HIGH", weight = 0},
            {id = "MEDICINE_LOW", weight = 0},
            {id = "MEDICINE_HIGH", weight = 0},
            {id = "SEED_LOW", weight = 0},
            {id = "SEED_MID", weight = 0},
            {id = "SEED_HIGH", weight = 0},
            {id = "HELD_LOW", weight = 0},
            {id = "HELD_MID", weight = 0},
            {id = "HELD_HIGH", weight = 0},
            {id = "HELD_TYPE", weight = 0},
            {id = "HELD_PLATES", weight = 0},
            {id = "LOOT_LOW", weight = 0},
            {id = "LOOT_HIGH", weight = 0},
            {id = "EVO_ITEMS", weight = 0},
            {id = "ORBS_LOW", weight = 0},
            {id = "ORBS_MID", weight = 0},
            {id = "ORBS_HIGH", weight = 0},
            {id = "WANDS_LOW", weight = 0},
            {id = "WANDS_MID", weight = 0},
            {id = "WANDS_HIGH", weight = 0},
            {id = "TM_LOW", weight = 0},
            {id = "TM_MID", weight = 0},
            {id = "TM_HIGH", weight = 0},
            {id = "SPECIAL", weight = 9} --Very rare, powerful treasures (Amber Tears, Ability Capsules, Golden Apples, etc.)
        }
    },
    --- List of all reward pools. You must at least include all pools referenced in the rewards_per_difficulty table, but you can add more.
    --- Pools are a list of items and other pools.
    --- Every item must be specified using this format: {id, count, hidden, weight}
    --- count and hidden are optional. If omitted, count will be the item's max stack.
    --- If the id of a reward matches a pool, count and hidden will be ignored.
    reward_pools = {
        NECESSITIES = {
            {id = "seed_reviver", weight = 10},
            {id = "berry_leppa", weight = 5},
            {id = "berry_oran", weight = 5},
            {id = "berry_lum", weight = 5},
            {id = "food_apple", weight = 5},
            {id = "orb_escape", weight = 5},
            {id = "apricorn_plain", weight = 5},
            {id = "key", weight = 2}
        },

        AMMO_LOW = {
            {id = "ammo_iron_thorn", weight = 5},
            {id = "ammo_geo_pebble", weight = 1},
            {id = "ammo_stick", weight = 1},
        },

        AMMO_MID = {
            {id = "ammo_geo_pebble", weight = 5},
            {id = "ammo_gravelerock", weight = 5},
            {id = "ammo_stick", weight = 5},
            {id = "ammo_silver_spike", weight = 5}
        },

        AMMO_HIGH = {
            {id = "ammo_rare_fossil", weight = 5},
            {id = "ammo_corsola_twig", weight = 5},
            {id = "ammo_cacnea_spike", weight = 5}
        },

        APRICORN_GENERIC = {
            {id = "apricorn_plain", weight = 12},
            {id = "apricorn_big", weight = 4}
        },

        APRICORN_TYPED = {
            {id = "apricorn_blue", weight = 5},
            {id = "apricorn_green", weight = 5},
            {id = "apricorn_brown", weight = 5},
            {id = "apricorn_purple", weight = 5},
            {id = "apricorn_red", weight = 5},
            {id = "apricorn_white", weight = 5},
            {id = "apricorn_yellow", weight = 5},
            {id = "apricorn_black", weight = 5},
            {id = "apricorn_glittery", weight = 5}
        },
        --Rare chance for gummis
        FOOD_LOW = {
            {id = "food_apple", weight = 30},
            {id = "food_banana", weight = 18},
            {id = "gummi_blue", weight = 1},
            {id = "gummi_black", weight = 1},
            {id = "gummi_clear", weight = 1},
            {id = "gummi_grass", weight = 1},
            {id = "gummi_green", weight = 1},
            {id = "gummi_brown", weight = 1},
            {id = "gummi_orange", weight = 1},
            {id = "gummi_gold", weight = 1},
            {id = "gummi_pink", weight = 1},
            {id = "gummi_purple", weight = 1},
            {id = "gummi_red", weight = 1},
            {id = "gummi_royal", weight = 1},
            {id = "gummi_silver", weight = 1},
            {id = "gummi_white", weight = 1},
            {id = "gummi_yellow", weight = 1},
            {id = "gummi_sky", weight = 1},
            {id = "gummi_gray", weight = 1},
            {id = "gummi_magenta", weight = 1}
        },
        --Moderate chance of gummis, rare chance of wonder gummis
        FOOD_MID = {
            {id = "food_apple_big", weight = 30},
            {id = "food_banana_big", weight = 18},
            {id = "gummi_blue", weight = 2},
            {id = "gummi_black", weight = 2},
            {id = "gummi_clear", weight = 2},
            {id = "gummi_grass", weight = 2},
            {id = "gummi_green", weight = 2},
            {id = "gummi_brown", weight = 2},
            {id = "gummi_orange", weight = 2},
            {id = "gummi_gold", weight = 2},
            {id = "gummi_pink", weight = 2},
            {id = "gummi_purple", weight = 2},
            {id = "gummi_red", weight = 2},
            {id = "gummi_royal", weight = 2},
            {id = "gummi_silver", weight = 2},
            {id = "gummi_white", weight = 2},
            {id = "gummi_yellow", weight = 2},
            {id = "gummi_sky", weight = 2},
            {id = "gummi_gray", weight = 2},
            {id = "gummi_magenta", weight = 2},
            {id = "gummi_wonder", weight = 1}
        },
        --Small chance for vitamins
        FOOD_HIGH = {
            {id = "food_apple_huge", weight = 30},
            {id = "food_apple_perfect", weight = 18},
            {id = "food_banana_big", weight = 18},
            {id = "gummi_wonder", weight = 30},
            {id = "boost_calcium", weight = 3},
            {id = "boost_protein", weight = 3},
            {id = "boost_hp_up", weight = 3},
            {id = "boost_zinc", weight = 3},
            {id = "boost_carbos", weight = 3},
            {id = "boost_iron", weight = 3},
            {id = "boost_nectar", weight = 5}
        },

        --Basic manufactured medicine
        MEDICINE_LOW = {
            {id = "medicine_potion", weight = 20},
            {id = "medicine_elixir", weight = 20},
            {id = "medicine_full_heal", weight = 10},
            {id = "medicine_x_attack", weight = 10},
            {id = "medicine_x_defense", weight = 10},
            {id = "medicine_x_sp_atk", weight = 10},
            {id = "medicine_x_sp_def", weight = 10},
            {id = "medicine_x_speed", weight = 10},
            {id = "medicine_x_accuracy", weight = 10},
            {id = "medicine_dire_hit", weight = 10}
        },

        --Advanced manufactued medicine
        MEDICINE_HIGH = {
            {id = "medicine_max_potion", weight = 20},
            {id = "medicine_max_elixir", weight = 20},
            {id = "medicine_full_heal", weight = 10}
        },

        --includes seeds and berries, as well as white herbs
        SEED_LOW = {
            {id = "seed_blast", weight = 5},
            {id = "seed_sleep", weight = 5},
            {id = "seed_warp", weight = 5},
            {id = "berry_oran", weight = 5},
            {id = "berry_leppa", weight = 5},
            {id = "berry_sitrus", weight = 5},
            {id = "berry_lum", weight = 5},
            {id = "herb_white", weight = 10}
        },
        --Includes advanced seeds, herbs, and type berries
        SEED_MID = {
            {id = "seed_reviver", weight = 25},
            {id = "seed_decoy", weight = 5},
            {id = "seed_blinker", weight = 5},
            {id = "seed_last_chance", weight = 5},
            {id = "seed_doom", weight = 5},
            {id = "seed_ban", weight = 5},
            {id = "seed_ice", weight = 5},
            {id = "seed_vile", weight = 5},
            {id = "berry_tanga", weight = 2},
            {id = "berry_colbur", weight = 2},
            {id = "berry_wacan", weight = 2},
            {id = "berry_haban", weight = 2},
            {id = "berry_chople", weight = 2},
            {id = "berry_occa", weight = 2},
            {id = "berry_coba", weight = 2},
            {id = "berry_kasib", weight = 2},
            {id = "berry_rindo", weight = 2},
            {id = "berry_shuca", weight = 2},
            {id = "berry_yache", weight = 2},
            {id = "berry_chilan", weight = 2},
            {id = "berry_kebia", weight = 2},
            {id = "berry_payapa", weight = 2},
            {id = "berry_charti", weight = 2},
            {id = "berry_babiri", weight = 2},
            {id = "berry_passho", weight = 2},
            {id = "berry_roseli", weight = 2},
            {id = "herb_power", weight = 10},
            {id = "herb_mental", weight = 10}
        },

        --includes rare seeds and berries
        SEED_HIGH = {
            {id = "seed_pure", weight = 15},
            {id = "seed_joy", weight = 1},
            {id = "berry_rowap", weight = 5},
            {id = "berry_jaboca", weight = 5},
            {id = "berry_liechi", weight = 5},
            {id = "berry_ganlon", weight = 5},
            {id = "berry_salac", weight = 5},
            {id = "berry_petaya", weight = 5},
            {id = "berry_apicot", weight = 5},
            {id = "berry_micle", weight = 5},
            {id = "berry_enigma", weight = 5},
            {id = "berry_starf", weight = 5}
        },

        HELD_LOW = {
            {id = "held_power_band", weight = 5},
            {id = "held_special_band", weight = 5},
            {id = "held_defense_scarf", weight = 5},
            {id = "held_zinc_band", weight = 5},
            {id = "held_toxic_orb", weight = 5},
            {id = "held_flame_orb", weight = 5},
            {id = "held_iron_ball", weight = 5},
            {id = "held_ring_target", weight = 5}
        },

        HELD_MID = {
            {id = "held_pierce_band", weight = 5},
            {id = "held_warp_scarf", weight = 5},
            {id = "held_scope_lens", weight = 5},
            {id = "held_reunion_cape", weight = 5},
            {id = "held_heal_ribbon", weight = 5},
            {id = "held_twist_band", weight = 5},
            {id = "held_grip_claw", weight = 5},
            {id = "held_binding_band", weight = 5},
            {id = "held_metronome", weight = 5},
            {id = "held_shed_shell", weight = 5},
            {id = "held_wide_lens", weight = 5},
            {id = "held_sticky_barb", weight = 5},
            {id = "held_choice_band", weight = 5},
            {id = "held_choice_scarf", weight = 5},
            {id = "held_choice_specs", weight = 5}
        },

        HELD_HIGH = {
            {id = "held_golden_mask", weight = 5},
            {id = "held_friend_bow", weight = 2},
            {id = "held_shell_bell", weight = 5},
            {id = "held_mobile_scarf", weight = 5},
            {id = "held_cover_band", weight = 5},
            {id = "held_pass_scarf", weight = 5},
            {id = "held_trap_scarf", weight = 5},
            {id = "held_pierce_band", weight = 5},
            {id = "held_goggle_specs", weight = 5},
            {id = "held_x_ray_specs", weight = 5},
            {id = "held_assault_vest", weight = 5},
            {id = "held_life_orb", weight = 5}
        },

        HELD_TYPE = {
            {id = "held_silver_powder", weight = 5},
            {id = "held_black_glasses", weight = 5},
            {id = "held_dragon_scale", weight = 5},
            {id = "held_magnet", weight = 5},
            {id = "held_pink_bow", weight = 5},
            {id = "held_black_belt", weight = 5},
            {id = "held_charcoal", weight = 5},
            {id = "held_sharp_beak", weight = 5},
            {id = "held_spell_tag", weight = 5},
            {id = "held_miracle_seed", weight = 5},
            {id = "held_soft_sand", weight = 5},
            {id = "held_never_melt_ice", weight = 5},
            {id = "held_silk_scarf", weight = 5},
            {id = "held_poison_barb", weight = 5},
            {id = "held_twisted_spoon", weight = 5},
            {id = "held_hard_stone", weight = 5},
            {id = "held_metal_coat", weight = 5},
            {id = "held_mystic_water", weight = 5}
        },

        HELD_PLATES = {
            {id = "held_insect_plate", weight = 5},
            {id = "held_dread_plate", weight = 5},
            {id = "held_draco_plate", weight = 5},
            {id = "held_zap_plate", weight = 5},
            {id = "held_pixie_plate", weight = 5},
            {id = "held_fist_plate", weight = 5},
            {id = "held_flame_plate", weight = 5},
            {id = "held_sky_plate", weight = 5},
            {id = "held_spooky_plate", weight = 5},
            {id = "held_meadow_plate", weight = 5},
            {id = "held_earth_plate", weight = 5},
            {id = "held_icicle_plate", weight = 5},
            {id = "held_blank_plate", weight = 5},
            {id = "held_toxic_plate", weight = 5},
            {id = "held_mind_plate", weight = 5},
            {id = "held_stone_plate", weight = 5},
            {id = "held_iron_plate", weight = 5},
            {id = "held_splash_plate", weight = 5}
        },

        --Spawns boxes, keys, heart scales, and loot
        LOOT_LOW = {
            {id = "loot_heart_scale", weight = 5},
            {id = "loot_pearl", weight = 10},
            {id = "machine_assembly_box", weight = 10},
            {id = "key", weight = 10}
        },

        LOOT_HIGH = {
            {id = "loot_heart_scale", weight = 20},
            {id = "loot_nugget", weight = 5},
            {id = "machine_recall_box", weight = 10},
            {id = "machine_storage_box", weight = 10}
        },

        EVO_ITEMS = {
            {id = "evo_link_cable", weight = 30},
            {id = "evo_fire_stone", weight = 5},
            {id = "evo_thunder_stone", weight = 5},
            {id = "evo_water_stone", weight = 5},
            {id = "evo_leaf_stone", weight = 5},
            {id = "evo_moon_stone", weight = 5},
            {id = "evo_sun_stone", weight = 5},
            {id = "evo_magmarizer", weight = 5},
            {id = "evo_electirizer", weight = 5},
            {id = "evo_reaper_cloth", weight = 5},
            {id = "evo_cracked_pot", weight = 5},
            {id = "evo_chipped_pot", weight = 5},
            {id = "evo_shiny_stone", weight = 5},
            {id = "evo_dusk_stone", weight = 5},
            {id = "evo_dawn_stone", weight = 5},
            {id = "evo_up_grade", weight = 5},
            {id = "evo_dubious_disc", weight = 5},
            {id = "evo_razor_fang", weight = 5},
            {id = "evo_razor_claw", weight = 5},
            {id = "evo_protector", weight = 5},
            {id = "evo_prism_scale", weight = 5},
            {id = "evo_kings_rock", weight = 5},
            {id = "evo_sun_ribbon", weight = 5},
            {id = "evo_lunar_ribbon", weight = 5},
            {id = "evo_ice_stone", weight = 5}
        },

        ORBS_LOW = {
            {id = "orb_escape", weight = 5},
            {id = "orb_weather", weight = 5},
            {id = "orb_cleanse", weight = 5},
            {id = "orb_endure", weight = 5},
            {id = "orb_trapbust", weight = 5},
            {id = "orb_petrify", weight = 5},
            {id = "orb_foe_hold", weight = 5},
            {id = "orb_nullify", weight = 5},
            {id = "orb_all_dodge", weight = 5},
            {id = "orb_rebound", weight = 5},
            {id = "orb_mirror", weight = 5},
            {id = "orb_foe_seal", weight = 5},
            {id = "orb_rollcall", weight = 5},
            {id = "orb_mug", weight = 5},
        },

        ORBS_MID = {
            {id = "orb_escape", weight = 5},
            {id = "orb_mobile", weight = 5},
            {id = "orb_invisify", weight = 5},
            {id = "orb_all_aim", weight = 5},
            {id = "orb_trawl", weight = 5},
            {id = "orb_one_shot", weight = 5},
            {id = "orb_pierce", weight = 5},
            {id = "orb_all_protect", weight = 5},
            {id = "orb_trap_see", weight = 5},
            {id = "orb_slumber", weight = 5},
            {id = "orb_totter", weight = 5},
            {id = "orb_freeze", weight = 5},
            {id = "orb_spurn", weight = 5},
            {id = "orb_itemizer", weight = 5},
            {id = "orb_halving", weight = 5},
        },

        ORBS_HIGH = {
            {id = "orb_escape", weight = 5},
            {id = "orb_luminous", weight = 5},
            {id = "orb_invert", weight = 5},
            {id = "orb_devolve", weight = 5},
            {id = "orb_revival", weight = 5},
            {id = "orb_scanner", weight = 5},
            {id = "orb_stayaway", weight = 5},
            {id = "orb_one_room", weight = 5},
        },

        WANDS_LOW = {
            {id = "wand_pounce", weight = 5},
            {id = "wand_slow", weight = 5},
            {id = "wand_topsy_turvy", weight = 5},
            {id = "wand_purge", weight = 5}
        },

        WANDS_MID = {
            {id = "wand_path", weight = 5},
            {id = "wand_whirlwind", weight = 5},
            {id = "wand_switcher", weight = 5},
            {id = "wand_fear", weight = 5},
            {id = "wand_warp", weight = 5},
            {id = "wand_lob", weight = 5}
        },

        WANDS_HIGH = {
            {id = "wand_lure", weight = 5},
            {id = "wand_stayaway", weight = 5},
            {id = "wand_transfer", weight = 5},
            {id = "wand_vanish", weight = 5}
        },

        TM_LOW = {
            {id = "tm_snatch", weight = 5},
            {id = "tm_sunny_day", weight = 5},
            {id = "tm_rain_dance", weight = 5},
            {id = "tm_sandstorm", weight = 5},
            {id = "tm_hail", weight = 5},
            {id = "tm_taunt", weight = 5},

            {id = "tm_safeguard", weight = 5},
            {id = "tm_light_screen", weight = 5},
            {id = "tm_dream_eater", weight = 5},
            {id = "tm_nature_power", weight = 5},
            {id = "tm_swagger", weight = 5},
            {id = "tm_captivate", weight = 5},
            {id = "tm_fling", weight = 5},
            {id = "tm_payback", weight = 5},
            {id = "tm_reflect", weight = 5},
            {id = "tm_rock_polish", weight = 5},
            {id = "tm_pluck", weight = 5},
            {id = "tm_psych_up", weight = 5},
            {id = "tm_secret_power", weight = 5},

            {id = "tm_return", weight = 5},
            {id = "tm_frustration", weight = 5},
            {id = "tm_torment", weight = 5},
            {id = "tm_endure", weight = 5},
            {id = "tm_echoed_voice", weight = 5},
            {id = "tm_gyro_ball", weight = 5},
            {id = "tm_recycle", weight = 5},
            {id = "tm_false_swipe", weight = 5},
            {id = "tm_defog", weight = 5},
            {id = "tm_telekinesis", weight = 5},
            {id = "tm_double_team", weight = 5},
            {id = "tm_thunder_wave", weight = 5},
            {id = "tm_attract", weight = 5},
            {id = "tm_smack_down", weight = 5},
            {id = "tm_snarl", weight = 5},
            {id = "tm_flame_charge", weight = 5},

            {id = "tm_protect", weight = 5},
            {id = "tm_round", weight = 5},
            {id = "tm_rest", weight = 5},
            {id = "tm_thief", weight = 5},
            {id = "tm_cut", weight = 5},
            {id = "tm_whirlpool", weight = 5},
            {id = "tm_infestation", weight = 5},
            {id = "tm_roar", weight = 5},
            {id = "tm_flash", weight = 5},
            {id = "tm_embargo", weight = 5},
            {id = "tm_struggle_bug", weight = 5},
            {id = "tm_quash", weight = 5}},

        TM_MID = {
            {id = "tm_explosion", weight = 5},
            {id = "tm_will_o_wisp", weight = 5},
            {id = "tm_facade", weight = 5},
            {id = "tm_water_pulse", weight = 5},
            {id = "tm_shock_wave", weight = 5},
            {id = "tm_brick_break", weight = 5},
            {id = "tm_calm_mind", weight = 5},
            {id = "tm_charge_beam", weight = 5},
            {id = "tm_retaliate", weight = 5},
            {id = "tm_roost", weight = 5},
            {id = "tm_acrobatics", weight = 5},
            {id = "tm_bulk_up", weight = 5},


            {id = "tm_shadow_claw", weight = 5},

            {id = "tm_steel_wing", weight = 5},
            {id = "tm_snarl", weight = 5},
            {id = "tm_bulldoze", weight = 5},
            {id = "tm_substitute", weight = 5},
            {id = "tm_brine", weight = 5},
            {id = "tm_venoshock", weight = 5},
            {id = "tm_u_turn", weight = 5},
            {id = "tm_aerial_ace", weight = 5},
            {id = "tm_hone_claws", weight = 5},
            {id = "tm_rock_smash", weight = 5},

            {id = "tm_hidden_power", weight = 5},
            {id = "tm_rock_tomb", weight = 5},
            {id = "tm_strength", weight = 5},
            {id = "tm_grass_knot", weight = 5},
            {id = "tm_power_up_punch", weight = 5},
            {id = "tm_work_up", weight = 5},
            {id = "tm_incinerate", weight = 5},
            {id = "tm_bullet_seed", weight = 5},
            {id = "tm_low_sweep", weight = 5},
            {id = "tm_volt_switch", weight = 5},
            {id = "tm_avalanche", weight = 5},
            {id = "tm_dragon_tail", weight = 5},
            {id = "tm_silver_wind", weight = 5},
            {id = "tm_frost_breath", weight = 5},
            {id = "tm_sky_drop", weight = 5}
        },

        TM_HIGH = {
            {id = "tm_earthquake", weight = 5},
            {id = "tm_hyper_beam", weight = 5},
            {id = "tm_overheat", weight = 5},
            {id = "tm_blizzard", weight = 5},
            {id = "tm_swords_dance", weight = 5},
            {id = "tm_surf", weight = 5},
            {id = "tm_dark_pulse", weight = 5},
            {id = "tm_psychic", weight = 5},
            {id = "tm_thunder", weight = 5},
            {id = "tm_shadow_ball", weight = 5},
            {id = "tm_ice_beam", weight = 5},
            {id = "tm_giga_impact", weight = 5},
            {id = "tm_fire_blast", weight = 5},
            {id = "tm_dazzling_gleam", weight = 5},
            {id = "tm_flash_cannon", weight = 5},
            {id = "tm_stone_edge", weight = 5},
            {id = "tm_sludge_bomb", weight = 5},
            {id = "tm_focus_blast", weight = 5},

            {id = "tm_x_scissor", weight = 5},
            {id = "tm_wild_charge", weight = 5},
            {id = "tm_focus_punch", weight = 5},
            {id = "tm_psyshock", weight = 5},
            {id = "tm_rock_slide", weight = 5},
            {id = "tm_thunderbolt", weight = 5},
            {id = "tm_flamethrower", weight = 5},
            {id = "tm_energy_ball", weight = 5},
            {id = "tm_scald", weight = 5},
            {id = "tm_waterfall", weight = 5},
            {id = "tm_rock_climb", weight = 5},

            {id = "tm_giga_drain", weight = 5},
            {id = "tm_dive", weight = 5},
            {id = "tm_poison_jab", weight = 5},

            {id = "tm_iron_tail", weight = 5},

            {id = "tm_dig", weight = 5},
            {id = "tm_fly", weight = 5},
            {id = "tm_dragon_claw", weight = 5},
            {id = "tm_dragon_pulse", weight = 5},
            {id = "tm_sludge_wave", weight = 5},
            {id = "tm_drain_punch", weight = 5}},

        --special and unique rewards, very rare
        SPECIAL = {
            {id = "medicine_amber_tear", weight = 1},
            {id = "machine_ability_capsule", weight = 1},
            {id = "ammo_golden_thorn", weight = 1},
            {id = "food_apple_golden", weight = 1},
            {id = "seed_golden", weight = 1},
            {id = "evo_harmony_scarf", weight = 1},
            {id = "apricorn_perfect", weight = 1}
        }
    },
    --- This is where dungeon difficulty is set. Quests can only generate for dungeons inside this list.
    --- Given the complexity of this structure, it is best generated using the "AddDungeonSection" function at the bottom of this file.
    dungeons = {},
    --- Jobs are sorted by dungeon, following this order. Missing dungeons are shoved at the bottom and sorted alphabetically.
    --- This list is automatically populated if dungeons are added via the "AddDungeonSection" function.
    dungeon_order = {},
    --- Use this table to determine various property regarding quest types.
    --- Remove a quest type entirely to disable its generation altogether.
    --- Format: quest_id = {rank_modifier = number, min_rank = string, min_level = int}
    --- rank_modifier: these jobs will always have this modifier applied to their rank.
    --- min_level (optional): these jobs only appear if the dungeon's level cap is equal to or higher than this.
    --- min_rank (optional): this type of jobs can never be of a rank lower than this.
    --- This influences possible dungeon spawn: a rank_modifier 1 job with min_rank "C" can also spawn in "D" rank dungeons.
    --- Supported quest types are: RESCUE_SELF, RESCUE_FRIEND, ESCORT, EXPLORATION, DELIVERY, LOST_ITEM, OUTLAW, OUTLAW_ITEM, OUTLAW_MONSTER_HOUSE, OUTLAW_FLEE
    quest_types = {
        RESCUE_SELF = {rank_modifier = 0, min_rank = "F"},
        RESCUE_FRIEND = {rank_modifier = 0, min_rank = "E"},
        ESCORT = {rank_modifier = 1, min_rank = "C"},
        EXPLORATION = {rank_modifier = 1, min_rank = "C"},
        DELIVERY = {rank_modifier = 0, min_rank = "D"},
        LOST_ITEM = {rank_modifier = 0, min_rank = "D"},
        OUTLAW = {rank_modifier = 1, min_rank = "C"},
        OUTLAW_ITEM = {rank_modifier = 1, min_rank = "C"},
        OUTLAW_MONSTER_HOUSE = {rank_modifier = 2, min_rank = "S"},
        OUTLAW_FLEE = {rank_modifier = 1, min_rank = "B"}
    },
    --- A list of board ids and their respective data
    --- Format: board_id = {size = number, quest_types = {{id = string, weight = number}}}
    boards = {
        quest_board = {
            size = 8,
            quest_types = {
                {id = "RESCUE_SELF", weight = 10},
                {id = "RESCUE_FRIEND", weight = 10},
                {id = "ESCORT", weight = 10},
                {id = "EXPLORATION", weight = 10},
                {id = "DELIVERY", weight = 10},
                {id = "LOST_ITEM", weight = 10},
                {id = "OUTLAW", weight = 10},
                {id = "OUTLAW_ITEM", weight = 10},
                {id = "OUTLAW_MONSTER_HOUSE", weight = 10},
                {id = "OUTLAW_FLEE", weight = 10}
            }
        }
    },
    --- The maximum amount of guest-based jobs that can be generated in the same dungeon.
    --- Guest-based jobs are: ESCORT, EXPLORATION
    max_guests = 1
    --TODO add flavor text, titles and species
}

--- Adds a new dungeon section to the list of possible job destinations.
--- Section start values should always be added in ascending order.
--- @param zone string the string id of the dungeon zone
--- @param segment number the numeric id of the dungeon segment
--- @param start number the starting floor of this dungeon section (start counting from 1 for this)
--- @param difficulty string the string id of the difficulty assigned to this section
--- @param finish number Only considered when first adding a segment to the list. This will be the last floor of the segment where jobs can spawn. If higher than the dungeon floors, it will default to the full dungeon length
--- @param must_end boolean Only considered when first adding a dungeon to the list. If true, this dungeon must be completed before jobs can spawn in it
function AddDungeonSection(zone, segment, start, difficulty, finish, must_end)
    if settings.dungeons[zone] == nil then table.insert(settings.dungeon_order, zone) end
    settings.dungeons[zone] = settings.dungeons[zone] or {must_end = must_end}
    settings.dungeons[zone][segment] = settings.dungeons[zone][segment] or {max_floor = finish-1}
    table.insert(settings.dungeons[zone][segment], {start = start-1, difficulty = difficulty})
end

AddDungeonSection("tropical_path", 0, 3, "F", 4, true)
AddDungeonSection("faultline_ridge", 0, 4, "D", 10, true)
AddDungeonSection("guildmaster_trail", 0, 11, "STAR_2", 30, false)
AddDungeonSection("guildmaster_trail", 0, 15, "STAR_3", 30, false)
AddDungeonSection("guildmaster_trail", 0, 20, "STAR_4")
AddDungeonSection("guildmaster_trail", 0, 25, "STAR_5")
AddDungeonSection("lava_floe_island", 0, 8,"C", 16, true)
AddDungeonSection("lava_floe_island", 1, 1,"STAR_1", 9)
AddDungeonSection("castaway_cave", 0, 6, "B", 12, true)
AddDungeonSection("faded_trail", 0, 4, "E", 7, true)
AddDungeonSection("faded_trail", 1, 1, "D", 3)
AddDungeonSection("bramble_woods", 0, 4, "E", 7, true)
AddDungeonSection("bramble_woods", 1, 1, "D", 3)
AddDungeonSection("trickster_woods", 0, 5, "C", 10, true)
AddDungeonSection("trickster_woods", 1, 1, "B", 4)
AddDungeonSection("overgrown_wilds", 0, 6, "C", 12, true)
AddDungeonSection("overgrown_wilds", 1, 1, "B", 4)
AddDungeonSection("moonlit_courtyard", 0, 7, "C", 14, true)
AddDungeonSection("moonlit_courtyard", 0, 11, "B")
AddDungeonSection("moonlit_courtyard", 1, 1, "A", 6)
AddDungeonSection("ambush_forest", 0, 10, "B", 20, true)
AddDungeonSection("ambush_forest", 0, 15, "A")
AddDungeonSection("sickly_hollow", 0, 8, "S", 16, false)
AddDungeonSection("sickly_hollow", 0, 13, "STAR_1")
AddDungeonSection("secret_garden", 0, 14, "STAR_3", 40, false)
AddDungeonSection("secret_garden", 0, 19, "STAR_4")
AddDungeonSection("secret_garden", 0, 24, "STAR_5")
AddDungeonSection("secret_garden", 0, 29, "STAR_6")
AddDungeonSection("secret_garden", 0, 32, "STAR_7")
AddDungeonSection("secret_garden", 0, 35, "STAR_8")
AddDungeonSection("secret_garden", 0, 38, "STAR_9")
AddDungeonSection("flyaway_cliffs", 0, 5, "C", 10, true)
AddDungeonSection("fertile_valley", 0, 4, "D", 8, true)
AddDungeonSection("fertile_valley", 1, 1, "C", 5)
AddDungeonSection("copper_quarry", 0, 5, "C", 11, true)
AddDungeonSection("copper_quarry", 0, 1, "B", 4)
AddDungeonSection("depleted_basin", 0, 5, "C", 9, true)
AddDungeonSection("forsaken_desert", 0, 2, "A", 4, true)
AddDungeonSection("relic_tower", 0, 6, "S", 13, true)
AddDungeonSection("relic_tower", 0, 10, "STAR1")
AddDungeonSection("sleeping_caldera", 0, 6, "B", 18, true)
AddDungeonSection("sleeping_caldera", 0, 14, "A")
AddDungeonSection("thunderstruck_pass", 0, 7, "B", 14, true)
AddDungeonSection("veiled_ridge", 0, 8, "B", 16, true)
AddDungeonSection("veiled_ridge", 1, 1, "A", 6)
AddDungeonSection("snowbound_path", 0, 9, "B", 18, true)
AddDungeonSection("snowbound_path", 1, 1, "A", 6)
AddDungeonSection("treacherous_mountain", 0, 10, "A", 20, true)
AddDungeonSection("treacherous_mountain", 0, 15, "S")
AddDungeonSection("champions_road", 0, 11, "S", 23, true)
AddDungeonSection("champions_road", 0, 18, "STAR_1")

return settings