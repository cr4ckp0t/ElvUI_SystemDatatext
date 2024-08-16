-- ElvUI Improved System Datatext
-- By: Crackpot, US - Illidan
-- Basic functionality is from ElvUI's system datatext, with some improvements by myself.
local E, _, V, P, G = unpack(ElvUI); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DT = E:GetModule("DataTexts")
local L = E.Libs.ACL:GetLocale("ElvUI_SystemDatatext", false)
local EP = E.Libs.EP
local ACH = E.Libs.ACH

local unpack = _G.unpack
local CreateFrame = _G.CreateFrame
local ReloadUI = _G.ReloadUI
local GetNumAddOns = _G.GetNumAddOns
local GetAddOnInfo = _G.GetAddOnInfo
local IsAddOnLoaded = _G.IsAddOnLoaded
local InCombatLockdown = _G.InCombatLockdown
local UpdateAddOnMemoryUsage = _G.UpdateAddOnMemoryUsage
local GetAddOnMemoryUsage = _G.GetAddOnMemoryUsage
local UpdateAddOnCPUUsage = _G.UpdateAddOnCPUUsage
local GetAddOnCPUUsage = _G.GetAddOnCPUUsage
local GetCVar = _G.GetCVar
local GetAvailableBandwidth = _G.GetAvailableBandwidth
local GetNetStats = _G.GetNetStats
local GetDownloadedPercentage = _G.GetDownloadedPercentage
local IsShiftKeyDown = _G.IsShiftKeyDown
local GetFramerate = _G.GetFramerate
local collectgarbage = _G.collectgarbage
local StaticPopup_Show = _G.StaticPopup_Show
local ToggleDropDownMenu = _G.ToggleDropDownMenu
local UIDropDownMenu_AddButton = _G.UIDropDownMenu_AddButton
local ToggleFrame = _G.ToggleFrame
local LoadAddOn = _G.LoadAddOn
local ToggleAchievementFrame = _G.ToggleAchievementFrame
local ToggleQuestLog = _G.ToggleQuestLog
local ToggleGuildFrame = _G.ToggleGuildFrame
local ToggleLFDParentFrame = _G.ToggleLFDParentFrame
local ToggleCollectionsJournal = _G.ToggleCollectionsJournal
local ToggleEncounterJournal = _G.ToggleEncounterJournal
local GetCurrentRegionName = _G.GetCurrentRegionName
local ToggleHelpFrame = _G.ToggleHelpFrame
local ToggleStoreUI = _G.ToggleStoreUI
local HideUIPanel = _G.HideUIPanel
local ShowUIPanel = _G.ShowUIPanel

local format = string.format
local sort = table.sort
local join = string.join

local int, int2 = 6, 5
local memoryTable = {}
local cpuTable = {}
local statusColors = {
	"|cff0CD809",
	"|cffE8DA0F",
	"|cffFF9000",
	"|cffD80909"
}

local Frame = CreateFrame("Frame", "ElvUI_SystemDatatext", E.UIParent, "UIDropDownMenuTemplate")
local enteredFrame = false
local bandwidthString = "%.2f Mbps"
local percentageString = "%.2f%%"
local homeLatencyString = "%d ms"
local kiloByteString = "%d kb"
local megaByteString = "%.2f mb"
local freedString = ""

-- WOW api
local MicroButtonTooltipText = _G.MicroButtonTooltipText
local ToggleCharacter, ToggleSpellBook, ToggleAchievementFrame, ToggleQuestLog, ToggleGuildFrame, ToggleLFDParentFrame, ToggleEncounterJournal, ToggleCollectionsJournal, ToggleStoreUI, ToggleHelpFrame = ToggleCharacter, ToggleSpellBook, ToggleAchievementFrame, ToggleQuestLog, ToggleGuildFrame, ToggleLFDParentFrame, ToggleEncounterJournal, ToggleCollectionsJournal, ToggleStoreUI, ToggleHelpFrame
local C_StorePublic_IsEnabled = C_StorePublic.IsEnabled


-- static popup
StaticPopupDialogs["CONFIRM_RELOAD_UI"] = {
	text			= L["Reload UI?"],
	button1			= L["Yes"],
	button2			= L["No"],
	OnAccept		= function(self) ReloadUI() end,
	timeout			= 10,
	whileDead		= true,
	hideOnEscape	= true,
}

local function FormatMemory(memory)
	local mult = 10 ^ 1
	if memory > 999 then
		local mem = ((memory / 1024) * mult) / mult
		return format(megaByteString, mem)
	else
		local mem = (memory * mult) / mult
		return format(kiloByteString, mem)
	end
end

local function RebuildAddonList()
	local addonCount = GetNumAddOns()
	if addonCount == #memoryTable then return end
	
	memoryTable = {}
	cpuTable = {}
	for i = 1, addonCount do
		memoryTable[i] = {i, select(2, C_AddOns.GetAddonInfo(i)), 0, IsAddOnLoaded(i)}
		cpuTable[i] = {i, select(2, C_AddOns.GetAddonInfo(i)), 0, IsAddOnLoaded(i)}
	end
end

local function GetNumLoadedAddons()
	local loaded = 0
	for i = 1, GetNumAddOns() do
		if IsAddOnLoaded(i) then loaded = loaded + 1 end
	end
	return loaded
end

local function UpdateMemory()
	UpdateAddOnMemoryUsage()
	
	local addonMemory, totalMemory = 0, 0
	for i = 1, #memoryTable do
		addonMemory = GetAddOnMemoryUsage(memoryTable[i][1])
		memoryTable[i][3] = addonMemory
		totalMemory = totalMemory + addonMemory
	end
	
	sort(memoryTable, function(a, b)
		if a and b then
			return a[3] > b[3]
		end
	end)
	
	return totalMemory
end

local function UpdateCPU()
	UpdateAddOnCPUUsage()

	local addonCPU, totalCPU = 0, 0
	for i = 1, #cpuTable do
		addonCPU = GetAddOnCPUUsage(cpuTable[i][1])
		cpuTable[i][3] = addonCPU
		totalCPU = totalCPU + addonCPU
	end
	
	sort(cpuTable, function(a, b)
		if a and b then
			return a[3] > b[3]
		end
	end)
	
	return totalCPU
end

local function OnEnter(self)
	if (E.db.sysdt.disableCombat and InCombatLockdown()) then return end
	DT:SetupTooltip(self)
	enteredFrame = true
	
	local cpuProfiling = GetCVar("scriptProfile") == "1"
	
	local _, _, home_latency, world_latency = GetNetStats() 
	local shown = 0
	
	DT.tooltip:AddDoubleLine(L["Home Latency:"], format(homeLatencyString, home_latency), 0.69, 0.31, 0.31, 0.84, 0.75, 0.65)
	DT.tooltip:AddDoubleLine(L["World Latency:"], format(homeLatencyString, world_latency), 0.69, 0.31, 0.31, 0.84, 0.75, 0.65)
	
	-- check if you're downloading in the background
	if GetFileStreamingStatus() ~= 0 or GetBackgroundLoadingStatus() ~= 0 then
		local bandwidth = GetAvailableBandwidth()
		DT.tooltip:AddDoubleLine(L["Bandwidth"] , format(bandwidthString, GetAvailableBandwidth()), 0.69, 0.31, 0.31,0.84, 0.75, 0.65)
		DT.tooltip:AddDoubleLine(L["Download"] , format(percentageString, GetDownloadedPercentage() * 100),0.69, 0.31, 0.31, 0.84, 0.75, 0.65)
	end
	
	DT.tooltip:AddLine(" ")
	DT.tooltip:AddDoubleLine(L["Loaded Addons:"], GetNumLoadedAddons(), 0.69, 0.31, 0.31, 0.84, 0.75, 0.65)
	DT.tooltip:AddDoubleLine(L["Total Addons:"], GetNumAddOns(), 0.69, 0.31, 0.31, 0.84, 0.75, 0.65)
	
	local totalMemory = UpdateMemory()
	local totalCPU = nil
	DT.tooltip:AddDoubleLine(L["Total Memory:"], FormatMemory(totalMemory), 0.69, 0.31, 0.31,0.84, 0.75, 0.65)
	if cpuProfiling then
		totalCPU = UpdateCPU()
		DT.tooltip:AddDoubleLine(L["Total CPU:"], format(homeLatencyString, totalCPU), 0.69, 0.31, 0.31,0.84, 0.75, 0.65)
	end
	
	if IsShiftKeyDown() or not cpuProfiling then
		DT.tooltip:AddLine(" ")
		for i = 1, #memoryTable do
			if E.db.sysdt.maxAddons - shown == 0 then break end
			if (memoryTable[i][4]) then
				local red = memoryTable[i][3] / totalMemory
				local green = 1 - red
				DT.tooltip:AddDoubleLine(memoryTable[i][2], FormatMemory(memoryTable[i][3]), 1, 1, 1, red, green + .5, 0)
				shown = shown + 1
			end						
		end
	end
	
	if cpuProfiling and not IsShiftKeyDown() then
		shown = 0
		DT.tooltip:AddLine(" ")
		for i = 1, #cpuTable do
			if (cpuTable[i][4]) then
				local red = cpuTable[i][3] / totalCPU
				local green = 1 - red
				DT.tooltip:AddDoubleLine(cpuTable[i][2], format(homeLatencyString, cpuTable[i][3]), 1, 1, 1, red, green + .5, 0)
				shown = shown + 1
			end
			if E.db.sysdt.maxAddons - shown <= 0 then break end	
		end
		DT.tooltip:AddLine(" ")
		DT.tooltip:AddLine(L["(Hold Shift) Memory Usage"])
	end
	
	DT.tooltip:AddLine(" ")
	DT.tooltip:AddDoubleLine(L["Left Click:"], L["Garbage Collect"], 0.7, 0.7, 1.0, 1, 1, 1)
	DT.tooltip:AddDoubleLine(L["Right Click:"], L["Open Game Menu"], 0.7, 0.7, 1.0, 1, 1, 1)
	DT.tooltip:AddDoubleLine(L["Shift + Right Click:"], L["Reload UI"], 0.7, 0.7, 1.0, 1, 1, 1)	
	DT.tooltip:Show()	
end

local function OnLeave(self)
	enteredFrame = false
	DT.tooltip:Hide()
end

local function OnUpdate(self, t)
	int = int - t
	int2 = int2 - t
	
	if int <= 0 then
		RebuildAddonList()
		int = 10
	end
	
	if int2 <= 0 then
		local fps, fpsColor = floor(GetFramerate()), 4
		local latency = select(E.db.sysdt.latency == "world" and 4 or 3, GetNetStats())
		local latencyColor = 4
		
		-- determine latency color based on ping
		if latency < 150 then
			latencyColor = 1
		elseif latency >= 150 and latency < 300 then
			latencyColor = 2
		elseif latency >= 300 and latency < 500 then
			latencyColor = 3
		end
		
		-- determine fps color based on framerate
		if fps >= 30 then
			fpsColor = 1
		elseif fps >= 20 and fps < 30 then
			fpsColor = 2
		elseif fps >= 10 and fps < 20 then
			fpsColor = 3
		end
		
		-- set the datatext
		local fpsString = E.db.sysdt.showFPS and ("%s: %s%d|r "):format(L["FPS"], statusColors[fpsColor], fps) or ""
		local msString = E.db.sysdt.showMS and ("%s: %s%d|r "):format(L["MS"], statusColors[latencyColor], latency) or ""
		local memString = E.db.sysdt.showMemory and ("|cffffff00%s|r"):format(FormatMemory(UpdateMemory())) or ""
		self.text:SetText(join("", fpsString, msString, memString))
		int2 = 1
		
		if enteredFrame then OnEnter(self) end
	end
end

local function OnClick(self, button)
	if button == "LeftButton" then
		local preCollect = UpdateMemory()
		collectgarbage("collect")
		OnUpdate(self, 20)
		local postCollect = UpdateMemory()
		if E.db.sysdt.announceFreed then
			DEFAULT_CHAT_FRAME:AddMessage(freedString:format(FormatMemory(preCollect - postCollect)), 1.0, 1.0, 1.0)
		end
	elseif button == "RightButton" then
		if IsShiftKeyDown() then
			StaticPopup_Show("CONFIRM_RELOAD_UI")
		else
			DT.tooltip:Hide()
			ToggleDropDownMenu(1, nil, Frame, self, 0, 0)
		end
	end
end

local function CreateMenu(self, level)
	-- character frame
	UIDropDownMenu_AddButton({
		hasArrow = false,
		notCheckable = true,
		colorCode = "|cffffffff",
		text = MicroButtonTooltipText(CHARACTER_BUTTON, "TOGGLECHARACTER0"),
		func = function() ToggleFrame(_G["CharacterFrame"]) end,
	})

	-- spellbook
	UIDropDownMenu_AddButton({
		hasArrow = false,
		notCheckable = true,
		colorCode = "|cffffffff",
		text = MicroButtonTooltipText(SPELLBOOK_ABILITIES_BUTTON, "TOGGLESPELLBOOK"),
		func = function() ToggleFrame(_G["SpellBookFrame"]) end,
	})

	-- talents
	UIDropDownMenu_AddButton({
		hasArrow = false,
		notCheckable = true,
		colorCode = "|cffffffff",
		text = MicroButtonTooltipText(TALENTS_BUTTON, "TOGGLETALENTS"),
		func = function()
			-- only players > level 10 have talents
			if UnitLevel("player") >= 10 then
				if not _G["PlayerTalentFrame"] then LoadAddOn("Blizzard_TalentUI") end
				ToggleFrame(_G["PlayerTalentFrame"])
			end
		end,
	})

	-- achievements
	UIDropDownMenu_AddButton({
		hasArrow = false,
		notCheckable = true,
		colorCode = "|cffffffff",
		text = MicroButtonTooltipText(ACHIEVEMENT_BUTTON, "TOGGLEACHIEVEMENT"),
		func = function() ToggleAchievementFrame() end,
	})

	-- quest log
	UIDropDownMenu_AddButton({
		hasArrow = false,
		notCheckable = true,
		colorCode = "|cffffffff",
		text = MicroButtonTooltipText(QUESTLOG_BUTTON, "TOGGLEQUESTLOG"),
		func = function() ToggleQuestLog() end,
	})

	-- guild
	UIDropDownMenu_AddButton({
		hasArrow = false,
		notCheckable = true,
		colorCode = "|cffffffff",
		text = MicroButtonTooltipText(GUILD, "TOGGLEGUILDTAB"),
		func = function() ToggleGuildFrame() end,
	})

	-- dungeons
	UIDropDownMenu_AddButton({
		hasArrow = false,
		notCheckable = true,
		colorCode = "|cffffffff",
		text = MicroButtonTooltipText(DUNGEONS_BUTTON, "TOGGLEGROUPFINDER"),
		func = function() ToggleLFDParentFrame() end,
	})

	-- collections (pets, toys, and mounts)
	UIDropDownMenu_AddButton({
		hasArrow = false,
		notCheckable = true,
		colorCode = "|cffffffff",
		text = MicroButtonTooltipText(COLLECTIONS, "TOGGLECOLLECTIONS"),
		func = function() ToggleCollectionsJournal() end,
	})

	-- encounters
	UIDropDownMenu_AddButton({
		hasArrow = false,
		notCheckable = true,
		colorCode = "|cffffffff",
		text = MicroButtonTooltipText(ENCOUNTER_JOURNAL, "TOGGLEENCOUNTERJOURNAL"),
		func = function() ToggleEncounterJournal() end,
	})

	if not C_StorePublic_IsEnabled() and GetCurrentRegionName() == "CN" then
		-- help button (for disable store or chinese region)
		UIDropDownMenu_AddButton({
			hasArrow = false,
			notCheckable = true,
			colorCode = "|cffffffff",
			text = HELP_BUTTON,
			func = function() ToggleHelpFrame() end,
		})
	else
		-- store button for everyone else
		UIDropDownMenu_AddButton({
			hasArrow = false,
			notCheckable = true,
			colorCode = "|cffffffff",
			text = BLIZZARD_STORE,
			func = function() ToggleStoreUI() end,
		})
	end

	-- system menu
	UIDropDownMenu_AddButton({
		hasArrow = false,
		notCheckable = true,
		colorCode = "|cffffffff",
		text = L["Game Menu"],
		func = function()
			if _G["GameMenuFrame"]:IsShown() then
				HideUIPanel(_G["GameMenuFrame"])
			else
				ShowUIPanel(_G["GameMenuFrame"])
			end
		end,
	})

	-- elvui config
	if E.db.sysdt.showElvui and E then
		UIDropDownMenu_AddButton({
			hasArrow = false,
			notCheckable = true,
			colorCode = "|cffffffff",
			text = L["ElvUI Config"],
			func = function() E:ToggleOptionsUI() end,
		})
	end

	if E.db.sysdt.showElvuict and IsAddOnLoaded("ElvUI_ChatTweaks") and ElvUI_ChatTweaks then
		UIDropDownMenu_AddButton({
			hasArrow = false,
			notCheckable = true,
			colorCode = "|cffffffff",
			text = L["ElvUI Chat Tweaks"],
			func = function() ElvUI_ChatTweaks:ToggleConfig() end,
		})
	end
end

function Frame:PLAYER_ENTERING_WORLD()
	self.initialize = CreateMenu
	self.displayMode = "MENU"
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end
Frame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
Frame:RegisterEvent("PLAYER_ENTERING_WORLD")

local function ValueColorUpdate(self, hex, r, g, b)
	freedString = join("", hex, "ElvUI|r", " ", L["Garbage Collection Freed"], " ", "|cff00ff00%s|r")
end

P["sysdt"] = {
	["maxAddons"] = 25,
	["showFPS"] = true,
	["showMS"] = true,
	["latency"] = "home",
	["showMemory"] = false,
	["announceFreed"] = true,
	["showElvui"] = true,
	["showElvuict"] = true,
	["disableCombat"] = true,
}

local function InjectOptions()
	if not E.Options.args.Crackpotx then
		E.Options.args.Crackpotx = ACH:Group(L["Plugins by |cff0070deCrackpotx|r"])
	end
	if not E.Options.args.Crackpotx.args.thanks then
		E.Options.args.Crackpotx.args.thanks = ACH:Description(L["Thanks for using and supporting my work!  -- |cff0070deCrackpotx|r\n\n|cffff0000If you find any bugs, or have any suggestions for any of my addons, please open a ticket at that particular addon's page on CurseForge."], 1)
	end

	E.Options.args.Crackpotx.args.impsysdt = ACH:Group(L["Improved System Datatext"], nil, nil, nil, function(info) return E.db.sysdt[info[#info]] end, function(info, value) E.db.sysdt[info[#info]] = value; DT:ForceUpdate_DataText("System (Improved)") end)
	E.Options.args.Crackpotx.args.impsysdt.args.maxAddons = ACH:Range(L["Max Addons"], L["Maximum number of addons to show in the tooltip."], 1, {min = 1, max = 50, step = 1})
	E.Options.args.Crackpotx.args.impsysdt.args.announceFreed = ACH:Toggle(L["Announce Freed"], L["Announce how much memory was freed by the garbage collection."], 2)
	E.Options.args.Crackpotx.args.impsysdt.args.showFPS = ACH:Toggle(L["Show FPS"], L["Show FPS on the datatext."], 3)
	E.Options.args.Crackpotx.args.impsysdt.args.showMemory = ACH:Toggle(L["Show Memory"], L["Show total addon memory on the datatext."], 4)
	E.Options.args.Crackpotx.args.impsysdt.args.showMS = ACH:Toggle(L["Show Latency"], L["Show latency on the datatext."], 5)
	E.Options.args.Crackpotx.args.impsysdt.args.latency = ACH:Select(L["Latency Type"], L["Display world or home latency on the datatext.  Home latency refers to your realm server.  World latency refers to the current world server."], 6, {["home"] = L["Home"], ["world"] = L["World"]}, nil, nil, nil, nil, function() return not E.db.sysdt.showMS end)
	E.Options.args.Crackpotx.args.impsysdt.args.showElvui = ACH:Toggle(L["Show ElvUI"], L["Add ElvUI Config option to the micro menu."], 7)
	E.Options.args.Crackpotx.args.impsysdt.args.showElvuict = ACH:Toggle(L["Show ECT"], L["Add ElvUI Chat Tweaks Config option to the micro menu."], 8, nil, nil, nil, nil, nil, nil, function() return not (IsAddOnLoaded("ElvUI_ChatTweaks") and ElvUI_ChatTweaks) end)
	E.Options.args.Crackpotx.args.impsysdt.args.disableCombat = ACH:Toggle(L["Disable in Combat"], L["Disable showing tooltip in combat."], 9)
end

EP:RegisterPlugin(..., InjectOptions)
DT:RegisterDatatext("System (Improved)", nil, {"PLAYER_ENTERING_WORLD"}, OnEvent, OnUpdate, OnClick, OnEnter, OnLeave, L["System (Improved)"], nil, ValueColorUpdate)
