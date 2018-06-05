
-- Using the Bagnon way to retrieve names, namespaces and stuff
local MODULE =  ...
local ADDON, Addon = MODULE:match("[^_]+"), _G[MODULE:match("[^_]+")]
local GarbageColoring = Bagnon:NewModule("GarbageColoring", Addon)

-- Lua API
local _G = _G

-- WoW API
local GetContainerItemInfo = _G.GetContainerItemInfo
local GetItemInfo = _G.GetItemInfo

local cache = {}
local junk = {}

local MERCHANT_VISIBLE

GarbageColoring.OnEnable = function(self)

	local updateJunkIcon = function()
		for junkIcon, show in pairs(junk) do
			junkIcon:SetShown(MERCHANT_VISIBLE and show)
		end
	end

	local frame = CreateFrame("Frame")
	frame:RegisterEvent("MERCHANT_SHOW")
	frame:RegisterEvent("MERCHANT_CLOSED")
	frame:SetScript("OnEvent", function(self, event, ...) 
		if (event == "MERCHANT_SHOW") then
			MERCHANT_VISIBLE = true
		elseif (event == "MERCHANT_CLOSED") then 
			MERCHANT_VISIBLE = false
		end
		updateJunkIcon()
	end)

	hooksecurefunc(Bagnon.ItemSlot, "Update", function(self) 

		local icon = self.icon or _G[self:GetName().."IconTexture"]
		if icon and (not cache[icon]) then

			local darker = self:CreateTexture()
			darker:Hide()
			darker:SetDrawLayer("ARTWORK")
			darker:SetAllPoints(icon)
			darker.owner = self

			local setTexture = darker.SetColorTexture or darker.SetTexture
			setTexture(darker, 51/255 * 1/5,  17/255 * 1/5,   6/255 * 1/5, .6)

			cache[icon] = darker

			hooksecurefunc(icon, "SetDesaturated", function(icon) 
				local darker = cache[icon]
				if darker.tempLocked then 
					return
				end
				darker.tempLocked = true
			
				local button = darker.owner

				local itemLink = button:GetItem()
				if itemLink then 
					local _, _, itemRarity, iLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
					local texture, itemCount, locked, quality, readable, _, _, isFiltered, noValue, itemID = GetContainerItemInfo(button:GetBag(), button:GetID())
				
					-- battle pet info must be extracted from the itemlink
					if (itemLink:find("battlepet")) then
						local data, name = strmatch(itemLink, "|H(.-)|h(.-)|h")
						local  _, _, level, rarity = strmatch(data, "(%w+):(%d+):(%d+):(%d+)")
						itemRarity = tonumber(rarity) or 0
					end
					
					if not(((quality and (quality > 0)) or (itemRarity and (itemRarity > 0))) and (not locked)) then
						icon:SetDesaturated(true)
					end 
				end

				darker.tempLocked = false
			end)

		end

		local showJunk = false

		local itemLink = self:GetItem()
		if (itemLink and icon) then
	
			local _, _, itemRarity, iLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
			local texture, itemCount, locked, quality, readable, _, _, isFiltered, noValue, itemID = GetContainerItemInfo(self:GetBag(), self:GetID())

			-- battle pet info must be extracted from the itemlink
			if (itemLink:find("battlepet")) then
				local data, name = strmatch(itemLink, "|H(.-)|h(.-)|h")
				local  _, _, level, rarity = strmatch(data, "(%w+):(%d+):(%d+):(%d+)")
				itemRarity = tonumber(rarity) or 0
				iLevel = level
			end
			
			local notGarbage = ((quality and (quality > 0)) or (itemRarity and (itemRarity > 0))) and (not locked) 
			if notGarbage then
				if (not locked) then 
					icon:SetDesaturated(false)
				end
				cache[icon]:Hide()
			else
				icon:SetDesaturated(true)
				cache[icon]:Show()
				showJunk = (quality == 0) and (not noValue)
			end 
		else
			if icon then 
				icon:SetDesaturated(false)
			end
			if cache[icon] then 
				cache[icon]:Hide()
			end
		end

		if self.JunkIcon then 
			junk[self.JunkIcon] = showJunk
			self.JunkIcon:SetShown(MERCHANT_VISIBLE and showJunk)
		end

	end)
end

