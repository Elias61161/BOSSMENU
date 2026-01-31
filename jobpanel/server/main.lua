ESX = exports['es_extended']:getSharedObject()

-- Data storage
local JobData = {}
local IndividualSalaries = {}
local CustomRankPermissions = {}

-- Initialize
CreateThread(function()
    Wait(1000) -- Vänta på att databasen ska vara redo
    
    -- Kontrollera att tabeller finns
    local tableCheck = MySQL.Sync.fetchScalar("SHOW TABLES LIKE 'job_panel_data'")
    if not tableCheck then
        print('^1[CORE FIVE Scripts]^7 ^3VARNING: Databastabeller saknas! Kör SQL-scriptet först.^7')
        return
    end
    
    -- Ladda sparad data från databas
    local results = MySQL.Sync.fetchAll('SELECT * FROM job_panel_data')
    
    if results then
        for _, row in ipairs(results) do
            if row.data_type == 'salary' then
                if not IndividualSalaries[row.identifier] then
                    IndividualSalaries[row.identifier] = {}
                end
                local success, data = pcall(json.decode, row.data)
                if success and data then
                    IndividualSalaries[row.identifier][row.job] = data.salary
                end
            elseif row.data_type == 'permissions' then
                local success, data = pcall(json.decode, row.data)
                if success and data then
                    CustomRankPermissions[row.job] = data
                end
            elseif row.data_type == 'salaries' then
                local success, salaries = pcall(json.decode, row.data)
                if success and salaries then
                    if not Config.DefaultSalaries[row.job] then
                        Config.DefaultSalaries[row.job] = {}
                    end
                    for grade, salary in pairs(salaries) do
                        if not Config.DefaultSalaries[row.job][tonumber(grade)] then
                            Config.DefaultSalaries[row.job][tonumber(grade)] = {}
                        end
                        Config.DefaultSalaries[row.job][tonumber(grade)].salary = salary
                    end
                end
            end
        end
    end
    
    print('^2[CORE FIVE Scripts]^7 Jobpanel data loaded successfully!')
end)

-- ESX Callback för att hämta data
ESX.RegisterServerCallback('jobpanel:server:getData', function(source, cb, job)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then 
        cb(nil)
        return
    end
    
    -- Använd pcall för att fånga eventuella fel
    local success, result = pcall(function()
        local employees = GetJobEmployees(job)
        local ranks = GetJobRanks(job)
        local finances = GetJobFinances(job)
        local logs = GetJobLogs(job)
        
        return {
            employees = employees,
            ranks = ranks,
            finances = finances,
            logs = logs
        }
    end)
    
    if success then
        cb(result)
    else
        print('^1[CORE FIVE Scripts]^7 Error getting job data: ' .. tostring(result))
        cb({
            employees = {},
            ranks = {},
            finances = { balance = 0, transactions = {} },
            logs = {}
        })
    end
end)

-- Hämta anställda för ett jobb
function GetJobEmployees(job)
    local employees = {}
    
    local result = MySQL.Sync.fetchAll('SELECT identifier, firstname, lastname, job, job_grade FROM users WHERE job = ?', {job})
    
    if not result then
        return employees
    end
    
    for _, row in ipairs(result) do
        -- Kolla om spelaren är online
        local online = false
        local xPlayer = ESX.GetPlayerFromIdentifier(row.identifier)
        if xPlayer then
            online = true
        end
        
        -- Hämta individuell lön om den finns
        local individualSalary = nil
        if IndividualSalaries[row.identifier] and IndividualSalaries[row.identifier][job] then
            individualSalary = IndividualSalaries[row.identifier][job]
        end
        
        -- Hämta standard lön för ranken
        local salary = 0
        if Config.DefaultSalaries[job] and Config.DefaultSalaries[job][row.job_grade] then
            salary = Config.DefaultSalaries[job][row.job_grade].salary or 0
        end
        
        -- Hämta rank namn
        local rankName = 'Rank ' .. (row.job_grade or 0)
        if Config.DefaultSalaries[job] and Config.DefaultSalaries[job][row.job_grade] then
            rankName = Config.DefaultSalaries[job][row.job_grade].name or rankName
        end
        
        -- Hämta arbetstimmar (med felhantering)
        local hours = 0
        local hoursResult = MySQL.Sync.fetchScalar(
            'SELECT IFNULL(SUM(hours), 0) FROM job_panel_hours WHERE identifier = ? AND YEARWEEK(date, 1) = YEARWEEK(CURDATE(), 1)',
            {row.identifier}
        )
        if hoursResult then
            hours = hoursResult
        end
        
        table.insert(employees, {
            identifier = row.identifier,
            name = (row.firstname or 'Okänd') .. ' ' .. (row.lastname or ''),
            grade = row.job_grade or 0,
            rankName = rankName,
            salary = individualSalary or salary,
            individualSalary = individualSalary,
            online = online,
            hours = hours
        })
    end
    
    return employees
end

-- Hämta ranker för ett jobb
function GetJobRanks(job)
    local ranks = {}
    
    -- Hämta från jobs och job_grades tabeller
    local result = MySQL.Sync.fetchAll([[
        SELECT jg.grade, jg.name, jg.salary 
        FROM job_grades jg 
        WHERE jg.job_name = ? 
        ORDER BY jg.grade ASC
    ]], {job})
    
    if result then
        for _, row in ipairs(result) do
            local grade = row.grade
            local salary = 0
            
            if Config.DefaultSalaries[job] and Config.DefaultSalaries[job][grade] then
                salary = Config.DefaultSalaries[job][grade].salary or row.salary or 0
            else
                salary = row.salary or 0
            end
            
            -- Hämta custom permissions om de finns
            local permissions = nil
            if CustomRankPermissions[job] and CustomRankPermissions[job][tostring(grade)] then
                permissions = CustomRankPermissions[job][tostring(grade)]
            elseif CustomRankPermissions[job] and CustomRankPermissions[job][grade] then
                permissions = CustomRankPermissions[job][grade]
            elseif Config.RankPermissions[job] and Config.RankPermissions[job][grade] then
                permissions = Config.RankPermissions[job][grade]
            else
                permissions = Config.RankPermissions['default'][grade] or Config.RankPermissions['default']['boss'] or {}
            end
            
            table.insert(ranks, {
                grade = grade,
                name = row.name,
                salary = salary,
                permissions = permissions
            })
        end
    end
    
    -- Om inga ranker hittades i databasen, använd config
    if #ranks == 0 and Config.DefaultSalaries[job] then
        for grade, data in pairs(Config.DefaultSalaries[job]) do
            local permissions = nil
            if CustomRankPermissions[job] and CustomRankPermissions[job][grade] then
                permissions = CustomRankPermissions[job][grade]
            elseif Config.RankPermissions[job] and Config.RankPermissions[job][grade] then
                permissions = Config.RankPermissions[job][grade]
            else
                permissions = Config.RankPermissions['default'][grade] or Config.RankPermissions['default']['boss'] or {}
            end
            
            table.insert(ranks, {
                grade = grade,
                name = data.name,
                salary = data.salary,
                permissions = permissions
            })
        end
        table.sort(ranks, function(a, b) return a.grade < b.grade end)
    end
    
    return ranks
end

-- Hämta ekonomi för ett jobb
function GetJobFinances(job)
    local balance = 0
    local transactions = {}
    
    -- Hämta balance från society account
    if Config.UseSociety then
        local accountName = Config.SocietyAccountPrefix .. job
        
        -- Försök med esx_addonaccount
        local result = MySQL.Sync.fetchScalar('SELECT money FROM addon_account_data WHERE account_name = ? LIMIT 1', {accountName})
        if result then
            balance = result
        else
            -- Försök med esx_society (nyare version)
            result = MySQL.Sync.fetchScalar('SELECT money FROM society_accounts WHERE name = ? LIMIT 1', {accountName})
            if result then
                balance = result
            else
                -- Försök med datastore
                result = MySQL.Sync.fetchScalar('SELECT data FROM datastore_data WHERE name = ? LIMIT 1', {accountName})
                if result then
                    local success, data = pcall(json.decode, result)
                    if success and data and data.money then
                        balance = data.money
                    end
                end
            end
        end
    end
    
    -- Hämta transaktionshistorik
    local result = MySQL.Sync.fetchAll('SELECT * FROM job_panel_transactions WHERE job = ? ORDER BY timestamp DESC LIMIT 50', {job})
    
    if result then
        for _, row in ipairs(result) do
            table.insert(transactions, {
                type = row.type,
                amount = row.amount,
                description = row.description,
                by = row.by_name,
                timestamp = row.timestamp
            })
        end
    end
    
    return {
        balance = balance,
        transactions = transactions
    }
end

-- Hämta loggar för ett jobb
function GetJobLogs(job)
    local logs = {}
    
    local result = MySQL.Sync.fetchAll('SELECT * FROM job_panel_logs WHERE job = ? ORDER BY timestamp DESC LIMIT 100', {job})
    
    if result then
        for _, row in ipairs(result) do
            table.insert(logs, {
                type = row.type,
                message = row.message,
                by = row.by_name,
                timestamp = row.timestamp
            })
        end
    end
    
    return logs
end

-- Hämta arbetstimmar för en anställd (säker version)
function GetEmployeeHours(identifier)
    local result = MySQL.Sync.fetchScalar(
        'SELECT IFNULL(SUM(hours), 0) FROM job_panel_hours WHERE identifier = ? AND YEARWEEK(date, 1) = YEARWEEK(CURDATE(), 1)',
        {identifier}
    )
    return result or 0
end

-- Anställ spelare
RegisterNetEvent('jobpanel:server:hirePlayer', function(playerId, job, grade)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local xTarget = ESX.GetPlayerFromId(playerId)
    
    if not xPlayer or not xTarget then 
        TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Kunde inte hitta spelaren')
        return 
    end
    
    -- Kolla permission
    local permissions = GetPlayerPermissions(src, job)
    if not permissions.canHire then
        TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Du har inte behörighet')
        return
    end
    
    -- Sätt jobb
    xTarget.setJob(job, grade)
    
    local playerName = xPlayer.getName()
    local targetName = xTarget.getName()
    
    -- Logga
    AddJobLog(job, 'hire', playerName .. ' anställde ' .. targetName, playerName)
    
    -- Webhook
    SendWebhook(job, 'Ny Anställning', playerName .. ' anställde ' .. targetName, 65280)
    
    TriggerClientEvent('jobpanel:client:notification', src, 'success', 'Spelare anställd')
    TriggerClientEvent('jobpanel:client:notification', playerId, 'success', 'Du har blivit anställd')
    
    -- Uppdatera alla med panelen öppen
    RefreshJobPanel(job)
end)

-- Avskeda anställd
RegisterNetEvent('jobpanel:server:fireEmployee', function(identifier, job)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local permissions = GetPlayerPermissions(src, job)
    if not permissions.canFire then
        TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Du har inte behörighet')
        return
    end
    
    -- Hitta spelaren
    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    local targetName = 'Okänd'
    
    if xTarget then
        targetName = xTarget.getName()
        xTarget.setJob('unemployed', 0)
        TriggerClientEvent('jobpanel:client:notification', xTarget.source, 'error', 'Du har blivit avskedad')
    else
        -- Offline spelare - uppdatera i databas
        MySQL.Async.execute('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?', {
            'unemployed', 0, identifier
        })
        
        local result = MySQL.Sync.fetchScalar('SELECT CONCAT(firstname, " ", lastname) as name FROM users WHERE identifier = ?', {identifier})
        if result then
            targetName = result
        end
    end
    
    local playerName = xPlayer.getName()
    AddJobLog(job, 'fire', playerName .. ' avskedade ' .. targetName, playerName)
    SendWebhook(job, 'Avskedning', playerName .. ' avskedade ' .. targetName, 16711680)
    
    TriggerClientEvent('jobpanel:client:notification', src, 'success', 'Person avskedad')
    RefreshJobPanel(job)
end)

-- Uppdatera anställd
RegisterNetEvent('jobpanel:server:updateEmployee', function(identifier, job, grade, individualSalary)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local permissions = GetPlayerPermissions(src, job)
    if not permissions.canPromote and not permissions.canEditSalaries then
        TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Du har inte behörighet')
        return
    end
    
    local xTarget = ESX.GetPlayerFromIdentifier(identifier)
    
    if xTarget then
        xTarget.setJob(job, grade)
    else
        -- Offline update
        MySQL.Async.execute('UPDATE users SET job_grade = ? WHERE identifier = ? AND job = ?', {grade, identifier, job})
    end
    
    -- Spara individuell lön
    if individualSalary and tonumber(individualSalary) and tonumber(individualSalary) > 0 then
        individualSalary = tonumber(individualSalary)
        if not IndividualSalaries[identifier] then
            IndividualSalaries[identifier] = {}
        end
        IndividualSalaries[identifier][job] = individualSalary
        
        MySQL.Async.execute('INSERT INTO job_panel_data (identifier, job, data_type, data) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE data = ?', {
            identifier, job, 'salary', json.encode({salary = individualSalary}), json.encode({salary = individualSalary})
        })
    else
        if IndividualSalaries[identifier] then
            IndividualSalaries[identifier][job] = nil
        end
        MySQL.Async.execute('DELETE FROM job_panel_data WHERE identifier = ? AND job = ? AND data_type = ?', {identifier, job, 'salary'})
    end
    
    local playerName = xPlayer.getName()
    AddJobLog(job, 'promote', playerName .. ' uppdaterade en anställd', playerName)
    
    TriggerClientEvent('jobpanel:client:notification', src, 'success', 'Ändringar sparade')
    RefreshJobPanel(job)
end)

-- Ta bort individuell lön
RegisterNetEvent('jobpanel:server:removeIndividualSalary', function(identifier, job)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local permissions = GetPlayerPermissions(src, job)
    if not permissions.canEditSalaries then
        TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Du har inte behörighet')
        return
    end
    
    if IndividualSalaries[identifier] then
        IndividualSalaries[identifier][job] = nil
    end
    MySQL.Async.execute('DELETE FROM job_panel_data WHERE identifier = ? AND job = ? AND data_type = ?', {identifier, job, 'salary'})
    
    TriggerClientEvent('jobpanel:client:notification', src, 'success', 'Individuell lön borttagen')
    RefreshJobPanel(job)
end)

-- Uppdatera löner
RegisterNetEvent('jobpanel:server:updateSalaries', function(job, salaries)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local permissions = GetPlayerPermissions(src, job)
    if not permissions.canEditSalaries then
        TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Du har inte behörighet')
        return
    end
    
    -- Uppdatera Config (runtime)
    if not Config.DefaultSalaries[job] then
        Config.DefaultSalaries[job] = {}
    end
    
    for grade, salary in pairs(salaries) do
        grade = tonumber(grade)
        salary = tonumber(salary)
        if grade and salary then
            if not Config.DefaultSalaries[job][grade] then
                Config.DefaultSalaries[job][grade] = { name = 'Rank ' .. grade }
            end
            Config.DefaultSalaries[job][grade].salary = salary
            
            -- Uppdatera även i job_grades tabellen
            MySQL.Async.execute('UPDATE job_grades SET salary = ? WHERE job_name = ? AND grade = ?', {salary, job, grade})
        end
    end
    
    -- Spara till databas
    MySQL.Async.execute('INSERT INTO job_panel_data (identifier, job, data_type, data) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE data = ?', {
        'salaries', job, 'salaries', json.encode(salaries), json.encode(salaries)
    })
    
    local playerName = xPlayer.getName()
    AddJobLog(job, 'salary', playerName .. ' uppdaterade lönerna', playerName)
    
    TriggerClientEvent('jobpanel:client:notification', src, 'success', 'Löner uppdaterade')
    RefreshJobPanel(job)
end)

-- Ge bonus
RegisterNetEvent('jobpanel:server:giveBonus', function(employeeId, amount, reason)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local job = xPlayer.getJob().name
    local permissions = GetPlayerPermissions(src, job)
    
    if not permissions.canEditSalaries then
        TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Du har inte behörighet')
        return
    end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Ogiltigt belopp')
        return
    end
    
    if amount > Config.BonusSettings.maxBonus then
        TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Maximal bonus är $' .. Config.BonusSettings.maxBonus)
        return
    end
    
    local xTarget = ESX.GetPlayerFromIdentifier(employeeId)
    
    if xTarget then
        xTarget.addAccountMoney('bank', amount, 'Bonus: ' .. (reason or 'Ingen anledning'))
        TriggerClientEvent('jobpanel:client:notification', xTarget.source, 'success', 'Du fick en bonus på $' .. amount)
    else
        -- Spara för offline spelare
        MySQL.Async.execute('UPDATE users SET bank = bank + ? WHERE identifier = ?', {amount, employeeId})
    end
    
    local playerName = xPlayer.getName()
    AddJobLog(job, 'salary', playerName .. ' gav en bonus på $' .. amount, playerName)
    
    TriggerClientEvent('jobpanel:client:notification', src, 'success', 'Bonus skickad')
end)

-- Uppdatera rank permissions
RegisterNetEvent('jobpanel:server:updateRankPermissions', function(job, data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local permissions = GetPlayerPermissions(src, job)
    if not permissions.canManageRanks then
        TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Du har inte behörighet')
        return
    end
    
    if not CustomRankPermissions[job] then
        CustomRankPermissions[job] = {}
    end
    
    local grade = tonumber(data.grade)
    if not grade then return end
    
    CustomRankPermissions[job][grade] = data.permissions
    
    -- Uppdatera även namn och lön om de ändrades
    if data.name then
        MySQL.Async.execute('UPDATE job_grades SET name = ? WHERE job_name = ? AND grade = ?', {data.name, job, grade})
    end
    if data.salary then
        local salary = tonumber(data.salary)
        if salary then
            MySQL.Async.execute('UPDATE job_grades SET salary = ? WHERE job_name = ? AND grade = ?', {salary, job, grade})
            if Config.DefaultSalaries[job] and Config.DefaultSalaries[job][grade] then
                Config.DefaultSalaries[job][grade].salary = salary
            end
        end
    end
    
    -- Spara till databas
    MySQL.Async.execute('INSERT INTO job_panel_data (identifier, job, data_type, data) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE data = ?', {
        'permissions', job, 'permissions', json.encode(CustomRankPermissions[job]), json.encode(CustomRankPermissions[job])
    })
    
    local playerName = xPlayer.getName()
    AddJobLog(job, 'promote', playerName .. ' uppdaterade permissions för rank ' .. grade, playerName)
    
    TriggerClientEvent('jobpanel:client:notification', src, 'success', 'Permissions uppdaterade')
    RefreshJobPanel(job)
end)

-- Society pengar
RegisterNetEvent('jobpanel:server:societyMoney', function(job, action, amount, reason)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local permissions = GetPlayerPermissions(src, job)
    if not permissions.canViewFinances then
        TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Du har inte behörighet')
        return
    end
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Ogiltigt belopp')
        return
    end
    
    local success = false
    local accountName = Config.SocietyAccountPrefix .. job
    
    if action == 'deposit' then
        -- Ta pengar från spelaren
        if xPlayer.getMoney() >= amount then
            xPlayer.removeMoney(amount, 'Insättning till ' .. job)
            
            -- Lägg till i society - försök olika metoder
            local updated = MySQL.Sync.execute('UPDATE addon_account_data SET money = money + ? WHERE account_name = ?', {amount, accountName})
            if updated == 0 then
                updated = MySQL.Sync.execute('UPDATE society_accounts SET money = money + ? WHERE name = ?', {amount, accountName})
            end
            
            success = true
        else
            TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Du har inte tillräckligt med pengar')
            return
        end
    elseif action == 'withdraw' then
        -- Kolla om det finns pengar
        local balance = MySQL.Sync.fetchScalar('SELECT money FROM addon_account_data WHERE account_name = ?', {accountName})
        if not balance then
            balance = MySQL.Sync.fetchScalar('SELECT money FROM society_accounts WHERE name = ?', {accountName}) or 0
        end
        
        if balance >= amount then
            -- Ta från society
            local updated = MySQL.Sync.execute('UPDATE addon_account_data SET money = money - ? WHERE account_name = ?', {amount, accountName})
            if updated == 0 then
                MySQL.Sync.execute('UPDATE society_accounts SET money = money - ? WHERE name = ?', {amount, accountName})
            end
            
            -- Ge till spelaren
            xPlayer.addMoney(amount, 'Uttag från ' .. job)
            success = true
        else
            TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Inte tillräckligt i kassan')
            return
        end
    end
    
    if success then
        local playerName = xPlayer.getName()
        
        -- Logga transaktion
        MySQL.Async.execute('INSERT INTO job_panel_transactions (job, type, amount, description, by_name, timestamp) VALUES (?, ?, ?, ?, ?, NOW())', {
            job, action, amount, reason or (action == 'deposit' and 'Insättning' or 'Uttag'), playerName
        })
        
        AddJobLog(job, 'finance', playerName .. ' ' .. (action == 'deposit' and 'satte in' or 'tog ut') .. ' $' .. amount, playerName)
        
        TriggerClientEvent('jobpanel:client:notification', src, 'success', (action == 'deposit' and 'Insättning' or 'Uttag') .. ' genomförd')
        RefreshJobPanel(job)
    end
end)

-- Beställ fordon
RegisterNetEvent('jobpanel:server:orderVehicle', function(job, model, price)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local permissions = GetPlayerPermissions(src, job)
    if not permissions.canOrderVehicles then
        TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Du har inte behörighet')
        return
    end
    
    price = tonumber(price)
    if not price then return end
    
    -- Ta pengar från society
    local accountName = Config.SocietyAccountPrefix .. job
    local balance = MySQL.Sync.fetchScalar('SELECT money FROM addon_account_data WHERE account_name = ?', {accountName})
    if not balance then
        balance = MySQL.Sync.fetchScalar('SELECT money FROM society_accounts WHERE name = ?', {accountName}) or 0
    end
    
    if balance < price then
        TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Inte tillräckligt i kassan')
        return
    end
    
    local updated = MySQL.Sync.execute('UPDATE addon_account_data SET money = money - ? WHERE account_name = ?', {price, accountName})
    if updated == 0 then
        MySQL.Sync.execute('UPDATE society_accounts SET money = money - ? WHERE name = ?', {price, accountName})
    end
    
    local playerName = xPlayer.getName()
    AddJobLog(job, 'finance', playerName .. ' beställde fordon: ' .. model .. ' för $' .. price, playerName)
    
    -- Logga transaktion
    MySQL.Async.execute('INSERT INTO job_panel_transactions (job, type, amount, description, by_name, timestamp) VALUES (?, ?, ?, ?, ?, NOW())', {
        job, 'withdraw', price, 'Fordonsbeställning: ' .. model, playerName
    })
    
    TriggerClientEvent('jobpanel:client:notification', src, 'success', 'Fordon beställt!')
    RefreshJobPanel(job)
end)

-- Beställ items
RegisterNetEvent('jobpanel:server:orderItems', function(job, items)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end
    
    local permissions = GetPlayerPermissions(src, job)
    if not permissions.canOrderItems then
        TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Du har inte behörighet')
        return
    end
    
    if not items or #items == 0 then
        TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Inga items att beställa')
        return
    end
    
    -- Beräkna totalkostnad
    local totalCost = 0
    for _, item in ipairs(items) do
        totalCost = totalCost + (tonumber(item.price) or 0) * (tonumber(item.quantity) or 1)
    end
    
    -- Ta pengar från society
    local accountName = Config.SocietyAccountPrefix .. job
    local balance = MySQL.Sync.fetchScalar('SELECT money FROM addon_account_data WHERE account_name = ?', {accountName})
    if not balance then
        balance = MySQL.Sync.fetchScalar('SELECT money FROM society_accounts WHERE name = ?', {accountName}) or 0
    end
    
    if balance < totalCost then
        TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Inte tillräckligt i kassan')
        return
    end
    
    local updated = MySQL.Sync.execute('UPDATE addon_account_data SET money = money - ? WHERE account_name = ?', {totalCost, accountName})
    if updated == 0 then
        MySQL.Sync.execute('UPDATE society_accounts SET money = money - ? WHERE name = ?', {totalCost, accountName})
    end
    
    -- Lägg till items
    for _, item in ipairs(items) do
        local quantity = tonumber(item.quantity) or 1
        for i = 1, quantity do
            -- Kolla om det är ett vapen
            if item.item and item.item:find('WEAPON_') then
                xPlayer.addWeapon(item.item, 250)
            else
                -- Om du använder ox_inventory
                if GetResourceState('ox_inventory') == 'started' then
                    exports.ox_inventory:AddItem(src, item.item, 1)
                else
                    xPlayer.addInventoryItem(item.item, 1)
                end
            end
        end
    end
    
    local playerName = xPlayer.getName()
    
    -- Logga transaktion
    MySQL.Async.execute('INSERT INTO job_panel_transactions (job, type, amount, description, by_name, timestamp) VALUES (?, ?, ?, ?, ?, NOW())', {
        job, 'withdraw', totalCost, 'Utrustningsbeställning', playerName
    })
    
    AddJobLog(job, 'finance', playerName .. ' beställde utrustning för $' .. totalCost, playerName)
    
    TriggerClientEvent('jobpanel:client:notification', src, 'success', 'Beställning mottagen! Totalt: $' .. totalCost)
    RefreshJobPanel(job)
end)

-- Hjälpfunktioner

-- Hämta permissions för en spelare
function GetPlayerPermissions(src, job)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return {} end
    
    local playerJob = xPlayer.getJob()
    if playerJob.name ~= job then return {} end
    
    local grade = playerJob.grade
    
    -- Kolla custom permissions först (både som nummer och sträng)
    if CustomRankPermissions[job] then
        if CustomRankPermissions[job][grade] then
            return CustomRankPermissions[job][grade]
        elseif CustomRankPermissions[job][tostring(grade)] then
            return CustomRankPermissions[job][tostring(grade)]
        end
    end
    
    -- Sedan config permissions
    if Config.RankPermissions[job] and Config.RankPermissions[job][grade] then
        return Config.RankPermissions[job][grade]
    end
    
    -- Default permissions
    if Config.RankPermissions['default'][grade] then
        return Config.RankPermissions['default'][grade]
    end
    
    return Config.RankPermissions['default']['boss'] or {}
end

-- Lägg till logg
function AddJobLog(job, logType, message, byName)
    MySQL.Async.execute('INSERT INTO job_panel_logs (job, type, message, by_name, timestamp) VALUES (?, ?, ?, ?, NOW())', {
        job, logType, message, byName
    })
    
    -- Skicka till Discord webhook om aktiverat
    if Config.Webhook.enabled and Config.Webhook.url ~= "YOUR_DISCORD_WEBHOOK_URL" then
        SendWebhook(job, logType:upper(), message, Config.Webhook.color)
    end
end

-- Skicka Discord webhook
function SendWebhook(job, title, message, color)
    if not Config.Webhook.enabled or Config.Webhook.url == "YOUR_DISCORD_WEBHOOK_URL" then return end
    
    local embed = {
        {
            ["title"] = title,
            ["description"] = message,
            ["color"] = color or Config.Webhook.color,
            ["footer"] = {
                ["text"] = Config.Webhook.botName .. " | " .. os.date("%Y-%m-%d %H:%M:%S")
            },
            ["fields"] = {
                {
                    ["name"] = "Jobb",
                    ["value"] = job:upper(),
                    ["inline"] = true
                }
            }
        }
    }
    
    PerformHttpRequest(Config.Webhook.url, function(err, text, headers) end, 'POST', json.encode({
        username = Config.Webhook.botName,
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Uppdatera alla med panelen öppen
function RefreshJobPanel(job)
    local xPlayers = ESX.GetExtendedPlayers('job', job)
    
    for _, xPlayer in pairs(xPlayers) do
        local employees = GetJobEmployees(job)
        local finances = GetJobFinances(job)
        
        TriggerClientEvent('jobpanel:client:updateEmployees', xPlayer.source, employees)
        TriggerClientEvent('jobpanel:client:updateFinances', xPlayer.source, finances)
    end
end

-- Export funktioner för andra scripts
exports('GetPlayerPermissions', GetPlayerPermissions)
exports('GetJobEmployees', GetJobEmployees)
exports('GetJobFinances', GetJobFinances)
exports('AddJobLog', AddJobLog)
exports('RefreshJobPanel', RefreshJobPanel)

-- Admin kommandon
RegisterCommand('jobpanel:reload', function(source, args)
    local src = source
    
    if src > 0 then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer or xPlayer.getGroup() ~= 'admin' then
            TriggerClientEvent('jobpanel:client:notification', src, 'error', 'Ingen behörighet')
            return
        end
    end
    
    -- Ladda om data från databas
    local results = MySQL.Sync.fetchAll('SELECT * FROM job_panel_data')
    
    IndividualSalaries = {}
    CustomRankPermissions = {}
    
    if results then
        for _, row in ipairs(results) do
            if row.data_type == 'salary' then
                if not IndividualSalaries[row.identifier] then
                    IndividualSalaries[row.identifier] = {}
                end
                local success, data = pcall(json.decode, row.data)
                if success and data then
                    IndividualSalaries[row.identifier][row.job] = data.salary
                end
            elseif row.data_type == 'permissions' then
                local success, data = pcall(json.decode, row.data)
                if success and data then
                    CustomRankPermissions[row.job] = data
                end
            end
        end
    end
    
    if src > 0 then
        TriggerClientEvent('jobpanel:client:notification', src, 'success', 'Jobpanel data omladdad')
    end
    print('^2[CORE FIVE Scripts]^7 Jobpanel data reloaded!')
end, true)

print('^2[CORE FIVE Scripts]^7 Jobpanel (ESX) loaded successfully!')