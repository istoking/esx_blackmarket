resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

description 'Esx Blackmarket'

version '1.1.0'

client_scripts {
	'@es_extended/locale.lua',
	'locales/en.lua',
	'config.lua',
	'client/main.lua'
}

server_scripts {
	'@es_extended/locale.lua',
	'@mysql-async/lib/MySQL.lua',
	'locales/en.lua',
	'config.lua',
	'server/main.lua'
}

dependencies {
	'es_extended',
	'progressBars',
	'mythic_notify'
}