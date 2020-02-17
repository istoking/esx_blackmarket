ESX                           = nil
local HasAlreadyEnteredMarker = false
local LastZone                = nil
local CurrentAction           = nil
local CurrentActionMsg        = ''
local CurrentActionData       = {}
local PlayerData              = {}

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	Citizen.Wait(5000)
	PlayerData = ESX.GetPlayerData()

	ESX.TriggerServerCallback('esx_blackmarket:requestDBItems', function(ShopItems)
		for k,v in pairs(ShopItems) do
			Config.Zones[k].Items = v
		end
	end)
end)

function OpenShopMenu(zone)
	PlayerData = ESX.GetPlayerData()

	local elements = {}
	for i=1, #Config.Zones[zone].Items, 1 do
		local item = Config.Zones[zone].Items[i]

		if item.limit == -1 then
			item.limit = 100
		end

		table.insert(elements, {
			label      = item.label .. ' - <span style="color: green;">$' .. item.price .. '</span>',
			label_real = item.label,
			item       = item.item,
			price      = item.price,

			-- menu properties
			value      = 1,
			type       = 'slider',
			min        = 1,
			max        = item.limit
		})
	end

	ESX.UI.Menu.CloseAll()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'blackmarket', {
		title    = _U('blackmarket'),
		align    = 'bottom-right',
		elements = elements
	}, function(data, menu)
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'shop_confirm', {
			title    = _U('shop_confirm', data.current.value, data.current.label_real, data.current.price * data.current.value),
			align    = 'bottom-right',
			elements = {
				{label = _U('no'),  value = 'no'},
				{label = _U('yes'), value = 'yes'}
			}
		}, function(data2, menu2)
			if data2.current.value == 'yes' then
				TriggerServerEvent('esx_blackmarket:buyItem', data.current.item, data.current.value, zone)
			end

			menu2.close()
		end, function(data2, menu2)
			menu2.close()
		end)
	end, function(data, menu)
		menu.close()
		CurrentAction     = 'shop_menu'
		CurrentActionMsg  = _U('press_menu')
		CurrentActionData = {zone = zone}
	end)
end

AddEventHandler('esx_blackmarket:hasEnteredMarker', function(zone)
	CurrentAction     = 'shop_menu'
	CurrentActionMsg  = _U('press_menu')
	CurrentActionData = {zone = zone}
end)

AddEventHandler('esx_blackmarket:hasExitedMarker', function(zone)
	CurrentAction = nil
	ESX.UI.Menu.CloseAll()
end)

function Draw3DText(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
        
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 41, 11, 41, 68)
end
--[[
-- Create Blips
Citizen.CreateThread(function()
	for k,v in pairs(Config.Zones) do
		for i = 1, #v.Pos, 1 do
			local blip = AddBlipForCoord(v.Pos[i].x, v.Pos[i].y, v.Pos[i].z)
			SetBlipSprite (blip, 110)
			SetBlipDisplay(blip, 4)
			SetBlipScale  (blip, 1.0)
			SetBlipColour (blip, 49)
			SetBlipAsShortRange(blip, true)
			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString(_U('blackmarket'))
			EndTextCommandSetBlipName(blip)
		end
	end
end)
--]]
-- Display markers
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)
		local coords = GetEntityCoords(GetPlayerPed(-1))

		for k,v in pairs(Config.Zones) do
			for i = 1, #v.Pos, 1 do
				if(Config.Type ~= -1 and GetDistanceBetweenCoords(coords, v.Pos[i].x, v.Pos[i].y, v.Pos[i].z, true) < Config.DrawDistance) then
					DrawMarker(Config.Type, v.Pos[i].x, v.Pos[i].y, v.Pos[i].z - 0.99, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 1.0, 139, 16, 20, 250, false, false, 2, false, false, false, false)
--					DrawMarker(Config.Type, v.Pos[i].x, v.Pos[i].y, v.Pos[i].z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.Size.x, Config.Size.y, Config.Size.z, Config.Color.r, Config.Color.g, Config.Color.b, 100, false, true, 2, false, false, false, false)
				end
			end
		end
	end
end)

-- Enter / Exit marker events
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)
		local coords      = GetEntityCoords(GetPlayerPed(-1))
		local isInMarker  = false
		local currentZone = nil

		for k,v in pairs(Config.Zones) do
			for i = 1, #v.Pos, 1 do
				if(GetDistanceBetweenCoords(coords, v.Pos[i].x, v.Pos[i].y, v.Pos[i].z, true) < Config.Size.x) then
					isInMarker  = true
					ShopItems   = v.Items
					currentZone = k
					LastZone    = k
					Draw3DText(v.Pos[i].x, v.Pos[i].y, v.Pos[i].z + 0.5, '~w~Press ~g~[E] ~w~to access the BlackMarket')
				end
			end
		end
		if isInMarker and not HasAlreadyEnteredMarker then
			HasAlreadyEnteredMarker = true
			TriggerEvent('esx_blackmarket:hasEnteredMarker', currentZone)
		end
		if not isInMarker and HasAlreadyEnteredMarker then
			HasAlreadyEnteredMarker = false
			TriggerEvent('esx_blackmarket:hasExitedMarker', LastZone)
		end
	end
end)

-- Key Controls
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)
		if CurrentAction ~= nil then
		    if IsControlJustReleased(0, 38) then
				if CurrentAction == 'shop_menu' then
					OpenShopMenu(CurrentActionData.zone)
				end
			CurrentAction = nil
			end
		else
			Citizen.Wait(500)
		end
	end
end)

RegisterNetEvent('esx_blackmarket:bulletproof')
AddEventHandler('esx_blackmarket:bulletproof', function()
	local playerPed = GetPlayerPed(-1)
	SetPedComponentVariation(playerPed, 9, 27, 9, 2)
	exports['progressBars']:startUI(5000, "Putting on Bullet-Proof Vest")
	Citizen.Wait(5000)
	AddArmourToPed(playerPed, 50)
	SetPedArmour(playerPed, 50)
	exports['mythic_notify']:SendAlert('success', 'You have equipped a Bullet-Proof Vest', 5000)
--	ESX.ShowNotification("You have equipped a Bullet-Proof Vest")
end)

RegisterNetEvent('esx_blackmarket:clip')
AddEventHandler('esx_blackmarket:clip', function()
  ped = GetPlayerPed(-1)
  if IsPedArmed(ped, 4) then
    hash=GetSelectedPedWeapon(ped)
	if hash~=nil then
	exports['progressBars']:startUI(1500, "Reloading")
	Citizen.Wait(1500)
	  AddAmmoToPed(GetPlayerPed(-1), hash, 250)
	    exports['mythic_notify']:SendAlert('success', 'You have used an Ammobox to reload your Weapon', 5000)
--      ESX.ShowNotification("You used an Ammobox to reload your weapon")
	else
		exports['mythic_notify']:SendAlert('error', 'You do not have a Weapon in your hands', 5000)
--      ESX.ShowNotification("You have no weapon in your hands")
    end
  else
	  exports['mythic_notify']:SendAlert('error', 'This type of Ammo is not suitable for this Weapon', 5000)
--    ESX.ShowNotification("This type of ammo is not suitable for this weapon")
  end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer 
end)

local used = 0

RegisterNetEvent('esx_blackmarket:silencer')
AddEventHandler('esx_blackmarket:silencer', function(duration)
				local inventory = ESX.GetPlayerData().inventory
				local silencer = 0
					for i=1, #inventory, 1 do
					  if inventory[i].name == 'silencer' then
						silencer = inventory[i].count
					  end
					end
    local ped = PlayerPedId()
    local currentWeaponHash = GetSelectedPedWeapon(ped)
		if used < silencer then

			if currentWeaponHash == GetHashKey("WEAPON_PISTOL") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_PISTOL"), GetHashKey("COMPONENT_AT_PI_SUPP_02"))
				exports['progressBars']:startUI(5000, "Attaching Suppressor")
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Silencer. It will re-equip every return to town.', 5000) 
		  		used = used + 1

		  	elseif currentWeaponHash == GetHashKey("WEAPON_PISTOL50") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_PISTOL50"), GetHashKey("COMPONENT_AT_AR_SUPP_02"))  
				exports['progressBars']:startUI(5000, "Attaching Suppressor")
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Silencer. It will re-equip every return to town.', 5000) 
		  		used = used + 1


		  	elseif currentWeaponHash == GetHashKey("WEAPON_COMBATPISTOL") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_COMBATPISTOL"), GetHashKey("COMPONENT_AT_PI_SUPP"))
				exports['progressBars']:startUI(5000, "Attaching Suppressor") 
				Citizen.Wait(5000) 
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Silencer. It will re-equip every return to town.', 5000) 
				used = used + 1

		  	elseif currentWeaponHash == GetHashKey("WEAPON_APPISTOL") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_APPISTOL"), GetHashKey("COMPONENT_AT_PI_SUPP"))
				exports['progressBars']:startUI(5000, "Attaching Suppressor")
				Citizen.Wait(5000)  
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Silencer. It will re-equip every return to town.', 5000) 
				used = used + 1

		  	elseif currentWeaponHash == GetHashKey("WEAPON_HEAVYPISTOL") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_HEAVYPISTOL"), GetHashKey("COMPONENT_AT_PI_SUPP"))
				exports['progressBars']:startUI(5000, "Attaching Suppressor")
				Citizen.Wait(5000)  
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Silencer. It will re-equip every return to town.', 5000) 
		  		used = used + 1

		  	elseif currentWeaponHash == GetHashKey("WEAPON_VINTAGEPISTOL") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_VINTAGEPISTOL"), GetHashKey("COMPONENT_AT_PI_SUPP"))  
				exports['progressBars']:startUI(5000, "Attaching Suppressor")
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Silencer. It will re-equip every return to town.', 5000)
		  		used = used + 1

		  	elseif currentWeaponHash == GetHashKey("WEAPON_SMG") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_SMG"), GetHashKey("COMPONENT_AT_PI_SUPP"))  
				exports['progressBars']:startUI(5000, "Attaching Suppressor")
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Silencer. It will re-equip every return to town.', 5000) 
		  		used = used + 1


		  	elseif currentWeaponHash == GetHashKey("WEAPON_MICROSMG") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_MICROSMG"), GetHashKey("COMPONENT_AT_AR_SUPP_02")) 
				exports['progressBars']:startUI(5000, "Attaching Suppressor")
				Citizen.Wait(5000) 
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Silencer. It will re-equip every return to town.', 5000) 
	            used = used + 1
				

		  	elseif currentWeaponHash == GetHashKey("WEAPON_ASSAULTSMG") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_ASSAULTSMG"), GetHashKey("COMPONENT_AT_AR_SUPP_02"))  
				exports['progressBars']:startUI(5000, "Attaching Suppressor")
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Silencer. It will re-equip every return to town.', 5000) 
	            used = used + 1
		  		

		  	elseif currentWeaponHash == GetHashKey("WEAPON_ASSAULTRIFLE") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_ASSAULTRIFLE"), GetHashKey("COMPONENT_AT_AR_SUPP_02"))  
				exports['progressBars']:startUI(5000, "Attaching Suppressor")
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Silencer. It will re-equip every return to town.', 5000) 
	            used = used + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_CARBINERIFLE") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_CARBINERIFLE"), GetHashKey("COMPONENT_AT_AR_SUPP"))  
				exports['progressBars']:startUI(5000, "Attaching Suppressor")
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Silencer. It will re-equip every return to town.', 5000) 
	            used = used + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_ADVANCEDRIFLE") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_ADVANCEDRIFLE"), GetHashKey("COMPONENT_AT_AR_SUPP"))  
				exports['progressBars']:startUI(5000, "Attaching Suppressor")
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Silencer. It will re-equip every return to town.', 5000) 
	            used = used + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_SPECIALCARBINE") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_SPECIALCARBINE"), GetHashKey("COMPONENT_AT_AR_SUPP_02")) 
				exports['progressBars']:startUI(5000, "Attaching Suppressor") 
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Silencer. It will re-equip every return to town.', 5000) 
	            used = used + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_BULLPUPRIFLE") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_BULLPUPRIFLE"), GetHashKey("COMPONENT_AT_AR_SUPP"))  
				exports['progressBars']:startUI(5000, "Attaching Suppressor")
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Silencer. It will re-equip every return to town.', 5000) 
	            used = used + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_ASSAULTSHOTGUN") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_ASSAULTSHOTGUN"), GetHashKey("COMPONENT_AT_AR_SUPP"))  
				exports['progressBars']:startUI(5000, "Attaching Suppressor")
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Silencer. It will re-equip every return to town.', 5000) 
	            used = used + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_HEAVYSHOTGUN") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_HEAVYSHOTGUN"), GetHashKey("COMPONENT_AT_AR_SUPP_02")) 
				exports['progressBars']:startUI(5000, "Attaching Suppressor") 
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Silencer. It will re-equip every return to town.', 5000) 
	            used = used + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_BULLPUPSHOTGUN") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_BULLPUPSHOTGUN"), GetHashKey("COMPONENT_AT_AR_SUPP_02"))  
				exports['progressBars']:startUI(5000, "Attaching Suppressor")
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Silencer. It will re-equip every return to town.', 5000) 
	            used = used + 1
		  		 
		  	elseif currentWeaponHash == GetHashKey("WEAPON_PUMPSHOTGUN") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_PUMPSHOTGUN"), GetHashKey("COMPONENT_AT_SR_SUPP"))  
				exports['progressBars']:startUI(5000, "Attaching Suppressor")
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Silencer. It will re-equip every return to town.', 5000) 
	            used = used + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_MARKSMANRIFLE") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_MARKSMANRIFLE"), GetHashKey("COMPONENT_AT_AR_SUPP"))  
				exports['progressBars']:startUI(5000, "Attaching Suppressor")
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Silencer. It will re-equip every return to town.', 5000) 
	            used = used + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_SNIPERRIFLE") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_SNIPERRIFLE"), GetHashKey("COMPONENT_AT_AR_SUPP_02"))  
				exports['progressBars']:startUI(5000, "Attaching Suppressor")
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Silencer. It will re-equip every return to town.', 5000) 
	            used = used + 1
		  		
			else
				exports['mythic_notify']:SendAlert('error', 'You do not have a weapon in your hands, or your weapon can not take a Silencer.', 5000)
			end
			else
			exports['mythic_notify']:SendAlert('error', "You have no more Silencer\'s to add.", 5000)
		end
end)

local used2 = 0

RegisterNetEvent('esx_blackmarket:flashlight')
AddEventHandler('esx_blackmarket:flashlight', function(duration)
					local inventory = ESX.GetPlayerData().inventory
				local flashlight = 0
					for i=1, #inventory, 1 do
					  if inventory[i].name == 'flashlight' then
						flashlight = inventory[i].count
					  end
					end
    local ped = PlayerPedId()
    local currentWeaponHash = GetSelectedPedWeapon(ped)
		if used2 < flashlight then

			if currentWeaponHash == GetHashKey("WEAPON_PISTOL") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_PISTOL"), GetHashKey("COMPONENT_AT_PI_FLSH"))  
				exports['progressBars']:startUI(5000, "Attaching FlashLight")
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Flashlight. It will re-equip every return to town.', 5000) 
				used2 = used2 + 1
					   
		  	elseif currentWeaponHash == GetHashKey("WEAPON_PISTOL50") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_PISTOL50"), GetHashKey("COMPONENT_AT_PI_FLSH"))  
				exports['progressBars']:startUI(5000, "Attaching FlashLight")
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Flashlight. It will re-equip every return to town.', 5000) 
	            used2 = used2 + 1
		  		

		  	elseif currentWeaponHash == GetHashKey("WEAPON_COMBATPISTOL") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_COMBATPISTOL"), GetHashKey("COMPONENT_AT_PI_FLSH"))  
				exports['progressBars']:startUI(5000, "Attaching FlashLight")
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Flashlight. It will re-equip every return to town.', 5000) 
				used2 = used2 + 1
				
		  	elseif currentWeaponHash == GetHashKey("WEAPON_APPISTOL") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_APPISTOL"), GetHashKey("COMPONENT_AT_PI_FLSH"))
				exports['progressBars']:startUI(5000, "Attaching FlashLight")
				Citizen.Wait(5000)  
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Flashlight. It will re-equip every return to town.', 5000) 
	            used2 = used2 + 1
		  		 
		  	elseif currentWeaponHash == GetHashKey("WEAPON_HEAVYPISTOL") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_HEAVYPISTOL"), GetHashKey("COMPONENT_AT_PI_FLSH")) 
				exports['progressBars']:startUI(5000, "Attaching FlashLight") 
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Flashlight. It will re-equip every return to town.', 5000) 
	            used2 = used2 + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_SMG") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_SMG"), GetHashKey("COMPONENT_AT_AR_FLSH"))  
				exports['progressBars']:startUI(5000, "Attaching FlashLight")
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Flashlight. It will re-equip every return to town.', 5000) 
		  		used2 = used2 + 1


		  	elseif currentWeaponHash == GetHashKey("WEAPON_MICROSMG") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_MICROSMG"), GetHashKey("COMPONENT_AT_PI_FLSH"))
				exports['progressBars']:startUI(5000, "Attaching FlashLight") 
				Citizen.Wait(5000) 
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Flashlight. It will re-equip every return to town.', 5000) 
	            used2 = used2 + 1
				

		  	elseif currentWeaponHash == GetHashKey("WEAPON_ASSAULTSMG") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_ASSAULTSMG"), GetHashKey("COMPONENT_AT_AR_FLSH"))
				exports['progressBars']:startUI(5000, "Attaching FlashLight")
				Citizen.Wait(5000)  
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Flashlight. It will re-equip every return to town.', 5000) 
	            used2 = used2 + 1
				 
		  	elseif currentWeaponHash == GetHashKey("WEAPON_COMBATPDW") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_COMBATPDW"), GetHashKey("COMPONENT_AT_AR_FLSH"))
				exports['progressBars']:startUI(5000, "Attaching FlashLight")
				Citizen.Wait(5000)  
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Flashlight. It will re-equip every return to town.', 5000) 
	            used2 = used2 + 1
		  			

		  	elseif currentWeaponHash == GetHashKey("WEAPON_ASSAULTRIFLE") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_ASSAULTRIFLE"), GetHashKey("COMPONENT_AT_AR_FLSH"))
				exports['progressBars']:startUI(5000, "Attaching FlashLight") 
				Citizen.Wait(5000) 
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Flashlight. It will re-equip every return to town.', 5000) 
	            used2 = used2 + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_CARBINERIFLE") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_CARBINERIFLE"), GetHashKey("COMPONENT_AT_AR_FLSH"))
				exports['progressBars']:startUI(5000, "Attaching FlashLight")
				Citizen.Wait(5000)  
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Flashlight. It will re-equip every return to town.', 5000) 
	            used2 = used2 + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_ADVANCEDRIFLE") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_ADVANCEDRIFLE"), GetHashKey("COMPONENT_AT_AR_FLSH"))
				exports['progressBars']:startUI(5000, "Attaching FlashLight")
				Citizen.Wait(5000)  
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Flashlight. It will re-equip every return to town.', 5000) 
	            used2 = used2 + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_SPECIALCARBINE") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_SPECIALCARBINE"), GetHashKey("COMPONENT_AT_AR_FLSH"))
				exports['progressBars']:startUI(5000, "Attaching FlashLight") 
				Citizen.Wait(5000) 
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Flashlight. It will re-equip every return to town.', 5000) 
	            used2 = used2 + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_BULLPUPRIFLE") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_BULLPUPRIFLE"), GetHashKey("COMPONENT_AT_AR_FLSH"))
				exports['progressBars']:startUI(5000, "Attaching FlashLight")
				Citizen.Wait(5000)  
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Flashlight. It will re-equip every return to town.', 5000) 
	            used2 = used2 + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_ASSAULTSHOTGUN") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_ASSAULTSHOTGUN"), GetHashKey("COMPONENT_AT_AR_FLSH"))
				exports['progressBars']:startUI(5000, "Attaching FlashLight")
				Citizen.Wait(5000)  
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Flashlight. It will re-equip every return to town.', 5000) 
	            used2 = used2 + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_HEAVYSHOTGUN") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_HEAVYSHOTGUN"), GetHashKey("COMPONENT_AT_AR_FLSH"))
				exports['progressBars']:startUI(5000, "Attaching FlashLight")
				Citizen.Wait(5000)  
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Flashlight. It will re-equip every return to town.', 5000) 
	            used2 = used2 + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_BULLPUPSHOTGUN") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_BULLPUPSHOTGUN"), GetHashKey("COMPONENT_AT_AR_FLSH"))
				exports['progressBars']:startUI(5000, "Attaching FlashLight") 
				Citizen.Wait(5000) 
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Flashlight. It will re-equip every return to town.', 5000) 
	            used2 = used2 + 1
		  		 
		  	elseif currentWeaponHash == GetHashKey("WEAPON_PUMPSHOTGUN") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_PUMPSHOTGUN"), GetHashKey("COMPONENT_AT_AR_FLSH"))
				exports['progressBars']:startUI(5000, "Attaching FlashLight") 
				Citizen.Wait(5000) 
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Flashlight. It will re-equip every return to town.', 5000) 
	            used2 = used2 + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_MARKSMANRIFLE") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_MARKSMANRIFLE"), GetHashKey("COMPONENT_AT_AR_FLSH"))
				exports['progressBars']:startUI(5000, "Attaching FlashLight") 
				Citizen.Wait(5000) 
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Flashlight. It will re-equip every return to town.', 5000) 
	            used2 = used2 + 1
		  		
			else 
				exports['mythic_notify']:SendAlert('error', 'You do not have a weapon in your hands, or your weapon can not take a Flashlight.', 5000)
			end
		else
			exports['mythic_notify']:SendAlert('error', "You have no more Flashlight\'s to add", 5000)
		end
end)

local used3 = 0

RegisterNetEvent('esx_blackmarket:grip')
AddEventHandler('esx_blackmarket:grip', function(duration)
					local inventory = ESX.GetPlayerData().inventory
				local grip = 0
					for i=1, #inventory, 1 do
					  if inventory[i].name == 'grip' then
						grip = inventory[i].count
					  end
					end
    local ped = PlayerPedId()
    local currentWeaponHash = GetSelectedPedWeapon(ped)
		if used3 < grip then

			
			if currentWeaponHash == GetHashKey("WEAPON_COMBATPDW") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_COMBATPDW"), GetHashKey("COMPONENT_AT_AR_AFGRIP")) 
				exports['progressBars']:startUI(5000, "Attaching Grip") 
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Grip. It will re-equip every return to town.', 5000) 
		  		used3 = used3 + 1


		  	elseif currentWeaponHash == GetHashKey("WEAPON_ASSAULTRIFLE") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_ASSAULTRIFLE"), GetHashKey("COMPONENT_AT_AR_AFGRIP"))
				exports['progressBars']:startUI(5000, "Attaching Grip")
				Citizen.Wait(5000)  
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Grip. It will re-equip every return to town.', 5000) 
	            used3 = used3 + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_CARBINERIFLE") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_CARBINERIFLE"), GetHashKey("COMPONENT_AT_AR_AFGRIP"))
				exports['progressBars']:startUI(5000, "Attaching Grip") 
				Citizen.Wait(5000) 
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Grip. It will re-equip every return to town.', 5000) 
	            used3 = used3 + 1
		  		
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_SPECIALCARBINE") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_SPECIALCARBINE"), GetHashKey("COMPONENT_AT_AR_AFGRIP")) 
				exports['progressBars']:startUI(5000, "Attaching Grip") 
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Grip. It will re-equip every return to town.', 5000) 
	            used3 = used3 + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_BULLPUPRIFLE") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_BULLPUPRIFLE"), GetHashKey("COMPONENT_AT_AR_AFGRIP"))
				exports['progressBars']:startUI(5000, "Attaching Grip") 
				Citizen.Wait(5000) 
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Grip. It will re-equip every return to town.', 5000) 
	            used3 = used3 + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_ASSAULTSHOTGUN") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_ASSAULTSHOTGUN"), GetHashKey("COMPONENT_AT_AR_AFGRIP"))
				exports['progressBars']:startUI(5000, "Attaching Grip")  
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Grip. It will re-equip every return to town.', 5000) 
	            used3 = used3 + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_HEAVYSHOTGUN") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_HEAVYSHOTGUN"), GetHashKey("COMPONENT_AT_AR_AFGRIP")) 
				exports['progressBars']:startUI(5000, "Attaching Grip")
				Citizen.Wait(5000) 
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Grip. It will re-equip every return to town.', 5000) 
	            used3 = used3 + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_BULLPUPSHOTGUN") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_BULLPUPSHOTGUN"), GetHashKey("COMPONENT_AT_AR_AFGRIP"))
				exports['progressBars']:startUI(5000, "Attaching Grip") 
				Citizen.Wait(5000) 
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Grip. It will re-equip every return to town.', 5000) 
	            used3 = used3 + 1
		  		 
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_MARKSMANRIFLE") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_MARKSMANRIFLE"), GetHashKey("COMPONENT_AT_AR_AFGRIP"))
				exports['progressBars']:startUI(5000, "Attaching Grip")
				Citizen.Wait(5000)  
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Grip. It will re-equip every return to town.', 5000) 
	            used3 = used3 + 1
			else
				exports['mythic_notify']:SendAlert('error', 'You do not have a weapon in your hands, or your weapon can not take a Grip.', 5000)
			end
		else
			exports['mythic_notify']:SendAlert('error', "You have no more Grip\'s to add", 5000)
		end
end)

local used4 = 0

RegisterNetEvent('esx_blackmarket:yusuf')
AddEventHandler('esx_blackmarket:yusuf', function(duration)
					local inventory = ESX.GetPlayerData().inventory
				local yusuf = 0
					for i=1, #inventory, 1 do
					  if inventory[i].name == 'yusuf' then
						yusuf = inventory[i].count
					  end
					end
					
    local ped = PlayerPedId()
    local currentWeaponHash = GetSelectedPedWeapon(ped)
		if used4 < yusuf then

			if currentWeaponHash == GetHashKey("WEAPON_PISTOL") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_PISTOL"), GetHashKey("COMPONENT_PISTOL_VARMOD_LUXE"))
				exports['progressBars']:startUI(5000, "Attaching Deluxe Weapon Skin") 
				Citizen.Wait(5000) 
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped your Deluxe Weapon Skin. It will re-equip every return to town.', 5000) 
		  		used4 = used4 + 1

		  	elseif currentWeaponHash == GetHashKey("WEAPON_PISTOL50") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_PISTOL50"), GetHashKey("COMPONENT_PISTOL50_VARMOD_LUXE"))
				exports['progressBars']:startUI(5000, "Attaching Deluxe Weapon Skin")  
				Citizen.Wait(5000)
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped your Deluxe Weapon Skin. It will re-equip every return to town.', 5000) 
				used4 = used4 + 1
				   
			elseif currentWeaponHash == GetHashKey("WEAPON_COMBATPISTOL") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_COMBATPISTOL"), GetHashKey("COMPONENT_COMBATPISTOL_VARMOD_LOWRIDER"))
				exports['progressBars']:startUI(5000, "Attaching Deluxe Weapon Skin")
				Citizen.Wait(5000)  
				exports['mythic_notify']:SendAlert('success', 'You have just equipped your Deluxe Weapon Skin. It will re-equip every return to town.', 5000) 
				used4 = used4 + 1
				  
            elseif currentWeaponHash == GetHashKey("WEAPON_SNSPISTOL") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_SNSPISTOL"), GetHashKey("COMPONENT_SNSPISTOL_VARMOD_LOWRIDER"))
				exports['progressBars']:startUI(5000, "Attaching Deluxe Weapon Skin")
				Citizen.Wait(5000)  
	            exports['mythic_notify']:SendAlert('success', 'You have just equipped your Deluxe Weapon Skin. It will re-equip every return to town.', 5000) 
	            used = used + 1
				
		  	elseif currentWeaponHash == GetHashKey("WEAPON_APPISTOL") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_APPISTOL"), GetHashKey("COMPONENT_APPISTOL_VARMOD_LUXE"))
				exports['progressBars']:startUI(5000, "Attaching Deluxe Weapon Skin")
				Citizen.Wait(5000)  
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped your Deluxe Weapon Skin. It will re-equip every return to town.', 5000) 
	            used4 = used4 + 1
		  		 
		  	elseif currentWeaponHash == GetHashKey("WEAPON_HEAVYPISTOL") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_HEAVYPISTOL"), GetHashKey("COMPONENT_HEAVYPISTOL_VARMOD_LUXE"))
				exports['progressBars']:startUI(5000, "Attaching Deluxe Weapon Skin")
				Citizen.Wait(5000)  
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped your Deluxe Weapon Skin. It will re-equip every return to town.', 5000) 
	            used4 = used4 + 1

		  	elseif currentWeaponHash == GetHashKey("WEAPON_SMG") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_SMG"), GetHashKey("COMPONENT_SMG_VARMOD_LUXE"))
				exports['progressBars']:startUI(5000, "Attaching Deluxe Weapon Skin") 
				Citizen.Wait(5000) 
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped your Deluxe Weapon Skin. It will re-equip every return to town.', 5000) 
				used4 = used4 + 1
				   
			elseif currentWeaponHash == GetHashKey("WEAPON_PUMPSHOTGUN") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_PUMPSHOTGUN"), GetHashKey("COMPONENT_PUMPSHOTGUN_VARMOD_LOWRIDER"))
				exports['progressBars']:startUI(5000, "Attaching Deluxe Weapon Skin") 
				Citizen.Wait(5000) 
				exports['mythic_notify']:SendAlert('success', 'You have just equipped your Deluxe Weapon Skin. It will re-equip every return to town.', 5000) 
				used4 = used4 + 1

			elseif currentWeaponHash == GetHashKey("WEAPON_SAWNOFFSHOTGUN") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_SAWNOFFSHOTGUN"), GetHashKey("COMPONENT_SAWNOFFSHOTGUN_VARMOD_LUXE"))
				exports['progressBars']:startUI(5000, "Attaching Deluxe Weapon Skin")
				Citizen.Wait(5000)  
				exports['mythic_notify']:SendAlert('success', 'You have just equipped your Deluxe Weapon Skin. It will re-equip every return to town.', 5000) 
				used4 = used4 + 1

		  	elseif currentWeaponHash == GetHashKey("WEAPON_MICROSMG") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_MICROSMG"), GetHashKey("COMPONENT_MICROSMG_VARMOD_LUXE"))
				exports['progressBars']:startUI(5000, "Attaching Deluxe Weapon Skin")
				Citizen.Wait(5000)  
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped your Deluxe Weapon Skin. It will re-equip every return to town.', 5000) 
	            used4 = used4 + 1

		  	elseif currentWeaponHash == GetHashKey("WEAPON_ASSAULTRIFLE") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_ASSAULTRIFLE"), GetHashKey("COMPONENT_ASSAULTRIFLE_VARMOD_LUXE")) 
				exports['progressBars']:startUI(5000, "Attaching Deluxe Weapon Skin")
				Citizen.Wait(5000) 
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped your Deluxe Weapon Skin. It will re-equip every return to town.', 5000) 
	            used4 = used4 + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_CARBINERIFLE") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_CARBINERIFLE"), GetHashKey("COMPONENT_CARBINERIFLE_VARMOD_LUXE"))
				exports['progressBars']:startUI(5000, "Attaching Deluxe Weapon Skin")
				Citizen.Wait(5000)  
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped your Deluxe Weapon Skin. It will re-equip every return to town.', 5000) 
	            used4 = used4 + 1
		  		
		  	elseif currentWeaponHash == GetHashKey("WEAPON_ADVANCEDRIFLE") then
				GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_ADVANCEDRIFLE"), GetHashKey("COMPONENT_ADVANCEDRIFLE_VARMOD_LUXE"))
				exports['progressBars']:startUI(5000, "Attaching Deluxe Weapon Skin")
				Citizen.Wait(5000)  
		  		exports['mythic_notify']:SendAlert('success', 'You have just equipped your Deluxe Weapon Skin. It will re-equip every return to town.', 5000) 
	            used4 = used4 + 1
		  	else 
				exports['mythic_notify']:SendAlert('error', 'You do not have a weapon in your hands, or your weapon can not take a Deluxe Skin.', 5000)
			end
		else
			exports['mythic_notify']:SendAlert('error', "You have no more Deluxe Skin\'s to add", 5000)
		end
end)

local used5 = 0

RegisterNetEvent('esx_blackmarket:magazine')
AddEventHandler('esx_blackmarket:magazine', function(duration)
				local inventory = ESX.GetPlayerData().inventory
				local magazine = 0
					for i=1, #inventory, 1 do
					  if inventory[i].name == 'magazine' then
						magazine = inventory[i].count
					  end
					end
	local ped = PlayerPedId()
	local currentWeaponHash = GetSelectedPedWeapon(ped)
		if used5 < magazine then

			if currentWeaponHash == GetHashKey("WEAPON_PISTOL") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_PISTOL"), GetHashKey("COMPONENT_PISTOL_CLIP_02"))
					exports['progressBars']:startUI(5000, "Attaching Extended Magazine") 
					Citizen.Wait(5000) 
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with an Extended Magazine. It will re-equip every return to town.', 5000) 
					used5 = used5 + 1

			  elseif currentWeaponHash == GetHashKey("WEAPON_COMBATPISTOL") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_COMBATPISTOL"), GetHashKey("COMPONENT_COMBATPISTOL_CLIP_02"))
					exports['progressBars']:startUI(5000, "Attaching Extended Magazine")
					Citizen.Wait(5000)  
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with an Extended Magazine. It will re-equip every return to town.', 5000) 
					used5 = used5 + 1

			  elseif currentWeaponHash == GetHashKey("WEAPON_APPISTOL") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_APPISTOL"), GetHashKey("COMPONENT_APPISTOL_CLIP_02"))
					exports['progressBars']:startUI(5000, "Attaching Extended Magazine")
					Citizen.Wait(5000)  
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with an Extended Magazine. It will re-equip every return to town.', 5000) 
					used5 = used5 + 1

			  elseif currentWeaponHash == GetHashKey("WEAPON_PISTOL50") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_PISTOL50"), GetHashKey("COMPONENT_PISTOL50_CLIP_02"))
					exports['progressBars']:startUI(5000, "Attaching Extended Magazine")
					Citizen.Wait(5000)  
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with an Extended Magazine. It will re-equip every return to town.', 5000) 
					used5 = used5 + 1

			  elseif currentWeaponHash == GetHashKey("WEAPON_SNSPISTOL") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_SNSPISTOL"), GetHashKey("COMPONENT_SNSPISTOL_CLIP_02"))
					exports['progressBars']:startUI(5000, "Attaching Extended Magazine")
					Citizen.Wait(5000)  
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with an Extended Magazine. It will re-equip every return to town.', 5000) 
					used5 = used5 + 1

			  elseif currentWeaponHash == GetHashKey("WEAPON_HEAVYPISTOL") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_HEAVYPISTOL"), GetHashKey("COMPONENT_HEAVYPISTOL_CLIP_02"))
					exports['progressBars']:startUI(5000, "Attaching Extended Magazine")
					Citizen.Wait(5000)  
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with an Extended Magazine. It will re-equip every return to town.', 5000) 
					used5 = used5 + 1

			  elseif currentWeaponHash == GetHashKey("WEAPON_VINTAGEPISTOL") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_VINTAGEPISTOL"), GetHashKey("COMPONENT_VINTAGEPISTOL_CLIP_02"))
					exports['progressBars']:startUI(5000, "Attaching Extended Magazine")
					Citizen.Wait(5000)  
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with an Extended Magazine. It will re-equip every return to town.', 5000)
					used5 = used5 + 1

			  elseif currentWeaponHash == GetHashKey("WEAPON_MICROSMG") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_MICROSMG"), GetHashKey("COMPONENT_MICROSMG_CLIP_02"))
					exports['progressBars']:startUI(5000, "Attaching Extended Magazine")
					Citizen.Wait(5000)  
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with an Extended Magazine. It will re-equip every return to town.', 5000) 
				    used5 = used5 + 1

			  elseif currentWeaponHash == GetHashKey("WEAPON_SMG") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_SMG"), GetHashKey("COMPONENT_SMG_CLIP_02"))
					exports['progressBars']:startUI(5000, "Attaching Extended Magazine")
					Citizen.Wait(5000)  
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with an Extended Magazine. It will re-equip every return to town.', 5000) 
					used5 = used5 + 1				

			  elseif currentWeaponHash == GetHashKey("WEAPON_ASSAULTSMG") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_ASSAULTSMG"), GetHashKey("COMPONENT_ASSAULTSMG_CLIP_02"))
					exports['progressBars']:startUI(5000, "Attaching Extended Magazine")
					Citizen.Wait(5000)  
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with an Extended Magazine. It will re-equip every return to town.', 5000) 
				    used5 = used5 + 1
				  
			  elseif currentWeaponHash == GetHashKey("WEAPON_MINISMG") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_MINISMG"), GetHashKey("COMPONENT_MINISMG_CLIP_02"))
					exports['progressBars']:startUI(5000, "Attaching Extended Magazine")
					Citizen.Wait(5000)  
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with an Extended Magazine. It will re-equip every return to town.', 5000) 
				    used5 = used5 + 1

			  elseif currentWeaponHash == GetHashKey("WEAPON_MACHINEPISTOL") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_MACHINEPISTOL"), GetHashKey("COMPONENT_MACHINEPISTOL_CLIP_02"))
					exports['progressBars']:startUI(5000, "Attaching Extended Magazine") 
					Citizen.Wait(5000) 
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with an Extended Magazine. It will re-equip every return to town.', 5000) 
				    used5 = used5 + 1

			  elseif currentWeaponHash == GetHashKey("WEAPON_COMBATPDW") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_COMBATPDW"), GetHashKey("COMPONENT_COMBATPDW_CLIP_02"))
					exports['progressBars']:startUI(5000, "Attaching Extended Magazine") 
					Citizen.Wait(5000) 
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with an Extended Magazine. It will re-equip every return to town.', 5000) 
				    used5 = used5 + 1

			  elseif currentWeaponHash == GetHashKey("WEAPON_ASSAULTSHOTGUN") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_ASSAULTSHOTGUN"), GetHashKey("COMPONENT_ASSAULTSHOTGUN_CLIP_02"))
					exports['progressBars']:startUI(5000, "Attaching Extended Magazine") 
					Citizen.Wait(5000) 
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with an Extended Magazine. It will re-equip every return to town.', 5000) 
				    used5 = used5 + 1

			  elseif currentWeaponHash == GetHashKey("WEAPON_HEAVYSHOTGUN") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_HEAVYSHOTGUN"), GetHashKey("COMPONENT_HEAVYSHOTGUN_CLIP_02"))
					exports['progressBars']:startUI(5000, "Attaching Extended Magazine") 
					Citizen.Wait(5000) 
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with an Extended Magazine. It will re-equip every return to town.', 5000) 
				    used5 = used5 + 1

			  elseif currentWeaponHash == GetHashKey("WEAPON_ASSAULTRIFLE") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_ASSAULTRIFLE"), GetHashKey("COMPONENT_ASSAULTRIFLE_CLIP_02"))
					exports['progressBars']:startUI(5000, "Attaching Extended Magazine") 
					Citizen.Wait(5000) 
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with an Extended Magazine. It will re-equip every return to town.', 5000) 
				    used5 = used5 + 1
				  
			  elseif currentWeaponHash == GetHashKey("WEAPON_CARBINERIFLE") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_CARBINERIFLE"), GetHashKey("COMPONENT_CARBINERIFLE_CLIP_02"))
					exports['progressBars']:startUI(5000, "Attaching Extended Magazine") 
					Citizen.Wait(5000) 
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with an Extended Magazine. It will re-equip every return to town.', 5000) 
				    used5 = used5 + 1
				  
			  elseif currentWeaponHash == GetHashKey("WEAPON_ADVANCEDRIFLE") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_ADVANCEDRIFLE"), GetHashKey("COMPONENT_ADVANCEDRIFLE_CLIP_02"))
					exports['progressBars']:startUI(5000, "Attaching Extended Magazine")  
					Citizen.Wait(5000)
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with an Extended Magazine. It will re-equip every return to town.', 5000) 
				    used5 = used5 + 1
				  
			  elseif currentWeaponHash == GetHashKey("WEAPON_SPECIALCARBINE") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_SPECIALCARBINE"), GetHashKey("COMPONENT_SPECIALCARBINE_CLIP_02"))
					exports['progressBars']:startUI(5000, "Attaching Extended Magazine") 
					Citizen.Wait(5000) 
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with an Extended Magazine. It will re-equip every return to town.', 5000) 
				    used5 = used5 + 1
				  
			  elseif currentWeaponHash == GetHashKey("WEAPON_BULLPUPRIFLE") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_BULLPUPRIFLE"), GetHashKey("COMPONENT_BULLPUPRIFLE_CLIP_02"))
					exports['progressBars']:startUI(5000, "Attaching Extended Magazine") 
					Citizen.Wait(5000) 
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with an Extended Magazine. It will re-equip every return to town.', 5000) 
				    used5 = used5 + 1
			  else 
				exports['mythic_notify']:SendAlert('error', 'You do not have a weapon in your hands, or your weapon can not take an Extended Magazine.', 5000)
			end
			else
				exports['mythic_notify']:SendAlert('error', "You have no more Extended Magazine\'s to add.", 5000) 
		end
end)

RegisterNetEvent('esx_blackmarket:scope')
AddEventHandler('esx_blackmarket:scope', function(duration)
				local inventory = ESX.GetPlayerData().inventory
				local scope = 0
					for i=1, #inventory, 1 do
					  if inventory[i].name == 'scope' then
						scope = inventory[i].count
					  end
					end
	local ped = PlayerPedId()
	local currentWeaponHash = GetSelectedPedWeapon(ped)
		if used6 < scope then

			if currentWeaponHash == GetHashKey("WEAPON_MICROSMG") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_MICROSMG"), GetHashKey("COMPONENT_AT_SCOPE_MACRO"))
					exports['progressBars']:startUI(5000, "Attaching Weapon Scope") 
					Citizen.Wait(5000) 
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Scope. It will re-equip every return to town.', 5000) 
				    used6 = used6 + 1

			  elseif currentWeaponHash == GetHashKey("WEAPON_SMG") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_SMG"), GetHashKey("COMPONENT_AT_SCOPE_MACRO_02"))
					exports['progressBars']:startUI(5000, "Attaching Weapon Scope") 
					Citizen.Wait(5000) 
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Scope. It will re-equip every return to town.', 5000) 
					used6 = used6 + 1				

			  elseif currentWeaponHash == GetHashKey("WEAPON_ASSAULTSMG") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_ASSAULTSMG"), GetHashKey("COMPONENT_AT_SCOPE_MACRO"))
					exports['progressBars']:startUI(5000, "Attaching Weapon Scope") 
					Citizen.Wait(5000) 
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Scope. It will re-equip every return to town.', 5000) 
				    used6 = used6 + 1

			  elseif currentWeaponHash == GetHashKey("WEAPON_COMBATPDW") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_COMBATPDW"), GetHashKey("COMPONENT_AT_SCOPE_SMALL")) 
					exports['progressBars']:startUI(5000, "Attaching Weapon Scope") 
					Citizen.Wait(5000)
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Scope. It will re-equip every return to town.', 5000) 
				    used6 = used6 + 1

			  elseif currentWeaponHash == GetHashKey("WEAPON_ASSAULTRIFLE") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_ASSAULTRIFLE"), GetHashKey("COMPONENT_AT_SCOPE_MACRO"))
					exports['progressBars']:startUI(5000, "Attaching Weapon Scope") 
					Citizen.Wait(5000) 
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Scope. It will re-equip every return to town.', 5000) 
				    used6 = used6 + 1
				  
			  elseif currentWeaponHash == GetHashKey("WEAPON_CARBINERIFLE") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_CARBINERIFLE"), GetHashKey("COMPONENT_AT_SCOPE_MEDIUM")) 
					exports['progressBars']:startUI(5000, "Attaching Weapon Scope") 
					Citizen.Wait(5000)
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Scope. It will re-equip every return to town.', 5000) 
				    used6 = used6 + 1
				  
			  elseif currentWeaponHash == GetHashKey("WEAPON_ADVANCEDRIFLE") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_ADVANCEDRIFLE"), GetHashKey("COMPONENT_AT_SCOPE_SMALL"))
					exports['progressBars']:startUI(5000, "Attaching Weapon Scope")  
					Citizen.Wait(5000)
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Scope. It will re-equip every return to town.', 5000) 
				    used6 = used6 + 1
				  
			  elseif currentWeaponHash == GetHashKey("WEAPON_SPECIALCARBINE") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_SPECIALCARBINE"), GetHashKey("COMPONENT_AT_SCOPE_MEDIUM"))
					exports['progressBars']:startUI(5000, "Attaching Weapon Scope") 
					Citizen.Wait(5000) 
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Scope. It will re-equip every return to town.', 5000) 
				    used6 = used6 + 1
				  
			  elseif currentWeaponHash == GetHashKey("WEAPON_BULLPUPRIFLE") then
					GiveWeaponComponentToPed(GetPlayerPed(-1), GetHashKey("WEAPON_BULLPUPRIFLE"), GetHashKey("COMPONENT_AT_SCOPE_SMALL")) 
					exports['progressBars']:startUI(5000, "Attaching Weapon Scope")
					Citizen.Wait(5000)
				    exports['mythic_notify']:SendAlert('success', 'You have just equipped yourself with a Scope. It will re-equip every return to town.', 5000) 
				    used6 = used6 + 1
			  else 
				exports['mythic_notify']:SendAlert('error', 'You do not have a weapon in your hands, or your weapon can not take a Scope.', 5000)
			end
			else
				exports['mythic_notify']:SendAlert('error', "You have no more Scope\'s to add.", 5000) 
		end
end)


AddEventHandler('playerSpawned', function()
  used = 0
  used2 = 0
  used3 = 0
  used4 = 0
  used5 = 0
  used6 = 0
end)
