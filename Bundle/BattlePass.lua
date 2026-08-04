local _, T = ...

local AB = assert(T.ActionBook:compatible(2, 36), "A compatible version of ActionBook is required")
local L = T.L

local PAGE_REWARDS, PAGE_QUESTS = 1, 2
local DAILY, WEEKLY = Enum.BattlePass.QuestType.Daily, Enum.BattlePass.QuestType.Weekly

local function numComplete(qt)
	local c = 0
	for i = 1, C_BattlePass.GetNumQuests(qt) or 0 do
		if C_BattlePass.IsQuestComplete(qt, i) then
			c = c + 1
		end
	end
	return c
end
local function collectQuests(qt)
	for i = C_BattlePass.GetNumQuests(qt) or 0, 1, -1 do
		if C_BattlePass.IsQuestComplete(qt, i) then
			C_BattlePass.CollectQuestReward(qt, i)
		end
	end
end
local function canOpen()
	return C_BattlePass.IsActiveOrHasRewards() and
			   not C_Hardcore.IsFeature1Available(Enum.Hardcore.Features1.BATTLEPASS_REWARDS)
end
local function togglePanel(page)
	if BattlePassFrame:IsShown() and BattlePassFrame:GetSelectedPage() == page then
		HideUIPanel(BattlePassFrame)
	elseif canOpen() then
		BattlePassFrame:SetPage(page)
		ShowUIPanel(BattlePassFrame)
	end
end

local order = {"open", "quests", "daily", "all", "rewards"}
local defs = {
	open = {L "Open Battle Pass", "Interface/Icons/INV_Misc_Book_09", function()
		local shown = BattlePassFrame:IsShown() and BattlePassFrame:GetSelectedPage() == PAGE_REWARDS
		return canOpen(), shown and 1 or 0, 0
	end, function()
		togglePanel(PAGE_REWARDS)
	end},
	quests = {L "Open quests", "Interface/Icons/INV_Misc_Note_02", function()
		local shown = BattlePassFrame:IsShown() and BattlePassFrame:GetSelectedPage() == PAGE_QUESTS
		return canOpen(), shown and 1 or 0, numComplete(DAILY) + numComplete(WEEKLY)
	end, function()
		togglePanel(PAGE_QUESTS)
	end},
	daily = {L "Complete daily quests", "Interface/Icons/Achievement_Quests_Completed_04", function()
		local n = numComplete(DAILY)
		return n > 0, 0, n
	end, function()
		collectQuests(DAILY)
	end},
	all = {L "Complete all quests", "Interface/Icons/Achievement_Quests_Completed_08", function()
		local n = numComplete(DAILY) + numComplete(WEEKLY)
		return n > 0, 0, n
	end, function()
		collectQuests(DAILY)
		collectQuests(WEEKLY)
	end},
	rewards = {L "Collect rewards", "Interface/Icons/INV_Misc_Gift_02", function()
		return C_BattlePass.HasUnclaimedReward(), 0, 0
	end, function()
		C_BattlePass.TakeAllLevelRewards()
	end}
}

local map = {}
local function hint(k)
	local d = defs[k]
	if not d then
		return
	end
	local usable, state, count = d[3]()
	return usable, state, d[2], d[1], count, 0, 0
end
local function run(k)
	local d = defs[k]
	if d then
		d[4]()
	end
end
for i = 1, #order do
	local k = order[i]
	map[k] = AB:CreateActionSlot(hint, k, "func", run, k)
end

local function createBattlePass(k)
	return map[k]
end
local function describeBattlePass(k)
	local d = defs[k]
	if d then
		return L "Battle Pass", d[1], d[2]
	end
	return L "Battle Pass"
end
AB:RegisterActionType("opie.battlepass", createBattlePass, describeBattlePass, 1)
AB:AugmentCategory(L "Battle Pass", function(_, add)
	if not C_BattlePass.IsEnabled() then
		return
	end
	for i = 1, #order do
		add("opie.battlepass", order[i])
	end
end)
