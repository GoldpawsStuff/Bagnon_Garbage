
-- Using the Bagnon way to retrieve names, namespaces and stuff
local MODULE =  ...
local ADDON, Addon = MODULE:match("[^_]+"), _G[MODULE:match("[^_]+")]
local ItemLevel = Bagnon:NewModule("GarbageColoring", Addon)

-- Lua API
local _G = _G

-- WoW API
local GetContainerItemInfo = _G.GetContainerItemInfo
local GetItemInfo = _G.GetItemInfo

local cache = {}

ItemLevel.OnEnable = function(self)
	hooksecurefunc(Bagnon.ItemSlot, "Update", function(self) 

		local icon = self.icon or _G[self:GetName().."IconTexture"]
		if icon and (not cache[icon]) then
			cache[icon] = self

			local darker = self:CreateTexture()
			darker:Hide()
			darker:SetDrawLayer("ARTWORk")
			darker:SetAllPoints(icon)

			local setTexture = darker.SetColorTexture or darker.SetTexture
			setTexture(darker, 51/255 * 1/5,  17/255 * 1/5,   6/255 * 1/5, .6)

			hooksecurefunc(icon, "SetDesaturated", function(self) 
				if self.tempLocked then 
					return
				end
				self.tempLocked = true
				
				local itemLink = cache[self]:GetItem()
				if itemLink then
			
					local _, _, itemRarity, iLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
					local texture, itemCount, locked, quality, readable, _, _, isFiltered, noValue, itemID = GetContainerItemInfo(cache[self]:GetBag(), cache[self]:GetID())

					if ((itemRarity > 0) and (not locked)) then
						icon:SetDesaturated(false)
						darker:Hide()
					else
						icon:SetDesaturated(true)
						darker:Show()
					end 
				else
					darker:Hide()
				end

				self.tempLocked = false
			end)
		end

	end)
end

