local _, T = ...

-- texture metatable
do
	local f = CreateFrame("Frame")
	local tx = f:CreateTexture()
	local mt = getmetatable(tx)
	local idx = mt and type(mt.__index) == "table" and mt.__index
	if idx then
		if not idx.SetColorTexture then
			idx.SetColorTexture = function(self, r, g, b, a) self:SetTexture(r, g, b, a) end
		end
		if idx.SetGradient then
			local orig = idx.SetGradient
			idx.SetGradient = function(self, orient, c1, c2, ...)
				if type(c1) == "table" then
					local r1, g1, b1, a1 = c1.r or 0, c1.g or 0, c1.b or 0, c1.a or 1
					local r2, g2, b2, a2 = c2.r or 0, c2.g or 0, c2.b or 0, c2.a or 1
					if self.SetGradientAlpha then
						self:SetGradientAlpha(orient, r1, g1, b1, a1, r2, g2, b2, a2)
					else
						orig(self, orient, r1, g1, b1, r2, g2, b2)
					end
				else
					orig(self, orient, c1, c2, ...)
				end
			end
		end
		if not idx.GetAtlas               then idx.GetAtlas               = function() return nil end end
		if not idx.SetTextureSliceMargins  then idx.SetTextureSliceMargins  = function() end end
		if not idx.GetTextureSliceMargins  then idx.GetTextureSliceMargins  = function() return 0, 0, 0, 0 end end
		if not idx.SetTexelSnappingBias    then idx.SetTexelSnappingBias    = function() end end
		if not idx.SetSnapToPixelGrid      then idx.SetSnapToPixelGrid      = function() end end
		if not idx.SetVertexOffset         then idx.SetVertexOffset         = function() end end
		if not idx.SetHorizTile            then idx.SetHorizTile            = function() end end
		if not idx.SetVertTile             then idx.SetVertTile             = function() end end
	end
	f, tx, mt, idx = nil, nil, nil, nil
end

-- frame metatable — only SetAttributeNoHandler; other retail methods intentionally omitted
-- (Lua closures in frame metatable are tainted, propagating via NamePlate secure thread)
do
	local f = CreateFrame("Frame")
	local mt = getmetatable(f)
	local idx = mt and type(mt.__index) == "table" and mt.__index
	if idx and not idx.SetAttributeNoHandler then
		idx.SetAttributeNoHandler = idx.SetAttribute
	end
	f = nil
end

-- EditBox metatable
do
	local eb = CreateFrame("EditBox")
	local mt = getmetatable(eb)
	local idx = mt and type(mt.__index) == "table" and mt.__index
	if idx and not idx.SetHyperlinkPropagateToParent then
		idx.SetHyperlinkPropagateToParent = function() end
	end
	eb:SetAutoFocus(false)
	eb:EnableKeyboard(false)
	eb:Hide()
	eb = nil
end

-- Slider metatable
do
	local sl = CreateFrame("Slider")
	local mt = getmetatable(sl)
	local idx = mt and type(mt.__index) == "table" and mt.__index
	if idx and not idx.SetObeyStepOnDrag then
		idx.SetObeyStepOnDrag = function() end
	end
	sl = nil
end

-- FontString metatable
do
	local f = CreateFrame("Frame")
	local fs = f:CreateFontString()
	local mt = getmetatable(fs)
	local idx = mt and type(mt.__index) == "table" and mt.__index
	if idx then
		if not idx.SetWordWrap   then idx.SetWordWrap   = function() end end
		if not idx.SetScript     then idx.SetScript     = function() end end
		if not idx.GetLineHeight then
			idx.GetLineHeight = function(self)
				local _, size = self:GetFont()
				return size or 12
			end
		end
	end
	f, fs, mt, idx = nil, nil, nil, nil
end

-- Alpha animation metatable
do
	local f = CreateFrame("Frame")
	local ag = f.CreateAnimationGroup and f:CreateAnimationGroup()
	local anim = ag and ag.CreateAnimation and ag:CreateAnimation("Alpha")
	if anim then
		local mt = getmetatable(anim)
		local idx = mt and type(mt.__index) == "table" and mt.__index
		if idx then
			if not idx.SetFromAlpha then
				idx.SetFromAlpha = function(self, v)
					self.__fromAlpha = v
					if self.__toAlpha ~= nil and self.SetChange then
						self:SetChange(self.__toAlpha - v)
					end
				end
			end
			if not idx.SetToAlpha then
				idx.SetToAlpha = function(self, v)
					self.__toAlpha = v
					if self.__fromAlpha ~= nil and self.SetChange then
						self:SetChange(v - self.__fromAlpha)
					end
				end
			end
			if not idx.SetTarget then idx.SetTarget = function() end end
		end
	end
	f, ag, anim = nil, nil, nil
end

-- C_Timer.After: Sirus calls it as colon method; Evie captures the reference before this file loads.
-- Patch via evie.raw rather than C_Timer.After to avoid tainting the global
-- (FrameXML reads C_Timer.After in secure paths → taint → SetTargetClampingInsets blocked).
do
	local pending = {}
	local sf = CreateFrame("Frame")
	sf:Hide()
	sf:SetScript("OnUpdate", function(_, dt)
		local now = GetTime()
		local i = 1
		while i <= #pending do
			local t = pending[i]
			if now >= t[1] then
				table.remove(pending, i)
				t[2]()
			else
				i = i + 1
			end
		end
		if #pending == 0 then sf:Hide() end
	end)
	local function safeAfter(a, b, c)
		local delay, fn
		if type(a) == "number" then
			delay, fn = a, b
		else
			delay, fn = b, c
		end
		if type(delay) == "number" and type(fn) == "function" then
			pending[#pending + 1] = {GetTime() + delay, fn}
			sf:Show()
		end
	end
	local evie = T.Evie and T.Evie.raw
	if type(evie) == "table" then evie.After = safeAfter end
end

if not GetFileIDFromPath then GetFileIDFromPath = function() return nil end end

if not C_Texture then C_Texture = {} end
if not C_Texture.GetAtlasInfo      then C_Texture.GetAtlasInfo      = function() return nil end end
if not C_Texture.GetAtlasElementID then C_Texture.GetAtlasElementID = function() return nil end end

if not C_AddOns then
	C_AddOns = {
		GetAddOnMetadata = GetAddOnMetadata,
		GetAddOnInfo     = GetAddOnInfo,
		IsAddOnLoaded    = IsAddOnLoaded,
		LoadAddOn        = LoadAddOn,
		DisableAddOn     = DisableAddOn,
		EnableAddOn      = EnableAddOn,
	}
end
if not C_AddOns.DisableAddOn then C_AddOns.DisableAddOn = DisableAddOn or function() end end
if not C_AddOns.EnableAddOn  then C_AddOns.EnableAddOn  = EnableAddOn  or function() end end

-- only add if not native — overwriting a native C_Widget with tainted Lua causes ADDON_ACTION_BLOCKED
if not C_Widget then C_Widget = {} end
if not C_Widget.IsFrameWidget then
	C_Widget.IsFrameWidget = function(v)
		return type(v) == "table" and type(v[0]) == "userdata"
	end
end

if not SettingsPanel then
	local sp = CreateFrame("Frame")
	sp:Hide()
	SettingsPanel = sp
end

if not Settings then
	Settings = {
		RegisterCanvasLayoutCategory = function(_c, name) return {ID = name} end,
		RegisterAddOnCategory        = function() end,
		OpenToCategory               = function() end,
		GetCategory                  = function() return nil end,
	}
end

if not AreDangerousScriptsAllowed then AreDangerousScriptsAllowed = function() return true end end
if not SetAllowDangerousScripts   then SetAllowDangerousScripts   = function() end end

if not C_Spell then C_Spell = {} end
if not C_Spell.GetSpellName    then C_Spell.GetSpellName    = function(id) return (GetSpellInfo(id)) end end
if not C_Spell.GetSpellTexture then C_Spell.GetSpellTexture = function(id) return select(3, GetSpellInfo(id)) end end
if not C_Spell.GetSpellSubtext then
	C_Spell.GetSpellSubtext = function(id)
		if id then return select(2, GetSpellInfo(id)) end
	end
end

if not C_Loot then C_Loot = {IsLegacyLootModeEnabled = function() return false end} end
if not C_CVar then C_CVar = {GetCVar = GetCVar, SetCVar = SetCVar, RegisterCVar = function() end} end

if not C_Container then C_Container = {} end
if not C_Container.GetContainerNumSlots  then C_Container.GetContainerNumSlots  = GetContainerNumSlots end
if not C_Container.GetContainerItemID    then C_Container.GetContainerItemID    = GetContainerItemID end
if not C_Container.GetContainerItemLink  then C_Container.GetContainerItemLink  = GetContainerItemLink end
if not C_Container.GetItemCooldown       then C_Container.GetItemCooldown       = function(iid) return GetItemCooldown(iid) end end
if not C_Container.GetContainerItemInfo  then
	C_Container.GetContainerItemInfo = function(bag, slot)
		local name, _, _, _, readable, lootable = GetContainerItemInfo(bag, slot)
		if not name then return nil end
		return {isReadable = readable, hasLoot = lootable}
	end
end
if not C_Container.GetContainerItemQuestInfo then
	C_Container.GetContainerItemQuestInfo = function(bag, slot)
		local isQ, qid, isA = GetContainerItemQuestInfo(bag, slot)
		return {isQuestItem = isQ, questID = qid, isActive = isA}
	end
end

if not C_Item then C_Item = {} end
if not C_Item.GetItemCount             then C_Item.GetItemCount             = GetItemCount end
if not C_Item.GetItemSpell             then C_Item.GetItemSpell             = GetItemSpell end
if not C_Item.GetItemInfo              then C_Item.GetItemInfo              = GetItemInfo end
if not C_Item.IsEquippableItem         then C_Item.IsEquippableItem         = IsEquippableItem end
if not C_Item.IsItemInRange            then C_Item.IsItemInRange            = IsItemInRange end
if not C_Item.IsUsableItem             then C_Item.IsUsableItem             = IsUsableItem end
if not C_Item.IsCurrentItem            then C_Item.IsCurrentItem            = IsCurrentItem end
if not C_Item.IsEquippedItem           then C_Item.IsEquippedItem           = IsEquippedItem end
if not C_Item.GetItemInfoInstant then
	C_Item.GetItemInfoInstant = function(id)
		local _, _, _, _, _, class, subclass, _, equipSlot, texture = GetItemInfo(id)
		return tonumber(id), class, subclass, equipSlot, texture
	end
end
if not C_Item.GetItemNameByID          then C_Item.GetItemNameByID          = function(id) return (GetItemInfo(id)) end end
if not C_Item.GetItemIconByID          then C_Item.GetItemIconByID          = function(id) return select(10, GetItemInfo(id)) end end
if not C_Item.GetItemIDForItemInfo     then C_Item.GetItemIDForItemInfo     = function(id) return tonumber(id) or select(2, GetItemInfo(id) and id or "") end end
if not C_Item.GetDetailedItemLevelInfo then
	C_Item.GetDetailedItemLevelInfo = function(link)
		local _, _, _, ilvl = GetItemInfo(link or "")
		return ilvl
	end
end

if not C_QuestLog then
	local completed = {}
	do
		local qf = CreateFrame("Frame")
		qf:RegisterEvent("QUEST_QUERY_COMPLETE")
		qf:SetScript("OnEvent", function()
			if GetQuestsCompleted then
				local t = {}
				GetQuestsCompleted(t)
				completed = t
			end
		end)
		if QueryQuestsCompleted then QueryQuestsCompleted() end
	end
	C_QuestLog = {
		IsQuestFlaggedCompleted = IsQuestFlaggedCompleted or function(qid)
			return completed[tonumber(qid) or qid] == true
		end,
		IsOnQuest = function(qid)
			for i = 1, GetNumQuestLogEntries() do
				if select(9, GetQuestLogTitle(i)) == qid then return true end
			end
		end,
		IsComplete = function(qid)
			for i = 1, GetNumQuestLogEntries() do
				local _, _, _, _, _, _, isComplete, _, id = GetQuestLogTitle(i)
				if id == qid then return isComplete end
			end
		end,
	}
end

if not C_UnitAuras then C_UnitAuras = {} end
if not C_UnitAuras.IsAuraFilteredOutByInstanceID then C_UnitAuras.IsAuraFilteredOutByInstanceID = function() return true end end
if not C_UnitAuras.GetAuraSlots                  then C_UnitAuras.GetAuraSlots                  = function() return nil end end
if not C_UnitAuras.GetAuraDataBySlot             then C_UnitAuras.GetAuraDataBySlot             = function() return nil end end
if not C_UnitAuras.GetPlayerAuraBySpellID then
	C_UnitAuras.GetPlayerAuraBySpellID = function(sid)
		for i = 1, 40 do
			local name, _, _, _, _, _, _, _, _, spellID = UnitBuff("player", i)
			if not name then break end
			if spellID == sid then return {auraInstanceID = i} end
		end
	end
end

if not C_GamePad then
	C_GamePad = {IsEnabled = function() return false end, GetDeviceMappedState = function() return nil end}
end
if not IsGamePadFreelookEnabled then IsGamePadFreelookEnabled = function() return false end end

if not C_PetJournal then C_PetJournal = {} end
if not C_PetJournal.SetSearchFilter          then C_PetJournal.SetSearchFilter          = function() end end
if not C_PetJournal.ClearSearchFilter        then C_PetJournal.ClearSearchFilter        = function() end end
if not C_PetJournal.GetNumPetSources         then C_PetJournal.GetNumPetSources         = function() return 0 end end
if not C_PetJournal.IsPetSourceChecked       then C_PetJournal.IsPetSourceChecked       = function() return false end end
if not C_PetJournal.SetAllPetSourcesChecked  then C_PetJournal.SetAllPetSourcesChecked  = function() end end
if not C_PetJournal.GetNumPetTypes           then C_PetJournal.GetNumPetTypes           = function() return 0 end end
if not C_PetJournal.IsPetTypeChecked         then C_PetJournal.IsPetTypeChecked         = function() return false end end
if not C_PetJournal.SetAllPetTypesChecked    then C_PetJournal.SetAllPetTypesChecked    = function() end end
if not C_PetJournal.IsFilterChecked          then C_PetJournal.IsFilterChecked          = function() return false end end
if not C_PetJournal.SetFilterChecked         then C_PetJournal.SetFilterChecked         = function() end end
if not C_PetJournal.GetPetSortParameter      then C_PetJournal.GetPetSortParameter      = function() return 0 end end
if not C_PetJournal.SetPetSortParameter      then C_PetJournal.SetPetSortParameter      = function() end end
if not C_PetJournal.GetNumPets               then C_PetJournal.GetNumPets               = function() return 0 end end
if not C_PetJournal.GetPetInfoByIndex        then C_PetJournal.GetPetInfoByIndex        = function() return nil end end
if not C_PetJournal.SetPetTypeFilter         then C_PetJournal.SetPetTypeFilter         = function() end end
if not C_PetJournal.SetPetSourceChecked      then C_PetJournal.SetPetSourceChecked      = function() end end
if not C_PetJournal.GetPetInfoByPetID        then C_PetJournal.GetPetInfoByPetID        = function() return nil end end
if not C_PetJournal.GetPetStats              then C_PetJournal.GetPetStats              = function() return nil end end
if not C_PetJournal.IsCurrentlySummoned      then C_PetJournal.IsCurrentlySummoned      = function() return false end end
if not C_PetJournal.DismissSummonedPet       then C_PetJournal.DismissSummonedPet       = function() end end
if not C_PetJournal.SummonPetByGUID          then C_PetJournal.SummonPetByGUID          = function() end end
if not C_PetJournal.GetPetCooldownByGUID     then C_PetJournal.GetPetCooldownByGUID     = function() return 0, 0, 1 end end
if not C_PetJournal.GetSummonedPetGUID       then C_PetJournal.GetSummonedPetGUID       = function() return nil end end
if not C_PetJournal.PetIsSummonable          then C_PetJournal.PetIsSummonable          = function() return false end end
if not C_PetJournal.GetPetInfoBySpeciesID    then C_PetJournal.GetPetInfoBySpeciesID    = function() return nil end end
if not C_PetJournal.FindPetIDByName          then C_PetJournal.FindPetIDByName          = function() return nil end end

if not LE_PET_JOURNAL_FILTER_COLLECTED     then LE_PET_JOURNAL_FILTER_COLLECTED     = 1 end
if not LE_PET_JOURNAL_FILTER_NOT_COLLECTED then LE_PET_JOURNAL_FILTER_NOT_COLLECTED = 2 end
if not LE_SORT_BY_LEVEL                    then LE_SORT_BY_LEVEL                    = 0 end

if not C_ToyBox then C_ToyBox = {} end
if not C_ToyBox.SetFilterString              then C_ToyBox.SetFilterString              = function() end end
if not C_ToyBox.ForceToyRefilter             then C_ToyBox.ForceToyRefilter             = function() end end
if not C_ToyBox.GetNumFilteredToys           then C_ToyBox.GetNumFilteredToys           = function() return 0 end end
if not C_ToyBox.GetToyFromIndex              then C_ToyBox.GetToyFromIndex              = function() return 0 end end
if not C_ToyBox.GetCollectedShown            then C_ToyBox.GetCollectedShown            = function() return true end end
if not C_ToyBox.GetUncollectedShown          then C_ToyBox.GetUncollectedShown          = function() return false end end
if not C_ToyBox.IsSourceTypeFilterChecked    then C_ToyBox.IsSourceTypeFilterChecked    = function() return true end end
if not C_ToyBox.IsExpansionTypeFilterChecked then C_ToyBox.IsExpansionTypeFilterChecked = function() return true end end
if not C_ToyBox.SetCollectedShown            then C_ToyBox.SetCollectedShown            = function() end end
if not C_ToyBox.SetUncollectedShown          then C_ToyBox.SetUncollectedShown          = function() end end
if not C_ToyBox.SetAllSourceTypeFilters      then C_ToyBox.SetAllSourceTypeFilters      = function() end end
if not C_ToyBox.SetAllExpansionTypeFilters   then C_ToyBox.SetAllExpansionTypeFilters   = function() end end
if not C_ToyBox.SetSourceTypeFilter          then C_ToyBox.SetSourceTypeFilter          = function() end end
if not C_ToyBox.SetExpansionTypeFilter       then C_ToyBox.SetExpansionTypeFilter       = function() end end
if not C_ToyBox.GetToyInfo then
	C_ToyBox.GetToyInfo = function(iid)
		local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(iid)
		return nil, name, icon
	end
end
if not C_ToyBox.IsToyUsable then C_ToyBox.IsToyUsable = function() return true end end

if not C_MountJournal then C_MountJournal = {} end
if not C_MountJournal.GetMountIDs           then C_MountJournal.GetMountIDs           = function() return {} end end
if not C_MountJournal.GetMountInfoByID      then C_MountJournal.GetMountInfoByID      = function() return nil end end
if not C_MountJournal.GetMountInfoExtraByID then C_MountJournal.GetMountInfoExtraByID = function() return nil end end
if not C_MountJournal.SummonByID            then C_MountJournal.SummonByID            = function() end end
-- force nil so mount spells route through the spell handler (GetSpellInfo/GetSpellTexture) instead
C_MountJournal.GetMountFromSpell = function() return nil end

if not GetActionCharges   then GetActionCharges   = function() return nil end end
if not GetSpellCharges    then GetSpellCharges     = function() return nil end end
if not GetSpellCount      then GetSpellCount       = function() return 0 end end
if not IsSpellOverlayed   then IsSpellOverlayed    = function() return false end end

if not FindSpellBookSlotBySpellID then
	FindSpellBookSlotBySpellID = function(spellID)
		if type(spellID) ~= "number" or spellID == 0 then return nil end
		for tab = 1, GetNumSpellTabs() do
			local _, _, offset, count = GetSpellTabInfo(tab)
			for i = offset + 1, offset + count do
				local link = GetSpellLink(i, "spell")
				local sid = link and tonumber(link:match("|Hspell:(%d+)"))
				if sid == spellID then return i end
			end
		end
	end
end

if not DoesSpellExist     then DoesSpellExist     = function(name) return not not (GetSpellInfo(name)) end end
if not PlayerHasToy       then PlayerHasToy       = function() return true end end
if not GetNumExpansions   then GetNumExpansions    = function() return 0 end end

if not C_EquipmentSet then
	local function iterSets()
		return GetNumEquipmentSets and GetNumEquipmentSets() or 0
	end
	C_EquipmentSet = {
		GetEquipmentSetIDs = function()
			local ids = {}
			for i = 1, iterSets() do
				local _, _, id = GetEquipmentSetInfo(i)
				ids[i] = id
			end
			return ids
		end,
		GetEquipmentSetInfo = function(id)
			for i = 1, iterSets() do
				local name, icon, sid = GetEquipmentSetInfo(i)
				if sid == id then return name, icon end
			end
		end,
		GetEquipmentSetID = function(name)
			for i = 1, iterSets() do
				local n, _, id = GetEquipmentSetInfo(i)
				if n == name then return id end
			end
		end,
		UseEquipmentSet = function(id)
			if UseEquipmentSet then UseEquipmentSet(id) end
			return true
		end,
	}
end

if not C_Minimap then
	C_Minimap = {
		GetNumTrackingTypes = GetNumTrackingTypes,
		GetTrackingInfo = function(id)
			local name, tex, active = GetTrackingInfo(id)
			if not name then return nil end
			return {name = name, texture = tex, active = active, type = "", subType = "", spellID = 0}
		end,
		SetTracking = function(id, enable)
			if SetTracking then SetTracking(enable and id or 0) end
		end,
	}
end

if not C_TaskQuest   then C_TaskQuest   = {IsActive       = function() return false end} end
if not C_Scenario    then C_Scenario    = {IsInScenario   = function() return false end} end
if not C_KeyBindings then C_KeyBindings = {GetBindingByKey = GetBindingByKey or function() return nil end} end
if not C_Map         then C_Map         = {GetBestMapForUnit = function() return nil end} end

if not DoesTemplateExist then DoesTemplateExist = function() return false end end
if not IsMetaKeyDown     then IsMetaKeyDown     = function() return false end end

if not C_CurveUtil then
	C_CurveUtil = {EvaluateColorValueFromBoolean = function(b, v1, v2) return b and v1 or v2 end}
end

if not GetNumSpecializations then GetNumSpecializations = function() return 0 end end

if not SOUNDKIT then
	SOUNDKIT = setmetatable({
		IG_MAINMENU_OPTION_CHECKBOX_ON  = 599,
		IG_MAINMENU_OPTION_CHECKBOX_OFF = 600,
		IG_MAINMENU_OPEN                = 847,
		IG_MAINMENU_CLOSE               = 848,
		U_CHAT_SCROLL_BUTTON            = 1115,
		IG_CHARACTER_INFO_TAB           = 1196,
	}, {__index = function() return 0 end})
end

if RAID_CLASS_COLORS then
	for _, c in pairs(RAID_CLASS_COLORS) do
		if not c.colorStr and c.r then
			c.colorStr = string.format("ff%02x%02x%02x",
				math.floor(c.r * 255 + 0.5),
				math.floor(c.g * 255 + 0.5),
				math.floor(c.b * 255 + 0.5))
		end
	end
end

if not UnitClassBase then
	UnitClassBase = function(unit)
		local _, classFile = UnitClass(unit)
		return classFile, 0
	end
end

if not UnitFullName then
	UnitFullName = function(unit)
		local name = UnitName(unit)
		local realm = GetRealmName and GetRealmName() or ""
		return name, realm or ""
	end
end

if not strcmputf8i then
	strcmputf8i = function(a, b)
		local la, lb = (a or ""):lower(), (b or ""):lower()
		if la < lb then return -1 elseif la > lb then return 1 else return 0 end
	end
end

do
	local function copyFont(dst, src, sizeDelta)
		if src then
			local face, size = src:GetFont()
			dst:SetFont(face, (size or 12) + (sizeDelta or 0))
			dst:SetTextColor(src:GetTextColor())
		end
	end
	if not GameFontNormalLargeOutline then
		local f = CreateFont("GameFontNormalLargeOutline")
		local base = GameFontNormalLarge or GameFontNormal
		if base then
			local face, size = base:GetFont()
			f:SetFont(face, size or 12, "OUTLINE")
		end
	end
	if not GameFontNormalMed2      then copyFont(CreateFont("GameFontNormalMed2"),      GameFontNormal) end
	if not GameFontHighlightMed2   then copyFont(CreateFont("GameFontHighlightMed2"),   GameFontHighlight) end
	if not GameFontHighlightSmall2 then copyFont(CreateFont("GameFontHighlightSmall2"), GameFontHighlightSmall) end
	if not GameFont_Gigantic then
		copyFont(CreateFont("GameFont_Gigantic"), GameFontNormalHuge or GameFontNormalLarge, 0)
	end
end

GetAllIcons = function()
	local t, n = {}, GetNumMacroIcons and GetNumMacroIcons() or 0
	for i = 1, n do
		local icon = GetMacroIconInfo(i)
		if icon then t[#t+1] = icon end
	end
	return t
end
if not GetLooseMacroIcons      then GetLooseMacroIcons      = function() end end
if not GetMacroItemIcons       then GetMacroItemIcons       = function() end end
if not GetLooseMacroItemIcons  then GetLooseMacroItemIcons  = function() end end

if not GetMacroIcons then
	GetMacroIcons = function(into)
		local global, perChar = GetNumMacros()
		for i = 1, (global or 0) + (perChar or 0) do
			local _, iconID = GetMacroInfo(i)
			if iconID then into[#into + 1] = iconID end
		end
	end
end

if not GetSpellBookItemName then
	GetSpellBookItemName = function() return nil end
end
if not GetSpellBookItemInfo then
	GetSpellBookItemInfo = function(index, bookType)
		local name = GetSpellBookItemName(index, bookType)
		if not name then return nil end
		local _, _, _, _, _, _, id = GetSpellInfo(name)
		if id then return "SPELL", id end
	end
end

if not GetServerTime  then GetServerTime  = function() return time() end end
if not GetExtraBarIndex then GetExtraBarIndex = function() return 0 end end
if not OPTIONS        then OPTIONS        = "Options" end
if not REVERT         then REVERT         = "Revert" end

if not UIDropDownMenu_AddSeparator then
	UIDropDownMenu_AddSeparator = function(level)
		local info = UIDropDownMenu_CreateInfo()
		info.isTitle      = true
		info.text         = " "
		info.notClickable = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, level)
	end
end

if not UIDropDownMenu_SetDisplayMode then
	UIDropDownMenu_SetDisplayMode = function(frame, mode)
		frame.displayMode = mode
	end
end
