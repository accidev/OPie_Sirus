local _, T = ...
if T.SkipLocalActionBook then return end

local EV, WR = T.Evie, T.Ware
local AB = T.ActionBook:compatible(2, 31)
local KR = T.ActionBook:compatible("Kindred", 1,33)
local RW = T.ActionBook:compatible("Rewire", 1,40)
assert(EV and WR and AB and KR and RW and 1, "Incompatible library bundle")
local playerClassLocal, playerClass = UnitClass("player")

local stringArgCache = {} do
	local empty = {}
	setmetatable(stringArgCache, {__index=function(t,k)
		if k then
			local at
			for s in k:gmatch("[^/]+") do
				s = s:match("^%s*(%S.-)%s*$")
				if s then
					at = at or {}
					at[#at + 1] = KR:UnescapeCmdOptionsValue(s)
				end
			end
			at = at or empty
			t[k] = at
			return at
		end
		return empty
	end})
end

securecall(function() -- zone:Zone/Sub Zone
	local function onZoneUpdate()
		local cz
		for i=1,4 do
			local z = (i == 1 and GetRealZoneText or i == 2 and GetSubZoneText or i == 3 and GetZoneText or GetMinimapZoneText)()
			if z and z ~= "" then
				cz = (cz and (cz .. "/") or "") .. z:gsub("%s*[,/%[%]][[,/%[%]]%s]*", " ")
			end
		end
		KR:SetStateConditionalValue("zone", cz or false)
	end
	onZoneUpdate()
	EV.ZONE_CHANGED = onZoneUpdate
	EV.ZONE_CHANGED_INDOORS = onZoneUpdate
	EV.ZONE_CHANGED_NEW_AREA = onZoneUpdate
	EV.PLAYER_ENTERING_WORLD = onZoneUpdate
end)
securecall(function() -- me:Player Name/Class
	KR:SetStateConditionalValue("me", UnitName("player") .. "/" .. playerClassLocal .. "/" .. playerClass)
end)
securecall(function() -- form:token
	local GetSpellName = GetSpellInfo
	local map, curCnd, pending =
		playerClass == "DRUID" and {
			[GetSpellName(40120) or 1]="/flight",
			[GetSpellName(33943) or 1]="/flight",
			[GetSpellName(1066) or 1]="/aquatic",
			[GetSpellName(783) or 1]="/travel",
			[GetSpellName(24858) or 1]="/moon/moonkin",
			[GetSpellName(768) or 1]="/cat",
			[GetSpellName(171745) or 1]="/cat",
			[GetSpellName(5487) or 1]="/bear",
			[GetSpellName(9634) or 1]="/bear",
			[GetSpellName(114282) or 1]="/treant",
			[GetSpellName(210053) or 1]="/stag",
		} or
		playerClass == "WARRIOR" and {
			[GetSpellName(197690) or 1]="/defensive",
			[GetSpellName(386164) or 1]="/battle",
			[GetSpellName(386196) or 1]="/berserker",
			[GetSpellName(386208) or 1]="/defensive",
			[GetSpellName(2457) or 1]="/battle",
			[GetSpellName(71) or 1]="/defensive",
			[GetSpellName(2458) or 1]="/berserker",
		}
	if map then
		KR:SetAliasConditional("stance", "form")
		local function syncForm()
			local GetSpellName, s = GetSpellInfo, ""
			for i=1,10 do
				local _, name = GetShapeshiftFormInfo(i)
				s = ("%s[form:%d] %d%s;"):format(s, i,i, map[name] or "")
			end
			if curCnd ~= s then
				KR:SetStateConditionalDriver("form", s, true)
			end
			curCnd, pending = s, nil
			return "remove"
		end
		EV.PLAYER_LOGIN = syncForm
		function EV.UPDATE_SHAPESHIFT_FORMS()
			if InCombatLockdown() then
				pending = pending or EV.RegisterEvent("PLAYER_REGEN_ENABLED", syncForm) or 1
			else
				syncForm()
			end
		end
	end
end)
securecall(function() -- instance:arena/bg/ratedbg/lfr/raid/scenario + outland/northrend/...
	local mapTypes = {
		party="dungeon", pvp="battleground/bg", ratedbg="ratedbg/rgb", none="world",
	}
	local function syncInstance()
		local _, itype, did = GetInstanceInfo()
		local stype = itype == "raid" and did == 7 and "/lfr"
		itype = mapTypes[itype] or itype or "daze"
		itype = stype and (itype .. stype) or itype
		KR:SetStateConditionalValue("in", itype)
	end
	EV.PLAYER_ENTERING_WORLD = syncInstance
	EV.ZONE_CHANGED_NEW_AREA = syncInstance
	KR:SetAliasConditional("instance", "in")
	KR:SetStateConditionalValue("in", "daze")
end)
securecall(function() -- petcontrol
	local hasControl = (playerClass ~= "HUNTER" and playerClass ~= "WARLOCK") or UnitLevel("player") >= 10
	KR:SetStateConditionalValue("petcontrol", hasControl)
	if not hasControl then
		function EV.PLAYER_LEVEL_UP(_, level)
			if level >= 10 then
				KR:SetStateConditionalValue("petcontrol", "*")
				return "remove"
			end
		end
	end
end)
securecall(function() -- outpost
	KR:SetStateConditionalValue("outpost", "")
end)
securecall(function() -- level:floor
	local function syncLevel()
		KR:SetThresholdConditionalValue("level", UnitLevel("player") or 0)
	end
	syncLevel()
	EV.PLAYER_LEVEL_UP = syncLevel
end)
securecall(function() -- horde/alliance
	local function syncFactionGroup(e, u)
		if e ~= "UNIT_FACTION" or u == "player" then
			local fg = UnitFactionGroup("player")
			KR:SetStateConditionalValue("horde", fg == "Horde" and "*" or "")
			KR:SetStateConditionalValue("alliance", fg == "Alliance" and "*" or "")
			KR:SetStateConditionalValue("merc", "")
		end
	end
	syncFactionGroup()
	EV.PLAYER_ENTERING_WORLD, EV.UNIT_FACTION = syncFactionGroup, syncFactionGroup
	KR:SetAliasConditional("mercenary", "merc")
end)
securecall(function() -- moving
	KR:SetNonSecureConditional("moving", function()
		return GetUnitSpeed("player") > 0
	end)
end)
securecall(function() -- falling
	KR:SetNonSecureConditional("falling", function()
		return IsFalling()
	end)
end)
securecall(function() -- ready:spell name/spell id/item name/item id
	KR:SetNonSecureConditional("ready", function(_name, args)
		local gcS, gcL = GetSpellCooldown(61304)
		if not args or args == "" then
			return (gcS == 0 and gcL == 0)
		end
		
		local at = stringArgCache[args]
		local gcE = gcS and gcL and (gcS + gcL) or math.huge
		for i=1,#at do
			local rc = at[i]
			local cdS, cdL, _cdA = GetSpellCooldown(rc)
			if cdL == nil then
				local _, iid = GetItemInfo(rc)
				iid = tonumber((iid or rc):match("item:(%d+)"))
				if iid then
					cdS, cdL, _cdA = GetItemCooldown(iid)
				end
			end
			if cdL == 0 or (cdS and cdL and (cdS + cdL) <= gcE) then
				return true
			end
		end
		
		return false
	end)
end)
securecall(function() -- have:item name/id
	KR:SetNonSecureConditional("have", function(_name, args)
		if not args or args == "" then
			return false
		end
		
		local at, GetItemCount = stringArgCache[args], GetItemCount
		for i=1,#at do
			if (GetItemCount(at[i]) or 0) > 0 then
				return true
			end
		end
		
		return false
	end)
end)
securecall(function() -- self(de)buff:name, own(de)buff:name, (de)buff:name, cleanse
	local conditionalFilter = {
		selfbuff="HELPFUL", selfdebuff="HARMFUL",
		ownbuff="HELPFUL PLAYER", owndebuff="HARMFUL PLAYER",
		buff="HELPFUL", debuff="HARMFUL",
	}
	local function checkAura(name, args, target)
		target = (name == "selfbuff" or name == "selfdebuff") and "player" or target or "target"
		if not args or args == "" or not UnitExists(target) then
			return false
		end
		local at, filter = stringArgCache[args], conditionalFilter[name]
		for i=1, 100 do
			local an = UnitAura(target, i, filter)
			if not an then
				return false
			end
			for j=1, #at do
				if strcmputf8i(an, at[j]) == 0 then
					return true
				end
			end
		end
		return false
	end
	KR:SetNonSecureConditional("selfbuff", checkAura)
	KR:SetNonSecureConditional("selfdebuff", checkAura)
	KR:SetNonSecureConditional("debuff", checkAura)
	KR:SetNonSecureConditional("owndebuff", checkAura)
	KR:SetNonSecureConditional("buff", checkAura)
	KR:SetNonSecureConditional("ownbuff", checkAura)
	KR:SetNonSecureConditional("cleanse", function(_, _, target)
		target = target or "target"
		return UnitIsFriend("player", target) and UnitAura(target, 1, "HARMFUL RAID") ~= nil
	end)
end)
securecall(function() -- combo:count
	local power, powerMap = 4, {[265]=7, [267]=14, [258]=13, PALADIN=9, MONK=12}
	local defaultPower = powerMap[playerClass] or 4
	KR:SetNonSecureConditional("combo", function(_name, args)
		local pow = power == 4 and GetComboPoints("player", "target") or UnitPower("player", power)
		return pow >= (tonumber(args) or 1)
	end)
	local function syncComboPower()
		power = defaultPower
	end
	EV.ACTIVE_TALENT_GROUP_CHANGED, EV.PLAYER_ENTERING_WORLD = syncComboPower, syncComboPower
end)
securecall(function() -- near:oid/cid
	local argCache, nearValue, nearGroup, holdGroup, holdExpire = {}
	local GROUP_HOLD_TIME = {["tww-herb-overload"]=5, ["tww-mine-overload"]=5, ["mid-herb-overload"]=5, ["mid-mine-overload"]=5}
	local typePrefix, groups = {GameObject="o", Creature="c"}, {}
	for k, v in pairs({
		["herb-overload"] = "o375245/o381199/o381213/o356536/o381202/o381210/o381196/o381205/o375242/o375244/o381214/o381201/o381200/o381212/o375246/o381198/o381203/o381197/o381211/o375243/o381204/o390141/o390140/o390142/o390139/o398761/o398760/o398759/o398762/o398767/o398764/o398765/o398766/o407696/o407688/o407698/o407693",
		["mine-overload"] = "o381516/o375235/o375234/o381515/o381517/o375238/o375239/o381518/o381519/o375240/o390137/o390138/o407669/o407668",
		["tww-herb-overload"] = "o414327/o414329/o414326/o414328/o414325/o414337/o414339/o454053/o454008/o414338/o454084/o414336/o414335/o454066/o454079/o454069/o454074/o423363/o454082/o454067/o423368/o454077/o423364/o423366/o423367/o454072/o454064/o454006/o454050/o414332/o414331/o414330",
		["tww-mine-overload"] = "o413886/o413895/o413905/o430351/o430335/o430352/o413900/o413883/o413890/o413902/o413892/o413884",
		["mid-herb-overload"] = "o516967/o516966/o516965/o516964/o516963//o516979/o516980/o516981/o516982/o516983//o516973/o516974/o516975/o516976/o516977//o516968/o516969/o516970/o516971/o516972",
		["mid-mine-overload"] = "o523284/o523294/o523303//o523287/o523293/o523301//o523285/o523291/o523299//o523286/o523292/o523300",
	}) do
		for e in v:gmatch("[^/]+") do
			groups[e] = k
		end
	end
	local function checkNearHoldExpire()
		if holdGroup and holdExpire < GetTime() then
			holdGroup, holdExpire = nil
			KR:PokeConditional("near")
		end
	end
	KR:SetNonSecureConditional("near", function(_name, args)
		checkNearHoldExpire()
		if args == nil then
			return nearValue ~= nil
		end
		local ca = argCache[args]
		if ca == nil then
			ca = {}
			for v in args:gmatch("[^%s/][^/]*") do
				ca[v:match("^(.-)%s*$")] = 1
			end
			argCache[args] = ca
		end
		return (ca[nearValue] or ca[nearGroup] or ca[holdGroup]) ~= nil
	end)
	function EV:PLAYER_SOFT_INTERACT_CHANGED(_, guid)
		local ct, oid
		if guid and not InCombatLockdown() then
			ct, oid = guid:match("^(%a+)%-[-%d]+%-(%d+)%-[^-]+$")
			ct = typePrefix[ct]
			oid = ct and ct .. oid or nil
		end
		if oid ~= nearValue then
			local ht = not oid and GROUP_HOLD_TIME[nearGroup]
			if ht then
				holdGroup, holdExpire = nearGroup, GetTime() + ht
				EV.After(ht+1/128, checkNearHoldExpire)
			elseif oid then
				holdGroup, holdExpire = nil
			end
			nearValue, nearGroup = oid, groups[oid]
			KR:PokeConditional("near")
		end
	end
end)
securecall(function() -- race:token
	local map, _, raceToken = {
		Scourge="Scourge/Undead/Forsaken",
	}, UnitRace("player")
	KR:SetStateConditionalValue("race", map[raceToken] or raceToken)
end)
securecall(function() -- professions
	local ct, ot, syncProfInner = {}, {}
	local GetSpellName = GetSpellInfo
	local map = {
		[GetSpellName(3908) or ""]="tail",
		[GetSpellName(2108) or ""]="lw",
		[GetSpellName(2018) or ""]="bs",
		[GetSpellName(2259) or ""]="alch",
		[GetSpellName(4036) or ""]="engi",
		[GetSpellName(7411) or ""]="ench",
		[GetSpellName(2366) or ""]="herb",
		[GetSpellName(2575) or ""]="mine",
		[GetSpellName(8613) or ""]="skin",
		[GetSpellName(2550) or ""]="cook",
		[GetSpellName(3273) or ""]="faid",
		[GetSpellName(7620) or ""]="fish",
		[GetSpellName(20221) or ""]="gobeng",
		[GetSpellName(20222) or ""]="gobeng",
		[GetSpellName(20220) or ""]="nomeng",
		[GetSpellName(20219) or ""]="nomeng",
	}
	local spellIDProfs = {
		[264636]="cook3",
		[264620]="tail3", [264626]="tail6",
		[271662]="fish5",
		[264588]="lw6", [264590]="lw7",
		[264479]="eng2", [264481]="eng3", [264483]="eng4", [264485]="eng5", [264488]="eng6", [264490]="eng7", [310542]="eng9",
		-- eng8 is in sync code, because factions
	}
	map[""]=nil
	syncProfInner = function()
		local idx, wasCollapsed
		for i=1,GetNumSkillLines() do
			local text, isHeader, isExpanded = GetSkillLineInfo(i)
			if isHeader and text == TRADE_SKILLS then
				idx, wasCollapsed = i, not isExpanded
				ExpandSkillHeader(i)
				break
			end
		end
		if not idx then return end
		local j, text, isHeader, _, curSkill = idx+1
		repeat
			j, text, isHeader, _, curSkill = j+1, GetSkillLineInfo(j)
			local skey = map[text]
			if skey and not isHeader then
				ct[skey] = curSkill
			end
		until isHeader or not text
		if wasCollapsed then
			CollapseSkillHeader(idx)
		end
	end
	local function syncProf()
		ct, ot = ot, ct
		for k in pairs(ct) do ct[k] = nil end
		syncProfInner()
		for sid, cnd in pairs(spellIDProfs) do
			ct[cnd] = GetSpellInfo(GetSpellInfo(sid) or "\1") and 1 or nil
		end
		ct["eng8"] = GetSpellInfo(GetSpellInfo(UnitFactionGroup("player") == "Horde" and 265807 or 264492) or "\1") and 1 or nil
		for k,v in pairs(ct) do
			if ot[k] ~= v then
				KR:SetThresholdConditionalValue(k, v)
				ot[k] = v
			end
		end
		for k,v in pairs(ot) do
			if ct[k] ~= v then
				KR:SetThresholdConditionalValue(k, false)
				ot[k] = nil
			end
		end
	end
	for _, v in pairs(map) do
		KR:SetThresholdConditionalValue(v, false)
	end
	for _, v in pairs(spellIDProfs) do
		KR:SetThresholdConditionalValue(v, false)
	end
	for alias, real in ("tailoring:tail leatherworking:lw alchemy:alch engineering:engi enchanting:ench jewelcrafting:jc blacksmithing:bs inscription:scri herbalism:herb archaeology:arch cooking:cook fishing:fish firstaid:faid mining:mine skinning:skin"):gmatch("(%a+):(%a+)") do
		KR:SetAliasConditional(alias, real)
	end
	EV.PLAYER_LOGIN, EV.CHAT_MSG_SKILL = syncProf, syncProf
end)
securecall(function() -- pet:stable id; havepet:stable id
	if playerClass ~= "HUNTER" then
		KR:SetStateConditionalValue("havepet", false)
		return
	end
	local pt, noPendingSync = {}, true
	local specTokenSuf = {}
	local function syncPet(e)
		if InCombatLockdown() then
			if noPendingSync then
				EV.PLAYER_REGEN_ENABLED, noPendingSync = syncPet, false
			end
			return
		end
		for k in pairs(pt) do pt[k] = nil end
		local o, hpo
		for i=1,NUM_PET_STABLE_SLOTS or 5 do
			local _, n, _, r, spN, spID = GetStablePetInfo(i)
			if n and r then
				local stk = specTokenSuf[spID or spN]
				local k = n == r and n or (n .. "/" .. r)
				pt[k] = (pt[k] or ("[pet:" .. n .. (n ~= r and ",pet:" .. r .. "] " or "] ") .. k)) .. "/" .. i .. (stk or "")
				hpo = (hpo and hpo .. "/" .. i or i)
			end
		end
		for k, v in pairs(pt) do
			o = k:match("/") and (v .. (o and "; " .. o or "")) or ((o and o .. "; " or "") .. v)
		end
		KR:SetStateConditionalDriver("pet","[nopet]; " .. (o and o .. "; 0" or " 0"), true)
		KR:SetStateConditionalValue("havepet", tostring(hpo or ""))
		noPendingSync = true
		return (e == "PLAYER_LOGIN" or e == "PLAYER_REGEN_ENABLED") and "remove"
	end
	KR:SetStateConditionalValue("havepet", false)
	EV.PLAYER_LOGIN, EV.PET_STABLE_UPDATE, EV.LOCALPLAYER_PET_RENAMED = syncPet, syncPet, syncPet
end)
securecall(function() -- game:wrath
	KR:SetStateConditionalValue("game", "daze")
	function EV.PLAYER_LOGIN()
		KR:SetStateConditionalValue("game", "wrath")
		return "remove"
	end
end)
securecall(function() -- visual
	local f = CreateFrame("Frame", nil, nil, "SecureFrameTemplate")
	f:SetAttribute("EvaluateMacroConditional", 'return false')
	KR:SetSecureExternalConditional("visual", f, function() return true end)
end)
securecall(function() -- coven:kyrian/venthyr/fae/necro
	KR:SetStateConditionalValue("coven", false)
	KR:SetStateConditionalValue("acoven80", false)
	KR:SetAliasConditional("covenant", "coven")
	KR:SetAliasConditional("acovenant80", "acoven80")
end)
securecall(function() -- worldhover
	KR:SetStateConditionalValue("worldhover", false)
end)
securecall(function() -- imbuedmh, imbuedoh, imbuedrw
	KR:SetStateConditionalValue("imbuedmh", false)
	KR:SetStateConditionalValue("imbuedoh", false)
	KR:SetNonSecureConditional("imbuedmh", function()
		return not not GetWeaponEnchantInfo()
	end)
	KR:SetNonSecureConditional("imbuedoh", function()
		return not not select(4, GetWeaponEnchantInfo())
	end)
	KR:SetStateConditionalValue("imbuedrw", false)
end)
securecall(function() -- bar:id (future-aware)
	local CMD_SWAP, CMD_SET, NUM_PAGES = SLASH_SWAPACTIONBAR1, SLASH_CHANGEACTIONBAR1, NUM_ACTIONBAR_PAGES
	local argCache = {}
	local f = CreateFrame("Button", nil, nil, "SecureActionButtonTemplate")
	local re = WR.GetRestrictedEnvironment(f)
	f:SetAttribute("type", "actionbar")
	f:SetAttribute("useOnKeyDown", false)
	re.argCache = WR.newtable
	re.CMD_SWAP, re.NUM_PAGES = CMD_SWAP, NUM_PAGES
	re.RW, re.KR = RW:seclib(), KR:seclib()
	f:SetAttribute("RunSlashCmd", [=[-- AB_bar_runslash
		local setTo, cmd, v = nil, ...
		if cmd == CMD_SWAP then
			local a, b = v:match("(%d+)%s+(%d+)")
			a, b = tonumber(a), tonumber(b)
			if a and b and a >= 1 and b >= 1 and a <= NUM_PAGES and b <= NUM_PAGES then
				setTo = KR:RunAttribute("EvaluateCmdOptions", "[bar:" .. a .. "]") and b or a
			end
		else
			local a = tonumber(v)
			if a and a >= 1 and a <= NUM_PAGES then
				setTo = a
			end
		end
		if setTo then
			pendingValue, pendingRunID = setTo, RW:GetAttribute("PyrolysisRunID")
			return cmd .. " " .. v, "notified-click", setTo
		end
	]=])
	f:SetAttribute("RunSlashCmd-PreClick", [[-- AB_bar_runslash_pre
		local cmd, v = ...
		pendingValue, pendingRunID = nil
		self:SetAttribute("action", v)
	]])
	f:SetAttribute("EvaluateMacroConditional", [=[-- AB_bar_evalmc
		local name, cv, target, _mark, futureID = ...
		if name ~= "bar" or not cv or cv == "" then return end
		if futureID == "driver-construct" then
			return nil, "use-scop"
		elseif not pendingRunID or RW:GetAttribute("PyrolysisRunID") ~= pendingRunID then
			pendingValue, pendingRunID = nil
			return nil, "use-scop"
		end
		local am = argCache[cv]
		if am == nil then
			am = newtable()
			for d in cv:gmatch("%s*(%d*)[^/]*/*") do
				am[d ~= "" and d+0 or 0] = true
			end
			argCache[cv], am[0] = am, nil
		end
		return am[pendingValue] ~= nil
	]=])

	local currentFutureID, currentBarState
	local function hintBarCommand(slash, _unparsed, clause, _target, _, _, _, speculationID)
		if (clause or "") == "" then return end
		if slash == CMD_SWAP then
			local a, b = clause:match("(%d+)%s+(%d+)")
			a, b = tonumber(a), tonumber(b)
			if a and b and a >= 1 and b >= 1 and a <= NUM_PAGES and b <= NUM_PAGES then
				if currentFutureID ~= speculationID then
					currentFutureID, currentBarState = speculationID, GetActionBarPage()
				end
				currentBarState = currentBarState == a and b or a
			end
		else
			local a = tonumber(clause)
			if a and a >= 1 and a <= NUM_PAGES then
				currentFutureID, currentBarState = speculationID, a
			end
		end
	end
	local function hintBarCondition(_name, cv, _target, _, futureID)
		if not cv or cv == "" then
			return false
		end
		local am = argCache[cv]
		if am == nil then
			am = {}
			for d in cv:gmatch("%s*(%d*)[^/]*/*") do
				am[d ~= "" and d+0 or 0] = true
			end
			am[0] = nil
			argCache[cv] = next(am) and am or false
		end
		return am and am[futureID == currentFutureID and currentBarState or GetActionBarPage()] or false
	end
	if RW:IsPyrolysisActive() and type(CMD_SET) == "string" and RW:GetCommandFlags(CMD_SET) then
		RW:RegisterCommandEx(CMD_SET, RW:GetCommandFlags(CMD_SET), f)
	end
	if RW:IsPyrolysisActive() and type(CMD_SWAP) == "string" and RW:GetCommandFlags(CMD_SWAP) then
		RW:RegisterCommandEx(CMD_SWAP, RW:GetCommandFlags(CMD_SWAP), f)
	end
	if type(CMD_SET) == "string" then RW:SetCommandHint(CMD_SET, math.huge, hintBarCommand) end
	if type(CMD_SWAP) == "string" then RW:SetCommandHint(CMD_SWAP, math.huge, hintBarCommand) end
	KR:SetSecureExternalConditional("bar", f, hintBarCondition)
end)
securecall(function() -- anyflyable
	KR:SetStateConditionalValue("blockedflyable", false)
	KR:SetStateConditionalValue("superflyable", false)
	KR:SetStateConditionalDriver("anyflyable", "[flyable] *;", false)
end)
KR:SetStateConditionalValue("holiday", false)
securecall(function() -- uslot:(slot token)
	KR:SetStateConditionalValue("uslot", false)
	local state, noPendingSync, slots = "", 1, {}
	for tk, sk in pairs({
		head="HEADSLOT", neck="NECKSLOT", shoulders="SHOULDERSLOT", shirt="SHIRTSLOT", chest="CHESTSLOT",
		waist="WAISTSLOT", legs="LEGSSLOT", feet="FEETSLOT", wrist="WRISTSLOT", hands="HANDSSLOT",
		finger1="FINGER0SLOT", finger2="FINGER1SLOT", trinket1="TRINKET0SLOT", trinket2="TRINKET1SLOT",
		back="BACKSLOT", tabard="TABARDSLOT",
	}) do
		local ok, slot = pcall(GetInventorySlotInfo, sk)
		slots[tk] = ok and slot or nil
	end
	local function syncActiveSlots()
		if InCombatLockdown() then
			return
		end
		local GetItemSpell, o = GetItemSpell
		for token, i in next, slots do
			local link, _, sid = token and (GetInventoryItemLink("player", i) or GetInventoryItemID("player", i))
			if link then
				_, sid = GetItemSpell(link)
			end
			if sid and not IsPassiveSpell(sid) then
				o = o and (o .. "/" .. token) or token
			end
		end
		o, noPendingSync = o or "", 1
		if state ~= o then
			state = o
			KR:SetStateConditionalValue("uslot", o)
		end
	end
	local function syncActiveSlotsIfPending()
		if not noPendingSync then
			syncActiveSlots()
		end
	end
	local function cueActiveSlotsSync(e)
		if noPendingSync and not InCombatLockdown() then
			EV.After(0, syncActiveSlots)
		end
		noPendingSync = nil
		return e ~= "PLAYER_EQUIPMENT_CHANGED" and "remove"
	end
	EV.PLAYER_REGEN_DISABLED = syncActiveSlotsIfPending
	EV.PLAYER_REGEN_ENABLED = syncActiveSlotsIfPending
	EV.PLAYER_EQUIPMENT_CHANGED = cueActiveSlotsSync
	EV.PLAYER_ENTERING_WORLD = cueActiveSlotsSync
end)
securecall(function() -- encount:(e-{id}/token)
	KR:SetStateConditionalValue("encount", false)
	KR:SetAliasConditional("encounter", "encount")
	local CV_ENCOUNT_STATE, state, enTokens = "actionbook-encount-state", nil, {
		[3135]="dimensius/ff-mount",
		[2837]="shadowcrown/ff-mount",
		[2839]="rashanan/ff-mount",
	}
	local function setEncounterState(newstate)
		state = newstate
		KR:SetStateConditionalValue("encount", state)
		SetCVar(CV_ENCOUNT_STATE, state or "")
	end
	function EV:ENCOUNTER_START(eid)
		if eid and not InCombatLockdown() then
			setEncounterState(enTokens[eid] and enTokens[eid] .. "/e-" .. eid or ("e-" .. eid))
		end
	end
	function EV:PLAYER_REGEN_ENABLED()
		if state then
			setEncounterState(false)
		end
	end
	function EV:PLAYER_ENTERING_WORLD(_, isReload)
		local s2 = isReload and GetCVar(CV_ENCOUNT_STATE) or ""
		if not InCombatLockdown() and s2 ~= "" and not state then
			setEncounterState(s2)
		else
			RegisterCVar(CV_ENCOUNT_STATE, "")
		end
		return "remove"
	end
end)

securecall(function() -- myth:token
	KR:SetStateConditionalValue("myth", false)
end)
securecall(function() -- prey:qid
	KR:SetStateConditionalValue("prey", false)
end)

securecall(function() -- Managed role units
	local mh = CreateFrame("Frame", nil, nil, "SecureFrameTemplate")
	SecureHandlerSetFrameRef(mh, "KR", KR:seclib())
	SecureHandlerExecute(mh, [=[-- MRU_Init_Manager
		KR, uf, ul, spare = self:GetFrameRef("KR"), newtable(), newtable(), newtable()
		self:SetAttribute("frameref-KR", nil)
	]=])
	local syncUnits = [==[-- MRU_Sync
		local nl, key, nj, fa = spare, %q, 1
		ul[key], spare, fa = nl, ul[key], uf[key]
		for i=1,40 do
			local u = fa[i]:GetAttribute("unit")
			if u then
				nl[i] = u
			else
				for j=i,#nl do
					nl[j] = nil
				end
				break
			end
		end
		for i=1,#nl do
			local u = nl[i]
			if u ~= playerUnit then
				KR:RunAttribute("SetAliasUnit", key .. nj, u)
				nj = nj + 1
			end
		end
		for i=nj,#spare do
			KR:RunAttribute("SetAliasUnit", key .. i, "raid42")
		end
		self:Show()
	]==]
	local function SpawnHeader(key, ...)
		local h = CreateFrame("Frame", nil, nil, "SecureGroupHeaderTemplate")
		for i=1,40 do
			local c = CreateFrame("Frame", nil, h, "SecureFrameTemplate")
			h:SetAttribute("child" .. i, c)
			SecureHandlerSetFrameRef(mh, "u" .. i, c)
			KR:SetAliasUnit(key .. i, "raid42")
		end
		SecureHandlerExecute(mh, ([[-- MRU_SpawnHeader_Init
			local a, k = newtable(), %q
			for i=1,40 do
				a[i] = self:GetFrameRef("u" .. i)
				self:SetAttribute("frameref-u" .. i, nil)
			end
			uf[k], ul[k] = a, newtable()
		]]):format(key))
		local cu = CreateFrame("Frame", nil, h, "SecureFrameTemplate")
		SecureHandlerWrapScript(cu, "OnHide", mh, syncUnits:format(key))
		h:SetAttribute("child41", cu)
		h:SetAttribute("template", "ImpossibleFrameTemplate")
		h:SetAttribute("templateType", "Frame")
		h:SetAttribute("showRaid", true)
		h:SetAttribute("showParty", true)
		h:SetAttribute("showPlayer", false)
		h:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
		h:SetAttribute("sortMethod", "NAME")
		for i=1, select("#", ...), 2 do
			local k, v = select(i, ...)
			h:SetAttribute(k, v)
		end
		return h
	end
	local ph = CreateFrame("Frame", nil, nil, "SecureGroupHeaderTemplate") do
		local c = CreateFrame("Frame", nil, ph, "SecureFrameTemplate")
		ph:SetAttribute("child1", c)
		SecureHandlerWrapScript(c, "OnAttributeChanged", mh, [=[-- MRU_Player_Change
			if name ~= "unit" or value == playerUnit then return end
			playerUnit = value
			for key, v in pairs(ul) do
				local nj = 1
				for i=1,#v do
					local u = v[i]
					if u ~= playerUnit then
						KR:RunAttribute("SetAliasUnit", key .. nj, u)
						nj = nj + 1
					end
				end
				KR:RunAttribute("SetAliasUnit", key .. nj, "raid42")
			end
		]=])
		ph:SetAttribute("showRaid", true)
		ph:SetAttribute("showParty", false)
		ph:SetAttribute("showPlayer", false)
		ph:SetAttribute("nameList", (UnitName("player")))
		ph:Show()
	end
	SpawnHeader("tank", "roleFilter","TANK"):Show()
	SpawnHeader("mtank", "roleFilter","MAINTANK"):Show()
	SpawnHeader("assist", "roleFilter","MAINASSIST"):Show()
	SpawnHeader("healer", "roleFilter","HEALER"):Show()
	SpawnHeader("dps", "roleFilter","DAMAGER"):Show()
end)