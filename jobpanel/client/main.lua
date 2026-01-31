ESX = exports['es_extended']:getSharedObject()

local isOpen = false
local currentJob = nil
local currentGrade = 0
local PlayerData = {}

-- Ladda locale filer
local function LoadLocales()
    local localeFile = LoadResourceFile(GetCurrentResourceName(), 'locales/' .. Config.Locale .. '.lua')
    if localeFile then
        load(localeFile)()
    end
    
    -- Ladda även engelska som fallback
    local enFile = LoadResourceFile(GetCurrentResourceName(), 'locales/en.lua')
    if enFile then
        load(enFile)()
    end
end

CreateThread(function()
    LoadLocales()
    
    while ESX.GetPlayerData().job == nil do
        Wait(100)
    end
    PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

-- Hämta permissions för en rank
function GetPermissionsForGrade(job, grade)
    local jobPerms = Config.RankPermissions[job]
    
    if jobPerms and jobPerms[grade] then
        return jobPerms[grade]
    end
    
    local defaultPerms = Config.RankPermissions['default']
    if defaultPerms[grade] then
        return defaultPerms[grade]
    end
    
    return defaultPerms['boss'] or {}
end

-- Öppna panelen
function OpenJobPanel()
    if not PlayerData.job or PlayerData.job.name == 'unemployed' then
        ESX.ShowNotification(L('no_permission'))
        return
    end
    
    currentJob = PlayerData.job.name
    currentGrade = PlayerData.job.grade
    
    local permissions = GetPermissionsForGrade(currentJob, currentGrade)
    
    if not permissions.canViewPanel then
        ESX.ShowNotification(L('no_permission'))
        return
    end
    
    ESX.TriggerServerCallback('jobpanel:server:getData', function(data)
        if not data then return end
        
        SetNuiFocus(true, true)
        isOpen = true
        
        local playerName = "Okänd"
        if PlayerData.firstName and PlayerData.lastName then
            playerName = PlayerData.firstName .. ' ' .. PlayerData.lastName
        end
        
        SendNUIMessage({
            action = 'openPanel',
            job = currentJob,
            grade = currentGrade,
            playerName = playerName,
            rankName = PlayerData.job.grade_label or PlayerData.job.grade_name or ('Rank ' .. currentGrade),
            permissions = permissions,
            employees = data.employees,
            ranks = data.ranks,
            finances = data.finances,
            vehicles = Config.VehicleOrders[currentJob] or {},
            items = Config.ItemOrders[currentJob] or {},
            logs = data.logs,
            branding = Config.Branding,
            locale = GetAllLocaleStrings()
        })
    end, currentJob)
end

-- NUI Callbacks
RegisterNUICallback('closePanel', function(data, cb)
    SetNuiFocus(false, false)
    isOpen = false
    cb('ok')
end)

RegisterNUICallback('getNearbyPlayers', function(data, cb)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearbyPlayers = {}
    
    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)
            
            if distance <= 10.0 then
                table.insert(nearbyPlayers, {
                    id = GetPlayerServerId(playerId),
                    name = GetPlayerName(playerId)
                })
            end
        end
    end
    
    SendNUIMessage({
        action = 'updateNearbyPlayers',
        players = nearbyPlayers
    })
    
    cb('ok')
end)

RegisterNUICallback('hirePlayer', function(data, cb)
    TriggerServerEvent('jobpanel:server:hirePlayer', data.playerId, currentJob, data.grade)
    cb('ok')
end)

RegisterNUICallback('fireEmployee', function(data, cb)
    TriggerServerEvent('jobpanel:server:fireEmployee', data.identifier, currentJob)
    cb('ok')
end)

RegisterNUICallback('updateEmployee', function(data, cb)
    TriggerServerEvent('jobpanel:server:updateEmployee', data.identifier, currentJob, data.grade, data.individualSalary)
    cb('ok')
end)

RegisterNUICallback('updateSalaries', function(data, cb)
    TriggerServerEvent('jobpanel:server:updateSalaries', currentJob, data.salaries)
    cb('ok')
end)

RegisterNUICallback('giveBonus', function(data, cb)
    TriggerServerEvent('jobpanel:server:giveBonus', data.employee, data.amount, data.reason)
    cb('ok')
end)

RegisterNUICallback('updateRankPermissions', function(data, cb)
    TriggerServerEvent('jobpanel:server:updateRankPermissions', currentJob, data)
    cb('ok')
end)

RegisterNUICallback('societyMoney', function(data, cb)
    TriggerServerEvent('jobpanel:server:societyMoney', currentJob, data.action, data.amount, data.reason)
    cb('ok')
end)

RegisterNUICallback('orderVehicle', function(data, cb)
    TriggerServerEvent('jobpanel:server:orderVehicle', currentJob, data.model, data.price)
    cb('ok')
end)

RegisterNUICallback('orderItems', function(data, cb)
    TriggerServerEvent('jobpanel:server:orderItems', currentJob, data.items)
    cb('ok')
end)

RegisterNUICallback('refreshData', function(data, cb)
    TriggerServerEvent('jobpanel:server:refreshData')
    cb('ok')
end)

-- Kommandon
RegisterCommand('jobpanel', function()
    OpenJobPanel()
end, false)

RegisterKeyMapping('jobpanel', 'Öppna Jobpanel', 'keyboard', 'F6')

-- Stäng med ESC
CreateThread(function()
    while true do
        Wait(0)
        if isOpen then
            if IsControlJustPressed(0, 322) then
                SetNuiFocus(false, false)
                isOpen = false
                SendNUIMessage({ action = 'close' })
            end
        end
    end
end)

-- Events
RegisterNetEvent('jobpanel:client:updateEmployees', function(employees)
    if isOpen then
        SendNUIMessage({
            action = 'updateEmployees',
            employees = employees
        })
    end
end)

RegisterNetEvent('jobpanel:client:updateFinances', function(finances)
    if isOpen then
        SendNUIMessage({
            action = 'updateFinances',
            finances = finances
        })
    end
end)

RegisterNetEvent('jobpanel:client:notification', function(type, message)
    if type == 'success' then
        ESX.ShowNotification('~g~' .. message)
    elseif type == 'error' then
        ESX.ShowNotification('~r~' .. message)
    else
        ESX.ShowNotification(message)
    end
end)