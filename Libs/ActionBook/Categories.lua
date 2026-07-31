local _, T = ...
if T.SkipLocalActionBook then return end

local AB = T.ActionBook:compatible(2,21)
local RW = T.ActionBook:compatible("Rewire", 1,27)
local IM = T.ActionBook:compatible("Imp", 1,8)
assert(AB and RW and IM and 1, "Incompatible library bundle")
local L = T.ActionBook.L
local mark = {}

local function icmp(a,b)
	return strcmputf8i(a,b) < 0
end
local function isItemInteresting(tf, testIdx, bag, slot, iid)
	if testIdx == 2 then
		local r = tf(bag, slot)
		return r and (r.hasLoot or r.isReadable)
	end
	return tf(iid)
end

do -- spellbook
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
	local function procRuneBookEntry(add, _ok, st, sid)
		if st == "SPELL" and sid then
			local n1 = GetSpellInfo(sid)
			local n2, _, _, _, _, _, sid2 = GetSpellInfo(n1 or "")
			if n2 ~= n1 and sid2 and not IsPassiveSpell(sid2) and not mark[sid2] then
				mark[sid2] = 1
				add("spell", sid2)
			end
		end
	end
	-- вкладки без заклинаний — у них свои категории в OPie
	local WRATH_SKIP_TABS = {
		["Общие"]                 = true,
		["Гильдейские бонусы"]    = true,
		["Спутники"]              = true,
		["Транспортные средства"] = true,
		["Транспорт"]             = true,
		["Питомец"]               = true,
		["Питомцы"]               = true,
		["Коллекция: Игрушки"]    = true,
		["Коллекция: Наследие"]   = true,
	}
	-- Sirus добавляет заголовки специализаций как спеллы: "ИмяКласса - Специализация"
	local WRATH_CLASS_PREFIX = (UnitClass("player")) .. " - "
	local function addSpells(add, knownFilter)
		local asv = GetCVar("showAllSpellRanks")
		if asv and asv ~= "1" then
			SetCVar("showAllSpellRanks", "1")
		end
		for i=1,GetNumSpellTabs()+12 do
			local tabName, ico, ofs, c, _, otherSpecID = GetSpellTabInfo(i)
			if not ofs then break end
			local isNotOffspec = true
			local isSkipped = WRATH_SKIP_TABS and WRATH_SKIP_TABS[tabName]
			if not isSkipped then
				for j=ofs+1,(isNotOffspec or not knownFilter) and (ofs+c) or 0 do
					-- Sirus: GetSpellBookItemInfo/Name не работают; используем GetSpellLink/GetSpellTexture
					local tex = GetSpellTexture(j, "spell")
					if tex and type(tex) == "string" then
						local link = GetSpellLink(j, "spell")
						local sid = link and tonumber(link:match("|Hspell:(%d+)"))
						if sid and sid > 0 and not mark[sid] and not IsPassiveSpell(sid) then
							local name = GetSpellInfo(sid)
							-- Skip spec header spells: "ClassName - SpecName"
							local isSpecHeader = WRATH_CLASS_PREFIX and name and name:sub(1, #WRATH_CLASS_PREFIX) == WRATH_CLASS_PREFIX
							if not isSpecHeader then
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
		end -- for i
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
			if spellType == nil then
				-- Sirus: GetSpellBookItemInfo broken; GetSpellLink(i,"pet") works
				local link = GetSpellLink(i, "pet")
				id = link and tonumber(link:match("|Hspell:(%d+)"))
			elseif spellType == "PETACTION" then
				id = nil -- behavior token, handled below as string
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
		-- pet stance/behavior tokens (dismiss excluded: no icon in WotLK actionInfo)
		for s in ("attack stay follow assist defend passive"):gmatch("%S+") do
			add("petspell", s)
		end
		wipe(mark)
		end)
	end
end
AB:AugmentCategory(L"Items", function(_, add)
	wipe(mark)
	local ns, giid = C_Container.GetContainerNumSlots, C_Container.GetContainerItemID
	for t=0,2 do
		local tf = t == 0 and C_Item.GetItemSpell or t == 1 and C_Item.IsEquippableItem or C_Container.GetContainerItemInfo
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
-- Sirus: GetSpellInfo pos3 возвращает fileID для кастомных маунтов/питомцев → белый квадрат в кольцах.
-- GetCompanionInfo поз4 всегда строка — используем её. Регистрируем через COMPANION_UPDATE.
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
	pcall(registerCompanionIconOverrides) -- try immediately; safe if data not ready yet
end

do -- Companions (WotLK: GetNumCompanions CRITTER)
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
do -- Mounts (WotLK: GetNumCompanions MOUNT)
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
end -- Mounts
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
	-- вторичные заклинания профессий (Sirus RU): открывашка + утилити-спеллы
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
						-- ВСЕ |Htrade: ссылки — опенеры профессий персонажа
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
do -- equipmentset (WotLK 3.x+)
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
-- Sirus: кастомный ToyBox с пагинацией; у каждой кнопки есть .spellID
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
do -- misc
	AB:AddActionToCategory(L"Miscellaneous", "imptext", "")
end
do -- aliases
	AB:AddCategoryAlias("Miscellaneous", L"Miscellaneous")
end
-- регистрируем иконки заклинаний сразу при входе — так кастомные кольца показывают иконки без открытия редактора
do
	local function registerSpellIcons()
		-- Sirus: GetSpellBookItemInfo/Name не работают; используем GetSpellLink + GetSpellTexture
		for i = 1, GetNumSpellTabs() do
			local _, _, ofs, c = GetSpellTabInfo(i)
			if not ofs then break end
			for j = ofs + 1, ofs + c do
				local tex = GetSpellTexture(j, "spell")
				if tex and type(tex) == "string" then
					local link = GetSpellLink(j, "spell")
					local sid = link and tonumber(link:match("|Hspell:(%d+)"))
					if sid and sid > 0 then
						local t2, name = tex, GetSpellInfo(sid)
						AB:SetSpellIconOverride(sid, function() return t2 end)
						if name then AB:SetSpellIconOverride(name, function() return t2 end) end
						RW:SetSpellCastableChecker(sid, function() return true end)
					end
				end
			end
		end
		-- pet spellbook (hunter/warlock)
		for i = 1, HasPetSpells() or 0 do
			local tex = GetSpellTexture(i, "pet")
			if tex and type(tex) == "string" then
				local link = GetSpellLink(i, "pet")
				local sid = link and tonumber(link:match("|Hspell:(%d+)"))
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
	local panels = {"character", "reputation", "currency", "spellbook", "talents", "profs", "achievements", "quests", "groupfinder", "collections", "adventureguide", "guild", "map", "vault", "social", "calendar", "macro", "options", "gamemenu"}
	AB:AugmentCategory(L"UI panels", function(_, add)
		for i=1,#panels do
			i = panels[i]
			if select(2, AB:GetActionListDescription("uipanel", i)) then
				add("uipanel", i)
			end
		end
	end)
end