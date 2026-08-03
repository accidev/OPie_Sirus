local _, T = ...

local suf, tn = 1
repeat
	tn, suf = "NotGameTooltip" .. suf, suf + 1
until _G[tn] == nil

-- External addons: please treat this as you would treat _G.GameTooltip
local tip = CreateFrame("GameTooltip", tn, UIParent, "GameTooltipTemplate")
tip.LIKE_GLOBAL_GAMETOOLTIP = true
tip.shoppingTooltips = tip.shoppingTooltips or GameTooltip.shoppingTooltips -- Classic.
tip:SetScript("OnUpdate", GameTooltip_OnUpdate)
T.NotGameTooltip = tip

do
	local function addTooltipShims(t)
		if not t.SetItemByID then
			function t:SetItemByID(iid)
				return self:SetHyperlink("item:" .. iid)
			end
		end
		if not t.SetMountBySpellID then
			function t:SetMountBySpellID(sid)
				return self:SetHyperlink("spell:" .. sid)
			end
		end
		if not t.SetSpellByID then
			function t:SetSpellByID(sid)
				return self:SetHyperlink("spell:" .. sid)
			end
		end
		if not t.SetToyByItemID then
			function t:SetToyByItemID(iid)
				return self:SetHyperlink("item:" .. iid)
			end
		end
		if not t.SetSpellBookItem then
			function t:SetSpellBookItem(slot, bookType)
				local link = GetSpellLink(slot, bookType or "spell")
				if link then
					return self:SetHyperlink(link)
				end
			end
		end
	end
	addTooltipShims(tip)
end

do
	local EV = T.Evie
	local adopted, pending = setmetatable({}, {
		__mode = "k"
	}), {}
	local function elvTooltipModule()
		local E = _G.ElvUI and _G.ElvUI[1]
		local p = E and E.initialized and E.private
		local bs = p and p.skins and p.skins.blizzard
		if not (p and p.tooltip and p.tooltip.enable and bs and bs.enable and bs.tooltip) then
			return
		end
		local TT = E.GetModule and E:GetModule("Tooltip", true)
		if TT and TT.SetStyle and TT.SecureHookScript then
			return TT
		end
	end
	local function adopt(tt)
		local TT = elvTooltipModule()
		if not TT then
			return false
		end
		if not adopted[tt] then
			adopted[tt] = true
			TT:SecureHookScript(tt, "OnShow", "SetStyle")
			if tt:IsShown() then
				TT:SetStyle(tt)
			end
		end
		return true
	end
	local function flush()
		for i = #pending, 1, -1 do
			if adopt(pending[i]) then
				table.remove(pending, i)
			end
		end
		return #pending == 0
	end
	function T.UseSharedTooltipSkin(tt)
		if tt and not adopted[tt] then
			pending[#pending + 1] = tt
			flush()
		end
	end
	local retriesLeft = 10
	local function retry()
		retriesLeft = retriesLeft - 1
		if flush() or retriesLeft <= 0 then
			return
		end
		EV.After(1, retry)
	end
	function EV.PLAYER_LOGIN()
		EV.After(0, retry)
		return "remove"
	end
	T.UseSharedTooltipSkin(tip)
end

do -- Avoid showing both at the same time
	local skipHide
	tip:SetScript("OnShow", function(self)
		skipHide = true
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		GameTooltip:SetText(" ")
		GameTooltip:Hide()
		-- GameTooltip's OnShow is deferred, so skipHide can't be cleared here
	end)
	local tw = CreateFrame("Frame", nil, GameTooltip)
	tw:SetScript("OnShow", function()
		if skipHide then
			skipHide = false
		else
			tip:Hide()
		end
	end)
end
