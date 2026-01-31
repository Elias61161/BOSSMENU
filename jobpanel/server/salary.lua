ESX = exports['es_extended']:getSharedObject()

-- Salary management module

local SalaryConfig = {
    payInterval = 60, -- Minuter mellan löneutbetalningar
    overtimeMultiplier = 1.5,
    weeklyBonusEnabled = true,
    weeklyBonusThreshold = 20,
    weeklyBonusAmount = 5000
}

-- Beräkna lön för en spelare
function CalculatePlayerSalary(xPlayer)
    local job = xPlayer.getJob()
    local jobName = job.name
    local grade = job.grade
    local identifier = xPlayer.getIdentifier()
    
    local baseSalary = 0
    
    -- Kolla individuell lön först
    local individualResult = MySQL.Sync.fetchScalar(
        'SELECT data FROM job_panel_data WHERE identifier = ? AND job = ? AND data_type = ?',
        {identifier, jobName, 'salary'}
    )
    
    if individualResult then
        local data = json.decode(individualResult)
        baseSalary = data.salary or 0
    elseif Config.DefaultSalaries[jobName] and Config.DefaultSalaries[jobName][grade] then
        baseSalary = Config.DefaultSalaries[jobName][grade].salary
    else
        baseSalary = job.grade_salary or 0
    end
    
    -- Kolla övertid (mer än 8 timmar per dag)
    local todayHours = MySQL.Sync.fetchScalar(
        'SELECT IFNULL(hours, 0) FROM job_panel_hours WHERE identifier = ? AND date = CURDATE()',
        {identifier}
    ) or 0
    
    local finalSalary = baseSalary
    
    if todayHours > 8 then
        finalSalary = math.floor(baseSalary * SalaryConfig.overtimeMultiplier)
    end
    
    return finalSalary, baseSalary, todayHours
end

-- Veckobonus
function CheckWeeklyBonus(xPlayer)
    if not SalaryConfig.weeklyBonusEnabled then return 0 end
    
    local identifier = xPlayer.getIdentifier()
    
    local weeklyHours = MySQL.Sync.fetchScalar(
        'SELECT IFNULL(SUM(hours), 0) FROM job_panel_hours WHERE identifier = ? AND WEEK(date) = WEEK(NOW())',
        {identifier}
    ) or 0
    
    -- Kolla om bonus redan utbetalats denna vecka
    local bonusPaid = MySQL.Sync.fetchScalar(
        'SELECT COUNT(*) FROM job_panel_bonuses WHERE identifier = ? AND WEEK(paid_date) = WEEK(NOW()) AND type = ?',
        {identifier, 'weekly'}
    ) or 0
    
    if weeklyHours >= SalaryConfig.weeklyBonusThreshold and bonusPaid == 0 then
        xPlayer.addAccountMoney('bank', SalaryConfig.weeklyBonusAmount, 'Veckobonus för ' .. weeklyHours .. ' timmars arbete')
        
        MySQL.Async.execute('INSERT INTO job_panel_bonuses (identifier, type, amount, paid_date) VALUES (?, ?, ?, NOW())', {
            identifier, 'weekly', SalaryConfig.weeklyBonusAmount
        })
        
        TriggerClientEvent('jobpanel:client:notification', xPlayer.source, 'success', 'Du fick en veckobonus på $' .. SalaryConfig.weeklyBonusAmount .. '!')
        
        return SalaryConfig.weeklyBonusAmount
    end
    
    return 0
end

-- Hämta lönehistorik
function GetSalaryHistory(identifier, limit)
    limit = limit or 30
    
    local result = MySQL.Sync.fetchAll(
        'SELECT * FROM job_panel_salary_history WHERE identifier = ? ORDER BY paid_date DESC LIMIT ?',
        {identifier, limit}
    )
    
    return result or {}
end

-- Spara löneutbetalning
function LogSalaryPayment(identifier, job, amount, bonuses)
    MySQL.Async.execute(
        'INSERT INTO job_panel_salary_history (identifier, job, base_amount, bonuses, total_amount, paid_date) VALUES (?, ?, ?, ?, ?, NOW())',
        {identifier, job, amount, json.encode(bonuses or {}), amount + (bonuses and bonuses.total or 0)}
    )
end

-- Callback för löneinfo
ESX.RegisterServerCallback('jobpanel:server:getSalaryInfo', function(source, cb, identifier)
    local salary, baseSalary, hours = 0, 0, 0
    
    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    if xTarget then
        salary, baseSalary, hours = CalculatePlayerSalary(xTarget)
    end
    
    local history = GetSalaryHistory(identifier, 10)
    
    cb({
        currentSalary = salary,
        baseSalary = baseSalary,
        todayHours = hours,
        history = history
    })
end)

-- Massuppdatering av löner
RegisterNetEvent('jobpanel:server:bulkUpdateSalaries', function(job, updates)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local permissions = exports['jobpanel']:GetPlayerPermissions(src, job)
    if not permissions.canEditSalaries then
        TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Du har inte behörighet')
        return
    end
    
    local updated = 0
    
    for identifier, salary in pairs(updates) do
        MySQL.Async.execute(
            'INSERT INTO job_panel_data (identifier, job, data_type, data) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE data = ?',
            {identifier, job, 'salary', json.encode({salary = salary}), json.encode({salary = salary})}
        )
        updated = updated + 1
    end
    
    local playerName = xPlayer.getName()
    exports['jobpanel']:AddJobLog(job, 'salary', playerName .. ' uppdaterade ' .. updated .. ' individuella löner', playerName)
    
    TriggerClientEvent('jobpanel:client:notification', src, 'success', updated .. ' löner uppdaterade')
    exports['jobpanel']:RefreshJobPanel(job)
end)

-- Löneutbetalning thread (valfri - kan användas istället för ESX:s inbyggda)
--[[
CreateThread(function()
    while true do
        Wait(1000 * 60 * SalaryConfig.payInterval)
        
        local xPlayers = ESX.GetExtendedPlayers()
        
        for _, xPlayer in pairs(xPlayers) do
            local job = xPlayer.getJob()
            
            if job.name ~= 'unemployed' then
                local salary, baseSalary, hours = CalculatePlayerSalary(xPlayer)
                
                if salary > 0 then
                    xPlayer.addAccountMoney('bank', salary, 'Löneutbetalning')
                    TriggerClientEvent('jobpanel:client:notification', xPlayer.source, 'success', 'Du fick din lön: $' .. salary)
                    
                    LogSalaryPayment(xPlayer.getIdentifier(), job.name, salary, nil)
                end
                
                -- Logga arbetstimme
                MySQL.Async.execute('INSERT INTO job_panel_hours (identifier, job, hours, date) VALUES (?, ?, 1, CURDATE()) ON DUPLICATE KEY UPDATE hours = hours + 1', {
                    xPlayer.getIdentifier(), job.name
                })
                
                -- Kolla veckobonus
                CheckWeeklyBonus(xPlayer)
            end
        end
    end
end)
]]

-- Export
exports('CalculatePlayerSalary', CalculatePlayerSalary)
exports('CheckWeeklyBonus', CheckWeeklyBonus)
exports('GetSalaryHistory', GetSalaryHistory)
exports('LogSalaryPayment', LogSalaryPayment)