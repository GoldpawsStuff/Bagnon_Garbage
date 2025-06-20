--[[

	The MIT License (MIT)

	Copyright (c) 2025 Lars Norberg

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

--]]
local Addon, Private =  ...
if (Private.Incompatible) then
	--print("|cffff1111"..Addon.." was auto-disabled.")
	return
end

local Module = Bagnon:NewModule(Addon, Private)
local cache = Private.cache

Module:AddUpdater(function(self)

	if (self.hasItem and self.info.quality == 0 and not(self.locked or self.info.isLocked)) then

		local overlay = cache[self]
		if (not overlay) then
			overlay = self:CreateTexture()
			overlay.icon = self.icon or _G[self:GetName().."IconTexture"]
			overlay:Hide()
			overlay:SetDrawLayer("ARTWORK")
			overlay:SetAllPoints(overlay.icon)
			overlay:SetColorTexture(.04, .013333333, .004705882, .6)
			cache[self] = overlay
		end

		overlay:Show()
		SetItemButtonDesaturated(self, true)

	else
		local overlay = cache[self]
		if (overlay) then
			overlay:Hide()
			SetItemButtonDesaturated(self, (self.locked or self.info.isLocked))
		end
	end

end)

-- Also need to hook this to locked updates
local item = Bagnon.ItemSlot or Bagnon.Item
for _,method in next,{ "SetLocked", "UpdateLocked", "UpdateSearch" } do
	if (item[method]) then
		hooksecurefunc(item, method, Private.updatesByModule[Module])
	end
end

local groupMethod = Bagnon.ContainerItemGroup and Bagnon.ContainerItemGroup.ITEM_LOCK_CHANGED
if (groupMethod) then
	local groupUpdate = function(self,_,bag,slot)
		if (not self:Delaying("Layout")) then
			bag = self.buttons[bag]
			slot = bag and bag[slot]
			if (slot) then
				Private.updatesByModule[Module](slot)
				--slot:UpdateLocked()
			end
		end
	end
	hooksecurefunc(Bagnon.ContainerItemGroup, "ITEM_LOCK_CHANGED", groupUpdate)
end
