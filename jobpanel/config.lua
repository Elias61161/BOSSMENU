Config = {}

-- ===== Grundinställningar =====
Config.Framework = 'esx' -- 'esx' eller 'qb'
Config.Debug = false
Config.Locale = 'sv' -- 'sv' eller 'en'

-- ===== Branding & Logo =====
Config.Branding = {
    title = "CORE FIVE Scripts",
    subtitle = "Job Management System",
    logo = "https://r2.fivemanage.com/asRG0qQqKyqmzHW3TX7AH/ChatGPT_Image_Jan_31_2026_12_36_42_PM-removebg-preview.png",
    logoDark = "https://r2.fivemanage.com/asRG0qQqKyqmzHW3TX7AH/ChatGPT_Image_Jan_31_2026_12_36_42_PM-removebg-preview.png", -- Logo för dark mode
    logoLight = "https://r2.fivemanage.com/asRG0qQqKyqmzHW3TX7AH/ChatGPT_Image_Jan_31_2026_12_36_42_PM-removebg-preview.png" -- Logo för light mode
}

-- ===== Web Config Panel =====
Config.WebPanel = {
    enabled = true,
    port = 3000, -- Port för web panelen (ändra om den är upptagen)
    password = "admin123", -- Lösenord för att logga in
    allowedIPs = {} -- Lämna tom för att tillåta alla, eller lägg till specifika IPs
}

-- ===== Standardlöner per rank =====
Config.DefaultSalaries = {
    ['police'] = {
        [0] = { name = 'Rekryt', salary = 2500 },
        [1] = { name = 'Polis', salary = 3500 },
        [2] = { name = 'Sergeant', salary = 4500 },
        [3] = { name = 'Löjtnant', salary = 5500 },
        [4] = { name = 'Kapten', salary = 7000 },
        [5] = { name = 'Chef', salary = 10000 }
    },
    ['ambulance'] = {
        [0] = { name = 'Praktikant', salary = 2000 },
        [1] = { name = 'Sjuksköterska', salary = 3000 },
        [2] = { name = 'Läkare', salary = 4500 },
        [3] = { name = 'Överläkare', salary = 6000 },
        [4] = { name = 'Chefsläkare', salary = 8500 }
    },
    ['mechanic'] = {
        [0] = { name = 'Lärling', salary = 1500 },
        [1] = { name = 'Mekaniker', salary = 2500 },
        [2] = { name = 'Senior Mekaniker', salary = 3500 },
        [3] = { name = 'Verkstadschef', salary = 5000 }
    }
}

-- ===== Permissions per rank =====
Config.RankPermissions = {
    ['police'] = {
        [0] = {
            canViewPanel = true,
            canViewEmployees = true,
            canViewFinances = false,
            canHire = false,
            canFire = false,
            canPromote = false,
            canEditSalaries = false,
            canOrderVehicles = false,
            canOrderItems = false,
            canViewLogs = false,
            canManageRanks = false
        },
        [1] = {
            canViewPanel = true,
            canViewEmployees = true,
            canViewFinances = false,
            canHire = false,
            canFire = false,
            canPromote = false,
            canEditSalaries = false,
            canOrderVehicles = false,
            canOrderItems = false,
            canViewLogs = false,
            canManageRanks = false
        },
        [2] = {
            canViewPanel = true,
            canViewEmployees = true,
            canViewFinances = true,
            canHire = true,
            canFire = false,
            canPromote = false,
            canEditSalaries = false,
            canOrderVehicles = false,
            canOrderItems = true,
            canViewLogs = false,
            canManageRanks = false
        },
        [3] = {
            canViewPanel = true,
            canViewEmployees = true,
            canViewFinances = true,
            canHire = true,
            canFire = true,
            canPromote = true,
            canEditSalaries = false,
            canOrderVehicles = true,
            canOrderItems = true,
            canViewLogs = true,
            canManageRanks = false
        },
        [4] = {
            canViewPanel = true,
            canViewEmployees = true,
            canViewFinances = true,
            canHire = true,
            canFire = true,
            canPromote = true,
            canEditSalaries = true,
            canOrderVehicles = true,
            canOrderItems = true,
            canViewLogs = true,
            canManageRanks = false
        },
        [5] = {
            canViewPanel = true,
            canViewEmployees = true,
            canViewFinances = true,
            canHire = true,
            canFire = true,
            canPromote = true,
            canEditSalaries = true,
            canOrderVehicles = true,
            canOrderItems = true,
            canViewLogs = true,
            canManageRanks = true
        }
    },
    ['default'] = {
        [0] = {
            canViewPanel = true,
            canViewEmployees = true,
            canViewFinances = false,
            canHire = false,
            canFire = false,
            canPromote = false,
            canEditSalaries = false,
            canOrderVehicles = false,
            canOrderItems = false,
            canViewLogs = false,
            canManageRanks = false
        },
        ['boss'] = {
            canViewPanel = true,
            canViewEmployees = true,
            canViewFinances = true,
            canHire = true,
            canFire = true,
            canPromote = true,
            canEditSalaries = true,
            canOrderVehicles = true,
            canOrderItems = true,
            canViewLogs = true,
            canManageRanks = true
        }
    }
}

-- ===== Bonus inställningar =====
Config.BonusSettings = {
    enabled = true,
    maxBonus = 50000
}

-- ===== Fordonsbeställningar =====
Config.VehicleOrders = {
    ['police'] = {
        { model = 'police', label = 'Polisbil', price = 45000 },
        { model = 'police2', label = 'Polisbil Omarkerad', price = 55000 },
        { model = 'police3', label = 'Polisbil Sport', price = 75000 },
        { model = 'policeb', label = 'Polismotorcykel', price = 35000 }
    },
    ['ambulance'] = {
        { model = 'ambulance', label = 'Ambulans', price = 65000 },
        { model = 'lguard', label = 'Livräddarbil', price = 45000 }
    }
}

-- ===== Itembeställningar =====
Config.ItemOrders = {
    ['police'] = {
        { item = 'WEAPON_PISTOL', label = 'Pistol', price = 5000 },
        { item = 'WEAPON_STUNGUN', label = 'Elpistol', price = 2500 },
        { item = 'handcuffs', label = 'Handfängsel', price = 500 },
        { item = 'radio', label = 'Radio', price = 1000 }
    },
    ['ambulance'] = {
        { item = 'firstaid', label = 'Första Hjälpen', price = 200 },
        { item = 'medikit', label = 'Medicinväska', price = 500 }
    }
}

-- ===== Panel platser =====
Config.PanelLocations = {
    ['police'] = {
        { coords = vector3(440.7, -974.3, 30.69), radius = 2.0 }
    },
    ['ambulance'] = {
        { coords = vector3(311.2, -599.5, 43.29), radius = 2.0 }
    }
}

-- ===== Society konto =====
Config.UseSociety = true
Config.SocietyAccountPrefix = 'society_'

-- ===== Discord Webhook =====
Config.Webhook = {
    enabled = false,
    url = "YOUR_DISCORD_WEBHOOK_URL",
    color = 3447003,
    botName = "CORE FIVE Scripts - Jobpanel"
}