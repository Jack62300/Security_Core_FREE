fx_version 'cerulean'
game 'gta5'

description 'Server security script'
author 'Jack Oneill and Pingouin'

version '1.1.0'

server_script {
    '@mysql-async/lib/MySQL.lua',
    '@es_extended/locale.lua',
    'config.lua',
    'main.lua',
}

client_scripts {
    'client.lua'
}

escrow_ignore {
    'config.lua',
    'client.lua',
    '*.txt',
    '*.sql'
}


lua54 'yes'
