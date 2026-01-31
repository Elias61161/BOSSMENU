-- ===== CORE FIVE Scripts - Web Config Panel =====
-- ===== Version 1.0 =====

local activeTokens = {}
local TOKEN_EXPIRY = 3600000 -- 1 timme i millisekunder

-- Generera random token
local function GenerateToken()
    local chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local token = ''
    for i = 1, 64 do
        local rand = math.random(1, #chars)
        token = token .. chars:sub(rand, rand)
    end
    return token
end

-- Validera token
local function ValidateToken(token)
    if not token or not activeTokens[token] then
        return false
    end
    
    if GetGameTimer() - activeTokens[token].created > TOKEN_EXPIRY then
        activeTokens[token] = nil
        return false
    end
    
    return true
end

-- Validera IP
local function ValidateIP(ip)
    if not Config.WebPanel.allowedIPs or #Config.WebPanel.allowedIPs == 0 then
        return true
    end
    
    for _, allowedIP in ipairs(Config.WebPanel.allowedIPs) do
        if ip == allowedIP then
            return true
        end
    end
    
    return false
end

-- CORS Headers
local function GetCORSHeaders()
    return {
        ['Access-Control-Allow-Origin'] = '*',
        ['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS',
        ['Access-Control-Allow-Headers'] = 'Content-Type, Authorization',
        ['Content-Type'] = 'application/json'
    }
end

-- HTTP Handler
SetHttpHandler(function(req, res)
    local path = req.path
    local method = req.method
    
    -- CORS preflight
    if method == 'OPTIONS' then
        res.writeHead(200, GetCORSHeaders())
        res.send('')
        return
    end
    
    -- Serve static files
    if path == '/config' or path == '/config/' then
        local file = LoadResourceFile(GetCurrentResourceName(), 'web/config.html')
        if file then
            res.writeHead(200, {['Content-Type'] = 'text/html'})
            res.send(file)
        else
            res.writeHead(404)
            res.send('Not Found')
        end
        return
    end
    
    -- API Routes
    if path:find('^/api/') then
        HandleAPIRequest(req, res, path, method)
        return
    end
    
    res.writeHead(404, GetCORSHeaders())
    res.send(json.encode({error = 'Not Found'}))
end)

-- API Request Handler
function HandleAPIRequest(req, res, path, method)
    local headers = GetCORSHeaders()
    
    -- Login
    if path == '/api/login' and method == 'POST' then
        local body = json.decode(req.body or '{}')
        
        if body.password == Config.WebPanel.password then
            local token = GenerateToken()
            activeTokens[token] = {
                created = GetGameTimer(),
                ip = req.address
            }
            
            res.writeHead(200, headers)
            res.send(json.encode({
                success = true,
                token = token,
                branding = Config.Branding
            }))
        else
            res.writeHead(401, headers)
            res.send(json.encode({success = false, error = 'Invalid password'}))
        end
        return
    end
    
    -- Validate token for all other routes
    local authHeader = req.headers['Authorization'] or req.headers['authorization'] or ''
    local token = authHeader:gsub('Bearer ', '')
    
    if not ValidateToken(token) then
        res.writeHead(401, headers)
        res.send(json.encode({success = false, error = 'Unauthorized'}))
        return
    end
    
    -- Get Config
    if path == '/api/config' and method == 'GET' then
        res.writeHead(200, headers)
        res.send(json.encode({
            success = true,
            config = {
                branding = Config.Branding,
                defaultSalaries = Config.DefaultSalaries,
                rankPermissions = Config.RankPermissions,
                vehicleOrders = Config.VehicleOrders,
                itemOrders = Config.ItemOrders,
                bonusSettings = Config.BonusSettings,
                webhook = {
                    enabled = Config.Webhook.enabled,
                    url = Config.Webhook.url ~= "YOUR_DISCORD_WEBHOOK_URL" and "***HIDDEN***" or "",
                    botName = Config.Webhook.botName
                },
                locale = Config.Locale
            }
        }))
        return
    end
    
    -- Update Branding
    if path == '/api/config/branding' and method == 'POST' then
        local body = json.decode(req.body or '{}')
        
        if body.title then Config.Branding.title = body.title end
        if body.subtitle then Config.Branding.subtitle = body.subtitle end
        if body.logo then Config.Branding.logo = body.logo end
        if body.logoDark then Config.Branding.logoDark = body.logoDark end
        if body.logoLight then Config.Branding.logoLight = body.logoLight end
        
        SaveConfigToFile()
        
        res.writeHead(200, headers)
        res.send(json.encode({success = true, branding = Config.Branding}))
        return
    end
    
    -- Update Salaries
    if path == '/api/config/salaries' and method == 'POST' then
        local body = json.decode(req.body or '{}')
        
        if body.job and body.salaries then
            Config.DefaultSalaries[body.job] = body.salaries
            SaveConfigToFile()
        end
        
        res.writeHead(200, headers)
        res.send(json.encode({success = true}))
        return
    end
    
    -- Update Permissions
    if path == '/api/config/permissions' and method == 'POST' then
        local body = json.decode(req.body or '{}')
        
        if body.job and body.permissions then
            Config.RankPermissions[body.job] = body.permissions
            SaveConfigToFile()
        end
        
        res.writeHead(200, headers)
        res.send(json.encode({success = true}))
        return
    end
    
    -- Update Vehicles
    if path == '/api/config/vehicles' and method == 'POST' then
        local body = json.decode(req.body or '{}')
        
        if body.job and body.vehicles then
            Config.VehicleOrders[body.job] = body.vehicles
            SaveConfigToFile()
        end
        
        res.writeHead(200, headers)
        res.send(json.encode({success = true}))
        return
    end
    
    -- Update Items
    if path == '/api/config/items' and method == 'POST' then
        local body = json.decode(req.body or '{}')
        
        if body.job and body.items then
            Config.ItemOrders[body.job] = body.items
            SaveConfigToFile()
        end
        
        res.writeHead(200, headers)
        res.send(json.encode({success = true}))
        return
    end
    
    -- Update Webhook
    if path == '/api/config/webhook' and method == 'POST' then
        local body = json.decode(req.body or '{}')
        
        if body.enabled ~= nil then Config.Webhook.enabled = body.enabled end
        if body.url then Config.Webhook.url = body.url end
        if body.botName then Config.Webhook.botName = body.botName end
        
        SaveConfigToFile()
        
        res.writeHead(200, headers)
        res.send(json.encode({success = true}))
        return
    end
    
    -- Get Jobs
    if path == '/api/jobs' and method == 'GET' then
        local jobs = {}
        
        for jobName, _ in pairs(Config.DefaultSalaries) do
            table.insert(jobs, jobName)
        end
        
        res.writeHead(200, headers)
        res.send(json.encode({success = true, jobs = jobs}))
        return
    end
    
    -- Get Employees
    if path:find('^/api/employees/') and method == 'GET' then
        local job = path:gsub('/api/employees/', '')
        local employees = GetJobEmployees(job)
        
        res.writeHead(200, headers)
        res.send(json.encode({success = true, employees = employees}))
        return
    end
    
    -- Get Logs
    if path:find('^/api/logs/') and method == 'GET' then
        local job = path:gsub('/api/logs/', '')
        local logs = GetJobLogs(job)
        
        res.writeHead(200, headers)
        res.send(json.encode({success = true, logs = logs}))
        return
    end
    
    -- Get Stats
    if path == '/api/stats' and method == 'GET' then
        local stats = GetGlobalStats()
        
        res.writeHead(200, headers)
        res.send(json.encode({success = true, stats = stats}))
        return
    end
    
    -- Logout
    if path == '/api/logout' and method == 'POST' then
        activeTokens[token] = nil
        res.writeHead(200, headers)
        res.send(json.encode({success = true}))
        return
    end
    
    res.writeHead(404, headers)
    res.send(json.encode({error = 'Not Found'}))
end

-- Get Global Stats
function GetGlobalStats()
    local totalEmployees = 0
    local onlineEmployees = 0
    local totalBalance = 0
    
    for jobName, _ in pairs(Config.DefaultSalaries) do
        local employees = GetJobEmployees(jobName)
        totalEmployees = totalEmployees + #employees
        
        for _, emp in ipairs(employees) do
            if emp.online then
                onlineEmployees = onlineEmployees + 1
            end
        end
        
        local finances = GetJobFinances(jobName)
        totalBalance = totalBalance + (finances.balance or 0)
    end
    
    local totalLogs = MySQL.Sync.fetchScalar('SELECT COUNT(*) FROM job_panel_logs') or 0
    
    return {
        totalEmployees = totalEmployees,
        onlineEmployees = onlineEmployees,
        totalBalance = totalBalance,
        totalLogs = totalLogs,
        totalJobs = TableLength(Config.DefaultSalaries)
    }
end

function TableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Save config (runtime only - för permanent behövs fil-skrivning)
function SaveConfigToFile()
    -- Denna funktion sparar bara i runtime
    -- För att spara permanent till fil behövs mer avancerad logik
    print('[CORE FIVE Scripts] Config updated (runtime)')
end

print('^2[CORE FIVE Scripts]^7 Web Config Panel loaded - Access at http://YOUR_SERVER_IP:30120/config')