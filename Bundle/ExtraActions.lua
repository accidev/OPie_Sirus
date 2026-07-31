local _, T = ...

local L, PC, AB, KR = T.L, T.OPieCore, T.ActionBook
AB, KR = AB and AB:compatible(2, 45), AB and AB:compatible("Kindred", 1, 33)
assert(PC and AB and KR and 1, "Incompatible library bundle")

KR:SetStateConditionalValue("dupeab", false)
do
	local function createXact(_kind)
		return nil
	end
	local function describeXact(_kind)
		return L"Extra Actions", L"Extra Actions", "Interface/Icons/INV_Misc_Lantern_01", nil, nil, nil, "collection"
	end
	PC:RegisterExtAction("xact", createXact, describeXact)
end