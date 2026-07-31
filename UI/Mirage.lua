local _, T = ...
local XU = T.exUI
local _assert, getWidgetData, newWidgetData, setWidgetData, _AddObjectMethods, _CallObjectScript = XU:GetImpl()

local IndicatorData, Indicator, CooldownData = {}, {}, {}
local IndicatorProps = {
	api=Indicator,
	iconAspect=1,
	ustate=-1,
	rcTextShown=false,
	cdTextShown=false,
}

local darken do
	local CSL = CreateFrame("ColorSelect")
	function darken(r,g,b, vf, sf)
		CSL:SetColorRGB(r,g,b)
		local h,s,v = CSL:GetColorHSV()
		CSL:SetColorHSV(h, s*(sf or 1), v*(vf or 1))
		return CSL:GetColorRGB()
	end
end

local function cooldownFormat(cd)
	if (cd or 0) == 0 then return "" end
	local f, n, unit = cd >= 9.95 and "%d%s" or "%.1f", cd, ""
	if n > 86400 then n, unit = ceil(n/86400), "d"
	elseif n > 3600 then n, unit = ceil(n/3600), "h"
	elseif n > 90 then n, unit = ceil(n/60), "m"
	elseif cd >= 9.95 then n = ceil(n) end
	return f, n, unit
end
local function adjustIconAspect(d, aspect)
	if d.iconAspect ~= aspect then
		d.iconAspect = aspect
		local w, h = d.iconbg:GetSize()
		d.icon:SetSize(aspect < 1 and h*aspect or w, aspect > 1 and w/aspect or h)
	end
end
local CreateCooldown, CallCooldownUpdate do
	local ninf = -math.huge
	local AROUND_LEFT, TAU = {x=0, y=0.5}, 2*math.pi
	local sparkPos do
		local CORNER_CUT = 3.5/62
		local CORNER_A4MIN = math.atan2(0.5-CORNER_CUT, 0.5)
		local CORNER_A4MAX = math.atan2(0.5, 0.5-CORNER_CUT)
		local CORNER_R = (0.5 - CORNER_CUT + CORNER_CUT^2)^0.5
		local mcos, msin, mtan = math.cos, math.sin, math.tan
		function sparkPos(p)
			local a4, x, y = (p % 0.25) * TAU
			if a4 > CORNER_A4MIN and a4 < CORNER_A4MAX then
				x, y = mcos(a4)*CORNER_R, msin(a4)*CORNER_R
			elseif a4 <= CORNER_A4MIN then
				x, y = 0.5, 0.5*mtan(a4)
			else
				x, y = 0.5/mtan(a4), 0.5
			end
			if p < 0.25 then
				x, y = y, x
			elseif p < 0.50 then
				x, y = x, -y
			elseif p < 0.75 then
				x, y = -y, -x
			else
				x, y = -x, y
			end
			return x+0.5, y+0.5
		end
	end
	local function cdOnUpdate(self, elapsed)
		local d = getWidgetData(self, CooldownData)
		local ucd, expire, time = d.updateCooldown or 0, d.expire or ninf, GetTime()
		if ucd > elapsed and time < expire then
			d.updateCooldown = ucd - elapsed
			return
		end
		d.updateCooldown = d.updateCooldownStep

		local duration, progress = d.duration or 0, expire - time
		if progress >= duration or duration == 0 then
			self:Hide()
			return
		end
		local s0, s1 = d, d.sst1
		progress = progress < 0 and 0 or (1 - progress/duration)
		local pos = progress >= 0.5 and 2 or 1
		for i=1, d.pos ~= pos and 2 or 0 do
			local j = i+2
			s0[i]:SetShown(i > pos)
			s0[j]:SetShown(i > pos)
			s1[i]:SetShown(i == pos)
			s1[j]:SetShown(i == pos)
		end
		d.pos = pos
		s1.mask:SetRotation((1-progress)*TAU, AROUND_LEFT)

		local sx, sy = sparkPos(progress)
		d.spark:SetPoint("CENTER", self, "CENTER", 45*(sx-0.5), 45*(sy-0.5))
	end
	local function cdSetVeilShown(d, shown)
		local s0, s1 = d, d.sst1
		for i=3, 4 do
			s0[i]:SetShown(shown)
			s1[i]:SetShown(shown)
		end
	end
	local function cdOnHide(self)
		local d = getWidgetData(self, CooldownData)
		local toExpire = GetTime() - (d.expire or 0)
		d.expire, d.pos = nil
		cdSetVeilShown(d, false)
		d.self:Hide()
		d.spark:Hide()
		if -0.1 < toExpire and toExpire < 0.25 then
			d.flashAG:Play()
		end
	end
	local function cdOnShow(self)
		local d = getWidgetData(self, CooldownData)
		cdSetVeilShown(d, true)
		d.pos = nil -- Forces quad texture update
		return cdOnUpdate(self, 0)
	end
	function CallCooldownUpdate(d)
		local self = d.self
		d.updateCooldown = nil
		self:Show()
		if d.updateCooldown == nil then
			return cdOnUpdate(self, 0)
		end
	end
	local function maybeAddMask(tex, mask)
		return mask and tex.AddMaskTexture and tex:AddMaskTexture(mask)
	end
	local function createSpiralOverlay(cd, parent, d, borderTex, white128, scale, mask, iconmask)
		local w, l
		if mask then
			if not parent.CreateMaskTexture then
				parent.CreateMaskTexture = function(self, ...) return self:CreateTexture(nil, ...) end
			end
			w = parent:CreateMaskTexture()
			w:SetTexture(white128, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE', 'NEAREST')
			w:SetSize(34*scale, 68*scale)
			w:SetPoint("LEFT", parent, "CENTER")
			if not w.AddMaskTexture then w:Hide() end
			d.mask, mask = w, w
		end
		for i=1,2 do
			w = cd:CreateTexture(nil, "ARTWORK", nil, 2)
			l, d[i] = i == 2, w
			w:SetTexture(borderTex)
			w:SetSize(24, 48)
			w:SetTexCoord(l and 0 or 0.5, l and 0.5 or 1, 0, 1)
			w:SetPoint(l and "RIGHT" or "LEFT", cd, "CENTER")
			maybeAddMask(w, mask)
			w:Hide()
			w = parent:CreateTexture(nil, "ARTWORK", nil, 4)
			w:SetTexture(1,1,1)
			if not w.AddMaskTexture then w:SetTexture(0,0,0,0) end
			w:SetPoint(l and "RIGHT" or "LEFT", cd, "CENTER")
			w:SetSize(21*scale, 42*scale)
			maybeAddMask(w, mask)
			maybeAddMask(w, iconmask)
			w:Hide()
			d[2+i] = w
		end
		return d
	end
	function CreateCooldown(parent, size, overParent, gx, pd, iconmask)
		local cd, scale = CreateFrame("Frame", nil, parent), size * 87/4032
		local d, w, b = setWidgetData(cd, CooldownData, {self=cd, parent=parent, parentControl=pd})
		cd:SetScale(size/48)
		cd:SetAllPoints()
		cd:SetScript("OnShow", cdOnShow)
		cd:SetScript("OnHide", cdOnHide)
		cd:SetScript("OnUpdate", cdOnUpdate)
		w = (overParent or cd):CreateTexture(nil, "OVERLAY", nil, 2)
		w:SetTexture(gx.CooldownSpark)
		w:SetSize(24,24)
		w, d.spark = w:CreateAnimationGroup(), w
		w:SetLooping("REPEAT")
		b = w:CreateAnimation("Rotation")
		b:SetDegrees(90)
		b:SetDuration(1/3)
		w:Play()

		w = parent:CreateTexture(nil, "OVERLAY")
		w:SetSize(size*60/64, size*60/64)
		w:SetPoint("CENTER")
		w:SetTexture(gx.CooldownStar)
		w:SetBlendMode("ADD")
		w:SetAlpha(0)
		w, d.flash = w:CreateAnimationGroup(), w
		b, d.flashAG = w:CreateAnimation("ROTATION"), w
		b:SetDuration(1/2)
		b:SetDegrees(-90)
		b = w:CreateAnimation("Alpha")
		b:SetFromAlpha(0)
		b:SetToAlpha(0.7)
		b:SetDuration(1/8)
		b = w:CreateAnimation("Alpha")
		b:SetFromAlpha(0.7)
		b:SetToAlpha(0)
		b:SetDuration(1/8)
		b:SetStartDelay(3/8)

		createSpiralOverlay(cd, parent, d, gx.BorderLow, gx.White128, scale, false, iconmask)
		local s1 = createSpiralOverlay(cd, parent, {}, gx.BorderLow, gx.White128, scale, true, iconmask)
		d.sst1 = s1

		return cd, d
	end
end

function Indicator:SetIcon(texture, aspect)
	local d = getWidgetData(self, IndicatorData)
	if texture then
		d.icon:SetTexture(texture)
		local ofs = 2.5/64
		d.icon:SetTexCoord(ofs, 1-ofs, ofs, 1-ofs)
	else
		d.icon:SetTexture("Interface/Icons/INV_Misc_QuestionMark")
		d.icon:SetTexCoord(0, 1, 0, 1)
	end
	return adjustIconAspect(d, aspect)
end
function Indicator:SetIconAtlas(atlas, aspect)
	local d = getWidgetData(self, IndicatorData)
	pcall(d.icon.SetAtlas, d.icon, atlas)
	return adjustIconAspect(d, aspect)
end
function Indicator:SetIconTexCoord(a,b,c,dc, e,f,g,h)
	if a and b and c and dc then
		local d = getWidgetData(self, IndicatorData)
		if e and f and g and h then
			d.icon:SetTexCoord(a,b,c,dc, e,f,g,h)
		else
			d.icon:SetTexCoord(a,b,c,dc)
		end
	end
end
function Indicator:SetIconVertexColor(r,g,b)
	local d = getWidgetData(self, IndicatorData)
	d.icon:SetVertexColor(r,g,b)
end
function Indicator:SetUsable(usable, _usableCharge, _cd, nomana, norange)
	local d = getWidgetData(self, IndicatorData)
	local state = usable and 0 or (norange and 1 or (nomana and 2 or 3))
	if d.ustate == state then return end
	d.ustate = state
	if not usable and (nomana or norange) then
		d.ribbon:Show()
		if norange then
			d.ribbon:SetVertexColor(1, 0.20, 0.15)
		else
			d.ribbon:SetVertexColor(0.15, 0.75, 1)
		end
	else
		d.ribbon:Hide()
	end
end
function Indicator:SetDominantColor(r,g,b)
	local d = getWidgetData(self, IndicatorData)
	r, g, b = r or 1, g or 1, b or 0.6
	if d.domR == r and d.domG == g and d.domB == b then return end
	d.domR, d.domG, d.domB = r, g, b
	local cdd, r2, g2, b2 = d.cdControl, darken(r,g,b, 0.20)
	local r3, g3, b3 = darken(r,g,b, 0.10, 0.50)
	local s1 = cdd.sst1
	d.hiEdge:SetVertexColor(r, g, b)
	d.iglow:SetVertexColor(r, g, b)
	d.oglow:SetVertexColor(r, g, b)
	d.edge:Show()
	d.edge:SetVertexColor(darken(r,g,b, 0.80))
	d.cdText:SetTextColor(r, g, b)
	cdd.spark:SetVertexColor(r, g, b)
	for i=1,2 do
		local j = i+2
		cdd[i]:SetVertexColor(r2, g2, b2)
		cdd[j]:SetVertexColor(r3, g3, b3)
		if s1 then
			s1[i]:SetVertexColor(r2, g2, b2)
			s1[j]:SetVertexColor(r3, g3, b3)
		end
	end
end
function Indicator:SetOverlayIcon(tex, w, h, ...)
	local oi = getWidgetData(self, IndicatorData).overIcon
	if not tex then
		return oi:Hide()
	end
	oi:Show()
	oi:SetTexture(tex)
	oi:SetSize(w, h)
	if ... then
		oi:SetTexCoord(...)
	else
		oi:SetTexCoord(0,1, 0,1)
	end
end
function Indicator:SetOverlayIconVertexColor(...)
	getWidgetData(self, IndicatorData).overIcon:SetVertexColor(...)
end
function Indicator:SetCount(count)
	getWidgetData(self, IndicatorData).count:SetText(count or "")
end
function Indicator:SetBinding(binding)
	binding = binding and GetBindingText(binding, 1) or ""
	getWidgetData(self, IndicatorData).key:SetText(binding)
end
function Indicator:SetCooldown(remain, duration, usableCharge)
	local d = getWidgetData(self, IndicatorData)
	local cdd = d.cdControl
	if (duration or 0) <= 0 or (remain or 0) <= 0 then
		d.cd:Hide()
		d.cdText:SetText("")
	else
		local now = GetTime()
		local expire, usable = now + remain, not not usableCharge
		local td, showSpark = expire - (cdd.expire or 0), usable and d.ustate == 0
		if td < -0.05 or td > 0.05 then
			cdd.duration, cdd.expire, cdd.updateCooldownStep, cdd.updateCooldown = duration, expire, duration/1536/d.self:GetEffectiveScale()
			cdd.spark:SetShown(showSpark)
		end
		if cdd.usable ~= usable then
			cdd.usable = usable
			local s0, s1 = cdd, cdd.sst1
			for i=1,2 do
				local j = 2+i
				s0[i]:SetAlpha(usable and 0.45 or 1)
				s0[j]:SetAlpha(usable and 0.25 or 0.85)
				s1[i]:SetAlpha(usable and 0.45 or 1)
				s1[j]:SetAlpha(usable and 0.25 or 0.85)
			end
			cdd.spark:SetShown(showSpark)
		end
		local gcS, gcL = GetSpellCooldown(61304)
		if (duration ~= gcL or gcS+gcL-now < remain) and d[usableCharge and "rcTextShown" or "cdTextShown"] then
			d.cdText:SetFormattedText(cooldownFormat(remain))
			d.cdText:SetAlpha(1)
		else
			d.cdText:SetText("")
		end
		CallCooldownUpdate(cdd)
	end
end
function Indicator:SetCooldownTextShown(cooldownShown, rechargeShown)
	local d = getWidgetData(self, IndicatorData)
	d.cdTextShown, d.rcTextShown = cooldownShown, rechargeShown
end
function Indicator:SetHighlighted(highlight)
	getWidgetData(self, IndicatorData).hiEdge:SetShown(highlight)
end
function Indicator:SetActive(active)
	getWidgetData(self, IndicatorData).iglow:SetShown(active)
end
function Indicator:SetOuterGlow(shown)
	getWidgetData(self, IndicatorData).oglow:SetShown(shown)
end
function Indicator:SetEquipState(isInContainer, isInInventory)
	local s = getWidgetData(self, IndicatorData).equipBanner
	local v, r, g, b = isInContainer or isInInventory, 0.1, 0.9, 0.15
	s:SetShown(v)
	if v then
		if not isInInventory then
			r, g, b = 1, 0.9, 0.2
		end
		s:SetVertexColor(r, g, b)
	end
end
function Indicator:SetShortLabel(text)
	getWidgetData(self, IndicatorData).label:SetText(text)
end
function Indicator:SetQualityOverlay(_qualID, qualAtlas)
	local s = getWidgetData(self, IndicatorData).qualityMark
	if qualAtlas then
		pcall(s.SetAtlas, s, qualAtlas)
	end
	s:SetShown(qualAtlas ~= nil)
end
function Indicator:SetCooldownDuration(duration)
	return Indicator.SetCooldown(self, duration, duration)
end

local function CreateIndicator(name, parent, size, nested, gx)
	local cf, d, w, ef = CreateFrame("Frame", name, parent)
		cf:SetSize(size, size)
	d = newWidgetData(cf, IndicatorData, IndicatorProps)
	ef = CreateFrame("Frame", nil, cf)
		ef:SetAllPoints()
	w = ef:CreateTexture(nil, "OVERLAY")
		w:SetAllPoints()
		w:SetTexture(gx.BorderLow)
		w:Hide()
	w, d.edge = ef:CreateTexture(nil, "OVERLAY", nil, 1), w
		w:SetAllPoints()
		w:SetTexture(gx.BorderHigh)
		w:Hide()
	w, d.hiEdge = T.CreateQuadTexture("BACKGROUND", size*2, gx.OuterGlow, cf), w
		w:SetShown(false)
	w, d.oglow = ef:CreateTexture(nil, "ARTWORK", nil, 1), w
		w:SetAllPoints()
		w:SetTexture(gx.InnerGlow)
		w:SetAlpha(nested and 0.6 or 1)
		w:Hide()
	w, d.iglow = ef:CreateTexture(nil, "ARTWORK"), w
		w:SetPoint("CENTER")
		w:SetSize(60*size/64, 60*size/64)
	w, d.icon = ef:CreateTexture(nil, "ARTWORK", nil, -2), w
		w:SetPoint("CENTER")
		w:SetSize(60*size/64, 60*size/64)
		w:SetTexture(0, 0, 0, 0)
	if not ef.CreateMaskTexture then
		ef.CreateMaskTexture = function(self, ...) return self:CreateTexture(nil, ...) end
	end
	w, d.iconbg = ef:CreateMaskTexture(), w
		w:SetAllPoints()
		if d.icon.AddMaskTexture then
			w:SetTexture(gx.IconMask)
			d.icon:AddMaskTexture(w)
		else
			w:SetTexture(0,0,0,0)
		end
		if d.iconbg.AddMaskTexture then d.iconbg:AddMaskTexture(w) end
	w, d.iconmask = CreateFrame("Frame", nil, cf), w
		w:SetAllPoints()
		w:SetFrameLevel(ef:GetFrameLevel()+5)
	d.cd, d.cdControl = CreateCooldown(ef, size, w, gx, d, d.iconmask)
	w = d.cd:CreateFontString(nil, "OVERLAY", "GameFontNormalLargeOutline")
		w:SetPoint("CENTER")
	w, d.cdText = ef:CreateTexture(nil, "ARTWORK", nil, 3), w
		w:SetAllPoints()
		w:SetTexture(gx.Ribbon)
		w:Hide()
	w, d.ribbon = ef:CreateTexture(nil, "ARTWORK", nil, 5), w
		w:SetPoint("BOTTOMLEFT", 4, 4)
	w, d.overIcon = ef:CreateFontString(nil, "OVERLAY", "NumberFontNormal"), w
		w:SetJustifyH("RIGHT")
		w:SetPoint("BOTTOMRIGHT", -2, 4)
	w, d.count = ef:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray"), w
		w:SetJustifyH("RIGHT")
		w:SetPoint("TOPRIGHT", -2, -3)
	w, d.key = ef:CreateTexture(nil, "ARTWORK", nil, 2), w
		w:SetSize(size/5, size/4)
		w:SetTexture("Interface\\GuildFrame\\GuildDifficulty")
		w:SetTexCoord(0, 42/128, 6/64, 52/64)
		w:SetPoint("TOPLEFT", 6*size/64, -3*size/64)
	w, d.equipBanner = ef:CreateFontString(nil, "OVERLAY", "TextStatusBarText", -1), w
		w:SetSize(size-4, 12)
		w:SetJustifyH("CENTER")
		w:SetJustifyV("BOTTOM")
		w:SetMaxLines(1)
		w:SetPoint("BOTTOMLEFT", 3, 4)
		w:SetPoint("BOTTOMRIGHT", d.count, "BOTTOMLEFT", 2, 0)
	w, d.label = ef:CreateTexture(nil, "ARTWORK", nil, 3), w
		w:SetPoint("TOPLEFT", 4, -4)
		w:SetSize(14,14)
		w:Hide()
	d.qualityMark = w
	return cf
end

XU:RegisterFactory("OPie:MirageIndicator", CreateIndicator)