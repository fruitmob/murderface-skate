fx_version 'cerulean'
game 'gta5'

description 'Skateboarding activity'
version '1.1.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/*.lua',
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    'server/*.lua',
}

dependencies {
    'ox_lib',
    'ox_inventory',
}
