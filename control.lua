script.on_init( -- new saves
function()
  Initialize()
end)

script.on_configuration_changed( --game version changes, prototypes change, startup mod settings change, and any time mod versions change including adding or removing mods
function()
  Initialize()
end)

function Initialize()
	if (global.OrientationUnitComponents == nil) then
		global.OrientationUnitComponents = {}
		global.OrientationUnitComponents[0] = {x = 0, y = -1, name = "up"}
		global.OrientationUnitComponents[0.25] = {x = 1, y = 0, name = "right"}
		global.OrientationUnitComponents[0.5] = {x = 0, y = 1, name = "down"}
		global.OrientationUnitComponents[0.75] = {x = -1, y = 0, name = "left"}
	end	
	
	if (global.AllPlayers == nil) then
		global.AllPlayers = {}		
	end
	
	for PlayerID, PlayerLuaData in pairs(game.players) do
		global.AllPlayers[PlayerID] = {}
	end
	
	if (global.FlyingTrains == nil) then
		global.FlyingTrains = {}		
	end
end


-- script.on_nth_tick(1, 
-- function(eventf)
--   if(global ~= nil and global.selected_entity ~= nil) then 
--     log("global.selected_entity.speed * global.selected_entity.max_speed")
--     --global.selected_entity.teleport({global.selected_entity.position.x, global.selected_entity.position.y-1})
--   end
-- end)

script.on_event("TeleportTrain", 
function(eventf)
  global.selected_entity = game.players[1].selected
  --selected_entity.teleport({selected_entity.position.x, selected_entity.position.y-1}) 
end)

script.on_nth_tick(1, 
function(eventf)
	----------------- train flight ----------------
	for PropUnitNumber, properties in pairs(global.FlyingTrains) do
		---------- launching connected wagons ---------

		-- if (properties.follower and properties.follower.valid) then
		-- 	if (properties.follower.train.speed>0) then
		-- 		properties.follower.train.speed = math.abs(properties.speed)
		-- 	else
		-- 		properties.follower.train.speed = -math.abs(properties.speed)
		-- 	end
		-- end

		--------- landing ----------
		if (game.tick == properties.LandTick) then
			TrainLandedOn = properties.GuideCar.surface.find_entities_filtered
				{
					name = {"RTTrainBouncePlate", "RTTrainDirectedBouncePlate"},
					position = properties.GuideCar.position,
					radius = 1.5,
					collision_mask = "object-layer"
				}[1] -- in theory only one thing should be detected in the object layer this way
			if (TrainLandedOn ~= nil and TrainLandedOn.name == "RTTrainBouncePlate") then
				properties.LaunchTick = game.tick
				properties.LandTick = math.ceil(game.tick + 130*math.abs(properties.speed))
				properties.GuideCar.teleport(TrainLandedOn.position)
				TrainLandedOn.surface.create_particle
					({
					name = "RTTrainBouncePlateParticle",
					position = TrainLandedOn.position,
					movement = {0,0},
					height = 0,
					vertical_speed = 0.2,
					frame_speed = 1
					})
				TrainLandedOn.surface.play_sound
					{
						path = "bounce",
						position = TrainLandedOn.position,
						volume = 2
					}

			elseif (TrainLandedOn ~= nil and TrainLandedOn.name == "RTTrainDirectedBouncePlate") then
				properties.GuideCar.teleport(TrainLandedOn.position)
				properties.RampOrientation = TrainLandedOn.orientation+0.5
				if (properties.GuideCar.speed > 0) then
					properties.GuideCar.orientation = TrainLandedOn.orientation
					properties.orientation = TrainLandedOn.orientation
				elseif (properties.GuideCar.speed < 0) then
					properties.GuideCar.orientation = TrainLandedOn.orientation+0.5
					properties.orientation = TrainLandedOn.orientation+0.5
				end
				
				if (properties.orientation >= 1) then
					properties.orientation = properties.orientation-1
				end	
				if (properties.RampOrientation >= 1) then
					properties.RampOrientation = properties.RampOrientation-1
				end

				base = properties.type
				mask = "NoMask"
				way = global.OrientationUnitComponents[properties.orientation].name
				if (base == "locomotive") then
					mask = "locomotiveMask"..way
				--elseif (base == "cargo-wagon") then
				--elseif (base == "fluid-wagon") then
				--elseif (base == "artillery-wagon") then
				end
				rendering.destroy(properties.TrainImageID)
				rendering.destroy(properties.MaskID)
				rendering.destroy(properties.ShadowID)
				properties.TrainImageID = rendering.draw_sprite
					{
					sprite = "RT"..base..way, 
					target = properties.GuideCar,
					surface = properties.GuideCar.surface,
					x_scale = 0.5,
					y_scale = 0.5,
					render_layer = 145
					}
				properties.MaskID = rendering.draw_sprite
					{
					sprite = "RT"..mask, 
					tint = properties.color or {r = 234, g = 17, b = 0, a = 100},
					target = properties.GuideCar,
					surface = properties.GuideCar.surface,
					x_scale = 0.5,
					y_scale = 0.5,
					render_layer = 145
					}
				properties.ShadowID = rendering.draw_sprite
					{
					sprite = "GenericShadow", 
					tint = {a = 90},
					target = properties.GuideCar,
					surface = properties.GuideCar.surface,
					orientation = properties.orientation,
					x_scale = 0.25,
					y_scale = 0.4,
					render_layer = 144
					}		
					
				properties.LaunchTick = game.tick
				properties.LandTick = math.ceil(game.tick + 130*math.abs(properties.speed))
				TrainLandedOn.surface.create_particle
					({
					name = "RTTrainBouncePlateParticle",
					position = TrainLandedOn.position,
					movement = {0,0},
					height = 0,
					vertical_speed = 0.2,
					frame_speed = 1
					})
				TrainLandedOn.surface.play_sound
					{
						path = "bounce",
						position = TrainLandedOn.position,
						volume = 2
					}			
			
			
			else
				NewTrain = properties.GuideCar.surface.create_entity
					({
						name = properties.name,
						position = properties.GuideCar.position,
						direction = properties.orientation, -- i think this does nothing
						force = properties.GuideCar.force,
						raise_built = true
					})
				-- train created --	
				if (NewTrain ~= nil) then 
					if (properties.passenger ~= nil) then
						NewTrain.set_driver(game.players[properties.passenger])	
					end	
				
					AngleChange = math.abs(NewTrain.orientation-properties.orientation) -- a new train will be made if there's enough rail, direction doesn't matter
					if (AngleChange > 0.5) then
						AngleChange = 1 - AngleChange
					end
					if (AngleChange <= 0.125) then					
					elseif (AngleChange >= 0.375) then
						NewTrain.disconnect_rolling_stock(defines.rail_direction.front)
						NewTrain.disconnect_rolling_stock(defines.rail_direction.back)
						NewTrain.rotate()
						NewTrain.connect_rolling_stock(defines.rail_direction.front)
						NewTrain.connect_rolling_stock(defines.rail_direction.back)
					else -- AngleChange is between 0.125 and 0.375, which is a rail ~90 degrees off from original launch. doesn't make sense so destroy
						NewTrain.die()
						for urmum, lol in pairs(properties.GuideCar.surface.find_entities_filtered({position = properties.GuideCar.position, radius = 4})) do
							if (lol.valid and lol.is_entity_with_health == true and lol.health ~= nil) then
								lol.damage(1000, "neutral", "explosion")
							elseif (lol.valid and lol.name == "cliff") then
								lol.destroy({do_cliff_correction = true})
							end
						end
					end
					
					if (NewTrain.valid) then
						-- this order of setting speed -> manual mode -> schedule is very important, other orders mess up a lot more
						if (properties.RampOrientation == properties.orientation) then
							NewTrain.train.speed = -properties.speed
						else
							NewTrain.train.speed = properties.speed
						end

						NewTrain.train.manual_mode = properties.ManualMode -- Trains are default created in manual mode
						if (properties.schedule ~= nil) then
							NewTrain.train.schedule = properties.schedule
						end	
					
						if (NewTrain.type == "locomotive") then
							NewTrain.color = properties.color
							NewTrain.backer_name = properties.SpecialName
							if (NewTrain.burner) then
								NewTrain.burner.currently_burning = properties.CurrentlyBurning
								NewTrain.burner.remaining_burning_fuel = properties.RemainingFuel 
								for FuelName, quantity in pairs(properties.FuelInventory) do
									NewTrain.get_fuel_inventory().insert({name = FuelName, count = quantity})
								end
							end
						elseif (NewTrain.type == "cargo-wagon") then
							for ItemName, quantity in pairs(properties.cargo) do
								NewTrain.get_inventory(defines.inventory.cargo_wagon).insert({name = ItemName, count = quantity})
							end
							NewTrain.get_inventory(defines.inventory.cargo_wagon).set_bar(properties.bar)
							for i, filter in pairs(properties.filter) do
								NewTrain.get_inventory(defines.inventory.cargo_wagon).set_filter(i, filter)
							end
						elseif (NewTrain.type == "fluid-wagon") then
							for FluidName, quantity in pairs(properties.fluids) do
								NewTrain.insert_fluid({name = FluidName, amount = quantity})
							end
						elseif (NewTrain.type == "artillery-wagon") then
							for ItemName, quantity in pairs(properties.artillery) do
								NewTrain.get_inventory(defines.inventory.artillery_wagon_ammo).insert({name = ItemName, count = quantity})
							end
						end	
					end
					properties.GuideCar.destroy()
					
				-- no train created --
				else 
					if (properties.GuideCar.surface.find_tiles_filtered{position = properties.GuideCar.position, radius = 1, limit = 1, collision_mask = "player-layer"}[1] == nil) then
						properties.GuideCar.surface.create_entity
							({
								name = "big-scorchmark",
								position = properties.GuideCar.position
							})
					end
					
					local key, value = next(game.entity_prototypes[properties.name].corpses)
					rip = properties.GuideCar.surface.create_entity
						({
							name = key or "locomotive-remnants",
							position = properties.GuideCar.position,
							force = properties.GuideCar.force
						})
					rip.color = properties.color
					rip.orientation = properties.orientation

					boom = properties.GuideCar.surface.create_entity
						({
							name = "locomotive-explosion",
							position = properties.GuideCar.position
						})
					properties.GuideCar.destroy()
					
					for each, guy in pairs(game.connected_players) do
						guy.add_alert(rip,defines.alert_type.entity_destroyed)
					end
					
					for urmum, lol in pairs(boom.surface.find_entities_filtered({position = boom.position, radius = 4})) do
						if (lol.valid and lol.is_entity_with_health == true and lol.health ~= nil) then
							lol.damage(1000, "neutral", "explosion")
						elseif (lol.name == "cliff") then
							lol.destroy({do_cliff_correction = true})
						end
					end
					
				end
				global.FlyingTrains[PropUnitNumber] = nil
			end	
		------------- animating -----------	
		elseif (properties.RampOrientation == 0) then -- going down
			rendering.set_target(properties.TrainImageID, properties.GuideCar, {0,((game.tick-properties.LaunchTick)^2-(game.tick-properties.LaunchTick)*properties.AirTime)/500})
			rendering.set_target(properties.MaskID, properties.GuideCar, {0,((game.tick-properties.LaunchTick)^2-(game.tick-properties.LaunchTick)*properties.AirTime)/500})
			rendering.set_target(properties.ShadowID, properties.GuideCar, {-((game.tick-properties.LaunchTick)^2-(game.tick-properties.LaunchTick)*properties.AirTime)/500,0})	
    elseif (properties.RampOrientation == 0.25) then -- going left
      rendering.set_target(properties.TrainImageID, properties.GuideCar, {0,(game.tick-properties.LaunchTick)*((game.tick-properties.LaunchTick)-properties.AirTime)/500})
			rendering.set_orientation(properties.TrainImageID, 0.25)
			rendering.set_target(properties.MaskID, properties.GuideCar, {0,(game.tick-properties.LaunchTick)*((game.tick-properties.LaunchTick)-properties.AirTime)/500})
			rendering.set_orientation(properties.MaskID, 0.25)
			rendering.set_target(properties.ShadowID, properties.GuideCar, {-((game.tick-properties.LaunchTick)^2-(game.tick-properties.LaunchTick)*properties.AirTime)/500,0})
			-- rendering.set_target(properties.TrainImageID, properties.GuideCar, {0,(game.tick-properties.LaunchTick)*((game.tick-properties.LaunchTick)-properties.AirTime)/500})
			-- rendering.set_orientation(properties.TrainImageID, 0.1*( (2*(game.tick-properties.LaunchTick)/properties.AirTime-1)^23 - (2*(game.tick-properties.LaunchTick)/properties.AirTime-1) ))
			-- rendering.set_target(properties.MaskID, properties.GuideCar, {0,(game.tick-properties.LaunchTick)*((game.tick-properties.LaunchTick)-properties.AirTime)/500})
			-- rendering.set_orientation(properties.MaskID, 0.1*( (2*(game.tick-properties.LaunchTick)/properties.AirTime-1)^23 - (2*(game.tick-properties.LaunchTick)/properties.AirTime-1) ))
			-- rendering.set_target(properties.ShadowID, properties.GuideCar, {-((game.tick-properties.LaunchTick)^2-(game.tick-properties.LaunchTick)*properties.AirTime)/500,0})
		elseif (properties.RampOrientation == 0.50) then -- going up
			rendering.set_target(properties.TrainImageID, properties.GuideCar, {0,((game.tick-properties.LaunchTick)^2-(game.tick-properties.LaunchTick)*properties.AirTime)/500})
			rendering.set_target(properties.MaskID, properties.GuideCar, {0,((game.tick-properties.LaunchTick)^2-(game.tick-properties.LaunchTick)*properties.AirTime)/500})
			rendering.set_target(properties.ShadowID, properties.GuideCar, {-((game.tick-properties.LaunchTick)^2-(game.tick-properties.LaunchTick)*properties.AirTime)/500,0})	
		elseif (properties.RampOrientation == 0.75) then -- going right
			rendering.set_target(properties.TrainImageID, properties.GuideCar, {0, properties.bridgeOffset})
			rendering.set_orientation(properties.TrainImageID, 0)
			rendering.set_target(properties.MaskID, properties.GuideCar, {0,properties.bridgeOffset})
			rendering.set_orientation(properties.MaskID, 0)
			rendering.set_target(properties.ShadowID, properties.GuideCar, {-properties.bridgeOffset,0})			
		end
	end
end)

script.on_event(defines.events.on_entity_damaged,
function(event)
if (event.entity.name == "RTTrainRamp" 
	and event.cause 
	and (event.cause.type == "locomotive" or event.cause.type == "cargo-wagon" or event.cause.type == "fluid-wagon" or event.cause.type == "artillery-wagon")
	and (math.abs(event.entity.orientation-event.cause.orientation) == 0.5 
		or math.abs(event.entity.orientation-event.cause.orientation) == 0
		)
	and (event.entity.orientation == 0 and event.entity.position.y-event.cause.position.y>0
		or event.entity.orientation == 0.25 and event.entity.position.x-event.cause.position.x<0
		or event.entity.orientation == 0.50 and event.entity.position.y-event.cause.position.y<0
		or event.entity.orientation == 0.75 and event.entity.position.x-event.cause.position.x>0
		)
	) then
	
	event.entity.health = 9999
	
	local SpookyGhost = event.entity.surface.create_entity
		({
			name = "RTPropCar",
			position = event.cause.position,
			force = event.cause.force
		})
	SpookyGhost.orientation = event.cause.orientation
	SpookyGhost.operable = false
  SpookyGhost.speed = 0.8*event.cause.speed
	
	base = event.cause.type
	mask = "NoMask"
	way = global.OrientationUnitComponents[event.cause.orientation].name
	if (event.cause.type == "locomotive") then
		mask = "locomotiveMask"..way
	--elseif (event.cause.type == "cargo-wagon") then
	--elseif (event.cause.type == "fluid-wagon") then
	--elseif (event.cause.type == "artillery-wagon") then
	end
	
	TrainImage = rendering.draw_sprite
		{
		sprite = "RT"..base..way, 
		target = SpookyGhost,
		surface = SpookyGhost.surface,
		x_scale = 0.5,
		y_scale = 0.5,
		render_layer = 145
		}
	Mask = rendering.draw_sprite
		{
		sprite = "RT"..mask, 
		tint = event.cause.color or {r = 234, g = 17, b = 0, a = 100},
		target = SpookyGhost,
		surface = SpookyGhost.surface,
		x_scale = 0.5,
		y_scale = 0.5,
		render_layer = 145
		}
	OwTheEdge = rendering.draw_sprite
		{
		sprite = "GenericShadow", 
		tint = {a = 90},
		target = SpookyGhost,
		surface = SpookyGhost.surface,
		orientation = event.cause.orientation,
		x_scale = 0.25,
		y_scale = 0.4,
		render_layer = 144
		}
	
	global.FlyingTrains[SpookyGhost.unit_number] = {}
	global.FlyingTrains[SpookyGhost.unit_number].GuideCar = SpookyGhost
	if (event.cause.get_driver() ~= nil) then
		global.FlyingTrains[SpookyGhost.unit_number].passenger = event.cause.get_driver().player.index
		SpookyGhost.set_passenger(event.cause.get_driver())	
	end
	global.FlyingTrains[SpookyGhost.unit_number].name = event.cause.name
	global.FlyingTrains[SpookyGhost.unit_number].type = event.cause.type
	global.FlyingTrains[SpookyGhost.unit_number].LaunchTick = game.tick
	
	global.FlyingTrains[SpookyGhost.unit_number].TrainImageID = TrainImage
	global.FlyingTrains[SpookyGhost.unit_number].MaskID = Mask
	global.FlyingTrains[SpookyGhost.unit_number].speed = event.cause.speed
	global.FlyingTrains[SpookyGhost.unit_number].SpecialName = event.cause.backer_name
	global.FlyingTrains[SpookyGhost.unit_number].color = event.cause.color or {r = 234, g = 17, b = 0, a = 100} 
	global.FlyingTrains[SpookyGhost.unit_number].orientation = event.cause.orientation
	global.FlyingTrains[SpookyGhost.unit_number].bridgeOffset = event.cause.position.y + 1.75 -- This magic number needs to be figured out properly
	global.FlyingTrains[SpookyGhost.unit_number].RampOrientation = event.entity.orientation
	global.FlyingTrains[SpookyGhost.unit_number].ShadowID = OwTheEdge
  global.FlyingTrains[SpookyGhost.unit_number].ManualMode = event.cause.train.manual_mode

  -- Find the out ramp of the bridge:
  -- TODO super hacky atm - Need to assure this is the right signal and not itself, or another elsewhere!
  local bridgeDownRamp = SpookyGhost.surface.find_entities_filtered
		{
      area = 
      {
        {event.cause.position.x+5,event.cause.position.y-5}, -- TODO take into account orientation
				{event.cause.position.x+60,event.cause.position.y+5}
      },
      type = {"rail-signal"},
      limit = 1
    }[1]
  global.FlyingTrains[SpookyGhost.unit_number].bridgeDownRamp = bridgeDownRamp

  local dist = bridgeDownRamp.position.x - event.entity.position.x
  global.FlyingTrains[SpookyGhost.unit_number].bridgDist = dist

  global.FlyingTrains[SpookyGhost.unit_number].LandTick = GetLandTick(event.cause.speed, dist)
  global.FlyingTrains[SpookyGhost.unit_number].AirTime = global.FlyingTrains[SpookyGhost.unit_number].LandTick - global.FlyingTrains[SpookyGhost.unit_number].LaunchTick
  
  --- TODO: This searchbox looks like it could be better replaced by asking the API for "rolling stock" 
	if (event.entity.orientation == 0) then --ramp down
		SearchBox = 
			{
				{event.cause.position.x-1,event.cause.position.y-6},
				{event.cause.position.x+1,event.cause.position.y-4}
			}
	elseif (event.entity.orientation == 0.25) then -- ramp left
		SearchBox = 
			{
				{event.cause.position.x+4,event.cause.position.y-1},
				{event.cause.position.x+6,event.cause.position.y+1}
			}
	elseif (event.entity.orientation == 0.50) then -- ramp up
		SearchBox = 
			{
				{event.cause.position.x-1,event.cause.position.y+4},
				{event.cause.position.x+1,event.cause.position.y+6}
			}
	elseif (event.entity.orientation == 0.75) then -- ramp right
		SearchBox = 
			{
				{event.cause.position.x-6,event.cause.position.y-1},
				{event.cause.position.x-4,event.cause.position.y+1}
			}
	end
	global.FlyingTrains[SpookyGhost.unit_number].follower = SpookyGhost.surface.find_entities_filtered
		{
		area = SearchBox,
		type = {"locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon"},
		limit = 1
		}[1]
		
	-- if (global.FlyingTrains[SpookyGhost.unit_number].follower ~= nil) then
	-- rendering.draw_circle
		-- {
		-- color = {r = 234, g = 17, b = 0, a = 100},
		-- radius = 1,
		-- filled = true,
		-- target = global.FlyingTrains[SpookyGhost.unit_number].follower,
		-- surface = SpookyGhost.surface
		-- }
	-- end
		
	global.FlyingTrains[SpookyGhost.unit_number].schedule = event.cause.train.schedule
	if (global.FlyingTrains[SpookyGhost.unit_number].schedule ~= nil) then
		if (global.FlyingTrains[SpookyGhost.unit_number].schedule.current == table_size(global.FlyingTrains[SpookyGhost.unit_number].schedule.records)) then
		global.FlyingTrains[SpookyGhost.unit_number].schedule.current = 1
		else
		global.FlyingTrains[SpookyGhost.unit_number].schedule.current = global.FlyingTrains[SpookyGhost.unit_number].schedule.current+1
		end
	end
	
	for number, properties in pairs(global.FlyingTrains) do
		if (properties.follower and properties.follower.valid and event.cause.unit_number == properties.follower.unit_number) then
			global.FlyingTrains[SpookyGhost.unit_number].leader = number
			global.FlyingTrains[SpookyGhost.unit_number].schedule = global.FlyingTrains[number].schedule
			global.FlyingTrains[SpookyGhost.unit_number].ManualMode = global.FlyingTrains[number].ManualMode
			--global.FlyingTrains[SpookyGhost.unit_number].LandTick = math.ceil(game.tick + 130*math.abs(global.FlyingTrains[number].speed))
			global.FlyingTrains[SpookyGhost.unit_number].LandTick = GetLandTick(global.FlyingTrains[number].speed, dist)
			global.FlyingTrains[SpookyGhost.unit_number].AirTime = global.FlyingTrains[number].AirTime
			if (global.FlyingTrains[SpookyGhost.unit_number].speed>0) then
				SpookyGhost.speed = 0.8*math.abs(global.FlyingTrains[number].speed)
				global.FlyingTrains[SpookyGhost.unit_number].speed = math.abs(global.FlyingTrains[number].speed)
			else
				SpookyGhost.speed = -0.8*math.abs(global.FlyingTrains[number].speed)
				global.FlyingTrains[SpookyGhost.unit_number].speed = -math.abs(global.FlyingTrains[number].speed)
			end
		end
	end	
	
	if (event.cause.type == "locomotive" and event.cause.burner) then
		global.FlyingTrains[SpookyGhost.unit_number].CurrentlyBurning = event.cause.burner.currently_burning
		global.FlyingTrains[SpookyGhost.unit_number].RemainingFuel = event.cause.burner.remaining_burning_fuel
		global.FlyingTrains[SpookyGhost.unit_number].FuelInventory = event.cause.get_fuel_inventory().get_contents()
	elseif (event.cause.type == "cargo-wagon") then
		global.FlyingTrains[SpookyGhost.unit_number].cargo = event.cause.get_inventory(defines.inventory.cargo_wagon).get_contents()
		global.FlyingTrains[SpookyGhost.unit_number].bar = event.cause.get_inventory(defines.inventory.cargo_wagon).get_bar()
		global.FlyingTrains[SpookyGhost.unit_number].filter = {}
		for i = 1, #event.cause.get_inventory(defines.inventory.cargo_wagon) do
			global.FlyingTrains[SpookyGhost.unit_number].filter[i] = event.cause.get_inventory(defines.inventory.cargo_wagon).get_filter(i)
		end
	elseif (event.cause.type == "fluid-wagon") then
		global.FlyingTrains[SpookyGhost.unit_number].fluids = event.cause.get_fluid_contents()
	elseif (event.cause.type == "artillery-wagon") then
		global.FlyingTrains[SpookyGhost.unit_number].artillery = event.cause.get_inventory(defines.inventory.artillery_wagon_ammo).get_contents()
	end
	
	event.cause.destroy()
end


end)

function GetLandTick(trainSpeed, dist)
  local speedKmh = 130*math.abs(trainSpeed) -- TODO Where does this 130 come from? Something here isn't accurate
  local speedMps = speedKmh * 0.2777777778 
  local distOverTime = dist/speedMps
  local tickPerSec = 60
  return math.ceil(game.tick + (distOverTime*tickPerSec))
end