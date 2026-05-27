Config = Config or {}

Config.FrameworkResource = Config.FrameworkResource or 'Az-Framework'
Config.DebugJobChecks = Config.DebugJobChecks == true
Config.JobName = 'hunter'
Config.RequireHunterJob = Config.RequireHunterJob ~= false


Config.DB = Config.DB or {
  table            = 'user_characters',
  identifierColumn = 'charid',
  jobColumn        = 'active_department'
}
Config.UseAzFrameworkCharacter = (Config.UseAzFrameworkCharacter ~= false)



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

Config.InteractKey = Config.InteractKey or 38 
Config.ActionKey   = Config.ActionKey or 47 



Config.CooldownMs = 9000
Config.MinReward = 80
Config.MaxReward = 240
Config.HarvestDistance = 2.2
Config.HarvestDurationMs = 4500
Config.MaxHarvestsPerMinute = 8
Config.AllowedWeapons = {
  weapon_musket = true,
  weapon_sniperrifle = true,
  weapon_heavysniper = true,
  weapon_heavysniper_mk2 = true,
  weapon_marksmanrifle = true,
  weapon_marksmanrifle_mk2 = true,
  weapon_carbinerifle = true,
  weapon_carbinerifle_mk2 = true
}
Config.Animals = {
  a_c_boar = 'https://docs.fivem.net/peds/a_c_boar.webp',
  a_c_deer = 'https://docs.fivem.net/peds/a_c_deer.webp',
  a_c_coyote = 'https://docs.fivem.net/peds/a_c_coyote.webp',
  a_c_rabbit_01 = 'https://docs.fivem.net/peds/a_c_rabbit_01.webp',
  a_c_mtlion = 'https://docs.fivem.net/peds/a_c_mtlion.webp',
}
