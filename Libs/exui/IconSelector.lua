local _, T = ...
local XU, type = T.exUI, type
local assert, getWidgetData, newWidgetData, setWidgetData, AddObjectMethods, CallObjectScript = XU:GetImpl()

local HOLD_HOVER_HINT_DURATION, ICON_FILE_NAMES, LookupIconName = 0.2, nil
local IconSelector, IconSelectorData, internal = {}, {}, {}
local IconSelectorProps = {
	api=IconSelector,
	scripts={"OnIconSelect", "OnEditFocusGained", "OnEditFocusLost"},
	lastVisibleIcon=-1,
	selectedAsset=nil,
	viewIndexOffset=0,
	firstAsset=nil,
	firstAssetValue=nil,
	columns=14,
	rows=7,
	cellWidth=36,
	cellHeight=36,
	pendingGridSync=true,
	manualInputHintText="",
}
AddObjectMethods({"IconSelector"}, IconSelectorProps)

function IconSelector:SetSelectedAsset(asset)
	local d = assert(getWidgetData(self, IconSelectorData), "Invalid object type")
	assert(asset == nil or type(asset) == "string" or type(asset) == "number", 'Syntax: IconSelector:SetSelectedAsset(asset)')
	d.selectedAsset = asset
	internal.RenderView(d, d.viewIndexOffset)
	internal.SyncHintText(d)
end
function IconSelector:SetFirstAsset(value, overrideAsset)
	local d = assert(getWidgetData(self, IconSelectorData), "Invalid object type")
	local asset = overrideAsset or value
	assert(asset == nil or type(asset) == "number" or type(asset) == "string", 'Syntax: IconSelector:SetFirstAsset(value[, overrideAsset])')
	d.firstAssetValue, d.firstAsset = value, asset
	internal.RenderView(d, d.viewIndexOffset)
end
function IconSelector:SetManualInputHintText(text)
	local d = assert(getWidgetData(self, IconSelectorData), "Invalid object type")
	assert(type(text) == "string", 'Syntax: IconSelector:SetManualInputHintText("text")')
	d.manualInputHintText = text
	internal.SyncHintText(d)
end
function IconSelector:SetGridSize(rows, cols)
	local d = assert(getWidgetData(self, IconSelectorData), "Invalid object type")
	assert(type(rows) == "number" and rows > 0 and rows % 1 == 0
	   and type(cols) == "number" and cols > 0 and cols % 1 == 0
	     , 'Syntax: IconSelector:SetGridSize(rows, cols)')
	d.pendingGridSync, d.rows, d.columns = true, rows, cols
	if d.proto.super.IsShown(d.self) then
		internal.ConfigureIconGrid(d)
	end
end
function IconSelector:FocusManualInput()
	local d = assert(getWidgetData(self, IconSelectorData), "Invalid object type")
	d.manualInput:SetFocus()
end
function IconSelector:IsSearchPossible()
	return not not (ICON_FILE_NAMES or LookupIconName and LookupIconName(0) or ICON_FILE_NAMES)
end

local GetAllIcons do
	function GetAllIcons()
		local a = {}
		local n = GetNumMacroIcons and GetNumMacroIcons() or 0
		for i = 1, n do
			local icon = GetMacroIconInfo(i)
			if icon then a[#a+1] = icon end
		end
		GetAllIcons = function() return a end
		return a
	end
end
function LookupIconName(fid)
	LookupIconName = nil
	if select(5, GetAddOnInfo("IconFileNames")) == "DEMAND_LOADED"
	   and not IsAddOnLoaded("IconFileNames") then
		LoadAddOn("IconFileNames")
	end
	ICON_FILE_NAMES = _G.ICON_FILE_NAMES
	ICON_FILE_NAMES = type(ICON_FILE_NAMES) == "table" and ICON_FILE_NAMES or nil
	return ICON_FILE_NAMES and ICON_FILE_NAMES[fid]
end

function internal:OnHide()
	local d = getWidgetData(self, IconSelectorData)
	d.hoverIcon, d.hoverIconLT = nil
	self:GetParent():Hide()
end
function internal:OnIconClick(_button, _down)
	local d, checked = getWidgetData(self:GetParent(), IconSelectorData), self:GetChecked()
	local idx = checked and self:GetID()+d.viewIndexOffset or nil
	local tex = idx and (idx == 0 and d.firstAssetValue or idx > 0 and d.iconList[idx] or nil)
	if d.selectedButton then
		d.selectedButton:SetChecked(nil)
	end
	d.selectedAsset, d.selectedButton = tex, checked and self or nil
	PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON)
	CallObjectScript(d.self, "OnIconSelect", tex)
end
function internal:OnIconEnter()
	local d = getWidgetData(self:GetParent(), IconSelectorData)
	d.hoverIcon, d.hoverIconLT = self, nil
	internal.SyncHintText(d)
end
function internal:OnUpdateTick()
	local d = getWidgetData(self, IconSelectorData)
	if d.hoverIconLT and d.hoverIconLT + HOLD_HOVER_HINT_DURATION > GetTime() then
		return
	elseif d.hoverIconLT then
		d.hoverIcon = nil
	end
	self:SetScript("OnUpdate", nil)
	internal.SyncHintText(d)
end
function internal:OnIconLeave()
	local d = getWidgetData(self:GetParent(), IconSelectorData)
	if d.hoverIcon == self then
		d.hoverIconLT = GetTime()
		d.clipRoot:SetScript("OnUpdate", internal.OnUpdateTick)
	end
end
function internal.CreateIconButton(parent, pool, id)
	local f, sz = CreateFrame("CheckButton", nil, parent, nil, id), 32
	f:SetSize(sz, sz)
	f:SetNormalTexture("")
	f:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
	f:GetHighlightTexture():SetBlendMode("ADD")
	f:SetCheckedTexture("Interface/Buttons/CheckButtonHilight")
	f:GetCheckedTexture():SetBlendMode("ADD")
	f:SetPushedTexture("Interface/Buttons/UI-Quickslot-Depress")
	f:SetScript("OnClick", internal.OnIconClick)
	f:SetScript("OnEnter", internal.OnIconEnter)
	f:SetScript("OnLeave", internal.OnIconLeave)
	local tex = f:CreateTexture(nil, "ARTWORK")
	tex:SetAllPoints()
	local bg = f:CreateTexture(nil, "BACKGROUND", nil, -1)
	bg:SetTexture("Interface/Buttons/UI-EmptySlot-Disabled")
	bg:SetPoint("CENTER", tex, "CENTER")
	bg:SetSize(1.5*sz, 1.5*sz)
	local edge = f:CreateTexture(nil, "OVERLAY", nil, -1)
	edge:SetTexture("Interface/Buttons/UI-Quickslot2")
	edge:SetSize(1.625*sz, 1.625*sz)
	edge:SetPoint("CENTER", tex, "CENTER", 0.25, -0.25)
	f.tex, f.background, f.edge = tex, bg, edge
	pool[id] = f
	return f
end
function internal:OnScroll(value, interaction)
	local d, co = getWidgetData(self, IconSelectorData), value % 1
	d.origin:SetPoint("TOPLEFT", 0, co*d.cellHeight)
	internal.RenderView(d, (value - co) * d.columns, true)
	if interaction and d.hoverIconLT then
		internal.SyncHintText(d)
	end
end
function internal.RenderView(d, value, allowSkip)
	if allowSkip and d.viewIndexOffset == value then return end
	local icons, icontex, sel, selectedButton = d.pool, d.iconList, d.selectedAsset
	for i=0, d.lastVisibleIcon do
		local ico, tex = icons[i].tex, i == 0 and value == 0 and (d.firstAsset or "Interface/Icons/INV_Misc_QuestionMark") or icontex[i+value]
		icons[i]:SetShown(not not tex)
		if tex then
			ico:SetTexture(tex)
			local check = sel and (tex == sel or ico:GetTexture() == sel)
			icons[i]:SetChecked(check)
			selectedButton = check and icons[i] or selectedButton
		end
	end
	d.viewIndexOffset, d.selectedButton = value, selectedButton
end
function internal.ConfigureIconGrid(d)
	local sb, pool, icontex, origin = d.scrollBar, d.pool, d.iconList, d.origin
	local rows, cols, cw, ch = d.rows, d.columns, d.cellWidth, d.cellHeight
	sb:SetStepsPerPage(rows, math.min(math.max(1, rows-2), 5))
	sb:SetWindowRange(rows)
	sb:SetMinMaxValues(0, math.ceil((#icontex-cols*rows)/cols))
	d.self:SetSize(42+cols*cw, 40+ch*rows)
	local usedIcons = cols*rows - 1
	for i=0, usedIcons do
		local w = pool[i] or internal.CreateIconButton(d.clipRoot, d.pool, i)
		w:SetPoint("TOPLEFT", origin, (i % cols)*cw, - ch*math.floor(i / cols))
	end
	for i=usedIcons+1, d.lastVisibleIcon do
		pool[i]:Hide()
	end
	d.lastVisibleIcon, d.pendingGridSync = usedIcons, nil
end
function internal:OnShow()
	local d = getWidgetData(self, IconSelectorData)
	internal.SetIconList(d, GetAllIcons(), nil, -1)
	if d.pendingGridSync then
		internal.ConfigureIconGrid(d)
	end
	d.scrollBar:SetValue(0, true)
	local p = d.self:GetParent()
	d.self:SetFrameLevel(math.max(d.self:GetFrameLevel(), p and p:GetFrameLevel()+200))
	local kbf = GetCurrentKeyBoardFocus()
	if kbf then
		kbf:ClearFocus()
	end
end
function internal.SyncHintText(d)
	if d.manualInput:HasFocus() then
		d.manualInputHint:Hide()
		d.manualInputFS:Show()
	elseif d.hoverIcon and (d.hoverIcon.IsMouseMotionFocus and d.hoverIcon:IsMouseMotionFocus() or d.hoverIcon:IsMouseOver()) then
		d.manualInputHint:Show()
		local idx = d.hoverIcon:GetID() + d.viewIndexOffset
		local asset = idx == 0 and d.firstAsset or d.iconList[idx]
		local fn = ICON_FILE_NAMES and ICON_FILE_NAMES[asset] or LookupIconName and securecall(LookupIconName, asset)
		d.manualInputHint:SetText(fn and asset .. " |cff606060[|r" .. fn .. "|cff606060]|r" or asset or "")
		d.manualInputFS:Hide()
	elseif d.selectedAsset then
		d.manualInput:SetText(d.selectedAsset)
		d.manualInputFS:Show()
		d.manualInputHint:Hide()
	else
		d.manualInputHint:SetText(d.manualInputHintText)
		d.manualInputHint:Show()
		d.manualInput:SetText("")
	end
end
function internal:OnEditFocusChange()
	local d = getWidgetData(self, IconSelectorData)
	internal.SyncHintText(d)
	CallObjectScript(d.self, self:HasFocus() and "OnEditFocusGained" or "OnEditFocusLost", self)
end
function internal:OnEnterPressed()
	local d, text = getWidgetData(self, IconSelectorData), self:GetText()
	if IsAltKeyDown() and (ICON_FILE_NAMES or LookupIconName and securecall(LookupIconName, 0) or ICON_FILE_NAMES) then
		return internal.FilterIcons(d, text, self)
	end
	if text:match("%S") then
		local fid0, nt = GetFileIDFromPath(text), tonumber(text) or 0
		local fid1 = not fid0 and GetFileIDFromPath("Interface/Icons/" .. text)
		local path = fid0 and (fid0 < 0 and text or fid0) or
		             fid1 and (fid1 < 0 and "Interface/Icons/" .. text or fid1) or
		             nt > 0 and nt or
		             select(3, GetSpellInfo(text))
		if not path then
			return self:HighlightText()
		end
		d.selectedAsset = path
		CallObjectScript(d.self, "OnIconSelect", path)
	end
	self:ClearFocus()
end
function internal:OnEscapePressed()
	self:ClearFocus()
end
function internal.FilterIcons(d, query, _editbox)
	local of, nf = d.filter, query:lower():gsub("[.%%%[%]%-+*?()]", ""):match(".+")
	if of == nf then
		return
	elseif not nf then
		internal.SetIconList(d, GetAllIcons(), nil)
	else
		local t, ni, p, smatch = {}, 1, nf:gsub(" +", ".*"), nf.match
		local ot = nf:match(of or "") and d.iconList or GetAllIcons()
		for i=1, #ot do
			local fn = ICON_FILE_NAMES[ot[i]]
			if fn and smatch(fn, p) then
				t[ni], ni = ot[i], ni + 1
			end
		end
		internal.SetIconList(d, t, nf)
	end
	internal.RenderView(d, d.viewIndexOffset)
end
function internal.SetIconList(d, iconList, filter, viewIndexOffset)
	d.iconList, d.filter, d.viewIndexOffset = iconList, filter, viewIndexOffset or d.viewIndexOffset
	d.scrollBar:SetMinMaxValues(0, math.ceil((#d.iconList-d.columns*d.rows)/d.columns))
end

local function CreateIconSelector(name, parent, outerTemplate, id)
	local f, d, t, a = CreateFrame("Frame", name, parent, outerTemplate, id)
	d = newWidgetData(f, IconSelectorData, IconSelectorProps)
	d.pool, d.backdrop = {}, XU:Create("Backdrop", f, {bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/DialogFrame/UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 11, top = 11, bottom = 10 }, bgColor=0xd8000000})
	f:EnableMouse(1)
	f:SetToplevel(1)
	f:Hide()
	t = CreateFrame("Frame", nil, f)
	t:SetPoint("TOPLEFT", 12, -32)
	t:SetPoint("BOTTOMRIGHT", -31, 12)
	if t.SetClipsChildren then t:SetClipsChildren(true) end
	t:SetScript("OnHide", internal.OnHide)
	t:SetScript("OnShow", internal.OnShow)
	setWidgetData(t, IconSelectorData, d)
	t, d.clipRoot = CreateFrame("Frame", nil, t), t
	t:SetSize(1,1)
	t:SetPoint("TOPLEFT")
	t:Hide()
	t, d.origin = XU:Create("ScrollBar", nil, f), t
	t:SetStyle("thin")
	t:SetPoint("TOPRIGHT", -9, -36)
	t:SetPoint("BOTTOMRIGHT", -9, 12)
	t:SetWheelScrollTarget(d.clipRoot, -2, -5, -2, -1)
	t:SetCoverTarget(d.clipRoot)
	t:SetScript("OnValueChanged", internal.OnScroll)
	setWidgetData(t, IconSelectorData, d)
	t, d.scrollBar = XU:Create("LineInput", nil, f), t
	t:SetStyle("chat")
	t:SetPoint("TOPLEFT", 11, -7)
	t:SetPoint("TOPRIGHT", -34, -7)
	setWidgetData(t, IconSelectorData, d)
	t:SetScript("OnEditFocusGained", internal.OnEditFocusChange)
	t:SetScript("OnEditFocusLost", internal.OnEditFocusChange)
	t:SetScript("OnEnterPressed", internal.OnEnterPressed)
	t:SetScript("OnEscapePressed", internal.OnEscapePressed)
	d.manualInputFS = t:GetRegions()
	a, d.manualInput = t:CreateFontString(nil, "OVERLAY", "GameFontHighlight"), t
	a:SetPoint("CENTER")
	a:SetTextColor(0.85, 0.85, 0.85)
	d.manualInputHint = a
	t = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	t:SetPoint("TOPRIGHT", -2, -1)
	t:SetHitRectInsets(4, 4, 4, 6)
	t, d.closeButton = t:CreateTexture(nil, "BACKGROUND", nil, -5), t
	t:SetTexture("Interface/ChatFrame/UI-ChatInputBorder-Mid2")
	t:SetPoint("BOTTOMLEFT", d.manualInput, "BOTTOMRIGHT", 7, -6.25)
	t:SetSize(18.75, 8)
	t:SetTexCoord(0,1, 0.75,1)
	return f
end

XU:RegisterFactory("IconSelector", CreateIconSelector)