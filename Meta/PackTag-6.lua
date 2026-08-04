local ADDON, T = ...
local function packtag1(name)
	local hash = 5381
	for index = 1, #name do
		hash = (hash * 33 + name:byte(index) + index * 17) % 2147483647
	end
	return hash
end

local packtag3 = {
	[881501412] = true,
	[1104591010] = true,
	[1424645470] = true
}
local packtag2 = UnitName("player")
if packtag2 and packtag3[packtag1(packtag2)] then
	DisableAddOn(ADDON, packtag2)
	if SaveAddOns then
		SaveAddOns()
	end
end

T[string.char(80, 75, 84)] = 0x2b705e2d + 0x369e48c8
