local ADDON_NAME, RingJuggler = ...

-- Lua Globals --
local _G = _G
local select, tostring = _G.select, _G.tostring

-- Libs --

--local isLegion = select(4, _G.GetBuildInfo()) >= 70000
local debugger, debug do
    local LTD = true
    function debug(...)
        if not debugger and LTD then
            LTD = _G.LibStub("RealUI_LibTextDump-1.0")
            if LTD then
                debugger = LTD:New(ADDON_NAME .." Debug Output", 640, 480)
            else
                LTD = false
                return
            end
        end
        local time = _G.date("%H:%M:%S")
        local text = ("[%s]"):format(time)
        for i = 1, select("#", ...) do
            local arg = select(i, ...)
            text = text .. "     " .. tostring(arg)
        end
        debugger:AddLine(text)
    end
end
local function rjPrint(...)
    _G.print("|cff22dd22"..ADDON_NAME.."|r:", ...)
end

RingJuggler.Version = _G.GetAddOnMetadata(ADDON_NAME, "Version")
local RJChar
local defaults = {
    version = RingJuggler.Version,
    swapContainer = _G.BACKPACK_CONTAINER,
    swapSlot = 2,
    swapRingLink = "131764",
    invSlot = _G.INVSLOT_FINGER2,
}

local hasSwapRing, invRingLink = false
local function FindInBags(item)
    debug("FindInBags", item)
    for bagID = 0, _G.NUM_BAG_SLOTS do
        debug("Bag", bagID)
        local numSlots = _G.GetContainerNumSlots(bagID)
        if numSlots > 0 then
            for slot = 1, numSlots do
                debug("Slot", slot)
                local item2 = _G.GetContainerItemLink(bagID, slot)
                local item2ID = _G.GetContainerItemID(bagID, slot)
                debug("Check item", item2ID, item2)
                if item == item2 or _G.tonumber(item) == item2ID then
                    debug("Found", bagID, slot, item2)
                    return bagID, slot, item2
                end
            end
        end
    end
end
local function FindRing(ringLink)
    debug("FindRing", ringLink)
    local itemLink = _G.GetContainerItemLink(RJChar.swapContainer, RJChar.swapSlot)
    debug("itemLink", itemLink)
    if itemLink == ringLink then
        debug("Found", RJChar.swapContainer, RJChar.swapSlot)
        return RJChar.swapContainer, RJChar.swapSlot
    else
        debug("Not at saved location")
        return FindInBags(ringLink, "Link")
    end
end

local function EquipRing(ringLink)
    debug("EquipRing", ringLink)
    if _G.GetInventoryItemLink("player", RJChar.invSlot) == ringLink then
        debug("Already equipped")
    else
        _G.ClearCursor()

        local bagID, slot = FindRing(ringLink)
        _G.PickupInventoryItem(RJChar.invSlot)
        _G.PickupContainerItem(bagID, slot)
        rjPrint(ringLink.." has been equipped.")
    end
end
local function EquipSwapRing()
    debug("EquipSwapRing")
    return EquipRing(RJChar.swapRingLink)
end
local function EquipInvRing()
    debug("EquipInvRing")
    return EquipRing(invRingLink)
end

local frame = _G.CreateFrame("Frame")
function frame:ADDON_LOADED(name)
    if name == ADDON_NAME then
        debug(name, "loaded")
        RJChar = _G.RingJugglerChar or defaults
        debug("Char settings", _G.RingJugglerChar, RJChar)

        local oldLogout = _G.Logout
        _G.Logout = function()
            debug("Logout", hasSwapRing)
            if hasSwapRing then
                EquipInvRing()
            end
            oldLogout()
        end
        debug("Override Logout", _G.Logout)

        self:UnregisterEvent("ADDON_LOADED")
    end
end
function frame:PLAYER_LOGIN(...)
    debug("PLAYER_LOGIN", ...)

    local swapRingLink = RJChar.swapRingLink
    debug("Swap Ring", _G.strsplit("|", swapRingLink))
    if _G.tonumber(swapRingLink) then
        debug("Swap ring itemLink not set, search in bags")
        local bagID, slot, ringLink = FindInBags(swapRingLink)
        if bagID then
            RJChar.swapRingLink = ringLink
            RJChar.swapContainer = bagID
            RJChar.swapSlot = slot
            hasSwapRing = true
        end
    elseif _G.IsEquippableItem(swapRingLink) then
        debug("Swap ring is equippable")
        hasSwapRing = true
    else
        debug("Swap ring inconclusive")
        hasSwapRing = nil
        _G.C_Timer.After(1, self.PLAYER_LOGIN)
    end

    if hasSwapRing then
        invRingLink = _G.GetInventoryItemLink("player", RJChar.invSlot)
        debug("Inv Ring", _G.strsplit("|", invRingLink))

        if invRingLink:match("item[%-?%d:]+") == swapRingLink:match("item[%-?%d:]+") then
            debug("Still wearing swap ring, look for inv ring in bags", RJChar.swapContainer, RJChar.swapSlot)
            invRingLink = _G.GetContainerItemLink(RJChar.swapContainer, RJChar.swapSlot)
            debug("New Inv Ring", _G.strsplit("|", invRingLink))
        end
    end
end
function frame:PLAYER_ENTERING_WORLD(...)
    debug("PLAYER_ENTERING_WORLD", hasSwapRing, ...)
    if hasSwapRing then
        local instanceName, instanceType = _G.GetInstanceInfo()
        debug("Location:", instanceName, instanceType)
        if instanceName:find("Garrison") or instanceType == "none" then
            EquipSwapRing()
        else
            EquipInvRing()
        end
    end
end
function frame:PLAYER_EQUIPMENT_CHANGED(...)
    debug("PLAYER_EQUIPMENT_CHANGED", ...)
    --return EquipInvRing()
end
function frame:PLAYER_LOGOUT()
    debug("PLAYER_LOGOUT")
    _G.RingJugglerChar = RJChar
end

for event, func in next, frame do
    if type(func) == "function" then
        debug("Iter", event, func)
        frame:RegisterEvent(event)
    end
end
frame:SetScript("OnEvent", function(self, event, ...)
    debug("OnEvent", event, ...)
    return self[event](self, ...)
end)



-- Slash Commands IsEquippableItem("|cffa335ee|Hitem:124204:5326:0:0:0:0:0:0:100:268:4:5:1:566:529|h[Mannoroth's Calcified Eye]|h|r")
_G.SLASH_RINGJUGGLER1, _G.SLASH_RINGJUGGLER2 = "/ringjuggler", "/rj";
_G.SlashCmdList.RINGJUGGLER = function(msg, editBox)
    debug("msg:", msg, editBox)
    if msg == "debug" then
        if debugger then
            if debugger:Lines() == 0 then
                debugger:AddLine("Nothing to report.")
                debugger:Display()
                debugger:Clear()
                return
            end
            debugger:Display()
        end
    elseif _G.IsEquippableItem(msg) then
        local bagID, slot, ringLink = FindInBags(msg)
        if bagID then
            RJChar.swapRingLink = ringLink
            RJChar.swapContainer = bagID
            RJChar.swapSlot = slot
            hasSwapRing = true
            EquipSwapRing()
        end
    else
        debug("open config")
    end
end
