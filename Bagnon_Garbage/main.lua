if (not Bagnon) then
	return
end
if (function(addon)
	for i = 1,GetNumAddOns() do
		local name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo(i)
		if (name:lower() == addon:lower()) then
			local enabled = not(GetAddOnEnableState(UnitName("player"), i) == 0) 
			if (enabled and loadable) then
				return true
			end
		end
	end
end)("Bagnon_ItemInfo") then 
	return 
end 

local MODULE =  ...
local ADDON, Addon = MODULE:match("[^_]+"), _G[MODULE:match("[^_]+")]
local Module = Bagnon:NewModule("GarbageColoring", Addon)

-- Lua API
local _G = _G
local string_find = string.find 
local string_match = string.match

-- WoW API
local GetContainerItemInfo = _G.GetContainerItemInfo
local GetItemInfo = _G.GetItemInfo

local Cache_ItemGarbage = {}

local Cache_GetItemGarbage = function(button)
	if (not Cache_ItemGarbage[button]) then
		local Icon = button.icon or _G[button:GetName().."IconTexture"]
		local ItemGarbage = button:CreateTexture()
		ItemGarbage:Hide()
		ItemGarbage:SetDrawLayer("ARTWORK")
		ItemGarbage:SetAllPoints(Icon)
		ItemGarbage:SetColorTexture(51/255 * 1/5,  17/255 * 1/5,   6/255 * 1/5, .6)
		ItemGarbage.owner = button

		hooksecurefunc(Icon, "SetDesaturated", function() 
			if (ItemGarbage.tempLocked) then 
				return
			end
			ItemGarbage.tempLocked = true
			local itemLink = button:GetItem()
			if (itemLink) then 
				local itemRarity
				local _, _, locked, quality, _, _, _, _, noValue = GetContainerItemInfo(button:GetBag(),button:GetID())
				if (string_find(itemLink, "battlepet")) then
					local data = string_match(itemLink, "|H(.-)|h(.-)|h")
					local  _, _, _, rarity = string_match(data, "(%w+):(%d+):(%d+):(%d+)")
					itemRarity = tonumber(rarity) or 0
				else
					_, _, itemRarity = GetItemInfo(itemLink)
				end
				if not(((quality and (quality > 0)) or (itemRarity and (itemRarity > 0))) and (not locked)) then
					Icon:SetDesaturated(true)
				end 
			end
			ItemGarbage.tempLocked = false
		end)

		Cache_ItemGarbage[button] = ItemGarbage
	end
	return Cache_ItemGarbage[button]
end

-----------------------------------------------------------
-- Main Update
-----------------------------------------------------------
local Update = function(self)
	local itemLink = self:GetItem() 
	if (itemLink) then
		local showJunk = false
		local Icon = self.icon or _G[self:GetName().."IconTexture"]
		if (Icon) then 
			local _, _, locked, quality, _, _, _, _, noValue = GetContainerItemInfo(self:GetBag(),self:GetID())
			local notGarbage = (quality and (quality > 0)) and (not locked) 
			if (not notGarbage) and (not locked)  then
				local _, _, itemRarity = GetItemInfo(itemLink)
				if (itemRarity and (itemRarity > 0)) then
					notGarbage = true
				end
			end
			if (notGarbage) then
				if (not locked) then 
					Icon:SetDesaturated(false)
				end
				if Cache_ItemGarbage[self] then 
					Cache_ItemGarbage[self]:Hide()
				end 
			else
				Icon:SetDesaturated(true)
				local ItemGarbage = Cache_ItemGarbage[self] or Cache_GetItemGarbage(self)
				ItemGarbage:Show()
				showJunk = (quality == 0) and (not noValue)
			end 
		else 
			if Cache_ItemGarbage[self] then 
				Cache_ItemGarbage[self]:Hide()
			end
		end
	else
		if Cache_ItemGarbage[self] then 
			Cache_ItemGarbage[self]:Hide()
			Cache_ItemGarbage[self].showJunk = nil
		end
	end
end 

local item = Bagnon.ItemSlot or Bagnon.Item
if (item) and (item.Update) then
	hooksecurefunc(item, "Update", Update)
end