local MAJ, _, T = 1, ...
if T.SkipLocalActionBook then
	return
end

local EV, WR, AB, KR, RW = T.Evie, T.Ware, T.ActionBook:compatible(2, 36), T.ActionBook:compatible("Kindred", 1, 22),
	T.ActionBook:compatible("Rewire", 1, 31)
assert(EV and WR and AB and KR and RW and 1, "Incompatible library bundle")

local FM, core = {}, CreateFrame("Frame", nil, nil, "SecureHandlerBaseTemplate")
local cenvW, cenv = WR.GetRestrictedEnvironment(core)
cenvW.KR, cenvW.flags, cenvW.cargcache, cenvW.crm = KR:seclib(), WR.newtable, WR.newtable, 2 ^ 24
WR.newtable(cenvW, "crand", math.random(2 ^ 24) - 1)
cenvW.NO_FLAGS_MESSAGE = AB.L "No flags are active."
core:SetAttribute("RunSlashCmd", [=[-- flag-RunSlashCmd
	local slash, clause, target = ...
	local flag, nv
	if slash == "/dumpflag" and clause then
		local o, n,s,a = nil, pairs(flags)
		if clause:match("([^=<%s/,:]+)%s*") then
			n, s, a = clause:gmatch("([^=<%s/,:]+)%s*")
		end
		for k in n,s,a do
			local v = flags[k]
			local fv = v and "[flag:" .. k .. "=" .. v .. "]" or ("[noflag:" .. k .. "]")
			o = o and o .. " " .. fv or fv
		end
		print(o or NO_FLAGS_MESSAGE)
	elseif (clause or "") == "" then
	elseif slash == "/setflag" then
		local name, eq, v = clause:match("^%s*([^=<%s/,:]+)%s*(=?)%s*(.-)%s*$")
		if name then
			flag, nv = name:lower(), eq == "" and "1" or (v ~= "" and v ~= "0" and v:lower()) or nil
		end
	elseif slash == "/cycleflag" then
		local name, eq, top, step = clause:match("^%s*([^=<%s/,:]+)%s*([<=]?)%s*(%d*)%+?(%-?%d*)%s*$")
		if name and (top == "") == (eq == "")then
			flag, top, step = name:lower(), top ~= "" and 0+top or 2, step ~= "" and 0+step or 1
			nv = ((tonumber(flags[flag]) or 0) + step) % top
			nv = nv > 0 and nv .. "" or nil
		end
	elseif slash == "/randflag" then
		local name, top = clause:match("^%s*([^=<%s/,:]+)%s*<%s*(%d*)%s*$")
		if not name then return end
		nv, flag, top = 0, name:lower(), top ~= "" and 0+top or 2
		if top > 1 then
			local cr = crand[clause]
			local rv = ((cr or crand[1]) * 12616645 + 16777213) % crm
			if cr == nil then
				crand[1] = rv
			end
			crand[clause], nv = rv, rv % top
		end
		nv = nv ~= 0 and nv .. "" or nil
	end
	if flag ~= nil and flags[flag] ~= nv then
		flags[flag] = nv
		if KR then
			KR:RunAttribute("PokeConditional", "flag")
		end
	end
]=])
core:SetAttribute("EvaluateMacroConditional", [=[-- flag-EvaluateMacroConditional
	local name, cv, target = ...
	if name ~= "flag" or not cv then return end
	local ca, ni = cargcache[cv]
	if not ca then
		ca, ni = newtable(), 1
		for s in cv:gmatch("[^/]*") do
			local name, eq, v = s:match("^%s*([^=%s]+)%s*(=?)%s*(.-)%s*$")
			if name then
				name, v = name:lower(), v:lower()
				if eq == "=" then
					ca[ni], ca[ni+1], ni = name, v ~= "0" and v, ni + 2
				else
					ca[ni], ca[ni+1], ni = name, false, ni + 2
				end
			end
		end
		cargcache[cv] = ca
	end
	for i=1, #ca, 2 do
		local cv, dv = flags[ca[i]], ca[i+1]
		if cv == dv or (dv == false and cv) then
			return true
		end
	end
	return false
]=])

local flagHint, flagCommandHint, dumpFlags
do
	local currentFutureID
	local function newSpeculativeProxy(base)
		local ov, ot = {}, {}
		local function getValue(_, k)
			if currentFutureID and ot[k] == currentFutureID then
				return ov[k]
			end
			return base[k]
		end
		local function setValue(_, k, nv)
			if k ~= nil and currentFutureID then
				ov[k], ot[k] = nv, currentFutureID
			end
		end
		return setmetatable({}, {
			__index = getValue,
			__newindex = setValue
		})
	end
	local flagProxy, crandProxy = newSpeculativeProxy(cenv.flags), newSpeculativeProxy(cenv.crand)
	local flagHintI = loadstring(("local cargcache, flags, newtable = ... return function(...) %s end"):format(
		core:GetAttribute("EvaluateMacroConditional")))({}, flagProxy, function()
		return {}
	end)
	local runSlashI = loadstring(("local KR, self, flags, crand, crm = false, ... return function(...) %s end"):format(
		core:GetAttribute("RunSlashCmd")))(core, flagProxy, crandProxy, cenv.crm)

	function flagHint(...)
		local _;
		_, _, _, _, currentFutureID = ...
		return flagHintI(...)
	end
	function flagCommandHint(slash, _, args2, target, _, _, _, speculationID)
		currentFutureID = speculationID
		runSlashI(slash, args2, target)
	end
	function dumpFlags(clause)
		runSlashI("/dumpflag", clause, nil)
	end
end

local ownDumpCommand, ownDumpKey
do
	local suf = 1
	repeat
		ownDumpKey, suf = "ABFM_DUMP_FLAG_" .. suf .. "X", suf + 1
	until SlashCmdList[ownDumpKey] == nil
	ownDumpCommand = "/dumpflag" .. (suf - 1)
	_G["SLASH_" .. ownDumpKey .. "1"], _G["SLASH_" .. ownDumpKey .. "2"] = "/dumpflag", ownDumpCommand
	SlashCmdList[ownDumpKey] = function(msg)
		local cv = KR:EvaluateCmdOptions(msg)
		if cv then
			dumpFlags(cv)
		end
	end
end

local pendingRestoreState, DoRestoreState = nil
do
	local function RestoreFlags(flags)
		if type(flags) ~= "table" then
			return
		end
		local r = cenvW.flags
		for k, v in pairs(flags) do
			if type(k) == 'string' and type(v) == 'string' then
				r[k] = v
			end
		end
	end
	local function RestoreReVars(revars)
		if type(revars) ~= "table" then
			return
		end
		for k, v in pairs(revars) do
			if type(k) == 'string' and type(v) == 'string' then
				RW:SetMacroVarValue(k, v)
			end
		end
	end
	function DoRestoreState(state)
		pendingRestoreState = 0
		RestoreFlags(state.flags)
		RestoreReVars(state.revars)
	end
end

function FM:GetState()
	local rf, rv = {}, {}
	for f, v in rtable.pairs(cenv.flags) do
		rf[f] = v
	end
	for n, v in RW:AllMacroVars() do
		rv[n] = v ~= "" and v or nil
	end
	rf, rv = next(rf) ~= nil and rf or nil, next(rv) ~= nil and rv or nil
	return (rf or rv) and {
		flags = rf,
		revars = rv,
		at = GetServerTime()
	} or nil
end
function FM:RestoreState(state)
	if type(state) == "table" and pendingRestoreState == nil and
		(type(state.flags) == "table" or type(state.revars) == "table") then
		pendingRestoreState = state
		if InCombatLockdown() then
			EV.PLAYER_REGEN_ENABLED = function()
				DoRestoreState(pendingRestoreState)
				return "remove"
			end
		else
			DoRestoreState(state)
		end
	end
end
function FM:GetFlagDumpCommand()
	return ownDumpCommand
end

KR:SetSecureExternalConditional("flag", core, flagHint)
RW:RegisterCommand("/setflag", true, true, core)
RW:RegisterCommand("/cycleflag", true, true, core)
RW:RegisterCommand("/randflag", true, true, core)
RW:RegisterCommand("/dumpflag", true, true, core)
RW:AddCommandAliases("/dumpflag", ownDumpCommand)
RW:SetCommandHint("/setflag", math.huge, flagCommandHint)
RW:SetCommandHint("/cycleflag", math.huge, flagCommandHint)
RW:SetCommandHint("/randflag", math.huge, flagCommandHint)

function FM:compatible(maj)
	return MAJ == maj and FM or nil
end

AB:RegisterModule("FlagMast", FM)
