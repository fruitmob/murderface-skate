local Skating = {}
local active = false
local busy = false

local ANIM_DICTS = { 'move_strafe@stealth', 'move_crouch_proto' }
local MODEL_BMX   = GetHashKey('bmx')
local MODEL_BOARD = GetHashKey('taymckenzienz_skateboard01')
local MODEL_PED   = 68070371

-- ox_inventory client export — triggered when player uses skateboard from inventory
exports('skateboard', function(data, slot)
    if busy then return end
    if active then
        Skating.Clear()
    else
        Skating.Start()
    end
end)

-- Secondary toggle via event (admin commands, other scripts)
RegisterNetEvent('astudios-skating:client:toggle', function()
    if busy then return end
    if active then
        Skating.Clear()
    else
        Skating.Start()
    end
end)

local function waitForModel(hash, label)
    if not IsModelValid(hash) then return false end
    RequestModel(hash)
    local timeout = 50
    while not HasModelLoaded(hash) do
        Wait(100)
        timeout = timeout - 1
        if timeout <= 0 then return false end
        RequestModel(hash)
    end
    return true
end

local function waitForAnimDict(dict)
    RequestAnimDict(dict)
    local timeout = 50
    while not HasAnimDictLoaded(dict) do
        Wait(100)
        timeout = timeout - 1
        if timeout <= 0 then return false end
        RequestAnimDict(dict)
    end
    return true
end

function Skating.LoadAssets()
    for _, dict in ipairs(ANIM_DICTS) do
        if not waitForAnimDict(dict) then return false end
    end
    if not waitForModel(MODEL_BMX, 'bmx') then return false end
    if not waitForModel(MODEL_BOARD, 'skateboard') then return false end
    if not waitForModel(MODEL_PED, 'invisible_ped') then return false end
    return true
end

function Skating.UnloadAssets()
    for _, dict in ipairs(ANIM_DICTS) do
        RemoveAnimDict(dict)
    end
    SetModelAsNoLongerNeeded(MODEL_BMX)
    SetModelAsNoLongerNeeded(MODEL_BOARD)
    SetModelAsNoLongerNeeded(MODEL_PED)
end

function Skating.Start()
    if active or busy then return end
    busy = true

    local ped = cache.ped

    if not Skating.LoadAssets() then
        busy = false
        lib.notify({ description = 'Skateboard failed to load models', type = 'error' })
        return
    end

    local spawnCoords = GetEntityCoords(ped) + GetEntityForwardVector(ped) * 2.0
    local spawnHeading = GetEntityHeading(ped)

    -- Invisible BMX as physics vehicle
    Skating.vehicle = CreateVehicle(MODEL_BMX, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnHeading, true, false)
    local vehTimeout = 100
    while not DoesEntityExist(Skating.vehicle) do
        Wait(5)
        vehTimeout = vehTimeout - 1
        if vehTimeout <= 0 then
            busy = false
            Skating.UnloadAssets()
            return
        end
    end

    SetEntityVisible(Skating.vehicle, false, false)
    SetEntityNoCollisionEntity(Skating.vehicle, ped, false)

    -- Skateboard prop
    Skating.board = CreateObject(MODEL_BOARD, 0.0, 0.0, 0.0, true, true, true)
    vehTimeout = 100
    while not DoesEntityExist(Skating.board) do
        Wait(5)
        vehTimeout = vehTimeout - 1
        if vehTimeout <= 0 then
            Skating.CleanEntities()
            busy = false
            return
        end
    end
    AttachEntityToEntity(Skating.board, Skating.vehicle, 0,
        0.0, 0.0, -0.40, 0.0, 0.0, 90.0, false, true, true, true, 1, true)

    -- Invisible ped to drive the BMX
    Skating.driver = CreatePed(12, MODEL_PED, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnHeading, true, true)
    SetEnableHandcuffs(Skating.driver, true)
    SetEntityInvincible(Skating.driver, true)
    SetEntityVisible(Skating.driver, false, false)
    FreezeEntityPosition(Skating.driver, true)
    TaskWarpPedIntoVehicle(Skating.driver, Skating.vehicle, -1)

    local warpTimeout = 50
    while not IsPedInVehicle(Skating.driver, Skating.vehicle) do
        Wait(0)
        warpTimeout = warpTimeout - 1
        if warpTimeout <= 0 then
            Skating.CleanEntities()
            busy = false
            lib.notify({ description = 'Failed to start skateboard, try again', type = 'error' })
            return
        end
    end

    -- Mount player
    TaskPlayAnim(ped, 'move_strafe@stealth', 'idle', 8.0, 8.0, -1, 1, 1.0, false, false, false)
    AttachEntityToEntity(ped, Skating.vehicle, 20,
        0.0, 0.0, 0.7, 0.0, 0.0, -15.0, true, true, false, true, 1, true)
    SetEntityCollision(ped, true, true)

    active = true
    busy = false
    Skating.speed = 0
    Skating.graceTimer = 100

    lib.notify({ description = Config.Controls, type = 'info' })
    Skating.Loop()
end

function Skating.ShouldRagdoll()
    local ped = cache.ped
    local rot = GetEntityRotation(Skating.vehicle)

    if (rot.x < -60.0 or rot.x > 60.0) and IsEntityInAir(Skating.vehicle) and Skating.speed < 5.0 then
        return true
    end
    if HasEntityCollidedWithAnything(ped) and Skating.speed > 5.0 then
        return true
    end
    if IsPedDeadOrDying(ped, false) then
        return true
    end

    return false
end

function Skating.HandleJump()
    if IsEntityInAir(Skating.vehicle) then return end

    local ped = cache.ped
    local vel = GetEntityVelocity(Skating.vehicle)

    TaskPlayAnim(ped, 'move_crouch_proto', 'idle_intro', 5.0, 8.0, -1, 0, 0, false, false, false)

    local duration = 0
    while IsControlPressed(0, 22) do
        Wait(10)
        duration = duration + 10.0
    end

    local boost = math.min(Config.MaxJumpHeight * duration / 250.0, Config.MaxJumpHeight)
    StopAnimTask(ped, 'move_crouch_proto', 'idle_intro', 1.0)

    if active then
        SetEntityVelocity(Skating.vehicle, vel.x, vel.y, vel.z + boost)
        TaskPlayAnim(ped, 'move_strafe@stealth', 'idle', 8.0, 2.0, -1, 1, 1.0, false, false, false)
    end
end

function Skating.HandleMovement()
    local ped = cache.ped

    if not NetworkHasControlOfEntity(Skating.driver) then
        NetworkRequestControlOfEntity(Skating.driver)
    end
    if not NetworkHasControlOfEntity(Skating.vehicle) then
        NetworkRequestControlOfEntity(Skating.vehicle)
    end

    local overSpeed = (GetEntitySpeed(Skating.vehicle) * 3.6) > Config.MaxSpeedKmh
    TaskVehicleTempAction(Skating.driver, Skating.vehicle, 1, 1)
    ForceVehicleEngineAudio(Skating.vehicle, "")
    SetEntityInvincible(Skating.vehicle, true)
    StopCurrentPlayingAmbientSpeech(Skating.driver)

    Skating.speed = GetEntitySpeed(Skating.vehicle) * 3.6
    if Skating.graceTimer > 0 then
        Skating.graceTimer = Skating.graceTimer - 1
    end
    if Skating.graceTimer <= 0 and Skating.ShouldRagdoll() then
        Skating.Clear()
        SetPedToRagdoll(ped, 5000, 4000, 0, true, true, false)
        return
    end

    local fwd   = IsControlPressed(0, 32)
    local back  = IsControlPressed(0, 33)
    local left  = IsControlPressed(0, 34)
    local right = IsControlPressed(0, 35)

    if IsControlPressed(0, 22) then
        Skating.HandleJump()
    elseif not overSpeed then
        if fwd and back then
            TaskVehicleTempAction(Skating.driver, Skating.vehicle, 30, 100)
        elseif fwd and left then
            TaskVehicleTempAction(Skating.driver, Skating.vehicle, 7, 1)
        elseif fwd and right then
            TaskVehicleTempAction(Skating.driver, Skating.vehicle, 8, 1)
        elseif back and left then
            TaskVehicleTempAction(Skating.driver, Skating.vehicle, 13, 1)
        elseif back and right then
            TaskVehicleTempAction(Skating.driver, Skating.vehicle, 14, 1)
        elseif fwd then
            TaskVehicleTempAction(Skating.driver, Skating.vehicle, 9, 1)
        elseif back then
            TaskVehicleTempAction(Skating.driver, Skating.vehicle, 22, 1)
        elseif left then
            TaskVehicleTempAction(Skating.driver, Skating.vehicle, 4, 1)
        elseif right then
            TaskVehicleTempAction(Skating.driver, Skating.vehicle, 5, 1)
        end
    end

    if (IsControlJustReleased(0, 32) or IsControlJustReleased(0, 33)) and not overSpeed then
        TaskVehicleTempAction(Skating.driver, Skating.vehicle, 6, 2500)
    end
end

function Skating.Loop()
    CreateThread(function()
        while active and DoesEntityExist(Skating.vehicle) and DoesEntityExist(Skating.driver) do
            if IsPedDeadOrDying(cache.ped, false) then
                Skating.Clear()
                break
            end

            Skating.HandleMovement()
            Wait(5)
        end
    end)

    -- Continuous no-collision loop for all nearby peds
    CreateThread(function()
        while active and DoesEntityExist(Skating.vehicle) do
            local allPeds = GetGamePool('CPed')
            for i = 1, #allPeds do
                local p = allPeds[i]
                if p ~= cache.ped then
                    SetEntityNoCollisionEntity(Skating.vehicle, p, false)
                    SetEntityNoCollisionEntity(p, Skating.vehicle, false)
                end
            end
            Wait(1000)
        end
    end)
end

function Skating.CleanEntities()
    if DoesEntityExist(Skating.vehicle) then
        DetachEntity(Skating.vehicle, true, true)
        DeleteVehicle(Skating.vehicle)
    end
    if DoesEntityExist(Skating.board) then
        DeleteEntity(Skating.board)
    end
    if DoesEntityExist(Skating.driver) then
        DeleteEntity(Skating.driver)
    end
    Skating.UnloadAssets()
end

function Skating.Clear()
    if not active then return end

    local ped = cache.ped
    DetachEntity(ped, false, false)
    StopAnimTask(ped, 'move_strafe@stealth', 'idle', 1.0)
    StopAnimTask(ped, 'move_crouch_proto', 'idle_intro', 1.0)

    active = false
    busy = false
    Skating.speed = 0

    if DoesEntityExist(Skating.vehicle) then
        DetachEntity(Skating.vehicle, true, true)
        DeleteVehicle(Skating.vehicle)
    end
    if DoesEntityExist(Skating.board) then
        DeleteEntity(Skating.board)
    end
    if DoesEntityExist(Skating.driver) then
        DeleteEntity(Skating.driver)
    end

    Skating.UnloadAssets()
end

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        Skating.Clear()
    end
end)
