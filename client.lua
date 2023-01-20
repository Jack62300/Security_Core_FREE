---------------
-- Functions --
---------------
local currentToken = ""

function ShowNotification(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, false)
end

------------
-- Events --
------------

RegisterNetEvent("security:OnRequestToken")
AddEventHandler("security:OnRequestToken", function(newToken)
    currentToken = newToken
end)

RegisterNetEvent("security:client:notify")
AddEventHandler("security:client:notify", function(str)
    -- ShowNotification(str)
    TriggerEvent('QBCore:Notify', str, 'primary', 3500)
end)


RegisterNetEvent("security:client:chat")
AddEventHandler("security:client:chat", function(str)
    TriggerEvent('chat:addMessage', {color = { 255, 0, 0},multiline = true, args = {"[Security]", str}})
end)


