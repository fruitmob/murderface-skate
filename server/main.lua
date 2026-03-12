-- Server-side toggle event (for admin commands, other scripts)
-- The skateboard item itself uses a client export (see client/main.lua)

RegisterNetEvent('astudios-skating:server:toggle', function()
    TriggerClientEvent('astudios-skating:client:toggle', source)
end)
