local _, T = ...
local L, R = T.L, OPie.CustomRings
if not (R and R.AddDefaultRing) then return end

R:AddDefaultRing("RaidSymbols", {
	{"raidmark", 1, _u="y"}, -- yellow star
	{"raidmark", 2, _u="o"}, -- orange circle
	{"raidmark", 3, _u="p"}, -- purple diamond
	{"raidmark", 4, _u="g"}, -- green triangle
	{"raidmark", 5, _u="s"}, -- silver moon
	{"raidmark", 6, _u="b"}, -- blue square
	{"raidmark", 7, _u="r"}, -- red cross
	{"raidmark", 8, _u="w"}, -- white skull
	{"raidmark", 0, _u="c"}, -- clear all
	name=L"Target Markers", hotkey="ALT-R", _u="OPCRS", v=1
})
local firstAid = {id="/cast {{spell:3273}}", _u="f"}
local _, playerClass = UnitClass("player")
local commonTrades = {
	{id="/cast {{spell:3908/51309}}", _u="t"}, -- tailoring
	{id="/cast {{spell:2108/51302}}", _u="l"}, -- leatherworking
	{id="/cast {{spell:2018/51300}}", _u="b"}, -- blacksmithing
	{id="/cast [mod] {{spell:13262}}; {{spell:7411/51313}}", _u="e"}, -- enchanting/disenchanting
	{id="/cast {{spell:2259/51304}}", _u="a"}, -- alchemy
	{id="/cast [mod] {{spell:818}}; {{spell:2550/51296}}; {{spell:818}}", _u="c"}, -- cooking/campfire
	{id="/cast {{spell:4036/51306}}", _u="g"}, -- engineering
	{id=2656, _u="m"}, -- smelting (WotLK: нет mining journal)
	{id="/cast [mod] {{spell:31252}}; {{spell:25229/51311}}", _u="j"}, -- jewelcrafting/prospecting (TBC+)
	{id="/cast [mod] {{spell:51005}}; {{spell:45357/45363}}", _u="i"}, -- inscription/milling (WotLK+)
	firstAid, -- first aid (WotLK)
	name=L"Trade Skills", hotkey="ALT-T", _u="OPCCT", v=8
}
if playerClass == "DEATHKNIGHT" then
	table.insert(commonTrades, 11, {id=53428, _u="u"}) -- runeforging перед firstAid, только ДК
end
R:AddDefaultRing("CommonTrades", commonTrades)
R:AddDefaultRing("OPieAutoQuest", {
	{"opie.autoquest", 1, _u="AC"},
	name=L"Quest Items", hotkey="ALT-Q", _u="OPbQI", v=5
})
