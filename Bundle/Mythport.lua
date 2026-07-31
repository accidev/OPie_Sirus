local COMPAT, _, T = select(4, GetBuildInfo()), ...
local L, EV, PC, AB = T.L, T.Evie, T.OPieCore, T.ActionBook:compatible("ActionBook", 2, 48)
local RW, KR = AB and AB:compatible("Rewire", 1, 47), AB and AB:compatible("Kindred", 1, 32)
local IM = AB and AB:compatible("Imp", 1, 13)
local AL = AB and AB.L
assert(EV and AB and RW and KR and PC and AL and IM and 1, "Incompatible library bundle")

IM:SetTokenReplacement('opie:mythport', false)
