local Skating = {}
local active = false
local busy = false

-- Toggle skateboard on/off from inventory use
RegisterNetEvent('astudios-skating:client:toggle', function()
    if busy then return end
    if active then
        Skating.Clear()
    else
        Skating.Start()
    end
end)

function Skating.Start()
    if active or busy then return end
    busy = true

    local ped = cache.ped

    Skating.LoadModels({
        GetHashKey('bmx'),
        68070371,
        GetHashKey('p_defilied_ragdoll_01_s'),
        'move_strafe@stealth',
        'move_crouch_proto',
    })

    local spawnCoords = GetEntityCoords(ped) + GetEntityForwardVector(ped) * 2.0
    local spawnHeading = GetEntityHeading(ped)

    -- Invisible BMX as physics vehicle
    Skating.vehicle = CreateVehicle(GetHashKey('bmx'), spawnCoords, spawnHeading, true, false)
    while not DoesEntityExist(Skating.vehicle) do Wait(5) end

    SetEntityVisible(Skating.vehicle, false, false)

    -- No collision between BMX and ALL peds (player, pets, NPCs)
    -- Prevents nearby peds from bumping/flipping the invisible bike
    SetEntityNoCollisionEntity(Skating.vehicle, ped, false)
    local allPeds = GetGamePool('CPed')
    for i = 1, #allPeds do
        if allPeds[i] ~= ped then
            SetEntityNoCollisionEntity(Skating.vehicle, allPeds[i], false)
            SetEntityNoCollisionEntity(allPeds[i], Skating.vehicle, false)
        end
    end

    -- Skateboard prop
    Skating.board = CreateObject(GetHashKey('p_defilied_ragdoll_01_s'), 0.0, 0.0, 0.0, true, true, true)
    while not DoesEntityExist(Skating.board) do Wait(5) end
    AttachEntityToEntity(Skating.board, Skating.vehicle, GetPedBoneIndex(ped, 28422),
        0.0, 0.0, -0.40, 0.0, 0.0, 90.0, false, true, true, true, 1, true)

    -- Invisible ped to drive the BMX
    Skating.driver = CreatePed(12, 68070371, spawnCoords, spawnHeading, true, true)
    SetEnableHandcuffs(Skating.driver, true)
    SetEntityInvincible(Skating.driver, true)
    SetEntityVisible(Skating.driver, false, false)
    FreezeEntityPosition(Skating.driver, true)
    TaskWarpPedIntoVehicle(Skating.driver, Skating.vehicle, -1)

    -- Wait for driver with timeout to prevent infinite hang
    local warpTimeout = 50
    while not IsPedInVehicle(Skating.driver, Skating.vehicle) do
        Wait(0)
        warpTimeout = warpTimeout - 1
        if warpTimeout <= 0 then
            -- Failed to seat driver — abort and clean up
            Skating.CleanEntities()
            busy = false
            lib.notify({ description = 'Failed to start skateboard, try again', type = 'error' })
            return
        end
    end

    -- Mount player immediately
    TaskPlayAnim(ped, 'move_strafe@stealth', 'idle', 8.0, 8.0, -1, 1, 1.0, false, false, false)
    AttachEntityToEntity(ped, Skating.vehicle, 20,
        0.0, 0.0, 0.7, 0.0, 0.0, -15.0, true, true, false, true, 1, true)
    SetEntityCollision(ped, true, true)

    active = true
    busy = false
    Skating.speed = 0
    Skating.graceTimer = 100 -- skip ragdoll checks for first ~500ms while physics settle

    lib.notify({ description = Config.Controls, type = 'info' })
    Skating.Loop()
end

function Skating.ShouldRagdoll()
    local ped = cache.ped
    local rot = GetEntityRotation(Skating.vehicle)

    if (-60.0 < rot.x and rot.x > 60.0) and IsEntityInAir(Skating.vehicle) and Skating.speed < 5.0 then
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

    -- Keep entity control
    if not NetworkHasControlOfEntity(Skating.driver) then
        NetworkRequestControlOfEntity(Skating.driver)
    end
    if not NetworkHasControlOfEntity(Skating.vehicle) then
        NetworkRequestControlOfEntity(Skating.vehicle)
    end

    local overSpeed = (GetEntitySpeed(Skating.vehicle) * 3.6) > Config.MaxSpeedKmh
    TaskVehicleTempAction(Skating.driver, Skating.vehicle, 1, 1)
    ForceVehicleEngineAudio(Skating.vehicle, 0)
    SetEntityInvincible(Skating.vehicle, true)
    StopCurrentPlayingAmbientSpeech(Skating.driver)

    -- Ragdoll check — wipe out = board gone, use item again
    -- Grace period skips ragdoll for first ~500ms while physics settle
    Skating.speed = GetEntitySpeed(Skating.vehicle) * 3.6
    if Skating.graceTimer > 0 then
        Skating.graceTimer = Skating.graceTimer - 1
    end
    if Skating.graceTimer <= 0 and Skating.ShouldRagdoll() then
        Skating.Clear()
        SetPedToRagdoll(ped, 5000, 4000, 0, true, true, false)
        return
    end

    -- Movement
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
end

-- Delete entities without state guards (used for abort during Start)
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
    Skating.UnloadModels()
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

    Skating.UnloadModels()
end

function Skating.LoadModels(models)
    Skating.models = models
    for _, model in ipairs(models) do
        if IsModelValid(model) then
            lib.requestModel(model)
        else
            lib.requestAnimDict(model)
        end
    end
end

function Skating.UnloadModels()
    if not Skating.models then return end
    for _, model in ipairs(Skating.models) do
        if IsModelValid(model) then
            SetModelAsNoLongerNeeded(model)
        else
            RemoveAnimDict(model)
        end
    end
    Skating.models = nil
end

-- Cleanup on resource stop / restart
AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        Skating.Clear()
    end
end)
