fx_version 'cerulean'
game 'gta5'

author       'Murderface (FMRP)'
version      '2.0.0'
license      'MIT'
repository   'https://github.com/fruitmob/murderface-skate'
description  'Physics-based skateboarding for FiveM — Qbox/ox stack. Charge jumps, ragdoll wipeouts, inventory integration.'

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
