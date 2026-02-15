local Skating = {}
local connected = false
local active = false

-- Toggle skateboard on/off from inventory use
RegisterNetEvent('astudios-skating:client:toggle', function()
    if active then
        Skating.Clear()
    else
        Skating.Start()
    end
end)

function Skating.Start()
    if active then return end

    local ped = cache.ped

    Skating.LoadModels({
        GetHashKey('bmx'),
        68070371,
        GetHashKey('p_defilied_ragdoll_01_s'),
        'pickup_object',
        'move_strafe@stealth',
        'move_crouch_proto',
    })

    local spawnCoords = GetEntityCoords(ped) + GetEntityForwardVector(ped) * 2.0
    local spawnHeading = GetEntityHeading(ped)

    -- Invisible BMX as physics vehicle
    Skating.vehicle = CreateVehicle(GetHashKey('bmx'), spawnCoords, spawnHeading, true, false)
    while not DoesEntityExist(Skating.vehicle) do Wait(5) end

    -- Skateboard prop
    Skating.board = CreateObject(GetHashKey('p_defilied_ragdoll_01_s'), 0.0, 0.0, 0.0, true, true, true)
    while not DoesEntityExist(Skating.board) do Wait(5) end

    SetEntityNoCollisionEntity(Skating.vehicle, ped, false)
    SetEntityCollision(Skating.vehicle, false, true)
    SetEntityVisible(Skating.vehicle, false, false)
    AttachEntityToEntity(Skating.board, Skating.vehicle, GetPedBoneIndex(ped, 28422),
        0.0, 0.0, -0.40, 0.0, 0.0, 90.0, false, true, true, true, 1, true)

    -- Invisible ped to drive the BMX
    Skating.driver = CreatePed(12, 68070371, spawnCoords, spawnHeading, true, true)
    SetEnableHandcuffs(Skating.driver, true)
    SetEntityInvincible(Skating.driver, true)
    SetEntityVisible(Skating.driver, false, false)
    FreezeEntityPosition(Skating.driver, true)
    TaskWarpPedIntoVehicle(Skating.driver, Skating.vehicle, -1)

    while not IsPedInVehicle(Skating.driver, Skating.vehicle) do Wait(0) end

    active = true
    Skating.PlaceBoard()
    Skating.Loop()
end

function Skating.PlaceBoard()
    if not DoesEntityExist(Skating.vehicle) then return end

    local ped = cache.ped
    AttachEntityToEntity(Skating.vehicle, ped, GetPedBoneIndex(ped, 28422),
        -0.1, 0.0, -0.2, 70.0, 0.0, 270.0, 1, 1, 0, 0, 2, 1)
    TaskPlayAnim(ped, 'pickup_object', 'pickup_low', 8.0, -8.0, -1, 0, 0, false, false, false)
    Wait(800)
    DetachEntity(Skating.vehicle, false, true)
    PlaceObjectOnGroundProperly(Skating.vehicle)

    lib.notify({ description = Config.Controls, type = 'info' })
end

function Skating.PickupBoard()
    if not DoesEntityExist(Skating.vehicle) then return end

    local ped = cache.ped
    TaskPlayAnim(ped, 'pickup_object', 'pickup_low', 8.0, -8.0, -1, 0, 0, false, false, false)
    Wait(600)
    AttachEntityToEntity(Skating.vehicle, ped, GetPedBoneIndex(ped, 28422),
        -0.1, 0.0, -0.2, 70.0, 0.0, 270.0, 1, 1, 0, 0, 2, 1)
    Wait(900)
    Skating.Clear()
end

function Skating.MountPlayer(toggle)
    local ped = cache.ped

    if toggle then
        TaskPlayAnim(ped, 'move_strafe@stealth', 'idle', 8.0, 8.0, -1, 1, 1.0, false, false, false)
        AttachEntityToEntity(ped, Skating.vehicle, 20,
            0.0, 0.0, 0.7, 0.0, 0.0, -15.0, true, true, false, true, 1, true)
        SetEntityCollision(ped, true, true)
    else
        DetachEntity(ped, false, false)
        StopAnimTask(ped, 'move_strafe@stealth', 'idle', 1.0)
        StopAnimTask(ped, 'move_crouch_proto', 'idle_intro', 1.0)
        TaskVehicleTempAction(Skating.driver, Skating.vehicle, 3, 1)
    end

    connected = toggle
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
    if not connected or IsEntityInAir(Skating.vehicle) then return end

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

    if connected then
        SetEntityVelocity(Skating.vehicle, vel.x, vel.y, vel.z + boost)
        TaskPlayAnim(ped, 'move_strafe@stealth', 'idle', 8.0, 2.0, -1, 1, 1.0, false, false, false)
    end
end

function Skating.HandleMovement(distance)
    local ped = cache.ped

    -- E to pick up (close range)
    if distance <= 1.5 and IsControlJustPressed(0, 38) then
        Skating.PickupBoard()
        return
    end

    -- G to mount/dismount (close range)
    if distance <= 1.5 and IsControlJustReleased(0, 113) then
        if connected then
            Skating.MountPlayer(false)
        elseif not IsPedRagdoll(ped) then
            Wait(200)
            Skating.MountPlayer(true)
        end
    end

    -- Too far from board — coast to stop
    if distance >= Config.LoseConnectionDistance then
        TaskVehicleTempAction(Skating.driver, Skating.vehicle, 6, 2500)
        return
    end

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

    -- Ragdoll check
    if connected then
        Skating.speed = GetEntitySpeed(Skating.vehicle) * 3.6
        if Skating.ShouldRagdoll() then
            Skating.MountPlayer(false)
            SetPedToRagdoll(ped, 5000, 4000, 0, true, true, false)
            connected = false
        end
    end

    -- Movement
    local fwd   = IsControlPressed(0, 32)
    local back  = IsControlPressed(0, 33)
    local left  = IsControlPressed(0, 34)
    local right = IsControlPressed(0, 35)

    if IsControlPressed(0, 22) and connected then
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
            local ped = cache.ped

            -- Auto-cleanup on death
            if IsPedDeadOrDying(ped, false) then
                Skating.Clear()
                break
            end

            local distance = #(GetEntityCoords(ped) - GetEntityCoords(Skating.vehicle))
            Skating.HandleMovement(distance)
            Wait(5)
        end
    end)
end

function Skating.Clear()
    if not active then return end

    active = false
    connected = false
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
