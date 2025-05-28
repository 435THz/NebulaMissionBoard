require 'nebula_mission_board.common'
require 'origin.services.baseservice'


local MissionMenuTools = Class('MissionMenuTools', BaseService)

--[[---------------------------------------------------------------
    MissionMenuTools:initialize()
      MissionMenuTools class constructor
---------------------------------------------------------------]]
function MissionMenuTools:initialize()
  BaseService.initialize(self)
  PrintInfo('MissionMenuTools:initialize()')
end

--[[---------------------------------------------------------------
    MenuTools:OnAddMenu(menu)
      When a menu is about to be added to the menu stack this is called!
---------------------------------------------------------------]]
function MissionMenuTools:OnAddMenu(menu)
    local labels = RogueEssence.Menu.MenuLabel
    if SV.MissionsEnabled and menu:HasLabel() then
        if RogueEssence.GameManager.Instance.CurrentScene == RogueEssence.Dungeon.DungeonScene.Instance then
            if menu.Label == labels.OTHERS_MENU then
                local choices = menu:ExportChoices()
                -- put right after Recruitment Search if present
                local index = menu:GetChoiceIndexByLabel("OTH_RECRUIT")+1
                -- if failed, put right before Settings if present
                if index <0 then index = menu:GetChoiceIndexByLabel(labels.OTH_SETTINGS) end
                -- fall back to either 1 or choices count if both fail
                if index <0 then index = math.min(1, menu.Choices.Count) end
                choices:Insert(index, RogueEssence.Menu.MenuTextChoice("OTH_MISSION", STRINGS:FormatKey(MissionGen.globals.keys.OPTION_OBJECTIVES_LIST), function () MissionGen:OpenObjectivesMenu() end))
                menu:ImportChoices(choices)
            end
        else
            if menu.Label == labels.MAIN_MENU then
                local choices = menu:ExportChoices()
                local taken_count = #MissionGen.root.taken
                local job_list_color = Color.Red
                if taken_count > 0 then job_list_color = Color.White end
                -- put right before Others if present
                local index = menu:GetChoiceIndexByLabel(labels.MAIN_OTHERS)
                -- fall back to either 1 or choices count if the check fails
                if index <0 then
                    index = math.min(1, menu.Choices.Count)
                end
                choices:Insert(index, RogueEssence.Menu.MenuTextChoice("MAIN_MISSION", STRINGS:FormatKey(MissionGen.globals.keys.OPTION_JOBLIST), function () MissionGen:OpenTakenMenuFromMain() end, taken_count > 0, job_list_color))
                menu:ImportChoices(choices)
            end
        end
    end
end

---Summary
-- Subscribe to all channels this service wants callbacks from
function MissionMenuTools:Subscribe(med)
  med:Subscribe("MissionMenuTools", EngineServiceEvents.AddMenu, function(_, args) self.OnAddMenu(self, args[0]) end )
end

---Summary
-- un-subscribe to all channels this service subscribed to
function MissionMenuTools:UnSubscribe(med)
end


--Add our service
SCRIPT:AddService("MissionMenuTools", MissionMenuTools:new())
return MissionMenuTools