local _, T = ...
local XU = T.exUI
local GFX = ([[Interface\AddOns\%s\gfx\]]):format((...))
local assert, getWidgetData, newWidgetData, _setWidgetData, AddObjectMethods, CallObjectScript = XU:GetImpl()

local DropDown, DropDownData, internal = {}, {}, {}
local DropDownProps = {
	api = DropDown,
	scripts = {"OnHide"},
	pulseAnim = nil
}
AddObjectMethods({"DropDown"}, DropDownProps)

function DropDown:HandlesGlobalMouseEvent(button)
	return button == "LeftButton" and self:IsEnabled()
end
function DropDown:Pulse()
	local d = assert(getWidgetData(self, DropDownData), 'invalid object type')
	if not d.pulseAnim then
		local tex = d.bg
		local atl, l, sl = tex:GetAtlas(), tex:GetDrawLayer()
		local r = tex:GetParent():CreateTexture(nil, l, nil, (sl or 0) + 1)
		r:SetAllPoints(tex)
		r[atl and "SetAtlas" or "SetTexture"](r, atl or tex:GetTexture())
		r:SetTexCoord(tex:GetTexCoord())
		r:SetVertexColor(0, 0.5, 0.75, 0)
		r:SetBlendMode("ADD")
		r:SetTextureSliceMargins(tex:GetTextureSliceMargins())
		local ag = d.self:CreateAnimationGroup()
		ag:SetLooping("BOUNCE")
		ag:SetScript("OnLoop", internal.OnPulseLoop)
		local aa = ag:CreateAnimation("Alpha")
		aa:SetTarget(r)
		aa:SetDuration(1 / 3)
		aa:SetFromAlpha(1)
		aa:SetToAlpha(0)
		aa:SetSmoothing("IN_OUT")
		d.pulseAnim = ag
	end
	d.pulseCyclesLeft = 6
	d.pulseAnim:Restart(true)
end

function internal.OnPulseLoop(self, ls)
	local d = ls == "FORWARD" and getWidgetData(self:GetParent(), DropDownData)
	if not d then
		return
	end
	local cl = (d.pulseCyclesLeft or 1) - 1
	d.pulseCyclesLeft = cl > 0 and cl or nil
	if cl <= 0 then
		d.pulseAnim:Finish()
	end
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
	if d.pulseAnim and d.pulseAnim:IsPlaying() then
		d.pulseAnim:Stop()
	end
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
