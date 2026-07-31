local _, T = ...

local L, EV, PC, AB, KR = T.L, T.Evie, T.OPieCore, T.ActionBook
AB, KR = AB and AB:compatible(2, 45), AB and AB:compatible("Kindred", 1, 33)
assert(EV and PC and AB and KR and 1, "Incompatible library bundle")
if T.TenEnv then T.TenEnv() end

KR:SetStateConditionalValue("dupeab", false) do
	local DUP_SPELL_ID = {
		[1257665]=1, [1250255]=1, -- Exit K'aresh Phasedive
	}
	local function syncDupEAB()
		local at, sid = GetActionInfo(GetExtraBarIndex()*12-11)
		KR:SetStateConditionalValue("dupeab", not not (at == "spell" and DUP_SPELL_ID[sid]))
	end
	EV.UPDATE_EXTRA_ACTIONBAR = syncDupEAB
end
do -- action handler (xact = zone context actions; MODERN-only, not used on WotLK)
	local function createXact(_kind)
		return nil
	end
	local function describeXact(_kind)
		return L"Extra Actions", L"Extra Actions", "Interface/Icons/INV_Misc_Lantern_01", nil, nil, nil, "collection"
	end
	PC:RegisterExtAction("xact", createXact, describeXact)
end