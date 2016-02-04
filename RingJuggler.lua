local ADDON_NAME, RingJuggler = ...
RingJuggler.Version = GetAddOnMetadata(ADDON_NAME, "Version")

-- Lua Globals --
local _G = _G
local select, tostring = _G.select, _G.tostring

-- WoW Globals --
local GetContainerItemLink = _G.GetContainerItemLink

-- Libs --

local isLegion = select(4, GetBuildInfo()) >= 70000
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

local RJChar
local defaults = {
    version = RingJuggler.Version,
    swapContainer = _G.BACKPACK_CONTAINER,
    swapSlot = 2,
    swapRingLink = "item:131764:0:0:0:0:0:0:0:0:0:0",
    invSlot = _G.INVSLOT_FINGER2,
}

local invRingLink
local function FindRing(ringLink)
    debug("FindRing", ringLink)
    local itemLink = GetContainerItemLink(RJChar.swapContainer, RJChar.swapSlot)
    debug("itemLink", itemLink)
    if itemLink == ringLink then
        debug("Found", RJChar.swapContainer, RJChar.swapSlot)
        return RJChar.swapContainer, RJChar.swapSlot
    else
        debug("Not at saved location")
        for bagID = 0, _G.NUM_BAG_SLOTS do
            local numSlots = _G.GetContainerNumSlots(bagID)
            if numSlots > 0 then
                for slot = 1, numSlots do
                    itemLink = GetContainerItemLink(bagID, slot)
                    if itemLink == ringLink then
                        debug("Found", bagID, slot)
                        RJChar.swapContainer = bagID
                        RJChar.swapSlot = slot
                        return bagID, slot
                    end
                end
            end
        end
    end
    debug("Didn't find swap ring")
end

local function EquipRing(ringLink)
    debug("EquipRing", ringLink)
    _G.ClearCursor()

    local bagID, slot = FindRing(ringLink)
    _G.PickupInventoryItem(RJChar.invSlot)
    _G.PickupContainerItem(bagID, slot)
end
local function EquipSwapRing()
    debug("EquipSwapRing")
    return EquipRing(RJChar.swapRingLink)
end
local function EquipInvRing()
    debug("EquipInvRing")
    return EquipRing(invRingLink)
end

local frame = CreateFrame("Frame")
function frame:ADDON_LOADED(name)
    if name == ADDON_NAME then
        debug(name, "loaded")
        RJChar = _G.RingJugglerChar or defaults
        debug("Char settings", _G.RingJugglerChar, RJChar)
        self:UnregisterEvent("ADDON_LOADED")
    end
end
function frame:PLAYER_LOGIN(...)
    debug("PLAYER_LOGIN", ...)
    invRingLink = _G.GetInventoryItemLink("player", RJChar.invSlot)
    debug("Inv Ring", invRingLink)
    if RJChar.swapRingLink == "" then
        rjPrint([[Type "/rj <itemLink>" to set the ring to swap in.]])
    end
    debug("Old Logout", _G.Logout)
    local oldLogout = _G.Logout
    _G.Logout = function()
        EquipInvRing()
        oldLogout()
    end
    debug("New Logout", _G.Logout)
end
function frame:PLAYER_ENTERING_WORLD(...)
    debug("PLAYER_ENTERING_WORLD", ...)
    if RJChar.swapRingLink == "" then return end
    local instanceName, instanceType = _G.GetInstanceInfo()
    debug("Location:", instanceName, instanceType)
    if instanceName:find("Garrison") or instanceType == "none" then
        EquipSwapRing()
    else
        EquipInvRing()
    end
end
function frame:PLAYER_LEAVING_WORLD(...)
    debug("PLAYER_LEAVING_WORLD", ...)
    --return EquipInvRing()
end
function frame:PLAYER_LOGOUT()
    debug("PLAYER_LOGOUT")
    _G.RingJugglerChar = RJChar
end

for event, func in next, frame do
    debug("Iter", event, func)
end
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LEAVING_WORLD")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function(self, event, ...)
    debug("OnEvent", event, ...)
    return self[event](self, ...)
end)



-- Slash Commands
_G.SLASH_RINGJUGGLER1, _G.SLASH_RINGJUGGLER2 = "/ringjuggler", "/rj";
function SlashCmdList.RINGJUGGLER(msg, editBox)
    debug("msg:", msg)
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
        RJChar.swapRingLink = msg
        EquipSwapRing()
    else
        -- open config
    end
end
