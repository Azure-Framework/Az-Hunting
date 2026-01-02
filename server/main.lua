local fw = exports[Config.FrameworkResource]

local function dbg(src, msg)
  if not Config.DebugJobChecks then return end
  print(("[az_hunting][debug][%s] %s"):format(tostring(src), tostring(msg)))
end

local function getJob(src)
  local ok, j = pcall(Config.GetPlayerJob, src)
  if ok and j then return tostring(j) end
  return "civ"
end

local function ensureJob(src)
  local job = getJob(src)
  if job ~= Config.JobName then
    dbg(src, ("DENY: expected=%s got=%s"):format(Config.JobName, job))
    return false, job
  end
  return true, job
end

local function payCash(src, amount)
  amount = math.floor(tonumber(amount) or 0)
  if amount <= 0 then return end
  fw:addMoney(src, amount)
end

local function takeCash(src, amount, cb)
  amount = math.floor(tonumber(amount) or 0)
  if amount <= 0 then return cb and cb(true) end
  fw:GetPlayerMoney(src, function(err, wallet)
    if err then return cb and cb(false, "wallet_error") end
    wallet = wallet or {}
    local cash = tonumber(wallet.cash or 0) or 0
    if cash < amount then return cb and cb(false, "not_enough_cash") end
    fw:deductMoney(src, amount)
    cb(true)
  end)
end

-- /quitjob (resign) support:
-- 1) tries framework setter if available
-- 2) falls back to DB update using oxmysql or MySQL wrapper
local function getCharId(src)
  if not Config.UseAzFrameworkCharacter then return nil end
  local ok, c = pcall(function() return exports[Config.FrameworkResource]:GetPlayerCharacter(src) end)
  if ok and c then return c end
  return nil
end

local function dbUpdateJob(charId, newJob, cb)
  local t = Config.DB and Config.DB.table or 'user_characters'
  local idc = Config.DB and Config.DB.identifierColumn or 'charid'
  local jc = Config.DB and Config.DB.jobColumn or 'active_department'
  local q = ("UPDATE %s SET %s = ? WHERE %s = ?"):format(t, jc, idc)

  if exports.oxmysql and exports.oxmysql.update then
    exports.oxmysql:update(q, { newJob, charId }, function(affected)
      cb(true, affected or 0)
    end)
    return
  end

  if MySQL and MySQL.update then
    MySQL.update(q, { newJob, charId }, function(affected)
      cb(true, affected or 0)
    end)
    return
  end

  cb(false, "no_mysql")
end

local function setJob(src, newJob, cb)
  newJob = tostring(newJob or "unemployed")
  local ok, hasSetter = pcall(function()
    return type(exports[Config.FrameworkResource].setPlayerJob) == "function"
  end)
  if ok and hasSetter then
    local ok2, err = pcall(function()
      exports[Config.FrameworkResource]:setPlayerJob(src, newJob)
    end)
    if ok2 then
      cb(true, "framework")
    else
      cb(false, err or "setter_failed")
    end
    return
  end

  local charId = getCharId(src)
  if not charId then
    cb(false, "no_char")
    return
  end

  dbUpdateJob(charId, newJob, function(ok3, info)
    if ok3 then
      cb(true, "db")
      if exports[Config.FrameworkResource].sendMoneyToClient then
        pcall(function() exports[Config.FrameworkResource]:sendMoneyToClient(src) end)
      end
    else
      cb(false, info)
    end
  end)
end

_G['AZ_HUNTING_SV'] = _G['AZ_HUNTING_SV'] or {}
local SV = _G['AZ_HUNTING_SV']
SV.dbg = dbg
SV.getJob = getJob
SV.ensureJob = ensureJob
SV.payCash = payCash
SV.takeCash = takeCash
SV.setJob = setJob

RegisterCommand('az_huntingdebug', function(source)
  local src = source
  if src == 0 then
    print("[az_hunting] use this in-game")
    return
  end
  local j = getJob(src)
  dbg(src, ("job=%s"):format(j))
  TriggerClientEvent('az_hunting:notify', src, ("[az_hunting] job=%s (see server console)"):format(j))
end, false)

RegisterCommand('quitjob', function(source)
  local src = source
  if src == 0 then return end
  setJob(src, "unemployed", function(ok4, how)
    if ok4 then
      dbg(src, "quitjob OK via " .. tostring(how))
      TriggerClientEvent('az_hunting:notify', src, "You quit your job. (unemployed)")
    else
      dbg(src, "quitjob FAIL: " .. tostring(how))
      TriggerClientEvent('az_hunting:notify', src, "Could not quit job (missing setter/DB). Use Job Center.")
    end
  end)
end, false)

RegisterNetEvent('az_hunting:reward', function(pedName, tier, weight, img)
  local src = source
  pedName = tostring(pedName or "animal")
  tier = tostring(tier or "Small")
  weight = tonumber(weight or 0) or 0
  img = tostring(img or "")

  local base = math.random(Config.MinReward, Config.MaxReward)
  local multi = 1.0
  if tier == "Medium" then multi = 1.25 end
  if tier == "Large" then multi = 1.55 end
  local reward = math.floor(base * multi + (weight * 1.2))

  exports[Config.FrameworkResource]:addMoney(src, reward)

  TriggerClientEvent('az_hunting:popup', src, {
    img = img,
    title = ("Hunt Reward • %s"):format(pedName),
    sub = ("You earned ~$%d"):format(reward),
    meta = ("Size: %s  •  Weight: %.1flb"):format(tier, weight),
    duration = 5200
  })
end)
