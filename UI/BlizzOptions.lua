local ADDON, T = ...
local L = T.L

local panel = CreateFrame("Frame", "OPieInterfaceOptions", InterfaceOptionsFramePanelContainer)
panel.name = "OPie"
panel:Hide()

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("|cff29a8ffOPie|r |cff8f939a" .. (GetAddOnMetadata(ADDON, "Version") or "") .. "|r")

local notes = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
notes:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
notes:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
notes:SetJustifyH("LEFT")
notes:SetJustifyV("TOP")
notes:SetTextColor(0.72, 0.75, 0.80)
notes:SetText(GetAddOnMetadata(ADDON, "Notes") or "")

local openButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
openButton:SetSize(170, 24)
openButton:SetPoint("TOPLEFT", notes, "BOTTOMLEFT", 0, -20)
openButton:SetText(L "Open OPie")
openButton:SetScript("OnClick", function()
	if InterfaceOptionsFrame:IsShown() then
		HideUIPanel(InterfaceOptionsFrame)
	end
	if T.ConfigHomePanel then
		T.ConfigHomePanel:OpenPanel()
	end
end)

local minimapToggle = CreateFrame("CheckButton", "$parentMinimapButton", panel, "InterfaceOptionsCheckButtonTemplate")
minimapToggle:SetPoint("TOPLEFT", openButton, "BOTTOMLEFT", 0, -14)
minimapToggle.Text:SetText(L "Show minimap icon")
minimapToggle:SetScript("OnClick", function(self)
	local show = self:GetChecked() and true or false
	PlaySound(show and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
	T.SetMinimapButtonShown(show)
end)

function panel.refresh()
	minimapToggle:SetChecked(T.IsMinimapButtonShown and T.IsMinimapButtonShown() or false)
end
function panel.default()
	if T.SetMinimapButtonShown then
		T.SetMinimapButtonShown(true)
	end
	panel.refresh()
end
panel:SetScript("OnShow", panel.refresh)

InterfaceOptions_AddCategory(panel)
