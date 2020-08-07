if (not Bagnon) then
	return
end
if (function(addon)
	for i = 1,GetNumAddOns() do
		if (string.lower((GetAddOnInfo(i))) == string.lower(addon)) then
			if (GetAddOnEnableState(UnitName("player"), i) ~= 0) then
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

-- Local Cache
local Cache_ItemGarbage = {}

-- Flag tracking merchant frame visibility
--local MERCHANT_VISIBLE

-- Just keep this running, regardless of other stuff (?)
-- *might be conflicts with the standard Update function here. 
--local MerchantTracker = CreateFrame("Frame")
--MerchantTracker:RegisterEvent("MERCHANT_SHOW")
--MerchantTracker:RegisterEvent("MERCHANT_CLOSED")
--MerchantTracker:SetScript("OnEvent", function(self, event, ...) 
--	if (event == "MERCHANT_SHOW") then
--		MERCHANT_VISIBLE = true
--	elseif (event == "MERCHANT_CLOSED") then 
--		MERCHANT_VISIBLE = false
--	end
--	for button,ItemGarbage in pairs(Cache_ItemGarbage) do
--		local JunkIcon = button.JunkIcon
--		if JunkIcon then
--			if (MERCHANT_VISIBLE and ItemGarbage.showJunk) then 
--				JunkIcon:Show()
--			else 
--				JunkIcon:Hide()
--			end
--		end
--	end
--end)

-----------------------------------------------------------
-- Utility Functions
-----------------------------------------------------------
-- Check if it's a caged battle pet
local GetBattlePetInfo = function(itemLink)
	if (string_find(itemLink, "battlepet")) then
		local data, name = string_match(itemLink, "|H(.-)|h(.-)|h")
		local  _, _, level, rarity = string_match(data, "(%w+):(%d+):(%d+):(%d+)")
		return true, level or 1, tonumber(rarity) or 0
	end
end

-----------------------------------------------------------
-- Cache & Creation
-----------------------------------------------------------
local Cache_GetItemGarbage = function(button)
	
	local Icon = button.icon or _G[button:GetName().."IconTexture"]

	local ItemGarbage = button:CreateTexture()
	ItemGarbage:Hide()
	ItemGarbage:SetDrawLayer("ARTWORK")
	ItemGarbage:SetAllPoints(Icon)
	ItemGarbage:SetColorTexture(51/255 * 1/5,  17/255 * 1/5,   6/255 * 1/5, .6)
	ItemGarbage.owner = button

	hooksecurefunc(Icon, "SetDesaturated", function() 
		if ItemGarbage.tempLocked then 
			return
		end

		ItemGarbage.tempLocked = true

		local itemLink = button:GetItem()
		if itemLink then 
			local _, _, itemRarity, iLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
			local texture, itemCount, locked, quality, readable, _, _, isFiltered, noValue, itemID = GetContainerItemInfo(button:GetBag(), button:GetID())
		
			local isBattlePet, battlePetLevel, battlePetRarity = GetBattlePetInfo(itemLink)
			if isBattlePet then 
				itemRarity = battlePetRarity
			end

			if not(((quality and (quality > 0)) or (itemRarity and (itemRarity > 0))) and (not locked)) then
				Icon:SetDesaturated(true)
			end 
		end

		ItemGarbage.tempLocked = false
	end)

	Cache_ItemGarbage[button] = ItemGarbage

	return ItemGarbage
end

-----------------------------------------------------------
-- Main Update
-----------------------------------------------------------
local Update = function(self)
	local itemLink = self:GetItem() 
	if itemLink then

		-- Get some blizzard info about the current item
		local itemName, _itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, iconFileDataID, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(itemLink)
		local effectiveLevel, previewLevel, origLevel = GetDetailedItemLevelInfo(itemLink)
		local isBattlePet, battlePetLevel, battlePetRarity = GetBattlePetInfo(itemLink)

		-- Retrieve the itemID from the itemLink
		local itemID = tonumber(string_match(itemLink, "item:(%d+)"))

		---------------------------------------------------
		-- ItemGarbage
		---------------------------------------------------
		local Icon = self.icon or _G[self:GetName().."IconTexture"]
		local showJunk = false

		if Icon then 
			local texture, itemCount, locked, quality, readable, _, _, isFiltered, noValue, itemID = GetContainerItemInfo(self:GetBag(), self:GetID())

			local notGarbage = ((quality and (quality > 0)) or (itemRarity and (itemRarity > 0))) and (not locked) 
			if notGarbage then
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

		--local JunkIcon = self.JunkIcon
		--if JunkIcon then 
		--	local ItemGarbage = Cache_ItemGarbage[self] 
		--	if ItemGarbage then 
		--		ItemGarbage.showJunk = showJunk
		--	end 
		--	if (MERCHANT_VISIBLE and showJunk) then 
		--		JunkIcon:Show()
		--	else
		--		JunkIcon:Hide()
		--	end
		--end

	else
		if Cache_ItemGarbage[self] then 
			Cache_ItemGarbage[self]:Hide()
			Cache_ItemGarbage[self].showJunk = nil
		end
		--local JunkIcon = self.JunkIcon
		--if JunkIcon then 
		--	if (MERCHANT_VISIBLE and showJunk) then 
		--		JunkIcon:Show()
		--	else
		--		JunkIcon:Hide()
		--	end
		--end
	end
end 

hooksecurefunc(Bagnon.ItemSlot, "Update", Update)
