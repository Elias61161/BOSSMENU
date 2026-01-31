fx_version 'cerulean'
game 'gta5'

author 'CORE FIVE Scripts'
description 'Advanced Job Panel System - ESX'
version '4.0.0'

lua54 'yes'

shared_scripts {
    'config.lua',
    'locales/*.lua',
    'shared/*.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/config.html',
    'web/css/*.css',
    'web/js/*.js',
    'locales/*.lua'
}

dependencies {
    'es_extended',
    'oxmysql'
}