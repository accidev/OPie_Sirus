local _, T = ...

local AUTHOR_CONTACTS = {
	["5"] = {"Выстрелбелка", "PALADIN"},
	["3"] = {"Murr", "WARRIOR"}
}
local FALLBACK_RATE = "5"

local function classIconMarkup(class)
	local c = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
	if not c then
		return ""
	end
	return ([[|TInterface\TargetingFrame\UI-Classes-Circles:14:14:0:-2:256:256:%d:%d:%d:%d|t ]]):format(c[1] * 256,
		c[2] * 256, c[3] * 256, c[4] * 256)
end

local function classColorMarkup(class)
	local c = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
	if not c then
		return "|cffffd200"
	end
	return c.colorStr and ("|c" .. c.colorStr) or ("|cff%02x%02x%02x"):format(c.r * 255 + 0.5, c.g * 255 + 0.5,
		c.b * 255 + 0.5)
end

local function authorContact()
	local rate = (GetRealmName() or ""):match("[Xx](%d+)")
	local contact, suffix = AUTHOR_CONTACTS[rate or ""], ""
	if not contact then
		contact, suffix = AUTHOR_CONTACTS[FALLBACK_RATE], " |cff8f939a- x" .. FALLBACK_RATE .. "|r"
	end
	return classIconMarkup(contact[2]) .. classColorMarkup(contact[2]) .. contact[1] .. "|r" .. suffix
end

function T.CreditsData(vh, li)
	local L = T.L
	vh(L "OPie")
	li((L "%s — author of the original addon."):format("|cffffd200foxlit|r"))
	vh(L "Adaptation")
	li((L "%s — adaptation for World of Warcraft 3.3.5a."):format("|cffffd200Poslevkusie|r"))
	vh(L "Sirus")
	li((L "%s — optimization for Sirus."):format("|cffffd200Accidev|r"))
	li((L "In-game: %s"):format(authorContact()))
end
