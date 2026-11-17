fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'whip_appearance'
description 'Clothing stores, barber shops, plastic surgery, tattoo studios and company wardrobes for WHIP, with Director, Dungeon Mode and Scenario cards.'
version '1.0.0'

dependencies {
    'oxmysql',
    'whip_core',
}
whip_requires '1.0'

shared_scripts {
    '@whip_core/lib/satellite.lua',
    '@whip_core/shared/hair_fades.lua',
    '@whip_core/shared/tattoo_list.lua',
    'config.lua',
    'shared/catalog.lua',
    'shared/settings.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/main.lua',
    'server/rules.lua',
    'server/wardrobe.lua',
    'server/director.lua',
}

client_scripts {
    'client/preview.lua',
    'client/maskfix.lua',
    'client/camera.lua',
    'client/anims.lua',
    'client/main.lua',
    'client/items.lua',
    'client/director.lua',
}

ui_page 'html/index.html'

nui_callback_strict_mode 'true'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/img/items/*.png',
}
