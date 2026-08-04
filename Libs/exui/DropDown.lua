local _, T = ...
local XU = T.exUI
local GFX = ([[Interface\AddOns\%s\gfx\]]):format((...))
local assert, getWidgetData, newWidgetData, _setWidgetData, AddObjectMethods, CallObjectScript = XU:GetImpl()

local DropDown, DropDownData, internal = {}, {}, {}
local DropDownProps = {
	api = DropDown,
	scripts = {"OnHide"},
	pulseTex = nil
}
AddObjectMethods({"DropDown"}, DropDownProps)

function DropDown:HandlesGlobalMouseEvent(button)
	local e = self:IsEnabled()
	return button == "LeftButton" and not not (e and e ~= 0)
end
function DropDown:Pulse()
	local d = assert(getWidgetData(self, DropDownData), 'invalid object type')
	if not d.pulseTex then
		local tex = d.bg
		local l, sl = tex:GetDrawLayer()
		local r = tex:GetParent():CreateTexture(nil, l, nil, (sl or 0) + 1)
		r:SetAllPoints(tex)
		r:SetTexture(tex:GetTexture())
		r:SetTexCoord(tex:GetTexCoord())
		r:SetVertexColor(0, 0.5, 0.75)
		r:SetBlendMode("ADD")
		r:Hide()
		d.pulseTex, d.pulseDriver = r, CreateFrame("Frame", nil, d.self)
		d.pulseDriver:Hide()
		d.pulseDriver:SetScript("OnUpdate", internal.OnPulseUpdate)
		d.pulseDriver.owner = d.self
	end
	d.pulseElapsed, d.pulseCyclesLeft = 0, 6
	d.pulseTex:SetAlpha(0)
	d.pulseTex:Show()
	d.pulseDriver:Show()
end
function internal.StopPulse(d)
	if d.pulseDriver then
		d.pulseDriver:Hide()
		d.pulseTex:Hide()
	end
end

local PULSE_PERIOD = 1 / 3
function internal.OnPulseUpdate(self, elapsed)
	local d = getWidgetData(self.owner, DropDownData)
	if not d or not d.pulseTex then
		return self:Hide()
	end
	local e = (d.pulseElapsed or 0) + elapsed
	while e >= PULSE_PERIOD do
		e = e - PULSE_PERIOD
		local cl = (d.pulseCyclesLeft or 1) - 1
		d.pulseCyclesLeft = cl
		if cl <= 0 then
			d.pulseElapsed = 0
			return internal.StopPulse(d)
		end
	end
	d.pulseElapsed = e
	local half = PULSE_PERIOD / 2
	local a = e < half and (e / half) or (2 - e / half)
	d.pulseTex:SetAlpha(a > 0 and (a < 1 and a or 1) or 0)
end
function internal.OnDropArrowClick(self)
	ToggleDropDownMenu(nil, nil, self, self, 8, 8)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end
function internal.OnDropHide(self, ...)
	local d = getWidgetData(self, DropDownData)
	if UIDROPDOWNMENU_OPEN_MENU == self and DropDownList1:IsVisible() then
		securecall(CloseDropDownMenus)
	end
	internal.StopPulse(d)
	CallObjectScript(d.self, "OnHide", ...)
end

local function prepArrowTexture(p, m, r, g, b)
	p["Set" .. m](p, GFX .. "chevron.tga")
	local tex = p["Get" .. m](p)
	tex:ClearAllPoints()
	tex:SetSize(12, 12)
	tex:SetPoint("RIGHT", -22, 3)
	tex:SetTexCoord(0, 1, 1, 0)
	tex:SetVertexColor(r, g, b)
	return tex
end
local function nop()
end
local nopTex = {
	SetWidth = nop,
	Hide = nop
}
local function CreateDropDown(name, parent, outerTemplate, id)
	local f, d, t = CreateFrame("Button", name, parent, outerTemplate, id)
	f:SetSize(120, 32)
	f:SetHitRectInsets(20, 18, 4, 8)
	f:SetText(" ")
	f:SetNormalFontObject(GameFontHighlightSmall)
	f:SetDisabledFontObject(GameFontDisableSmall)
	f:SetPushedTextOffset(0, 0)
	f:SetScript("OnHide", internal.OnDropHide)
	prepArrowTexture(f, "NormalTexture", 0.62, 0.65, 0.72)
	prepArrowTexture(f, "PushedTexture", 0.16, 0.66, 1.00)
	prepArrowTexture(f, "DisabledTexture", 0.34, 0.35, 0.39)
	prepArrowTexture(f, "HighlightTexture", 1, 1, 1)
	f:SetScript("OnClick", internal.OnDropArrowClick)
	t = f:CreateTexture(nil, "BACKGROUND", nil, -3)
	t:SetTexture(0.115, 0.125, 0.145, 1)
	t:SetPoint("TOPLEFT", 8, -1)
	t:SetPoint("BOTTOMRIGHT", -8, 7)
	for i = 1, 4 do
		local e = f:CreateTexture(nil, "BACKGROUND", nil, -2)
		e:SetTexture(0.21, 0.23, 0.27, 1)
		if i < 3 then
			e:SetHeight(1)
			e:SetPoint("LEFT", t, "LEFT")
			e:SetPoint("RIGHT", t, "RIGHT")
			e:SetPoint(i == 1 and "TOP" or "BOTTOM", t, i == 1 and "TOP" or "BOTTOM")
		else
			e:SetWidth(1)
			e:SetPoint("TOP", t, "TOP")
			e:SetPoint("BOTTOM", t, "BOTTOM")
			e:SetPoint(i == 3 and "LEFT" or "RIGHT", t, i == 3 and "LEFT" or "RIGHT")
		end
	end
	d = newWidgetData(f, DropDownData, DropDownProps)
	t, d.bg = f:GetFontString(), t
	t:ClearAllPoints()
	t:SetPoint("RIGHT", -43, 3)
	t:SetPoint("LEFT", 26, 3)
	t:SetJustifyH("RIGHT")
	t:SetWordWrap(false)
	f.Button, f.Text, f.Middle, f.Left, f.Right = f, t, nopTex, nopTex, nopTex
	return f
end

XU:RegisterFactory("DropDown", CreateDropDown)
