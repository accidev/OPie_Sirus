local ADDON, T = ...
local H, PC, TS, config, L = {}, T.OPieCore, T.TenSettings, T.config, T.L
local SKIN = TS.SKIN
local GFX = ([[Interface\AddOns\%s\gfx\]]):format(ADDON)
local GameTooltip = T.NotGameTooltip or GameTooltip

local frame = TS:CreateOptionsPanel("OPie", nil, {
	forceRootVersion=true,
	selfBrandedRoot=true,
	tabText="|TInterface/Buttons/UI-HomeButton:14:16:0:-3|t " .. L"Overview"
})
frame.version:SetText(PC:GetVersion() or "")
T.ConfigHomePanel = frame

local navView = CreateFrame("Frame", nil, frame) do
	navView:SetPoint("TOPLEFT")
	navView:SetPoint("BOTTOMRIGHT")
	local function onNavClick(self)
		return H.HandleNavClick(self:GetID())
	end

	local oy = TS.PANEL_VIEW_MARGIN_TOP_TITLESHIFT + 4
	local t = navView:CreateFontString(nil, "OVERLAY", "GameFont_Gigantic")
	t:SetTextColor(1, 1, 1)
	t:SetText("OPie_Sirus")
	t:SetPoint("TOPLEFT", 16, oy)
	oy = oy - 34
	t = navView:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	t:SetTextColor(0.62, 0.65, 0.70)
	t:SetText(GetAddOnMetadata(ADDON, "Notes") or "")
	t:SetPoint("TOPLEFT", 18, oy)
	t:SetPoint("TOPRIGHT", -16, oy)
	t:SetJustifyH("LEFT")
	oy = oy - 26

	local function makeNav(id, title, text)
		local b = CreateFrame("Button", nil, navView, nil, id)
		b:SetPoint("TOPLEFT", 16, oy)
		b:SetPoint("TOPRIGHT", -16, oy)
		b:SetHeight(52)
		TS.Box(b, "BACKGROUND", nil, SKIN.header)
		TS.Outline(b, "BORDER", nil, SKIN.line)
		TS.Box(b, "HIGHLIGHT", nil, SKIN.hover)
		local bar = TS.Fill(b, "ARTWORK", nil, SKIN.accent)
		bar:SetWidth(3)
		bar:SetPoint("TOPLEFT")
		bar:SetPoint("BOTTOMLEFT")
		local ct = b:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		ct:SetPoint("TOPLEFT", 16, -9)
		ct:SetText(title)
		ct:SetJustifyH("LEFT")
		local cd = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		cd:SetTextColor(0.66, 0.69, 0.74)
		cd:SetPoint("TOPLEFT", ct, "BOTTOMLEFT", 0, -4)
		cd:SetPoint("RIGHT", b, "RIGHT", -30, 0)
		cd:SetText(text)
		cd:SetJustifyH("LEFT")
		local ar = b:CreateTexture(nil, "OVERLAY")
		ar:SetTexture("Interface/Glues/Common/Glue-RightArrow-Button-Up")
		ar:SetSize(22, 22)
		ar:SetPoint("RIGHT", -10, 0)
		ar:SetVertexColor(0.55, 0.58, 0.64)
		b:SetScript("OnEnter", function()
			ar:SetVertexColor(SKIN.accent[1], SKIN.accent[2], SKIN.accent[3])
		end)
		b:SetScript("OnLeave", function()
			ar:SetVertexColor(0.55, 0.58, 0.64)
		end)
		b:SetScript("OnClick", onNavClick)
		oy = oy - 60
	end

	makeNav(1, L"Options", L"Customize OPie's appearance and behavior.")
	makeNav(2, L"Ring Bindings", L"Customize OPie ring and in-ring key bindings.")
	makeNav(3, L"Custom Rings", L"Edit existing rings, or create your own custom OPie rings.")

	oy = oy - 6
	local ch = navView:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	ch:SetPoint("TOPLEFT", 26, oy)
	ch:SetText(L"Credits")
	local chBar = TS.Fill(navView, "ARTWORK", nil, SKIN.accent)
	chBar:SetSize(3, 14)
	chBar:SetPoint("RIGHT", ch, "LEFT", -7, -1)
	local chRule = TS.Fill(navView, "ARTWORK", nil, SKIN.line)
	chRule:SetHeight(1)
	chRule:SetPoint("TOPLEFT", ch, "TOPRIGHT", 10, -8)
	chRule:SetPoint("TOPRIGHT", navView, "TOPRIGHT", -16, oy - 8)
	oy = oy - 24

	local credits = CreateFrame("Frame", nil, navView)
	credits:SetPoint("TOPLEFT", 26, oy)
	credits:SetPoint("TOPRIGHT", -16, oy)
	credits:SetHeight(10)
	local cy = 0
	local function vh(text)
		local t = credits:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		t:SetPoint("TOPLEFT", 0, cy)
		t:SetText(text)
		t:SetJustifyH("LEFT")
		cy = cy - 18
	end
	local function li(text)
		local b = credits:CreateTexture(nil, "OVERLAY")
		b:SetSize(3, 3)
		b:SetPoint("TOPLEFT", 10, cy - 7)
		b:SetTexture(SKIN.accent[1], SKIN.accent[2], SKIN.accent[3], 1)
		local t = credits:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		t:SetTextColor(0.72, 0.75, 0.80)
		t:SetPoint("TOPLEFT", 20, cy)
		t:SetPoint("TOPRIGHT", 0, cy)
		t:SetJustifyH("LEFT")
		t:SetText(text)
		cy = cy - 17
	end
	securecall(T.CreditsData, vh, li)

	local urlBox = CreateFrame("EditBox", nil, navView) do
		urlBox:SetHeight(22)
		urlBox:SetPoint("BOTTOMLEFT", 106, 14)
		urlBox:SetPoint("BOTTOMRIGHT", -16, 14)
		urlBox:SetFontObject(GameFontHighlightSmall)
		urlBox:SetTextInsets(6, 6, 0, 0)
		urlBox:SetAutoFocus(false)
		TS.Box(urlBox, "BACKGROUND", nil, SKIN.btn)
		TS.Outline(urlBox, "BORDER", nil, SKIN.edge)
		urlBox:SetScript("OnTextChanged", function(self, userChanged)
			if userChanged and self.url then
				self:SetText(self.url)
				self:HighlightText()
			end
			self:SetCursorPosition(0)
		end)
		urlBox:SetScript("OnMouseUp", function(self) self:HighlightText() end)
		urlBox:SetScript("OnEscapePressed", urlBox.ClearFocus)
		urlBox:SetScript("OnEnterPressed", urlBox.ClearFocus)
	end

	local linkPrev
	local function makeLink(icon, url, title)
		local b = CreateFrame("Button", nil, navView)
		b:SetSize(32, 32)
		if linkPrev then
			b:SetPoint("LEFT", linkPrev, "RIGHT", 8, 0)
		else
			b:SetPoint("BOTTOMLEFT", 16, 9)
		end
		linkPrev = b
		local bg = TS.Box(b, "BACKGROUND", nil, SKIN.btn)
		local edge = TS.Outline(b, "BORDER", nil, SKIN.edge)
		local tex = b:CreateTexture(nil, "ARTWORK")
		tex:SetPoint("TOPLEFT", 3, -3)
		tex:SetPoint("BOTTOMRIGHT", -3, 3)
		tex:SetTexture(icon)
		local function activate()
			bg:SetTexture(SKIN.accentDim[1], SKIN.accentDim[2], SKIN.accentDim[3], SKIN.accentDim[4])
			for i=1,#edge do
				edge[i]:SetTexture(SKIN.accent[1], SKIN.accent[2], SKIN.accent[3], 1)
			end
			urlBox.url = url
			urlBox:SetText(url)
			urlBox:SetCursorPosition(0)
		end
		b:SetScript("OnEnter", function(self)
			activate()
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine(title)
			GameTooltip:AddLine(L"Copy the URL shown above and visit it using a web browser.", 1, 1, 1, true)
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", function()
			bg:SetTexture(SKIN.btn[1], SKIN.btn[2], SKIN.btn[3], SKIN.btn[4])
			for i=1,#edge do
				edge[i]:SetTexture(SKIN.edge[1], SKIN.edge[2], SKIN.edge[3], 1)
			end
			config.ui.HideTooltip(b)
		end)
		b:SetScript("OnClick", function()
			activate()
			urlBox:SetFocus()
			urlBox:HighlightText()
		end)
		return b
	end
	makeLink(GFX .. "discord.tga", "https://discord.gg/wRPF8CCpNV", L"Report an Issue")
	makeLink(GFX .. "boosty.tga", "https://boosty.to/accidev", L"Donate")
	urlBox.url = "https://discord.gg/wRPF8CCpNV"
	urlBox:SetText(urlBox.url)

	local svWarning = CreateFrame("Button", nil, navView) do
		svWarning:SetSize(300, 18)
		svWarning:SetPoint("BOTTOMLEFT", 18, 50)
		svWarning:SetNormalFontObject(GameFontRed)
		svWarning:SetHighlightFontObject(GameFontHighlight)
		svWarning:SetScript("OnClick", function() config.checkSVState(frame, true) end)
		svWarning:SetScript("OnShow", function()
			if config.checkSVState(frame) then
				svWarning:Hide()
			end
		end)
		svWarning:SetText("|TInterface/EncounterJournal/UI-EJ-WarningTextIcon:0|t " .. L"Any changes you make now will not be saved.")
		local fs = svWarning:GetFontString()
		fs:ClearAllPoints()
		fs:SetPoint("LEFT")
		svWarning:SetWidth(math.max(300, fs:GetStringWidth()))
	end
end

local navDialogs = {"ShowOptionsPanel", "ShowBindingsPanel", "ShowCustomRingsPanel"}

function H.HandleNavClick(id)
	return H[navDialogs[id]]()
end
function H.ShowOptionsPanel()
	T.ShowOPieOptionsPanel()
end
function H.ShowBindingsPanel()
	T.ShowRingBindingPanel()
end
function H.ShowCustomRingsPanel()
	T.ShowCustomRingsPanel()
end
