local _, T = ...
if T.SkipLocalActionBook then return end

local EV, WR, AB, KR, RW, IM = T.Evie, T.Ware, T.ActionBook:compatible(2,38), T.ActionBook:compatible("Kindred", 1,26), T.ActionBook:compatible("Rewire", 1,27), T.ActionBook:compatible("Imp", 1,11)
assert(EV and WR and AB and KR and RW and IM and 1, "Incompatible library bundle")
local playerClass, _, playerRace = UnitClassBase("player"), UnitRace("player")

securecall(function() -- spec conditional sync
	local function syncSpec()
		local group = C_Talent and C_Talent.GetActiveTalentGroup and C_Talent.GetActiveTalentGroup() or GetActiveTalentGroup() or 1
		local maxPts, bestName = 0, nil
		for i = 1, GetNumTalentTabs() do
			local name, _, pts = GetTalentTabInfo(i)
			if pts and pts > maxPts then
				maxPts, bestName = pts, name
			end
		end
		local v = group .. (bestName and "/" .. bestName .. "/p" or "/s")
		KR:SetStateConditionalValue("spec", v)
	end
	function EV:PLAYER_TALENT_UPDATE()
		syncSpec()
	end
	EV.PLAYER_LOGIN = syncSpec
	EV.ACTIVE_TALENT_GROUP_CHANGED = syncSpec
	EV.PLAYER_TALENT_UPDATE_EX = syncSpec
	EV.PLAYER_TALENT_ACTIVE_GROUP_REFRESH = syncSpec
end)