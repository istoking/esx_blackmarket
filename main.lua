ESX             = nil
local ShopItems = {}
local hasSqlRun = false

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Load items
AddEventHandler('onMySQLReady', function()
	hasSqlRun = true
	LoadShop()
end)

-- extremely useful when restarting script mid-game
Citizen.CreateThread(function()
	Citizen.Wait(2000) -- hopefully enough for connection to the SQL server

	if not hasSqlRun then
		LoadShop()
		hasSqlRun = true
	end
end)

function LoadShop()
	local itemResult = MySQL.Sync.fetchAll('SELECT * FROM items')
	local shopResult = MySQL.Sync.fetchAll('SELECT * FROM blackmarket')

	local itemInformation = {}
	for i=1, #itemResult, 1 do

		if itemInformation[itemResult[i].name] == nil then
			itemInformation[itemResult[i].name] = {}
		end

		itemInformation[itemResult[i].name].label = itemResult[i].label
		itemInformation[itemResult[i].name].limit = itemResult[i].limit
	end

	for i=1, #shopResult, 1 do
		if ShopItems[shopResult[i].store] == nil then
			ShopItems[shopResult[i].store] = {}
		end

		if itemInformation[shopResult[i].item].limit == -1 then
			itemInformation[shopResult[i].item].limit = 30
		end

		table.insert(ShopItems[shopResult[i].store], {
			label = itemInformation[shopResult[i].item].label,
			item  = shopResult[i].item,
			price = shopResult[i].price,
			limit = itemInformation[shopResult[i].item].limit
		})
	end
end

ESX.RegisterServerCallback('esx_blackmarket:requestDBItems', function(source, cb)
	if not hasSqlRun then
		TriggerClientEvent('mythic_notify:client:SendAlert', source, { type = 'error', text = 'The Blackmarket database has not been loaded yet, try again in a few moments.', length = 5000})
--		TriggerClientEvent('esx:showNotification', source, 'The Blackmarket database has not been loaded yet, try again in a few moments.')
	end

	cb(ShopItems)
end)

RegisterServerEvent('esx_blackmarket:buyItem')
AddEventHandler('esx_blackmarket:buyItem', function(itemName, amount, zone)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local sourceItem = xPlayer.getInventoryItem(itemName)

	amount = ESX.Round(amount)

	-- is the player trying to exploit?
	if amount < 0 then
		print('esx_blackmarket: ' .. xPlayer.identifier .. ' attempted to exploit the Blackmarket!')
		return
	end

	-- get price
	local price = 0
	local itemLabel = ''

	for i=1, #ShopItems[zone], 1 do
		if ShopItems[zone][i].item == itemName then
			price = ShopItems[zone][i].price
			itemLabel = ShopItems[zone][i].label
			break
		end
	end

	price = price * amount

	-- can the player afford this item?
	if xPlayer.getAccount('black_money').money >= price then
		-- can the player carry the said amount of x item?
		if sourceItem.limit ~= -1 and (sourceItem.count + amount) > sourceItem.limit then
            TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'error', text = _U('player_cannot_hold'), length = 5000})
--			TriggerClientEvent('esx:showNotification', _source, _U('player_cannot_hold'))
		else
			xPlayer.removeAccountMoney('black_money', price)
			xPlayer.addInventoryItem(itemName, amount)
			TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'success', text = _U('bought', amount, itemLabel, price), length = 5000})
--			TriggerClientEvent('esx:showNotification', _source, _U('bought', amount, itemLabel, price))
		end
	else
		local missingMoney = price - xPlayer.getAccount('black_money').money
		TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'error', text = _U('not_enough', missingMoney), length = 5000})
--		TriggerClientEvent('esx:showNotification', _source, _U('not_enough', missingMoney))
	end
end)


ESX.RegisterUsableItem('clip', function(source)
	local xPlayer = ESX.GetPlayerFromId(source)
	TriggerClientEvent('esx_blackmarket:clip', source)
	xPlayer.removeInventoryItem('clip', 1)
end)

ESX.RegisterUsableItem('silencer', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)	
    TriggerClientEvent('esx_blackmarket:silencer', source)
end)

ESX.RegisterUsableItem('flashlight', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)	
    TriggerClientEvent('esx_blackmarket:flashlight', source)
end)

ESX.RegisterUsableItem('grip', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerClientEvent('esx_blackmarket:grip', source)
end)

ESX.RegisterUsableItem('yusuf', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerClientEvent('esx_blackmarket:yusuf', source)
end)

ESX.RegisterUsableItem('magazine', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)	
    TriggerClientEvent('esx_blackmarket:magazine', source)
end)

ESX.RegisterUsableItem('scope', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)	
    TriggerClientEvent('esx_blackmarket:scope', source)
end)

ESX.RegisterUsableItem('bulletproof', function(source)
	local xPlayer = ESX.GetPlayerFromId(source)
	TriggerClientEvent('esx_blackmarket:bulletproof', source)
	xPlayer.removeInventoryItem('bulletproof', 1)
end)