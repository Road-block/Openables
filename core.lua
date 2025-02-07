local addonName,NS = ...
NS.functions,NS.flags,NS.data,NS.frames = {},{},{},{}
local Fn,F,D,Fr = NS.functions,NS.flags,NS.data,NS.frames
local guidtip,guidbtn = "tip431EB727D1F047F099FED219B3B7E444","btn431EB727D1F047F099FED219B3B7E444"
local boxTex = 132761
local spell_opening = C_Spell.GetSpellName(6247)
local combat_queue = {}
local incompatible

local next,tinsert,tremove,pairs,ipairs,string_format,string_find = 
			next,tinsert,tremove,pairs,ipairs,string.format,string.find

Fr.events = CreateFrame("Frame")
Fr.events.OnEvent = function(self,event,...)
	return self[event] and self[event](...)
end
Fr.events:SetScript("OnEvent",Fr.events.OnEvent)
Fr.events:RegisterEvent("ADDON_LOADED")

Fr.events.ADDON_LOADED = function(...)
	if (...) == addonName then
		if IsLoggedIn() then
			Fr.events.PLAYER_LOGIN()
		else
			Fr.events:RegisterEvent("PLAYER_LOGIN")
		end
		local name,title,notes,loadable,reason,security,update = C_AddOns.GetAddOnInfo("ElvUI_Openables")
		incompatible = reason ~= "MISSING"
		if (incompatible) then
			C_AddOns.DisableAddOn("ElvUI_Openables")
			print("|cffFFFF00Old incompatible version of Openables detected!\nPlease exit and remove|r |cffFF0000\'ElvUI_Openables\'|r |cffFFFF00from your AddOns folder.|r")
		end
	end
	if (...) == "ElvUI" then
		if (Fr.theButton) then
			Fn.SkinButton()
		end
	end
end

Fr.events.PLAYER_LOGIN = function()
	OpenablesDB = OpenablesDB or {}
	Fr.scantip = CreateFrame("GameTooltip",guidtip,nil,"GameTooltipTemplate")
	Fr.scantip:SetOwner(WorldFrame,"ANCHOR_NONE")
	Fr.scantip:Hide()
	Fn.GetOpenPatterns()
	Fn.CreateButton()
end

Fr.events.BAG_UPDATE_DELAYED = function()
	Fn.SetOpenable()
end

Fr.events.PLAYER_REGEN_ENABLED = function()
	F.inCombat = nil
	while next(combat_queue) do
		tremove(combat_queue, 1)()
	end
end

Fr.events.PLAYER_REGEN_DISABLED = function()
	F.inCombat = true
end

Fr.events.UNIT_SPELLCAST_SENT = function(...)
	local _,target,castGUID,spellID = ...
	if (C_Spell.GetSpellName(spellID)) == spell_opening then
		F.opening = true
	end
end

Fr.events.UNIT_SPELLCAST_SUCCEEDED = function(...)
	if F.opening then
		F.opening = nil
		Fr.timer.anim:SetDuration(1.0)
		Fr.timer.anim:SetScript("OnFinished",Fn.SetOpenable)
		Fr.timer:Play()
	end
end
Fr.events.UNIT_SPELLCAST_FAILED = Fr.events.UNIT_SPELLCAST_SUCCEEDED
Fr.events.UNIT_SPELLCAST_STOP = Fr.events.UNIT_SPELLCAST_SUCCEEDED
Fr.events.UNIT_SPELLCAST_INTERRUPTED = Fr.events.UNIT_SPELLCAST_SUCCEEDED

Fn.PositionSave = function()
	local efscale = Fr.theButton:GetEffectiveScale()
	OpenablesDB.posx = Fr.theButton:GetLeft() * efscale
	OpenablesDB.posy = Fr.theButton:GetTop() * efscale
	Fn.SetOpenable()
end

Fn.PositionLoad = function()
	local posx,posy = OpenablesDB.posx, OpenablesDB.posy
	if not (posx and posy) then Fr.theButton:Show() return end
	local efscale = Fr.theButton:GetEffectiveScale()
	Fr.theButton:ClearAllPoints()
	Fr.theButton:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",posx/efscale,posy/efscale)
end

Fn.CreateButton = function()
	if Fr.theButton then return end
	if Fn.InCombat() then
		if not tContains(combat_queue,Fn.CreateButton) then
			tinsert(combat_queue,Fn.CreateButton)
		end
		return
	end
	
	Fr.theButton = CreateFrame("Button",guidbtn,UIParent,"SecureActionButtonTemplate,ActionButtonTemplate")
	Fr.theButton:Hide()
	Fr.theButton:SetWidth(36)
	Fr.theButton:SetHeight(36)
	Fr.theButton:ClearAllPoints()
	Fr.theButton:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	Fr.theButton:EnableMouse(true)
	Fr.theButton:RegisterForDrag("LeftButton")
	Fr.theButton:RegisterForClicks("AnyUp")
	Fr.theButton:SetMovable(true)
	Fr.theButton:SetClampedToScreen(true)
	Fr.theButton:SetScript("OnDragStart", function(self) if not Fn.InCombat() and IsAltKeyDown() then self:StartMoving() end end)
	Fr.theButton:SetScript("OnDragStop", function(self) if not Fn.InCombat() then self:StopMovingOrSizing() Fn.PositionSave() end end)
	Fr.theButton:SetScript("OnEnter", function(self)
		if self.tooltip then 
			GameTooltip:SetOwner(self,"ANCHOR_TOP")
			if type(self.tooltip)=="string" then 
				GameTooltip:SetText(self.tooltip)
				GameTooltip:AddLine("ALT-Click and drag to move")
			elseif type(self.tooltip)=="number" then
				GameTooltip:SetItemByID(self.tooltip)
				GameTooltip:AddDoubleLine("Click to loot container","ALT-Click and drag to move",0,1,0)
			end
			GameTooltip:Show()
		end 
	end)
	Fr.theButton:SetScript("OnLeave",GameTooltip_Hide)

 	Fr.theButton.icon = _G[string_format("%sIcon",guidbtn)]
	Fr.theButton.icon:SetTexture(boxTex)
	Fr.theButton.tooltip = BROWSE_NO_RESULTS
	
	if not Fr.timer then
    Fr.timer = Fr.events:CreateAnimationGroup()
    Fr.timer.anim = Fr.timer:CreateAnimation("Animation")
    Fr.timer:SetLooping("NONE")
  end

  Fn.SetOpenable()
	
	Fr.events:RegisterEvent("BAG_UPDATE_DELAYED")
	Fr.events:RegisterEvent("PLAYER_REGEN_ENABLED")
	Fr.events:RegisterEvent("PLAYER_REGEN_DISABLED")
	Fr.events:RegisterEvent("UNIT_SPELLCAST_SENT")
	Fr.events:RegisterUnitEvent("UNIT_SPELLCAST_FAILED","player")
	Fr.events:RegisterUnitEvent("UNIT_SPELLCAST_STOP","player")
	Fr.events:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED","player")
	Fr.events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED","player")
	
	Fr.timer.anim:SetDuration(2.0)
	Fr.timer.anim:SetScript("OnFinished",Fn.PositionLoad)
	Fr.timer:Play()
	
	if C_AddOns.IsAddOnLoaded("ElvUI") then
		Fn.SkinButton()
	end
	
end

D.open_spells,D.open_strings = {58172,98681,102923,109946,109947,109948,131934,131935,131936,132278,132279,142397,142901},{}
Fn.GetOpenPatterns = function()
	D.open_strings[ITEM_OPENABLE] = true
	local spell_effect
	for _,spellid in ipairs(D.open_spells) do
		if not Fr.scantip:IsOwned(WorldFrame) then
			Fr.scantip:SetOwner(WorldFrame)
		end
		Fr.scantip:ClearLines()
		Fr.scantip:SetSpellByID(spellid)
		if (Fr.scantip:GetSpell()) then
			spell_effect = (_G[string_format("%s%s%d",guidtip,"TextLeft",Fr.scantip:NumLines())]:GetText())
			if spell_effect and spell_effect ~= "" then 
				D.open_strings[string_format("%s %s",ITEM_SPELL_TRIGGER_ONUSE,spell_effect)] = true
				spell_effect = nil
			end
		end
	end
	Fr.scantip:Hide()
end

Fn.IsOpenable = function()
	if Fn.InCombat() then
		if not tContains(combat_queue,Fn.IsOpenable) then
			tinsert(combat_queue,Fn.IsOpenable)
		end
		return
	end
	
	for key,_ in pairs(D.open_strings) do
		for i=1,Fr.scantip:NumLines() do
			if string_find(_G[string_format("%s%s%d",guidtip,"TextLeft",i)]:GetText(),key,1,true) then
				return true
			end
		end
	end

	return false	
end

-- workaround for the bugged "Pet Supplies" bags/consumables that don't have a :use
-- http://www.wowhead.com/items=0.0?filter=na=pet+supplies, check after patches if they're fixed so we can remove this.
D.open_itemids = {[89125]=1,[93146]=1,[93147]=1,[93148]=1,[93149]=1,[94207]=1,[98095]=1}
Fn.SetOpenable = function()
	if Fn.InCombat() then
		if not tContains(combat_queue,Fn.SetOpenable) then
			tinsert(combat_queue,Fn.SetOpenable)
		end
		return
	end
	D.bag_id, D.bag_slot_id, D.item_id = nil, nil, nil
	for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS, 1 do
		for slot = 1, C_Container.GetContainerNumSlots(bag), 1 do
			if not D.bag_id then
				local item_id = C_Container.GetContainerItemID(bag,slot)
				if item_id then
					if not Fr.scantip:IsOwned(WorldFrame) then
						Fr.scantip:SetOwner(WorldFrame)
					end
					Fr.scantip:ClearLines()
					Fr.scantip:SetBagItem(bag,slot)
					if D.open_itemids[item_id] or Fn.IsOpenable() then
						D.bag_id = bag
						D.bag_slot_id = slot
						D.item_id = item_id
						D.item_icon = C_Container.GetContainerItemInfo(bag,slot).iconFileID
						break
					end
				end
			end
		end

		if D.bag_id then
			break
		end
	end
	Fr.scantip:Hide()

	if D.bag_id then
		Fr.theButton:SetAttribute("type1", "macro")
		Fr.theButton:SetAttribute("macrotext1", string_format("/run ClearCursor() if MerchantFrame:IsShown() then HideUIPanel(MerchantFrame) end\n/use %d %d",D.bag_id,D.bag_slot_id))
		Fr.theButton.icon:SetTexture(D.item_icon)
		Fr.theButton.tooltip = D.item_id
 		Fr.theButton:Show()
	else
		Fr.theButton.icon:SetTexture(boxTex)
		Fr.theButton.tooltip = BROWSE_NO_RESULTS
 		Fr.theButton:Hide()
	end
	
end

Fn.SkinButton = function()
	local E = unpack(ElvUI)
	AB = E:GetModule('ActionBars')
	AB:StyleButton(Fr.theButton)
end

Fn.InCombat = function()
	return F.inCombat or InCombatLockdown() or UnitAffectingCombat("player")
end

_G.BINDING_HEADER_OPENABLESHEADER = addonName
_G["BINDING_NAME_CLICK btn431EB727D1F047F099FED219B3B7E444:LeftButton"] = string_format("%s %s",_G.LOOT,_G.ITEM_CONTAINER)

-- debug
_G[addonName] = NS

--[[
add an exception for the "Pet Supplies" consumables
why the hell didn't Blizz make those 'boxes' like every other container
http://www.wowhead.com/item=89139
http://www.wowhead.com/items=0.0?filter=na=pet+supplies

]]