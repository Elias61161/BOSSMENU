ESX = exports['es_extended']:getSharedObject()

-- Permission management module

local PermissionCache = {}
local CACHE_TIME = 60000

-- Alla tillgängliga permissions
local AllPermissions = {
    { key = 'canViewPanel', label = 'Visa Jobpanel', description = 'Tillåt öppna jobpanelen' },
    { key = 'canViewEmployees', label = 'Visa Personal', description = 'Se lista över anställda' },
    { key = 'canViewFinances', label = 'Visa Ekonomi', description = 'Se företagets ekonomi' },
    { key = 'canHire', label = 'Anställa', description = 'Anställa nya medarbetare' },
    { key = 'canFire', label = 'Avskeda', description = 'Avskeda medarbetare' },
    { key = 'canPromote', label = 'Befordra/Degradera', description = 'Ändra rang på medarbetare' },
    { key = 'canEditSalaries', label = 'Ändra Löner', description = 'Redigera löner och ge bonusar' },
    { key = 'canOrderVehicles', label = 'Beställa Fordon', description = 'Köpa fordon till företaget' },
    { key = 'canOrderItems', label = 'Beställa Utrustning', description = 'Köpa utrustning' },
    { key = 'canViewLogs', label = 'Visa Loggar', description = 'Se aktivitetsloggar' },
    { key = 'canManageRanks', label = 'Hantera Ranker', description = 'Redigera rank permissions' },
    { key = 'canAccessStash', label = 'Tillgång till Förråd', description = 'Öppna företagets förråd' },
    { key = 'canManageVehicles', label = 'Hantera Fordonsflotta', description = 'Se och hantera alla företagsfordon' },
    { key = 'canGiveBonus', label = 'Ge Bonus', description = 'Ge bonus till anställda' },
    { key = 'canWithdrawMoney', label = 'Ta ut Pengar', description = 'Ta ut från företagskassan' },
    { key = 'canDepositMoney', label = 'Sätta in Pengar', description = 'Sätta in i företagskassan' }
}

-- Hämta cachad permission
function GetCachedPermissions(job, grade)
    local cacheKey = job .. '_' .. grade
    local cached = PermissionCache[cacheKey]
    
    if cached and (GetGameTimer() - cached.time) < CACHE_TIME then
        return cached.permissions
    end
    
    return nil
end

-- Spara till cache
function SetCachedPermissions(job, grade, permissions)
    local cacheKey = job .. '_' .. grade
    PermissionCache[cacheKey] = {
        permissions = permissions,
        time = GetGameTimer()
    }
end

-- Rensa cache
function ClearPermissionCache(job)
    if job then
        for key in pairs(PermissionCache) do
            if key:find(job) then
                PermissionCache[key] = nil
            end
        end
    else
        PermissionCache = {}
    end
end

-- Hämta permissions för en spelare (med cache)
function GetPlayerPermissionsWithCache(src, job)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return {} end
    
    local playerJob = xPlayer.getJob()
    if playerJob.name ~= job then return {} end
    
    local grade = playerJob.grade
    
    -- Kolla cache
    local cached = GetCachedPermissions(job, grade)
    if cached then return cached end
    
    -- Hämta permissions
    local permissions = exports['jobpanel']:GetPlayerPermissions(src, job)
    
    -- Spara i cache
    SetCachedPermissions(job, grade, permissions)
    
    return permissions
end

-- Kolla specifik permission
function HasPermission(src, job, permissionKey)
    local permissions = GetPlayerPermissionsWithCache(src, job)
    return permissions[permissionKey] == true
end

-- Kolla flera permissions (returnerar true om alla finns)
function HasAllPermissions(src, job, permissionKeys)
    local permissions = GetPlayerPermissionsWithCache(src, job)
    
    for _, key in ipairs(permissionKeys) do
        if not permissions[key] then
            return false
        end
    end
    
    return true
end

-- Kolla flera permissions (returnerar true om minst en finns)
function HasAnyPermission(src, job, permissionKeys)
    local permissions = GetPlayerPermissionsWithCache(src, job)
    
    for _, key in ipairs(permissionKeys) do
        if permissions[key] then
            return true
        end
    end
    
    return false
end

-- Hämta alla permissions för ett jobb
function GetAllJobPermissions(job)
    local result = {}
    
    -- Hämta ranker från databasen
    local grades = MySQL.Sync.fetchAll('SELECT grade FROM job_grades WHERE job_name = ?', {job})
    
    for _, row in ipairs(grades or {}) do
        local grade = row.grade
        
        -- Hämta från databas först
        local dbResult = MySQL.Sync.fetchScalar(
            'SELECT data FROM job_panel_data WHERE identifier = ? AND job = ? AND data_type = ?',
            {'permissions', job, 'permissions'}
        )
        
        if dbResult then
            local allPerms = json.decode(dbResult)
            result[grade] = allPerms[grade] or {}
        elseif Config.RankPermissions[job] and Config.RankPermissions[job][grade] then
            result[grade] = Config.RankPermissions[job][grade]
        else
            result[grade] = Config.RankPermissions['default'][grade] or Config.RankPermissions['default']['boss'] or {}
        end
    end
    
    return result
end

-- Sätt permissions för en rank
function SetRankPermissions(job, grade, permissions)
    local current = GetAllJobPermissions(job)
    current[grade] = permissions
    
    MySQL.Async.execute(
        'INSERT INTO job_panel_data (identifier, job, data_type, data) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE data = ?',
        {'permissions', job, 'permissions', json.encode(current), json.encode(current)}
    )
    
    ClearPermissionCache(job)
    
    return true
end

-- Kopiera permissions från en rank till en annan
function CopyRankPermissions(job, fromGrade, toGrade)
    local allPerms = GetAllJobPermissions(job)
    
    if not allPerms[fromGrade] then
        return false, 'Källrank har inga permissions'
    end
    
    allPerms[toGrade] = DeepCopy(allPerms[fromGrade])
    
    MySQL.Async.execute(
        'INSERT INTO job_panel_data (identifier, job, data_type, data) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE data = ?',
        {'permissions', job, 'permissions', json.encode(allPerms), json.encode(allPerms)}
    )
    
    ClearPermissionCache(job)
    
    return true
end

-- Återställ till default permissions
function ResetToDefaultPermissions(job, grade)
    local defaultPerms = Config.RankPermissions[job] and Config.RankPermissions[job][grade]
    
    if not defaultPerms then
        defaultPerms = Config.RankPermissions['default'][grade] or Config.RankPermissions['default']['boss']
    end
    
    return SetRankPermissions(job, grade, defaultPerms)
end

-- Callback för permission info
ESX.RegisterServerCallback('jobpanel:server:getAllPermissions', function(source, cb)
    cb(AllPermissions)
end)

ESX.RegisterServerCallback('jobpanel:server:getJobPermissions', function(source, cb, job)
    local permissions = GetAllJobPermissions(job)
    cb(permissions)
end)

-- Events
RegisterNetEvent('jobpanel:server:copyPermissions', function(job, fromGrade, toGrade)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    if not HasPermission(src, job, 'canManageRanks') then
        TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Du har inte behörighet')
        return
    end
    
    local success, err = CopyRankPermissions(job, fromGrade, toGrade)
    
    if success then
        local playerName = xPlayer.getName()
        exports['jobpanel']:AddJobLog(job, 'promote', playerName .. ' kopierade permissions från rank ' .. fromGrade .. ' till ' .. toGrade, playerName)
        TriggerClientEvent('jobpanel:client:notification', src, 'success', 'Permissions kopierade')
        exports['jobpanel']:RefreshJobPanel(job)
    else
        TriggerClientEvent('jobpanel:client:notification', src, 'error', err or 'Något gick fel')
    end
end)

RegisterNetEvent('jobpanel:server:resetPermissions', function(job, grade)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    if not HasPermission(src, job, 'canManageRanks') then
        TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Du har inte behörighet')
        return
    end
    
    ResetToDefaultPermissions(job, grade)
    
    local playerName = xPlayer.getName()
    exports['jobpanel']:AddJobLog(job, 'promote', playerName .. ' återställde permissions för rank ' .. grade, playerName)
    TriggerClientEvent('jobpanel:client:notification', src, 'success', 'Permissions återställda till standard')
    exports['jobpanel']:RefreshJobPanel(job)
end)

-- Helper function
function DeepCopy(original)
    local copy
    if type(original) == 'table' then
        copy = {}
        for key, value in next, original, nil do
            copy[DeepCopy(key)] = DeepCopy(value)
        end
        setmetatable(copy, DeepCopy(getmetatable(original)))
    else
        copy = original
    end
    return copy
end

-- Exports
exports('HasPermission', HasPermission)
exports('HasAllPermissions', HasAllPermissions)
exports('HasAnyPermission', HasAnyPermission)
exports('GetAllJobPermissions', GetAllJobPermissions)
exports('SetRankPermissions', SetRankPermissions)
exports('CopyRankPermissions', CopyRankPermissions)
exports('ResetToDefaultPermissions', ResetToDefaultPermissions)
exports('ClearPermissionCache', ClearPermissionCache)
exports('GetAllPermissionsList', function() return AllPermissions end)