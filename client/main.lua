function az_hunting_notify(msg)
  BeginTextCommandThefeedPost("STRING")
  AddTextComponentSubstringPlayerName(tostring(msg))
  EndTextCommandThefeedPostTicker(false, false)
end

function az_hunting_help(msg)
  BeginTextCommandDisplayHelp("STRING")
  AddTextComponentSubstringPlayerName(tostring(msg))
  EndTextCommandDisplayHelp(0, false, true, -1)
end

function az_hunting_doAction(label, ms)
  local ped = PlayerPedId()
  FreezeEntityPosition(ped, true)
  local start = GetGameTimer()
  while GetGameTimer() - start < ms do
    Wait(0)
    DisableAllControlActions(0)
    BeginTextCommandPrint("STRING")
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandPrint(1, true)
  end
  FreezeEntityPosition(ped, false)
end

RegisterNetEvent('az_hunting:notify', function(msg) az_hunting_notify(msg) end)

local uiOpen = false
local function nuiSend(msg) SendNUIMessage(msg) end

local function uiSet(open)
  uiOpen = open
  SetNuiFocus(false, false)
  SetNuiFocusKeepInput(false)
  if open and false then
    SetNuiCursorLocation(0.5, 0.5)
  end
end

RegisterNUICallback('close', function(_, cb)
  uiSet(false)
  cb({ ok=true })
end)

RegisterNUICallback('sell', function(_, cb)
  uiSet(false)
  TriggerServerEvent('az_hunting:bag:sell')
  cb({ ok=true })
end)

RegisterNetEvent('az_hunting:bag:open', function(payload)
  uiSet(true)
  nuiSend({ type='bag:open', kind=payload.kind, items=payload.items or {}, canSell=payload.canSell==true })
end)

RegisterNetEvent('az_hunting:bag:update', function(payload)
  nuiSend({ type='bag:update', kind=payload.kind, items=payload.items or {} })
end)

CreateThread(function()
  while true do
    Wait(0)
    if uiOpen and (IsControlJustPressed(0, 200) or IsControlJustPressed(0, 177)) then
      uiSet(false)
    end
  end
end)


local lastPaidAt = 0
local pendingHarvests = {}
local harvested = {}

local function isAnimal(ent)
  if not DoesEntityExist(ent) then return false end
  if not IsEntityAPed(ent) then return false end
  return GetPedType(ent) == 28
end

local function makeSize()
  local w = math.random(15, 240) + (math.random() * 10.0)
  local tier = "Small"
  if w >= 80 then tier = "Medium" end
  if w >= 150 then tier = "Large" end
  return tier, w
end

local function pedModelName(victim)
  local model = GetEntityModel(victim)
  local candidates = { "a_c_deer", "a_c_boar", "a_c_coyote", "a_c_rabbit_01", "a_c_mtlion" }
  for _, n in ipairs(candidates) do
    if model == joaat(n) then return n end
  end
  return "a_c_deer"
end

local function allowedWeapon()
  local _, weapon = GetCurrentPedWeapon(PlayerPedId(), true)
  if not weapon or weapon == 0 then return false end
  for name in pairs(Config.AllowedWeapons or {}) do
    if weapon == joaat(name) then return true end
  end
  return false
end

local function addHarvest(victim)
  if harvested[victim] or pendingHarvests[victim] then return end
  local pedName = pedModelName(victim)
  local img = (Config.Animals and Config.Animals[pedName]) or ("https://docs.fivem.net/peds/%s.webp"):format(pedName)
  local tier, weight = makeSize()
  pendingHarvests[victim] = {
    pedName = pedName,
    img = img,
    tier = tier,
    weight = weight,
    expiresAt = GetGameTimer() + 180000
  }
  az_hunting_notify(("Animal down. Press G near the carcass to harvest %s meat."):format(tier:lower()))
end

AddEventHandler('gameEventTriggered', function(name, args)
  if name ~= "CEventNetworkEntityDamage" then return end
  local victim = args[1]
  local attacker = args[2]
  if not victim or not attacker then return end
  if attacker ~= PlayerPedId() then return end
  if not DoesEntityExist(victim) then return end
  if not isAnimal(victim) then return end
  if not IsEntityDead(victim) then return end
  if not allowedWeapon() then
    az_hunting_notify("Use a proper hunting rifle to harvest clean meat.")
    return
  end

  local now = GetGameTimer()
  if now - lastPaidAt < (Config.CooldownMs or 2500) then return end
  lastPaidAt = now

  addHarvest(victim)
end)

CreateThread(function()
  while true do
    local wait = 750
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    for ent, data in pairs(pendingHarvests) do
      if data.expiresAt < GetGameTimer() or not DoesEntityExist(ent) then
        pendingHarvests[ent] = nil
      else
        local dist = #(coords - GetEntityCoords(ent))
        if dist < 8.0 then
          wait = 0
          DrawMarker(2, GetEntityCoords(ent).x, GetEntityCoords(ent).y, GetEntityCoords(ent).z + 0.7, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, .25, .25, .25, 47, 140, 255, 190, false, true, 2, false, nil, nil, false)
          if dist <= (Config.HarvestDistance or 2.2) then
            az_hunting_help("Press ~INPUT_DETONATE~ to harvest the animal")
            if IsControlJustReleased(0, Config.ActionKey or 47) then
              harvested[ent] = true
              pendingHarvests[ent] = nil
              az_hunting_doAction("Harvesting animal...", Config.HarvestDurationMs or 4500)
              TriggerServerEvent('az_hunting:reward', data.pedName, data.tier, data.weight, data.img)
              SetEntityAsMissionEntity(ent, true, true)
              DeleteEntity(ent)
              break
            end
          end
        end
      end
    end

    Wait(wait)
  end
end)

RegisterNetEvent('az_hunting:popup', function(data)
  SetNuiFocus(false, false)
  SendNUIMessage({
    type = "hunt:popup",
    img = data.img,
    title = data.title,
    sub = data.sub,
    meta = data.meta,
    duration = data.duration or 5200
  })
end)
