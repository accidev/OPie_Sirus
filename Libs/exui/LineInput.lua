local _, T = ...
local XU, type = T.exUI, type
local assert, getWidgetData, newWidgetData, _setWidgetData, AddObjectMethods, CallObjectScript = XU:GetImpl()

local FIELD_BG, FIELD_EDGE, FIELD_FOCUS = {0.075, 0.082, 0.096, 1}, {0.21, 0.23, 0.27, 1}, {0.16, 0.66, 1.00, 1}

local LineInput, LineInputData = {}, {}, {}
local LineInputProps = {
	api=LineInput,
	style='common',
	tipL=0, tipR=0, tipT=0, tipB = 0,
	scripts={"OnEditFocusGained", "OnEditFocusLost"},
}
AddObjectMethods({"LineInput"}, LineInputProps)

local function adjustPlaceholderVisibility(self)
	local d = assert(getWidgetData(self, LineInputData), 'invalid object type')
	local sup = d.proto.super
	d.phText:SetShown(not sup.HasFocus(self) and sup.GetText(self) == "")
end
local function paintFieldEdge(d, focused)
	local c = focused and FIELD_FOCUS or FIELD_EDGE
	for i=1,4 do
		d.edge[i]:SetTexture(c[1], c[2], c[3], c[4])
	end
end
function LineInput:SetStyle(style)
	local d = assert(getWidgetData(self, LineInputData), 'invalid object type')
	assert(style == nil or type(style) == 'string', 'Syntax: LineInput:SetStyle("style")')
	local vp = style == "common" and 0 or 3
	d.bg:ClearAllPoints()
	d.bg:SetPoint("TOPLEFT", -2, vp)
	d.bg:SetPoint("BOTTOMRIGHT", 2, -vp)
	d.style = style
	LineInput.SetTextInsets(self, d.tipL, d.tipR, d.tipT, d.tipB)
end
function LineInput:SetTextInsets(left, right, top, bottom)
	local d = assert(getWidgetData(self, LineInputData), 'invalid object type')
	left, right, top, bottom = tonumber(left or 0), tonumber(right or 0), tonumber(top or 0), tonumber(bottom or 0)
	assert(type(left) == 'number' and type(right) == 'number' and type(top) == 'number' and type(bottom) == 'number', 'Syntax: LineInput:SetTextInsets(left, right, top, bottom)')
	d.tipL, d.tipR, d.tipT, d.tipB = left, right, top, bottom
	local common = d.style == 'common'
	d.proto.super.SetTextInsets(self, left + (common and 0 or 2), right, top, bottom)
end
function LineInput:GetTextInsets()
	local d = assert(getWidgetData(self, LineInputData), 'invalid object type')
	return d.tipL, d.tipR, d.tipT, d.tipB
end
function LineInput:SetText(text)
	local d = assert(getWidgetData(self, LineInputData), 'invalid object type')
	local superSetText = d.proto.super.SetText
	superSetText(d.self, text == " " and "  " or " ")
	superSetText(d.self, text)
	d.text:SetText(text)
	adjustPlaceholderVisibility(self)
end
function LineInput:GetPlaceholderText()
	local d = assert(getWidgetData(self, LineInputData), 'invalid object type')
	return d.phText:GetText()
end
function LineInput:SetPlaceholderText(text)
	assert(type(text) == "string", 'Syntax: LineInput:SetPlaceholderText("text")')
	local d = assert(getWidgetData(self, LineInputData), 'invalid object type')
	d.phText:SetText(text)
end

local function findFontString(a, ...)
	if a and not a:IsObjectType("FontString") then
		return findFontString(...)
	end
	return a
end
local function onEditFocusGained(self, ...)
	adjustPlaceholderVisibility(self)
	paintFieldEdge(getWidgetData(self, LineInputData), true)
	return CallObjectScript(self, "OnEditFocusGained", ...)
end
local function onEditFocusLost(self, ...)
	adjustPlaceholderVisibility(self)
	paintFieldEdge(getWidgetData(self, LineInputData), false)
	self:HighlightText(0,0)
	return CallObjectScript(self, "OnEditFocusLost", ...)
end
local function CreateLineInput(name, parent, outerTemplate, id)
	local input, d, t = CreateFrame("EditBox", name, parent, outerTemplate, id)
	input:SetScript("OnEditFocusGained", onEditFocusGained)
	input:SetScript("OnEditFocusLost", onEditFocusLost)
	d = newWidgetData(input, LineInputData, LineInputProps)
	input:SetAutoFocus(false)
	input:SetSize(150, 20)
	input:SetFontObject(ChatFontNormal)
	t, d.text = input:CreateFontString(nil, "OVERLAY"), findFontString(input:GetRegions())
	t:SetFontObject(GameFontDisableSmall)
	t:SetTextColor(0.45, 0.46, 0.50)
	t:SetPoint("LEFT", 2, 0)
	t:SetPoint("RIGHT", -2, 0)
	t:SetJustifyH("LEFT")
	t:SetMaxLines(1)
	d.phText = t
	input:SetScript("OnEscapePressed", input.ClearFocus)
	d.bg = input:CreateTexture(nil, "BACKGROUND", nil, -3)
	d.bg:SetTexture(FIELD_BG[1], FIELD_BG[2], FIELD_BG[3], FIELD_BG[4])
	d.edge = {}
	for i=1,4 do
		local e = input:CreateTexture(nil, "BACKGROUND", nil, -2)
		d.edge[i] = e
		if i < 3 then
			e:SetHeight(1)
			e:SetPoint("LEFT", d.bg, "LEFT")
			e:SetPoint("RIGHT", d.bg, "RIGHT")
			e:SetPoint(i == 1 and "TOP" or "BOTTOM", d.bg, i == 1 and "TOP" or "BOTTOM")
		else
			e:SetWidth(1)
			e:SetPoint("TOP", d.bg, "TOP")
			e:SetPoint("BOTTOM", d.bg, "BOTTOM")
			e:SetPoint(i == 3 and "LEFT" or "RIGHT", d.bg, i == 3 and "LEFT" or "RIGHT")
		end
	end
	paintFieldEdge(d, false)
	LineInput.SetStyle(input, "common")
	return input
end

XU:RegisterFactory("LineInput", CreateLineInput)