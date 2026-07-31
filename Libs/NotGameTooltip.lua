local _, T = ...

local suf, tn = 1 repeat
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
		-- SetItemByID: retail API; WotLK equivalent is SetHyperlink("item:id")
		if not t.SetItemByID then
			function t:SetItemByID(iid)
				return self:SetHyperlink("item:" .. iid)
			end
		end
		-- SetMountBySpellID: MoP+ API; show spell info as fallback in WotLK
		if not t.SetMountBySpellID then
			function t:SetMountBySpellID(sid)
				return self:SetHyperlink("spell:" .. sid)
			end
		end
		-- SetSpellByID: retail API; use hyperlink fallback
		if not t.SetSpellByID then
			function t:SetSpellByID(sid)
				return self:SetHyperlink("spell:" .. sid)
			end
		end
		-- SetToyByItemID: WoD+ API; treat as item in WotLK (no toys)
		if not t.SetToyByItemID then
			function t:SetToyByItemID(iid)
				return self:SetHyperlink("item:" .. iid)
			end
		end
		-- SetSpellBookItem: WotLK native on real GameTooltip; Sirus: GetSpellBookItemInfo broken,
		-- use GetSpellLink(slot, bookType) to get the link and show via SetHyperlink.
		if not t.SetSpellBookItem then
			function t:SetSpellBookItem(slot, bookType)
				local link = GetSpellLink(slot, bookType or "spell")
				if link then return self:SetHyperlink(link) end
			end
		end
		-- SetEquipmentSet: exists natively in WotLK 3.1+; shim for safety only
		-- SetAction: exists natively in WotLK; no shim needed
	end
	addTooltipShims(tip)
	addTooltipShims(GameTooltip)
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