local _, T = ...
if T.SkipLocalActionBook then return end

local AB = T.ActionBook:compatible(2,21)
local RW = T.ActionBook:compatible("Rewire", 1,27)
local IM = T.ActionBook:compatible("Imp", 1,8)
assert(AB and RW and IM and 1, "Incompatible library bundle")
local L = T.ActionBook.L
local mark = {}
local spellRankFilter = {maxOnly=true}
T.SpellRankFilter = spellRankFilter

local function icmp(a,b)
	return strcmputf8i(a,b) < 0
end
local function getContainerItemLootState(bag, slot)
	local name, _, _, _, readable, lootable = GetContainerItemInfo(bag, slot)
	if not name then return nil end
	return {isReadable = readable, hasLoot = lootable}
end
local function isItemInteresting(tf, testIdx, bag, slot, iid)
	if testIdx == 2 then
		local r = tf(bag, slot)
		return r and (r.hasLoot or r.isReadable)
	end
	return tf(iid)
end

do
	local function procSpellBookEntry(add, at, knownFilter, sourceKnown, _ok, st, sid)
		if (st == "SPELL" or st == "FUTURESPELL") and not IsPassiveSpell(sid) and not mark[sid] then
			if (not knownFilter) == (st == "FUTURESPELL" or not sourceKnown) then
				mark[sid] = 1
				add(at, sid)
			end
		elseif st == "FLYOUT" then
			for j=1,select(3,GetFlyoutInfo(sid)) do
				local asid, _osid, ik = GetFlyoutSlotInfo(sid, j)
				if (not ik) == (not knownFilter) then
					procSpellBookEntry(add, at, knownFilter, sourceKnown, true, ik and "SPELL" or "FUTURESPELL", asid)
				end
			end
		end
	end
	local WRATH_SKIP_TABS = {
		["Общие"]                 = true,
		["Гильдейские бонусы"]    = true,
		["Спутники"]              = true,
		["Транспортные средства"] = true,
		["Транспорт"]             = true,
		["Питомец"]               = true,
		["Питомцы"]               = true,
		["Коллекция: Игрушки"]    = true,
		["Коллекция: Иллюзии"]    = true,
		["Коллекция: Наследие"]   = true,
	}
	local isSpecHeaderName do
		local prefixes, seen = {}, {}
		local localized, cls = UnitClass("player")
		local function addPrefix(n)
			if type(n) == "string" and n ~= "" and not seen[n] then
				seen[n], prefixes[#prefixes+1] = true, n .. " - "
			end
		end
		addPrefix(localized)
		addPrefix(LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[cls])
		addPrefix(LOCALIZED_CLASS_NAMES_FEMALE and LOCALIZED_CLASS_NAMES_FEMALE[cls])
		function isSpecHeaderName(...)
			for i=1,select("#", ...) do
				local name = select(i, ...)
				if type(name) == "string" then
					for j=1,#prefixes do
						local p = prefixes[j]
						if name:sub(1, #p) == p then return true end
					end
				end
			end
			return false
		end
	end
	local function spellBookRank(slot)
		local bookName, rank = GetSpellBookItemName(slot, "spell")
		return bookName, type(rank) == "string" and tonumber(rank:match("(%d+)%s*$")) or nil
	end
	local function collectTopRanks()
		local top = {}
		for i=1,GetNumSpellTabs()+12 do
			local tabName, _, ofs, c = GetSpellTabInfo(i)
			if not ofs then break end
			if not (WRATH_SKIP_TABS and WRATH_SKIP_TABS[tabName]) then
				for j=ofs+1, ofs+c do
					local bookName, rank = spellBookRank(j)
					if bookName and rank and rank > (top[bookName] or 0) then
						top[bookName] = rank
					end
				end
			end
		end
		return top
	end
	local function addSpells(add, knownFilter)
		local asv = GetCVar("showAllSpellRanks")
		if asv and asv ~= "1" then
			SetCVar("showAllSpellRanks", "1")
		end
		local top = spellRankFilter.maxOnly and collectTopRanks()
		for i=1,GetNumSpellTabs()+12 do
			local tabName, ico, ofs, c = GetSpellTabInfo(i)
			if not ofs then break end
			local isSkipped = WRATH_SKIP_TABS and WRATH_SKIP_TABS[tabName]
			if not isSkipped then
				for j=ofs+1, ofs+c do
					local tex = GetSpellTexture(j, "spell")
					if tex and type(tex) == "string" then
						local _, sid = GetSpellBookItemInfo(j, "spell")
						if sid and sid > 0 and not mark[sid] and not IsPassiveSpell(sid) then
							local name = GetSpellInfo(sid)
							local bookName, rank = spellBookRank(j)
							local isSpecHeader = isSpecHeaderName(name, bookName)
							local isLowRank = top and rank and bookName and top[bookName] and rank < top[bookName]
							if not isSpecHeader and not isLowRank then
								mark[sid] = 1
								local t2 = tex
								AB:SetSpellIconOverride(sid, function() return t2 end)
								if name then AB:SetSpellIconOverride(name, function() return t2 end) end
								if not isSkipped then
									add("spell", sid)
								end
							end
						end
					end
			end
		end
		end
		if asv and asv ~= "1" then
			SetCVar("showAllSpellRanks", asv)
		end
	end
	AB:AugmentCategory(L"Abilities", function(_, add)
		wipe(mark)
		addSpells(add, true)
		wipe(mark)
	end)
	local _, cl = UnitClass("player")
	if cl == "HUNTER" or cl == "WARLOCK" then
		AB:AugmentCategory(L"Pet abilities", function(_, add)
		wipe(mark)
		for i=1,HasPetSpells() or 0 do
			local spellType, id = GetSpellBookItemInfo(i, "pet")
			if spellType == "PETACTION" then
				id = nil
			elseif not id or id == 0 then
				local name, rank = GetSpellBookItemName(i, "pet")
				if name then
					local link = GetSpellLink(name, rank)
					id = tonumber(link and link:match("|Hspell:(%d+)"))
				end
			end
			if id and id > 0 and not IsPassiveSpell(id) and not mark[id] then
				mark[id] = true
				add("petspell", id)
			end
		end
		for s in ("attack stay follow assist defend passive"):gmatch("%S+") do
			add("petspell", s)
		end
		wipe(mark)
		end)
	end
end
AB:AugmentCategory(L"Items", function(_, add)
	wipe(mark)
	local ns, giid = GetContainerNumSlots, GetContainerItemID
	for t=0,2 do
		local tf = t == 0 and GetItemSpell or t == 1 and IsEquippableItem or getContainerItemLootState
		for bag=0,4 do
			for slot=1, ns(bag) do
				local iid = giid(bag, slot)
				if iid and not mark[iid] and isItemInteresting(tf, t, bag, slot, iid) then
					add("item", iid)
					mark[iid] = 1
				end
			end
		end
		for slot=INVSLOT_FIRST_EQUIPPED, t < 2 and INVSLOT_LAST_EQUIPPED or -10 do
			local iid = GetInventoryItemID("player", slot)
			if iid and not mark[iid] and tf(iid) then
				add("item", iid)
				mark[iid] = 1
			end
		end
	end
end)
AB:AugmentCategory(L"Equipped", function(_, add)
	for w in ("head neck shoulders back chest tabard shirt wrist hands waist legs feet finger1 finger2 trinket1 trinket2"):gmatch("%S+") do
		add("peq", w)
	end
end)
local function registerCompanionIconOverrides()
	for i = 1, GetNumCompanions("MOUNT") do
		local _, _, sid, icon = GetCompanionInfo("MOUNT", i)
		if sid and sid > 0 and icon then
			local ic = icon
			AB:SetSpellIconOverride(sid, function() return ic end)
		end
	end
	for i = 1, GetNumCompanions("CRITTER") do
		local _, _, sid, icon = GetCompanionInfo("CRITTER", i)
		if sid and sid > 0 and icon then
			local ic = icon
			AB:SetSpellIconOverride(sid, function() return ic end)
		end
	end
end
do
	local f = CreateFrame("Frame")
	f:RegisterEvent("COMPANION_UPDATE")
	f:SetScript("OnEvent", registerCompanionIconOverrides)
	pcall(registerCompanionIconOverrides)
end

do
	AB:AugmentCategory(COMPANIONS, function(_, add)
		local seen = {}
		for i=1, GetNumCompanions("CRITTER") do
			local _, _, sid, icon = GetCompanionInfo("CRITTER", i)
			if sid and sid > 0 and not seen[sid] then
				seen[sid] = true
				if icon then
					local ic = icon
					AB:SetSpellIconOverride(sid, function() return ic end)
				end
				add("spell", sid)
			end
		end
	end)
end
do
	AB:AugmentCategory(L"Mounts", function(_, add)
		local n2name, n2icon, sids = {}, {}, {}
		for i=1, GetNumCompanions("MOUNT") do
			local _, name, sid, icon = GetCompanionInfo("MOUNT", i)
			if sid and sid > 0 and not n2name[sid] then
				n2name[sid] = name or ""
				n2icon[sid] = icon
				sids[#sids+1] = sid
			end
		end
		table.sort(sids, function(a,b) return icmp(n2name[a], n2name[b]) end)
		for i=1,#sids do
			local sid = sids[i]
			local icon = n2icon[sid]
			if icon then
				local ic = icon
				AB:SetSpellIconOverride(sid, function() return ic end)
			end
			add("spell", sid)
		end
	end)
end
AB:AugmentCategory(L"Macros", function(_, add)
	add("imptext", "")
	local n, ni = {}, 1
	for name in RW:GetNamedMacros() do
		n[ni], ni = name, ni + 1
	end
	table.sort(n, icmp)
	for i=1,#n do
		add("macro", n[i])
	end
end)
do
	local profCatName = TRADE_SKILLS or "Professions"
	local PROF_SECONDARY = {
		["Горное дело"]    = {"Выплавка металлов"},
		["Ювелирное дело"] = {"Просеивание"},
		["Начертание"]     = {"Просеивание"},
		["Наложение чар"]  = {"Распыление"},
		["Кулинария"]      = {"Костер", "Разведение костра"},
	}
	AB:AugmentCategory(profCatName, function(_, add)
		local profSkills, inProfsHeader = {}, false
		for i = 1, GetNumSkillLines() do
			local name, isHeader = GetSkillLineInfo(i)
			if name then
				if isHeader then
					inProfsHeader = (name == profCatName)
				elseif inProfsHeader then
					profSkills[name] = true
				end
			end
		end

		local secondaryNames = {}
		for profName, list in pairs(PROF_SECONDARY) do
			if profSkills[profName] then
				for _, sn in ipairs(list) do secondaryNames[sn] = true end
			end
		end

		local profSpells, profIcons = {}, {}
		local secSpells, secIcons = {}, {}
		for i = 1, GetNumSpellTabs() do
			local _, _, ofs, count = GetSpellTabInfo(i)
			if not ofs then break end
			for j = ofs + 1, ofs + count do
				local link, tradeLink = GetSpellLink(j, "spell")
				local isTradeLink = (link and link:find("|Htrade:")) or (tradeLink and tradeLink:find("|Htrade:"))
				local sid = (link and (tonumber(link:match("|Hspell:(%d+)")) or tonumber(link:match("|Htrade:(%d+)"))))
				         or (tradeLink and tonumber(tradeLink:match("|Htrade:(%d+)")))
				if sid and sid > 0 then
					local spellName = GetSpellInfo(sid)
					local tex = spellName and GetSpellTexture(j, "spell")
					local texStr = type(tex) == "string" and tex or nil
					if isTradeLink and spellName and not profSpells[spellName] then
						profSpells[spellName] = sid
						profIcons[spellName] = texStr
					elseif spellName and profSkills[spellName] and not profSpells[spellName] then
						profSpells[spellName] = sid
						profIcons[spellName] = texStr
					elseif spellName and secondaryNames[spellName] then
						secSpells[spellName] = sid
						secIcons[spellName] = texStr or secIcons[spellName]
					end
				end
			end
		end

		for name, sid in pairs(profSpells) do
			local ic = profIcons[name]
			if ic then AB:SetSpellIconOverride(sid, function() return ic end) end
			add("spell", sid)
		end
		for profName, list in pairs(PROF_SECONDARY) do
			if profSkills[profName] and profSpells[profName] then
				for _, secName in ipairs(list) do
					local sid = secSpells[secName]
					if sid then
						local ic = secIcons[secName]
						if ic then AB:SetSpellIconOverride(sid, function() return ic end) end
						add("spell", sid)
					end
				end
			end
		end
	end)
end
do
	AB:AugmentCategory(L"Equipment sets", function(_, add)
		for _,id in pairs(C_EquipmentSet.GetEquipmentSetIDs()) do
			add("equipmentset", (C_EquipmentSet.GetEquipmentSetInfo(id)))
		end
	end)
end
AB:AugmentCategory(L"Raid markers", function(_, add)
	for i=0,8 do
		add("raidmark", i)
	end
end)
AB:AugmentCategory(L"Toys", function(_, add)
	if not ToyBox or not ToyBox.PagingFrame then return end
	local maxPages = ToyBox.PagingFrame:GetMaxPages()
	local origPage = ToyBox.PagingFrame:GetCurrentPage()
	local wasShown = ToyBox:IsShown()
	if not wasShown then ToyBox:Show() end
	for page = 1, maxPages do
		if page ~= origPage then ToyBox.PagingFrame:SetCurrentPage(page) end
		for b = 1, 18 do
			local btn = _G["ToyBoxIconsFrameSpellButton"..b]
			if btn and btn.spellID and btn.spellID > 0 then
				add("spell", btn.spellID)
			end
		end
	end
	if maxPages > 1 and origPage ~= maxPages then
		ToyBox.PagingFrame:SetCurrentPage(origPage)
	end
	if not wasShown then ToyBox:Hide() end
end)
do
	AB:AddActionToCategory(L"Miscellaneous", "imptext", "")
end
do
	AB:AddCategoryAlias("Miscellaneous", L"Miscellaneous")
end
do
	local function registerSpellIcons()
		for i = 1, GetNumSpellTabs() do
			local _, _, ofs, c = GetSpellTabInfo(i)
			if not ofs then break end
			for j = ofs + 1, ofs + c do
				local tex = GetSpellTexture(j, "spell")
				if tex and type(tex) == "string" then
					local _, sid = GetSpellBookItemInfo(j, "spell")
					if sid and sid > 0 then
						local t2, name = tex, GetSpellInfo(sid)
						AB:SetSpellIconOverride(sid, function() return t2 end)
						if name then AB:SetSpellIconOverride(name, function() return t2 end) end
						RW:SetSpellCastableChecker(sid, function() return true end)
					end
				end
			end
		end
		for i = 1, HasPetSpells() or 0 do
			local tex = GetSpellTexture(i, "pet")
			if tex and type(tex) == "string" then
				local _, sid = GetSpellBookItemInfo(i, "pet")
				if sid and sid > 0 then
					local t2, name = tex, GetSpellInfo(sid)
					AB:SetSpellIconOverride(sid, function() return t2 end)
					if name then AB:SetSpellIconOverride(name, function() return t2 end) end
				end
			end
		end
	end
	do
		local f = CreateFrame("Frame")
		f:RegisterEvent("PLAYER_LOGIN")
		f:RegisterEvent("SPELLS_CHANGED")
		f:SetScript("OnEvent", registerSpellIcons)
	end
end
do
	local panels = {"character", "reputation", "currency", "spellbook", "talents", "achievements", "quests", "groupfinder", "guild", "map", "social", "calendar", "macro", "options", "gamemenu"}
	AB:AugmentCategory(L"UI panels", function(_, add)
		for i=1,#panels do
			i = panels[i]
			if select(2, AB:GetActionListDescription("uipanel", i)) then
				add("uipanel", i)
			end
		end
	end)
end