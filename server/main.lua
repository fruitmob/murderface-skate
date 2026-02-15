-- ox_inventory server export handler
-- Item registered in ox_inventory/data/items.lua with:
--   server = { export = 'astudios-skating.skateboard' }
-- Per FMRP convention: NO _ placeholder (FiveM drops leading nil args)

exports(Config.ItemName, function(event, item, inventory, slot, data)
    if event == 'usingItem' then
        TriggerClientEvent('astudios-skating:client:toggle', inventory.id)
    end
end)
