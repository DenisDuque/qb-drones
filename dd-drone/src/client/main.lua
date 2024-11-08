local QBCore = exports['qb-core']:GetCoreObject()

local Drones = {}

Drones.SceneModels = {
  drone   = GetHashKey('ch_prop_arcade_drone_01a'),
  laptop  = GetHashKey('prop_cs_tablet')
}

Drones.LoadModel = function(hash)
  RequestModel(hash)
  while not HasModelLoaded(hash) do 
      Wait(0) 
  end
  print("Model loaded: " .. hash)  -- Debug log
end

Drones.CreateObject = function(pos, hash, net)
  Drones.LoadModel(hash)
  local del_obj = GetClosestObjectOfType(pos.x, pos.y, pos.z, 2.5, hash, false, true, true)
  if del_obj then
    SetEntityAsMissionEntity(del_obj, true, true)
    DeleteObject(del_obj)
  end
  local _object = CreateObject(hash, pos.x, pos.y, pos.z, net, true, true)
  if (type(pos) == "vector4") then
    SetEntityHeading(_object,pos.w)
  end
  return _object
end

Drones.SceneObjects = function()
  local pos = GetEntityCoords(PlayerPedId())
  local objects = {}
  for key,hash in pairs(Drones.SceneModels) do
    objects[key] = Drones.CreateObject(pos, hash, 1)
    SetEntityAsMissionEntity(objects[key], true, true)
    SetEntityCollision(objects[key], false, false)
    SetModelAsNoLongerNeeded(hash)
  end
  return objects
end

Drones.CreateCam = function(attach_to)
  local camera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", 0.0, 0.0, 0.0, 0, 0, 0, 50 * 1.0, false, 0)
  local min,max = GetModelDimensions(GetEntityModel(attach_to))

  SetCamActive(camera, true)
  RenderScriptCams(true, false, 0, true, false)
  AttachCamToEntity(camera,attach_to, 0.0, 0.0, -max.z/2, false)
  SetFocusEntity(attach_to)

  ClearTimecycleModifier()
  SetTimecycleModifier("eyeinthesky")
  SetTimecycleModifierStrength(0.1)

  return camera
end

Drones.CreateControls = function(abilities)
  local controls
  if type(abilities) == "string" then
    controls = {
      [1] = Config.Controls.Homing["cancel"],
      [2] = Config.Controls.Homing["disconnect"]
    }
  else
    controls = {
      [1] = Config.Controls.Drone["direction"],
      [2] = Config.Controls.Drone["heading"],
      [3] = Config.Controls.Drone["height"],
      [4] = Config.Controls.Drone["camera"],
      [5] = Config.Controls.Drone["zoom"],
    }

    if abilities.nightvision then
      table.insert(controls,Config.Controls.Drone["nightvision"])
    end

    if abilities.infrared then
      table.insert(controls,Config.Controls.Drone["infrared"])
    end

    if abilities.tazer then
      table.insert(controls,Config.Controls.Drone["tazer"])
    end

    if abilities.boost then
      table.insert(controls,Config.Controls.Drone["boost"])
    end

    if abilities.explosive then
      table.insert(controls,Config.Controls.Drone["explosive"])
    end

    table.insert(controls,Config.Controls.Drone["centercam"])
    table.insert(controls,Config.Controls.Drone["home"])
    table.insert(controls,Config.Controls.Drone["disconnect"])
  end

  return controls
end

Drones.SpawnDrone = function(drone_data)
  DoScreenFadeOut(500)
  local controls = Drones.CreateControls(drone_data.abilities)
  Drones.ButtonsScaleform = Instructional.Create(controls)
  Wait(500)

  local drone_model = drone_data.model
  local ply_ped = PlayerPedId()
  local ply_pos = GetEntityCoords(ply_ped)
  local ply_fwd = GetEntityForwardVector(ply_ped)

  local distance = 1.0 -- Distance from the player
  local spawn_pos = ply_pos + (ply_fwd * distance)

  local in_vehicle = IsPedInAnyVehicle(ply_ped, false)
  if in_vehicle then
    local vehicle = GetVehiclePedIsIn(ply_ped, false)
    local veh_pos = GetEntityCoords(vehicle)
    local veh_height = GetEntityHeightAboveGround(vehicle)
    spawn_pos = vector3(veh_pos.x, veh_pos.y, veh_pos.z + veh_height + 2.0)
  end

  local drone       = Drones.CreateObject((spawn_pos), drone_model, 1)
  local cam         = Drones.CreateCam(drone)

  SetEntityAsMissionEntity(drone, true, true)
  SetObjectPhysicsParams(drone, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0)

  local pos = GetEntityCoords(drone)
  local hed = GetEntityHeading(drone)
  local rot = GetEntityRotation(drone, 2)

  local velocity = vector3(0.0, 0.0, 0.0)
  local rotation = vector3(0.0, 0.0, 0.0)

  Drones.DroneScaleform = Scaleforms.LoadMovie("DRONE_CAM")
  Scaleforms.PopBool(Drones.DroneScaleform,"SET_EMP_METER_IS_VISIBLE", 0)
  Scaleforms.PopBool(Drones.DroneScaleform,"SET_INFO_LIST_IS_VISIBLE", 0)
  Scaleforms.PopBool(Drones.DroneScaleform,"SET_SOUND_WAVE_IS_VISIBLE", 0)
  Scaleforms.PopBool(Drones.DroneScaleform,"SET_TRANQUILIZE_METER_IS_VISIBLE", 0)

  Scaleforms.PopBool(Drones.DroneScaleform,"SET_DETONATE_METER_IS_VISIBLE",   drone_data.abilities.explosive)
  Scaleforms.PopBool(Drones.DroneScaleform,"SET_SHOCK_METER_IS_VISIBLE",      drone_data.abilities.tazer)
  Scaleforms.PopBool(Drones.DroneScaleform,"SET_RETICLE_IS_VISIBLE",          drone_data.abilities.tazer)
  Scaleforms.PopBool(Drones.DroneScaleform,"SET_BOOST_METER_IS_VISIBLE",      drone_data.abilities.boost)
  Scaleforms.PopBool(Drones.DroneScaleform,"SET_HEADING_METER_IS_VISIBLE", 1)
  Scaleforms.PopBool(Drones.DroneScaleform,"SET_ZOOM_METER_IS_VISIBLE", 1)

  Scaleforms.PopInt(Drones.DroneScaleform,"SET_ZOOM", 0)
  Scaleforms.PopInt(Drones.DroneScaleform,"SET_BOOST_PERCENTAGE", 100)
  Scaleforms.PopInt(Drones.DroneScaleform,"SET_DETONATE_PERCENTAGE", 100)
  Scaleforms.PopInt(Drones.DroneScaleform,"SET_SHOCK_PERCENTAGE", 100)

  Scaleforms.PopInt(Drones.DroneScaleform,"SET_TRANQUILIZE_PERCENTAGE", 100)
  Scaleforms.PopInt(Drones.DroneScaleform,"SET_EMP_PERCENTAGE", 100)

  Scaleforms.PopMulti(Drones.DroneScaleform,"SET_ZOOM_LABEL", 0, "Zoom")
  Scaleforms.PopMulti(Drones.DroneScaleform,"SET_ZOOM_LABEL", 1, "")
  Scaleforms.PopMulti(Drones.DroneScaleform,"SET_ZOOM_LABEL", 2, "DRONE_ZOOM_2")
  Scaleforms.PopMulti(Drones.DroneScaleform,"SET_ZOOM_LABEL", 3, "")
  Scaleforms.PopMulti(Drones.DroneScaleform,"SET_ZOOM_LABEL", 4, "DRONE_ZOOM_3")

  Drones.SoundID = GetSoundId()
  if Config.DroneSounds then
    PlaySoundFromEntity(Drones.SoundID, "Flight_Loop", drone, "DLC_BTL_Drone_Sounds", true, 0) 
  end

  SetEntityHealth(drone, 100)
  
  DoScreenFadeIn(500)
  Drones.DroneControl(drone_data, drone, cam)
  
end

local tab, temp = nil, false

local function attachObject()
	tab = CreateObject(Drones.SceneModels["laptop"], 0, 0, 0, true, true, true)
	AttachEntityToEntity(tab, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 28422), -0.05, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
end

local function stopAnim()
	temp = false
	StopAnimTask(PlayerPedId(), "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a", "idle_a", 8.0)

	if tab then  -- Check if tab is not nil
		DeleteObject(tab)
		tab = nil  -- Clear the variable after deletion
	end

	FreezeEntityPosition(PlayerPedId(), false)
end

local function startAnim()
  if not temp then
		RequestAnimDict("amb@code_human_in_bus_passenger_idles@female@tablet@idle_a")
		while not HasAnimDictLoaded("amb@code_human_in_bus_passenger_idles@female@tablet@idle_a") do
			Citizen.Wait(0)
		end
		attachObject()
    TaskPlayAnim(PlayerPedId(), "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a", "idle_a" ,8.0, -8.0, -1, 49, 0, false, false, false)
    FreezeEntityPosition(PlayerPedId(), true)
		temp = true
	end
end

Drones.DroneControl = function(drone_data, drone, camera)
  local ply_ped = PlayerPedId()
  local ply_pos = GetEntityCoords(ply_ped)
  local ply_fwd = GetEntityForwardVector(ply_ped)

  local pos = ply_pos + ply_fwd

  local zoom = 0
  local head = 0.0
  local boost = 100.0
  local explosive = 100.0
  local tazer = 100.0

  local rotation_momentum = 0.0
  local movement_momentum = vector3(0.0, 0.0, 0.0)
  local camera_rotation = vector3(0.0, 0.0, 0.0)

  Drones.DisplayRadar = (not IsRadarHidden())
  DisplayRadar(false)
  startAnim()
  while true do
    local forward,right,up,p = GetEntityMatrix(drone)
    local dist = Vdist(ply_pos,p)

    DisableAllControlActions(0)
    SetEntityNoCollisionEntity(ply_ped, drone, true)
    --
    -- Health
    --
    local health = GetEntityHealth(drone)
    local maxHealth = 100
    if health < maxHealth then
      QBCore.Functions.Notify('Drone damaged! Disconnecting...', 'error')
      Drones.Disconnect(drone, drone_data, true)
      Drones.DestroyCam(camera)
      
      -- Add particle effect if you want
      
      -- local dronePos = GetEntityCoords(drone)
      -- UseParticleFxAsset("core")
      -- StartParticleFxNonLoopedAtCoord("ent_amb_sparking_wires", dronePos.x, dronePos.y, dronePos.z, 0.0, 0.0, 0.0, 1.0, false, false, false)
      -- PlaySoundFromCoord(-1, "spooky_rattle", dronePos.x, dronePos.y, dronePos.z, "DLC_HALLOWEEN_FVJ_Sounds", false, 10, false)
      
      return
    end
    --
    -- Boost
    --
    local boosted = false
    if drone_data.abilities.boost then
      if IsDisabledControlPressed(0, Config.Controls.Drone["boost"].codes[1]) and boost > 1.0 then
        boost = math.max(1.0, boost - (Config.BoostDrain * GetFrameTime()))
        boosted = true
      else
        boost = math.min(100.0, boost + (Config.BoostFill * GetFrameTime()))
      end
      Scaleforms.PopInt(Drones.DroneScaleform, "SET_BOOST_PERCENTAGE", math.floor(boost))
    end
    --
    -- Drone Movement
    --
    local did_move = false
    local max_boost = (Config.MaxVelocity * drone_data.stats.speed)
    if boosted then
      max_boost = max_boost * Config.BoostSpeed
    end
    if IsDisabledControlPressed(0, Config.Controls.Drone["direction"].codes[1]) then
      movement_momentum = V3ClampMagnitude(movement_momentum + (forward * drone_data.stats.agility),max_boost)
      did_move = true
    end

    if IsDisabledControlPressed(0, Config.Controls.Drone["direction"].codes[2]) then
      movement_momentum = V3ClampMagnitude(movement_momentum - (forward * drone_data.stats.agility),max_boost)
      did_move = true
    end

    if IsDisabledControlPressed(0, Config.Controls.Drone["direction"].codes[3]) then
      movement_momentum = V3ClampMagnitude(movement_momentum - (right * drone_data.stats.agility),max_boost)
      did_move = true
    end

    if IsDisabledControlPressed(0, Config.Controls.Drone["direction"].codes[4]) then
      movement_momentum = V3ClampMagnitude(movement_momentum + (right * drone_data.stats.agility),max_boost)
      did_move = true
    end

    if IsDisabledControlPressed(0, Config.Controls.Drone["height"].codes[1]) then
      movement_momentum = V3ClampMagnitude(movement_momentum - (up * drone_data.stats.agility),max_boost)
      did_move = true
    end

    if IsDisabledControlPressed(0,Config.Controls.Drone["height"].codes[2]) then
      movement_momentum = V3ClampMagnitude(movement_momentum + (up * drone_data.stats.agility),max_boost)
      did_move = true
    end

    --
    -- Cam Rotation
    --
    local minRotationX = -70 -- Bottom limit
    local maxRotationX = 45 -- Top limit
    local mouseSensitivity = 5.0

    -- Cam Rotation using Y mouse movement
    local mouseY = GetDisabledControlNormal(0, 2)

    -- Apply the mouse movement to the camera rotation
    camera_rotation = camera_rotation + vector3(-mouseY * mouseSensitivity, 0.0, 0.0)

    -- Limit the camera rotation so it doesn't invert
    if camera_rotation.x < minRotationX then
        camera_rotation = vector3(minRotationX, camera_rotation.y, camera_rotation.z)
    elseif camera_rotation.x > maxRotationX then
        camera_rotation = vector3(maxRotationX, camera_rotation.y, camera_rotation.z)
    end


    --
    -- Drone Heading
    --

    -- Mouse sensitivity for heading
    local mouseSensitivityHeading = 7.0

    -- Get the mouse movement on the X axis
    local mouseX = GetDisabledControlNormal(0, 1)

    -- Invert the mouse movement to correct the turn direction
    rotation_momentum = -mouseX * mouseSensitivityHeading

    -- Limit the rotation momentum so it’s not excessive
    rotation_momentum = math.min(1.5, math.max(-1.5, rotation_momentum))

    -- Settings to smooth the movement when the mouse is stationary
    if math.abs(rotation_momentum) > 0.0 then
        if rotation_momentum > 0.0 then
            rotation_momentum = math.max(0.0, rotation_momentum - 0.04)
        elseif rotation_momentum < 0.0 then
            rotation_momentum = math.min(0.0, rotation_momentum + 0.04)
        end
    end

    --
    -- Zoom
    --
    if IsDisabledControlJustPressed(0,Config.Controls.Drone["zoom"].codes[1]) then
      zoom = math.max(0, (zoom or 0) - 1)
      Scaleforms.PopInt(Drones.DroneScaleform, "SET_ZOOM", zoom)

      SetCamFov(camera, 50.0 - (10.0 * zoom))
    end
    
    if IsDisabledControlJustPressed(0,Config.Controls.Drone["zoom"].codes[2]) then
      zoom = math.min(4, (zoom or 0) + 1)
      Scaleforms.PopInt(Drones.DroneScaleform, "SET_ZOOM", zoom)

      SetCamFov(camera, 50.0 - (10.0 * zoom))
    end

    --
    -- Nightvision
    --
    if drone_data.abilities.nightvision and IsDisabledControlJustPressed(0,Config.Controls.Drone["nightvision"].codes[1]) then
      if not NightvisionEnabled then
        NightvisionEnabled = true
        SetNightvision(true)
      else
        NightvisionEnabled = false
        SetNightvision(false)
      end
    end

    --
    -- infrared
    --
    if drone_data.abilities.infrared and IsDisabledControlJustPressed(0,Config.Controls.Drone["infrared"].codes[1]) then
      if not InfraredEnabled then
        InfraredEnabled = true
        SetSeethrough(true)
      else
        InfraredEnabled = false
        SetSeethrough(false)
      end
    end

    --
    -- Tazer
    --
    if drone_data.abilities.tazer then
      if IsDisabledControlJustPressed(0,Config.Controls.Drone["tazer"].codes[1]) and tazer >= 100.0 then
        tazer = 1.0
        local right,forward,up,p = GetCamMatrix(camera)
        forward = forward * 10.0

        SetCanAttackFriendly(PlayerPedId(), true, false)
        SetCanAttackFriendly(drone, true, false)
        NetworkSetFriendlyFireOption(true)
        Wait(0)

        ShootSingleBulletBetweenCoords(p.x,p.y,p.z, p.x+forward.x, p.y+forward.y, p.z+forward.z, 0, false, GetHashKey('WEAPON_STUNGUN'), PlayerPedId(), true, true, 100.0)   
      else
        tazer = math.min(100.0,tazer + (Config.TazerFill * GetFrameTime()))
      end
      Scaleforms.PopInt(Drones.DroneScaleform, "SET_SHOCK_PERCENTAGE", math.floor(tazer))
    end

    --
    -- Explosive
    --
    if drone_data.abilities.explosive then
      if IsDisabledControlJustPressed(0,Config.Controls.Drone["explosive"].codes[1]) and explosive >= 100.0 then
        local pos = GetEntityCoords(drone)
        Drones.Disconnect(drone, drone_data, true)
        Drones.DestroyCam(camera)
        AddExplosion(pos.x,pos.y,pos.z,1,1.0,true,false,1.0)
        return
      else
        explosive = math.min(100.0, explosive + (1.0 * GetFrameTime()))
      end
      Scaleforms.PopInt(Drones.DroneScaleform, "SET_DETONATE_PERCENTAGE", math.floor(explosive))
    end

    --
    -- Default Cam Position
    --
    if IsDisabledControlPressed(0,Config.Controls.Drone["centercam"].codes[1]) then
      camera_rotation = vector3(0.0,0.0,0.0)
    end

    --
    -- Return Home
    --
    if IsDisabledControlPressed(0,Config.Controls.Drone["home"].codes[1]) then
      QBCore.Functions.Notify('Returning home')
      PointCamAtEntity(camera,PlayerPedId(),0.0,0.0,0.0,true)

      local continue_flying = false
      local dist = Vdist(GetEntityCoords(drone),GetEntityCoords(PlayerPedId()))
      local controls = Drones.CreateControls("home")
      Drones.ButtonsScaleform = Instructional.Create(controls)

      Wait(100)
      while dist > 3.0 do
        local ply_ped   = PlayerPedId()
        local drone_pos = GetEntityCoords(drone)
        local ply_pos   = GetEntityCoords(ply_ped)
        local direction = -V3ClampMagnitude((drone_pos - ply_pos) * 10.0,(Config.MaxVelocity * drone_data.stats.speed))

        DisableAllControlActions(0)
        SetEntityNoCollisionEntity(ply_ped,drone,true)

        ApplyForceToEntity(drone,0,direction.x,direction.y,20.0 + (V2Dist(drone_pos,ply_pos) <= 5.0 and direction.z or 0.0), 0.0,0.0,0.0, 0, false,true,true,false,true)

        DrawScaleformMovieFullscreen(Drones.ButtonsScaleform,255,255,255,255,0)
        DrawScaleformMovieFullscreen(Drones.DroneScaleform,255,255,255,255,0)

        if IsDisabledControlJustReleased(0,Config.Controls.Homing["cancel"].codes[1]) then
          continue_flying = true
          Wait(100)
          break
        elseif IsDisabledControlJustReleased(0, Config.Controls.Homing["disconnect"].codes[1]) then
          Wait(100)
          break
        end
        
        dist = Vdist(drone_pos,ply_pos)
        SetTimecycleModifierStrength(dist / drone_data.stats.range)
        Wait(0)
      end
      
      if not continue_flying then
        Drones.Disconnect(drone, drone_data)
        Drones.DestroyCam(camera)
        return
      else
        local controls = Drones.CreateControls(drone_data.abilities)
        Drones.ButtonsScaleform = Instructional.Create(controls)
        StopCamPointing(camera)
      end
    end

    --
    -- Disconnect Drone
    --
    if IsDisabledControlJustReleased(0,Config.Controls.Drone["disconnect"].codes[1]) then
      Drones.Disconnect(drone, drone_data)
      Drones.DestroyCam(camera)
      return
    end

    --
    -- Drone Movement
    --
    local boost_val = Config.BoostSpeed
    head = head + (rotation_momentum * drone_data.stats.agility)

    if not did_move then
      if V3Magnitude(movement_momentum) > 0.0 then
        movement_momentum = movement_momentum - ((movement_momentum / 10.0) * drone_data.stats.agility)
      end
    end

    ApplyForceToEntity(drone,0,movement_momentum.x,movement_momentum.y,20.0 + movement_momentum.z, 0.0,0.0,0.0, 0, false,true,true,false,true)
    SetEntityHeading(drone,head)
    SetCamRot(camera,camera_rotation.x,camera_rotation.y,camera_rotation.z+head,2)

    --
    -- Scaleform
    --
    SetTimecycleModifierStrength(dist / drone_data.stats.range)
    DrawScaleformMovieFullscreen(Drones.ButtonsScaleform,255,255,255,255,0)
    DrawScaleformMovieFullscreen(Drones.DroneScaleform,255,255,255,255,0)

    Wait(0)
  end
end

Drones.DestroyCam = function(cam)
  local ply_ped   = PlayerPedId()
  SetFocusEntity(ply_ped)
  ClearTimecycleModifier()  
  RenderScriptCams(false,true,500,false,false)
  Wait(500)
  stopAnim()
  DestroyCam(cam, true)
end

Drones.Disconnect = function(drone, drone_data, destroy)
  local ply_pos   = GetEntityCoords(PlayerPedId())
  local drone_pos = GetEntityCoords(drone)
  if not destroy and not drone_data.singleuse and Vdist(drone_pos, ply_pos) <= 10.0 then
    QBCore.Functions.Notify('The drone is back')
    TriggerServerEvent("Drones:Back", drone_data)
  elseif destroy then
    QBCore.Functions.Notify("The drone disappeared")
  else
    QBCore.Functions.Notify("Drone Disconnected")
    local pos = GetGroundZ(drone_pos) + vector3(0.0,0.0,0.8)
    TriggerServerEvent("Drones:Disconnect", GetEntityModel(drone), drone_data, pos)
  end

  StopSound(Drones.SoundID)
  ReleaseSoundId(Drones.SoundID)
  Drones.SoundID = nil

  DisplayRadar(Drones.DisplayRadar)

  SetSeethrough(false)
  SetNightvision(false)
  DeleteObject(drone)
end

Citizen.CreateThread(function()
  ClearTimecycleModifier()
  ClearPedTasks(PlayerPedId())
  SetFocusEntity(PlayerPedId())
end)

Drones.Use = function(drone_data)
  Drones.SceneModels["drone"] = drone_data.model

  Drones.SpawnDrone(drone_data)

  Wait(1000)
  FreezeEntityPosition(PlayerPedId(), false)
  ClearPedTasks(PlayerPedId())
end

Drones.DropDrone = function(drone, model, pos)
  local groundHeight = GetGroundZ(pos)
  
  local positionOnGround = vector3(pos.x, groundHeight, pos.z)

  Drones.CreateObject(positionOnGround, model, 1)
  
end


--Citizen.CreateThread(Drones.Init)

RegisterNetEvent("Drones:UseDrone")
AddEventHandler("Drones:UseDrone", Drones.Use)
RegisterNetEvent("Drones:DropDrone")
AddEventHandler("Drones:DropDrone", Drones.DropDrone)