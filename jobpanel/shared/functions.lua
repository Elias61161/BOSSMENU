-- Locale system
Locales = Locales or {}
CurrentLocale = Config.Locale or 'sv'

function L(key, ...)
    local locale = Locales[CurrentLocale]
    if not locale then
        locale = Locales['sv'] or {}
    end
    
    local text = locale[key]
    if not text then
        return key
    end
    
    if ... then
        return string.format(text, ...)
    end
    
    return text
end

function SetLocale(locale)
    if Locales[locale] then
        CurrentLocale = locale
        return true
    end
    return false
end

function GetLocale()
    return CurrentLocale
end

function GetAllLocaleStrings()
    return Locales[CurrentLocale] or Locales['sv'] or {}
end