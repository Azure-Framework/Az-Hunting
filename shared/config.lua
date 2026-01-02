Config = Config or {}

Config.FrameworkResource = Config.FrameworkResource or 'Az-Framework'
Config.DebugJobChecks = Config.DebugJobChecks ~= false
Config.JobName = 'hunter'

-- Job Center DB mapping (used for /quitjob if no framework setter is available)
Config.DB = Config.DB or {
  table            = 'user_characters',
  identifierColumn = 'charid',
  jobColumn        = 'active_department'
}
Config.UseAzFrameworkCharacter = (Config.UseAzFrameworkCharacter ~= false)

-- Uses Az-Framework export you provided:
-- exports['Az-Framework']:getPlayerJob(source)
Config.GetPlayerJob = Config.GetPlayerJob or function(source)
    local ok, job = pcall(function()
        return exports[Config.FrameworkResource]:getPlayerJob(source)
    end)
    if ok then
        if type(job) == 'table' then
            job = job.name or job.job or job.label or job.id
        end
        if job ~= nil then
            local s = tostring(job):gsub("^%s+",""):gsub("%s+$","")
            if s ~= "" then return string.lower(s) end
        end
    end
    return 'civ'
end

Config.InteractKey = Config.InteractKey or 38 -- E
Config.ActionKey   = Config.ActionKey or 47 -- G



Config.CooldownMs = 2500
Config.MinReward = 80
Config.MaxReward = 240
Config.Animals = {
  a_c_boar = 'https://docs.fivem.net/peds/a_c_boar.webp',
  a_c_deer = 'https://docs.fivem.net/peds/a_c_deer.webp',
  a_c_coyote = 'https://docs.fivem.net/peds/a_c_coyote.webp',
  a_c_rabbit_01 = 'https://docs.fivem.net/peds/a_c_rabbit_01.webp',
  a_c_mtlion = 'https://docs.fivem.net/peds/a_c_mtlion.webp',
}
