--00Fant
-- To Much Changed...
-- Vacuum.lua --
dofile( "$CONTENT_61d4b3e3-c5f7-454c-87fb-7a0fff5d91d0/Scripts/partUUIDs.lua" )

dofile( "$SURVIVAL_DATA/Scripts/game/util/Curve.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/util/pipes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_loot.lua" )

Vacuum = class()
Vacuum.poseWeightCount = 1
Vacuum.connectionInput = sm.interactable.connectionType.logic
Vacuum.maxParentCount = 256
Vacuum.maxChildCount = 0	
Vacuum.fireDelay = 25 -- ticks
 
-- 00Fant version 2.2
Vacuum.LootFirePower = 5
Vacuum.HarvestAreaSize = 0.5 --DEFAULT IS 0.5


DestroyList = {}

local VacuumMode = { outgoing = 1, incoming = 2 }

local UuidToProjectile = {

	[tostring(obj_consumable_water)] = { uuid = projectile_water },
	[tostring(obj_consumable_fertilizer)] = { uuid = projectile_fertilizer },
	[tostring(obj_consumable_chemical)] = { uuid = projectile_chemical },

	[tostring(obj_plantables_banana)] = { uuid = projectile_banana },
	[tostring(obj_plantables_blueberry)] = { uuid = projectile_blueberry },
	[tostring(obj_plantables_orange)] = { uuid = projectile_orange },
	[tostring(obj_plantables_pineapple)] = { uuid = projectile_pineapple },
	[tostring(obj_plantables_carrot)] = { uuid = projectile_carrot },
	[tostring(obj_plantables_redbeet)] = { uuid = projectile_redbeet },
	[tostring(obj_plantables_tomato)] = { uuid = projectile_tomato },
	[tostring(obj_plantables_broccoli)] = { uuid = projectile_broccoli },
	[tostring(obj_plantables_potato)] = { uuid = projectile_potato },
	
	[tostring(obj_plantables_eggplant)] = { uuid = projectile_fant_eggplant },

	[tostring(obj_seed_banana)] = { uuid = projectile_seed, hvs = hvs_growing_banana },
	[tostring(obj_seed_blueberry)] = { uuid = projectile_seed, hvs = hvs_growing_blueberry },
	[tostring(obj_seed_orange)] = { uuid = projectile_seed, hvs = hvs_growing_orange },
	[tostring(obj_seed_pineapple)] = { uuid = projectile_seed, hvs = hvs_growing_pineapple },
	[tostring(obj_seed_carrot)] = { uuid = projectile_seed, hvs = hvs_growing_carrot },
	[tostring(obj_seed_potato)] = { uuid = projectile_seed, hvs = hvs_growing_potato },
	[tostring(obj_seed_redbeet)] = { uuid = projectile_seed, hvs = hvs_growing_redbeet },
	[tostring(obj_seed_tomato)] = { uuid = projectile_seed, hvs = hvs_growing_tomato },
	[tostring(obj_seed_broccoli)] = { uuid = projectile_seed, hvs = hvs_growing_broccoli },
	[tostring(obj_seed_cotton)] = { uuid = projectile_seed, hvs = hvs_growing_cotton },
	
	[tostring(obj_seed_eggplant)] = { uuid = projectile_seed, hvs = hvs_growing_eggplant },
}


Vacuum.UUIDRestrictions = {
	fant_beebot,
	fant_straw_dog,
	fant_straw_dog_body,
	fant_straw_dog_eye, 
	fant_straw_dog_head,
	fant_straw_dog_jaw,
	fant_straw_dog_left_feet,
	fant_straw_dog_left_leg,
	fant_straw_dog_right_feet,
	fant_straw_dog_right_leg,
	fant_straw_dog_tail,
	-- obj_crates_banana,
	-- obj_crates_blueberry,
	-- obj_crates_orange,
	-- obj_crates_pineapple,
	-- obj_crates_carrot,
	-- obj_crates_redbeet,
	-- obj_crates_tomato,
	-- obj_crates_broccoli,
	--obj_survivalobject_farmerball,
	obj_robotparts_tapebothead01,
	obj_robotparts_tapebottorso01,
	obj_robotparts_tapebotleftarm01,
	obj_robotparts_tapebotshooter,
	obj_robotparts_haybothead,
	obj_robotparts_haybotbody,
	obj_robotparts_haybotpelvis,
	obj_robotparts_haybotfork,
	obj_robotparts_farmbotpart_head,
	obj_robotparts_farmbotpart_cannonarm,
	obj_robotparts_farmbotpart_drill,
	obj_robotparts_farmbotpart_scytharm,
	obj_robotpart_totebotbody,
	obj_robotpart_totebotleg,
	obj_harvests_stones_p01,
	obj_harvests_stones_p02,
	obj_harvests_stones_p03,
	obj_harvests_stones_p04,
	obj_harvests_stones_p05,
	obj_harvests_stones_p06,
	obj_harvest_stonechunk01,
	obj_harvest_stonechunk02,
	obj_harvest_stonechunk03,
	obj_survivalobject_keycard,
	obj_survivalobject_cardreader,
	obj_survivalobject_cardreader_arm,
	obj_packingstation_front,
	obj_packingstation_mid,
	obj_packingstation_crateload,
	obj_packingstation_screen_fruit,
	obj_packingstation_screen_veggie,
	obj_survivalobject_elevatorfloor,
	obj_survivalobject_elevatorbutton,
	obj_survivalobject_elevatorcallbutton,
	obj_survivalobject_elevatordoor_left,
	obj_survivalobject_bananabox,
	obj_survivalobject_elevatorlamp,
	obj_survivalobject_elevatorwallleft,
	obj_survivalobject_elevatorwallright,
	obj_survivalobject_elevatorfan,
	obj_survivalobject_elevatorceiling,
	obj_survivalobject_workbench,
	obj_survivalobject_capsuledoor,
	obj_survivalobject_powercoresocket,
	obj_survivalobject_powercore,
	obj_survivalobject_dispenserbot,
	obj_survivalobject_dispenserbot_spawner,
	obj_survivalobject_terminal,
	obj_hideout_questgiver,
	obj_hideout_button,
	obj_hideout_dropoff,
	obj_survivalobject_kobag,
	obj_survivalobject_ruinchest,
	obj_harvest_log_s01,
	obj_harvest_log_m01,
	obj_harvest_log_l01,
	obj_harvest_log_l02a,
	obj_harvest_log_l02b,
	obj_harvests_trees_spruce02_p00,
	obj_harvests_trees_spruce02_p01,
	obj_harvests_trees_spruce02_p02,
	obj_harvests_trees_spruce02_p03,
	obj_harvests_trees_spruce02_p04,
	obj_harvests_trees_spruce01_p05,
	obj_harvests_trees_spruce02_p05,
	obj_harvests_trees_spruce03_p05,
	obj_harvests_trees_leafy01_p00,
	obj_harvests_trees_leafy01_p01,
	obj_harvests_trees_leafy01_p02,
	obj_harvests_trees_leafy01_p03,
	obj_harvests_trees_leafy01_p04,
	obj_harvests_trees_leafy02_p00,
	obj_harvests_trees_leafy02_p01,
	obj_harvests_trees_leafy02_p02,
	obj_harvests_trees_leafy02_p03,
	obj_harvests_trees_leafy02_p04,
	obj_harvests_trees_leafy02_p05,
	obj_harvests_trees_leafy02_p06,
	obj_harvests_trees_leafy02_p07,
	obj_harvests_trees_leafy03_p00,
	obj_harvests_trees_leafy03_p01,
	obj_harvests_trees_leafy03_p02,
	obj_harvests_trees_leafy03_p03,
	obj_harvests_trees_leafy03_p04,
	obj_harvests_trees_leafy03_p05,
	obj_harvests_trees_leafy03_p06,
	obj_harvests_trees_leafy03_p07,
	obj_harvests_trees_leafy03_p08,
	obj_harvests_trees_leafy03_p09,
	obj_harvests_trees_birch01_p00,
	obj_harvests_trees_birch01_p01,
	obj_harvests_trees_birch01_p02,
	obj_harvests_trees_birch01_p03,
	obj_harvests_trees_birch01_p04,
	obj_harvests_trees_birch01_p05,
	obj_harvests_trees_birch02_p00,
	obj_harvests_trees_birch02_p01,
	obj_harvests_trees_birch02_p02,
	obj_harvests_trees_birch02_p03,
	obj_harvests_trees_birch02_p04,
	obj_harvests_trees_birch02_p05,
	obj_harvests_trees_birch02_p06,
	obj_harvests_trees_birch03_p00,
	obj_harvests_trees_birch03_p01,
	obj_harvests_trees_birch03_p02,
	obj_harvests_trees_birch03_p03,
	obj_harvests_trees_birch03_p04,
	obj_harvests_trees_birch03_p05,
	obj_harvests_trees_birch03_p06,
	obj_harvests_trees_pine01_p00,
	obj_harvests_trees_pine01_p01,
	obj_harvests_trees_pine01_p02,
	obj_harvests_trees_pine01_p03,
	obj_harvests_trees_pine01_p04,
	obj_harvests_trees_pine01_p05,
	obj_harvests_trees_pine01_p06,
	obj_harvests_trees_pine01_p07,
	obj_harvests_trees_pine01_p08,
	obj_harvests_trees_pine01_p09,
	obj_harvests_trees_pine01_p10,
	obj_harvests_trees_pine01_p11,
	obj_harvests_trees_pine02_p00,
	obj_harvests_trees_pine02_p01,
	obj_harvests_trees_pine02_p02,
	obj_harvests_trees_pine02_p03,
	obj_harvests_trees_pine02_p04,
	obj_harvests_trees_pine02_p05,
	obj_harvests_trees_pine02_p06,
	obj_harvests_trees_pine02_p07,
	obj_harvests_trees_pine02_p08,
	obj_harvests_trees_pine02_p09,
	obj_harvests_trees_pine02_p10,
	obj_harvests_trees_pine03_p00,
	obj_harvests_trees_pine03_p01,
	obj_harvests_trees_pine03_p02,
	obj_harvests_trees_pine03_p03,
	obj_harvests_trees_pine03_p04,
	obj_harvests_trees_pine03_p05,
	obj_harvests_trees_pine03_p06,
	obj_harvests_trees_pine03_p07,
	obj_harvests_trees_pine03_p08,
	obj_harvests_trees_pine03_p09,
	obj_harvests_trees_pine03_p10,
	sm.uuid.new( "a84712d0-436f-4408-b56e-6a626ad72d9c" ),
	sm.uuid.new( "66ad6dcd-5927-461e-96db-619ae0f2a715" )
}

local partCrates = {
	obj_crates_banana,
	obj_crates_blueberry,
	obj_crates_orange,
	obj_crates_pineapple,
	obj_crates_carrot,
	obj_crates_redbeet,
	obj_crates_tomato,
	obj_crates_broccoli,
	obj_survivalobject_farmerball
}

function Vacuum.server_onCreate( self )
	self.sv = {}

	-- client table goes to client
	self.sv.client = {}
	self.sv.client.pipeNetwork = {}
	self.sv.client.state = PipeState.off
	self.sv.client.showBlockVisualization = false

	-- storage table goes to storage
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { mode = VacuumMode.outgoing, filterItems = {}, antifilter = false } -- Default value
		self.storage:save( self.sv.storage )
	end
	self.antifilter = self.sv.storage.antifilter
	self.filterItems = self.sv.storage.filterItems
	self.filtercontainer = self.shape:getInteractable():getContainer(1)
	if not self.filtercontainer then
		self.filtercontainer = self.shape:getInteractable():addContainer( 1, 20, 1 )
	end
	if self.filterItems ~= nil then
		sm.container.beginTransaction()		
		for i, k in pairs( self.filterItems ) do			
			sm.container.setItem( self.filtercontainer, i - 1, k, 1 )
		end
		sm.container.endTransaction()
		
	end	
	self.network:sendToClients( "cl_setantifilter", self.antifilter )
	
	self.sv.dirtyClientTable = false
	self.sv.dirtyStorageTable = false

	self.sv.fireDelayProgress = 0
	self.sv.canFire = true
	self.sv.ChestCollectTimer = 0
	self.sv.ChestCollectItemIndex = 0
	self.sv.areaTrigger = nil
	self.sv.connectedContainers = {}
	self.sv.foundContainer = nil
	self.sv.foundItem = sm.uuid.getNil()
	self.sv.parentActive = false
	self:sv_buildPipeNetwork()
	self:sv_updateStates()
	self.last_setVacuumStateOnAllShapes = nil
	-- public data used to interface with the packing station
	self.interactable:setPublicData( { packingStationTick = 0 } )
	
	self.sv.startDelay = 4
	
	self.onLoadTimer = 1
end



function Vacuum.server_onRefresh( self )
	self:uuidAddCheck()
end

function Vacuum.uuidAddCheck( self )
	local ModContainerUUID = {
		obj_interactive_fant_chest,
		obj_interactive_fant_large_container,
		obj_interactive_fant_teleport_pipe_in,
		obj_interactive_fant_teleport_pipe_out,
		obj_interactive_fant_pumpjack_out,
		obj_interactive_fant_trashcan,
		obj_interactive_fant_recycler,
		obj_interactive_fant_thin_chest,
	}
	for a, a_uuid in pairs( ModContainerUUID ) do
		local add = true
		for b, b_uuid in pairs( ContainerUuids ) do
			if a_uuid == b_uuid then
				add = false
				break
			end
		end
		if add then
			ContainerUuids[#ContainerUuids + 1] = a_uuid
		end
	end
	
	local ModPipeUUID = {
		obj_interactive_mcp,
		obj_interactive_mcp2,
		obj_interactive_mcp3
	}
	for a, a_uuid in pairs( ModPipeUUID ) do
		local add = true
		for b, b_uuid in pairs( PipeUuids ) do
			if a_uuid == b_uuid then
				add = false
				break
			end
		end
		if add then
			PipeUuids[#PipeUuids + 1] = a_uuid
		end
	end
end

function Vacuum.sv_markClientTableAsDirty( self )
	self.sv.dirtyClientTable = true
end

function Vacuum.sv_markStorageTableAsDirty( self )
	self.sv.dirtyStorageTable = true
	self:sv_markClientTableAsDirty()
end

function Vacuum.sv_n_toogle( self )
	if self.sv.storage.mode == VacuumMode.outgoing then
		self:server_outgoingReset()
		self.sv.storage.mode = VacuumMode.incoming
	else
		self.sv.storage.mode = VacuumMode.outgoing
	end

	self:sv_updateStates()
	self:sv_markStorageTableAsDirty()
end

function Vacuum.sv_updateStates( self )

	if self.sv.storage.mode == VacuumMode.incoming then
		if not self.sv.areaTrigger then
			local size = sm.vec3.new( self.HarvestAreaSize, self.HarvestAreaSize, self.HarvestAreaSize )		
			-- 00Fant start
			
			--local filter = sm.areaTrigger.filter.staticBody + sm.areaTrigger.filter.dynamicBody + sm.areaTrigger.filter.areaTrigger + sm.areaTrigger.filter.harvestable
			local filter = sm.areaTrigger.filter.all

			-- 00Fant end
			self.sv.areaTrigger = sm.areaTrigger.createAttachedBox( self.interactable, size, sm.vec3.new(0.0, -1.0, 0.0), sm.quat.identity(), filter )			
			self.sv.areaTrigger:bindOnProjectile( "trigger_onProjectile", self )
		end
	else
		if self.sv.areaTrigger then
			sm.areaTrigger.destroy( self.sv.areaTrigger )
			self.sv.areaTrigger = nil
		end
	end
end

function Vacuum.sv_buildPipeNetwork( self )

	self.sv.client.pipeNetwork = {}
	self.sv.connectedContainers = {}

	local function fnOnVertex( vertex )

		if isAnyOf( vertex.shape:getShapeUuid(), ContainerUuids ) then -- Is Container
			assert( vertex.shape:getInteractable():getContainer() )
			local container = {
				shape = vertex.shape,
				distance = vertex.distance,
				shapesOnContainerPath = vertex.shapesOnPath
			}

			table.insert( self.sv.connectedContainers, container )
		elseif isAnyOf( vertex.shape:getShapeUuid(), PipeUuids ) then -- Is Pipe
			assert( vertex.shape:getInteractable() )
			local pipe = {
				shape = vertex.shape,
				state = PipeState.off
			}

			table.insert( self.sv.client.pipeNetwork, pipe )
		end

		return true
	end

	ConstructPipedShapeGraph( self.shape, fnOnVertex )

	-- Sort container by closests
	table.sort( self.sv.connectedContainers, function(a, b) return a.distance < b.distance end )

	-- Synch the pipe network and initial state to clients
	local state = PipeState.off

	for _, container in ipairs( self.sv.connectedContainers ) do
		for _, shape in ipairs( container.shapesOnContainerPath ) do
			for _, pipe in ipairs( self.sv.client.pipeNetwork ) do
				if pipe.shape:getId() == shape:getId() then
					pipe.state = PipeState.connected
				end
			end
		end
	end

	self.sv.client.state = state
	self:sv_markClientTableAsDirty()
end

function Vacuum.constructionRayCast( self )
	local start = self.shape:getWorldPosition()
	local stop = self.shape:getWorldPosition() - self.shape.at * 4.625
	local valid, result = sm.physics.raycast( start, stop, self.shape )
	if valid then
		local groundPointOffset = -( sm.construction.constants.subdivideRatio_2 - 0.04 + sm.construction.constants.shapeSpacing + 0.005 )
		local pointLocal = result.pointLocal
		if result.type ~= "body" and result.type ~= "joint" then
			pointLocal = pointLocal + result.normalLocal * groundPointOffset
		end

		local n = sm.vec3.closestAxis( result.normalLocal )
		local a = pointLocal * sm.construction.constants.subdivisions - n * 0.5
		local gridPos = sm.vec3.new( math.floor( a.x ), math.floor( a.y ), math.floor( a.z ) ) + n

		local function getTypeData()
			local shapeOffset = sm.vec3.new( sm.construction.constants.subdivideRatio_2, sm.construction.constants.subdivideRatio_2, sm.construction.constants.subdivideRatio_2 )
			local localPos = gridPos * sm.construction.constants.subdivideRatio + shapeOffset
			if result.type == "body" then
				local shape = result:getShape()
				if shape and sm.exists( shape ) then
					return shape:getBody():transformPoint( localPos ), shape
				else
					valid = false
				end
			elseif result.type == "joint" then
				local joint = result:getJoint()
				if joint and sm.exists( joint ) then
					return joint:getShapeA():getBody():transformPoint( localPos ), joint
				else
					valid = false
				end
			elseif result.type == "lift" then
				local lift, topShape = result:getLiftData()
				if lift and ( not topShape or lift:hasBodies() ) then
					valid = false
				end
				return localPos, lift
			end
			return localPos
		end

		local worldPos, obj = getTypeData()
		return valid, gridPos, result.normalLocal, worldPos, obj
	end
	return valid
end

function Vacuum.server_outgoingReload( self, container, item )
	self.sv.foundContainer, self.sv.foundItem = container, item

	local isBlock = sm.item.isBlock( self.sv.foundItem )
	if self.sv.client.showBlockVisualization ~= isBlock then
		self.sv.client.showBlockVisualization = isBlock
		self:sv_markClientTableAsDirty()
	end

	if self.sv.canFire then
		self.sv.fireDelayProgress = Vacuum.fireDelay
		self.sv.canFire = false
	end

	if self.sv.foundContainer then
		self.network:sendToClients( "cl_n_onOutgoingReload", { shapesOnContainerPath = self.sv.foundContainer.shapesOnContainerPath, item = self.sv.foundItem } )
	end
end

function Vacuum.server_outgoingReset( self )
	self.sv.canFire = false
	self.sv.foundContainer = nil
	self.sv.foundItem = sm.uuid.getNil()

	if self.sv.client.showBlockVisualization then
		self.sv.client.showBlockVisualization = false
		self:sv_markClientTableAsDirty()
	end
end

function Vacuum.server_outgoingLoaded( self )
	return self.sv.foundContainer and self.sv.foundItem ~= sm.uuid.getNil()
end

function Vacuum.server_outgoingShouldReload( self, container, item )
	return self.sv.foundItem ~= item
end

function Vacuum.getInputs( self )
	local ActiveButtonInputParent = false
	local ArrowSwitchInputParent = false
	local pumpControler = nil
	for index, parent in pairs( sm.interactable.getParents( self.shape:getInteractable() ) ) do
		if sm.interactable.getShape( parent ).uuid == obj_interactive_fant_vacuumpump_controler then
			if sm.interactable.getShape( parent ).interactable then
				local pumpControler_publicData = sm.interactable.getShape( parent ).interactable:getPublicData()
				if pumpControler_publicData then
					if pumpControler_publicData.active then
						pumpControler = sm.interactable.getShape( parent ).interactable
					end
				end
			end
		else
			if tostring( sm.shape.getColor( sm.interactable.getShape( parent ) ) ) == "d02525ff" then  --Red
				ArrowSwitchInputParent = parent.active
			else
				ActiveButtonInputParent = parent.active
			end
		end
	end
	return ActiveButtonInputParent, ArrowSwitchInputParent, pumpControler
end

function Vacuum.getLocalBlockGridPosition( self, pos )
	local size = sm.vec3.new( 3, 3, 1 )
	local size_2 = sm.vec3.new( 1, 1, 0 )
	local a = pos * sm.construction.constants.subdivisions
	local gridPos = sm.vec3.new( math.floor( a.x ), math.floor( a.y ), a.z ) - size_2
	return gridPos * sm.construction.constants.subdivideRatio + ( size * sm.construction.constants.subdivideRatio ) * 0.5
end

function Vacuum.server_onFixedUpdate( self, dt )
	--self:sv_refreshFilter()
	if self.onLoadTimer > 0 then
		self.onLoadTimer = self.onLoadTimer - dt
		if self.onLoadTimer <= 0 then
			self:sv_buildPipeNetwork()
		end
	end
	if self.sv.startDelay > 0 then
		self.sv.startDelay = self.sv.startDelay  - (1/40)
		return
	end
	DestroyListLoop(self)
	
	local function setVacuumState( state, shapes )
		if self.sv.client.state ~= state then
			self.sv.client.state = state
			self:sv_markClientTableAsDirty()
		end

		for _, obj in ipairs( self.sv.client.pipeNetwork ) do
			for _, shape in ipairs( shapes ) do
				if obj.shape:getId() == shape:getId() then
					if obj.state ~= state then
						obj.state = state
						self:sv_markClientTableAsDirty()
					end
				end
			end
		end
	end

	local function setVacuumStateOnAllShapes( state )
		if self.sv.client.state ~= state then
			self.sv.client.state = state
			self:sv_markClientTableAsDirty()
		end

		for _, container in ipairs( self.sv.connectedContainers ) do
			for _, shape in ipairs( container.shapesOnContainerPath ) do
				for _, pipe in ipairs( self.sv.client.pipeNetwork ) do
					if pipe.shape:getId() == shape:getId() then
						pipe.state = state
						self:sv_markClientTableAsDirty()
					end
				end
			end
		end

	end

	-- Update fire delay progress
	if not self.sv.canFire then
		self.sv.fireDelayProgress = self.sv.fireDelayProgress - 1
		if self.sv.fireDelayProgress <= 0 then
			self.sv.fireDelayProgress = Vacuum.fireDelay
			self.sv.canFire = true
		end
	end

	
	
	-- Optimize this either through a simple has changed that only checks the body and not shapes
	-- Or let the body check and fire an event whenever it detects a change
	-- if  self.shape:getBody():hasChanged( sm.game.getCurrentTick() - 1 ) then
		-- self:sv_buildPipeNetwork()
	-- end
	

	if self.sv.ChestCollectTimer == nil then
		self.sv.ChestCollectTimer = 0
	end
	if self.sv.ChestCollectTimer > 0 then
		self.sv.ChestCollectTimer = self.sv.ChestCollectTimer - 1
		--print( self.sv.ChestCollectTimer )
	end
	
	
	
	local isPumpActive, arrowSwitchActive, pumpControler = self:getInputs() --sm.interactable.getParents( self.shape:getInteractable() )

	if pumpControler then
		local pumpControlerInventory = pumpControler:getContainer( 0 )
		local pumpControler_publicData = pumpControler:getPublicData()
		if pumpControler_publicData then
			if pumpControler_publicData.active then
				isPumpActive = pumpControler_publicData.active
				arrowSwitchActive = pumpControler_publicData.switch
				self.filtercontainer = pumpControlerInventory
			else
				self.filtercontainer = self.shape:getInteractable():getContainer(1)
			end
		end
	else
		self.filtercontainer = self.shape:getInteractable():getContainer(1)
	end
	
	
	if self.LastarrowSwitchparent == nil then
		self.LastarrowSwitchparent = false
	end
	if self.LastarrowSwitchparent ~= arrowSwitchActive then
		self.LastarrowSwitchparent = arrowSwitchActive
		
		if arrowSwitchActive then
			self:server_outgoingReset()
			self.sv.storage.mode = VacuumMode.incoming
		else
			self.sv.storage.mode = VacuumMode.outgoing
		end

		self:sv_updateStates()
		self:sv_markStorageTableAsDirty()
				
	end
	
	if self.lastChangedPipPipeNetwork == nil then
		self.lastChangedPipPipeNetwork = 0
	end
	if self.shape:getBody():hasChanged( sm.game.getCurrentTick() - 1 ) then
		if self.lastChangedPipPipeNetwork <= 0 then
			self.sv.ChangedPipPipeNetwork = true
		end
	end
	if self.lastChangedPipPipeNetwork >= 0 then
		self.lastChangedPipPipeNetwork = self.lastChangedPipPipeNetwork - 0.08
		if self.lastChangedPipPipeNetwork <= 0 then
			self.lastChangedPipPipeNetwork = 0
		end
	end	
	
	if isPumpActive then
		if self.sv.ChangedPipPipeNetwork then
			self:sv_buildPipeNetwork()
			self.sv.ChangedPipPipeNetwork = false
			self.lastChangedPipPipeNetwork = 1
		end
	end
	
	
	local AntiFilter = self.antifilter
	
	if self.sv.storage.mode == VacuumMode.outgoing and #self.sv.connectedContainers > 0 then
		local publicData = self.interactable:getPublicData()
		assert(publicData)
		local interfacingWithPackingStation = sm.game.getCurrentTick() - 4 < publicData.packingStationTick

		--local parent = parents --self.shape:getInteractable():getSingleParent()
		--if parent then
			if isPumpActive and not self.sv.parentActive and self.sv.canFire then
				if interfacingWithPackingStation then
					assert( publicData.packingStationProjectileUuid )
					local function findItemUidFromProjectileUuid()
						for uid, projectile in pairs( UuidToProjectile ) do
							if projectile.uuid == publicData.packingStationProjectileUuid then
								return sm.uuid.new( uid );
							end
						end
						return sm.uuid.getNil()
					end

					local itemUid = findItemUidFromProjectileUuid()
					assert( itemUid )					
					local function findContainerAndItemWithUid()
						for _, container in ipairs( self.sv.connectedContainers ) do
							if sm.exists( container.shape ) then
								if not container.shape:getInteractable():getContainer():isEmpty() then
									if sm.container.canSpend( container.shape:getInteractable():getContainer(), itemUid, 1 ) then
										return container, itemUid
									end
								end
							end
						end
						return nil, sm.uuid.getNil()
					end

					local container, item = findContainerAndItemWithUid()
					if item == itemUid then
						if self:server_outgoingShouldReload( container, item ) then
							self:server_outgoingReload( container, item )
						end
						publicData.requestExternalOpen = true
						setVacuumState( PipeState.valid, self.sv.connectedContainers[1].shapesOnContainerPath )
					else
						publicData.requestExternalOpen = false
						setVacuumState( PipeState.invalid, self.sv.connectedContainers[1].shapesOnContainerPath )
					end

				else
					if publicData.requestExternalOpen then
						self:server_outgoingReset()
					end
					publicData.requestExternalOpen = false
					setVacuumState( PipeState.connected, self.sv.connectedContainers[1].shapesOnContainerPath )
				end


				

				if not interfacingWithPackingStation then
					local function findFirstContainerAndItem()
						for _, container in ipairs( self.sv.connectedContainers ) do
							if sm.exists( container.shape ) then
								if not container.shape:getInteractable():getContainer():isEmpty() then
									for slot = 0, container.shape:getInteractable():getContainer():getSize() - 1 do
										local item = container.shape:getInteractable():getContainer():getItem( slot )
										local foundItem = false
										
										if item.uuid ~= tool_gatling and item.uuid ~= tool_shotgun and item.uuid ~= tool_spudgun and item.uuid ~= tool_spudgun_creative and item.uuid ~= tool_weld and item.uuid ~= tool_paint and item.uuid ~= tool_connect and item.uuid ~= tool_lift and item.uuid ~= tool_sledgehammer then
											if self.filtercontainer then
												if not self.filtercontainer:isEmpty() then
													for Filterslot = 0, self.filtercontainer:getSize() - 1 do
														local Filteritem = self.filtercontainer:getItem( Filterslot )											
														if Filteritem then
															if Filteritem.uuid == item.uuid then
																if Filteritem.quantity > 0 then
																	foundItem = true
																	break
																end
															end
														end
													end
												else
													foundItem = true
												end
											else
												foundItem = true
											end
											
											--print(tostring(foundItem) .. " - " .. tostring(AntiFilter).. " - " .. tostring(self.filtercontainer))
											
											if not self.filtercontainer then
												if UuidToProjectile[tostring(item.uuid)] or sm.item.isBlock( item.uuid ) then
													return container, item.uuid
												else									
													if item then
														if item.quantity > 0 then
															return container, item.uuid
														end
													end
												end												
											else
												if foundItem and not AntiFilter then
													if UuidToProjectile[tostring(item.uuid)] or sm.item.isBlock( item.uuid ) then
														return container, item.uuid
													else									
														if item then
															if item.quantity > 0 then
																return container, item.uuid
															end
														end
													end																																										
												elseif not foundItem and AntiFilter then
													if UuidToProjectile[tostring(item.uuid)] or sm.item.isBlock( item.uuid ) then
														return container, item.uuid
													else									
														if item then
															if item.quantity > 0 then
																return container, item.uuid
															end
														end
													end																																										
												end
											end
										end
									end
								end
							end
						end
						return nil, sm.uuid.getNil()
					end
					local container, item = findFirstContainerAndItem()
					if self:server_outgoingShouldReload( container, item ) then
						self:server_outgoingReload( container, item )
					end
				end

				local function isValidPlacement()
					local hit, gridPos, normalLocal, worldPos, obj = self:constructionRayCast()
					if sm.item.isBlock( self.sv.foundItem ) then						
						if hit then
							local function countTerrain()
								if type(obj) == "Shape" then
									return obj:getBody():isDynamic()
								end
								return false
							end
							return sm.physics.sphereContactCount( worldPos, 0.125, countTerrain() ) == 0 and
							sm.construction.validateLocalPosition( self.sv.foundItem, gridPos, normalLocal, obj ), gridPos, obj, false
						end
					else
						for i, crateUUID in pairs( partCrates ) do
							if self.sv.foundItem == crateUUID then
								return true, gridPos, obj, false, worldPos
							end
						end
						return false, worldPos, obj, true
					end
				end
				local valid, gridPos, obj, drop, worldPos = isValidPlacement()
						
				
				
				--00Fant
				PumpMode = false	
				FindChestContainer = nil
				
				if obj then
					local FindChestStart = self.shape:getWorldPosition()
					local FindChestStop = self.shape:getWorldPosition() - self.shape.at * 5
					local FindChestValid, FindChestResult = sm.physics.raycast( FindChestStart, FindChestStop, self.shape )
					
					if FindChestValid and FindChestResult then
						if FindChestResult.type == "body" then
							FindChestShape = FindChestResult:getShape()
							if FindChestShape then
								if FindChestShape:getInteractable() then
									FindChestContainer = FindChestShape:getInteractable():getContainer()						
								end					
							end
						elseif FindChestResult.type == "shape" then
							if FindChestResult then
								if FindChestResult:getInteractable() then
									FindChestContainer = FindChestResult:getInteractable():getContainer()
								end
							end
						end								
					end
				end

							
				if FindChestContainer and self.sv.foundContainer then					
					sm.container.beginTransaction()
					sm.container.collect( FindChestContainer, self.sv.foundItem, 1, true)			
					if sm.container.endTransaction() then
						sm.container.beginTransaction()
						sm.container.spend( self.sv.foundContainer.shape:getInteractable():getContainer(), self.sv.foundItem, 1, true )
						if sm.container.endTransaction() then
							self.network:sendToClients( "cl_n_onOutgoingFire", { shapesOnContainerPath = self.sv.foundContainer.shapesOnContainerPath, withoutEffect = true } )
						end
						self:server_outgoingReset()
					end
				else
					
					PumpColor = sm.shape.getColor( self.shape )
					Pumprgb = math.floor( ( PumpColor.r + PumpColor.g + PumpColor.b ) * 10 ) / 10
					if Pumprgb == 2.8 then
						PumpMode = true
					else
						PumpMode = false
					end
					
					if PumpMode then
						if self.sv.foundItem ~= sm.uuid.getNil() then					
							sm.container.beginTransaction()
							sm.container.spend( self.sv.foundContainer.shape:getInteractable():getContainer(), self.sv.foundItem, 1, true )
							if sm.container.endTransaction() then										
								if self.sv.foundItem == obj_resource_corn then
									sm.shape.createPart( obj_resource_corn, self.shape.worldPosition + sm.shape.getAt( self.shape ) * -1, sm.quat.identity(), true, true ) 
								elseif self.sv.foundItem == obj_consumable_fant_popcorn then
									sm.shape.createPart( obj_consumable_fant_popcorn, self.shape.worldPosition + sm.shape.getAt( self.shape ) * -1, sm.quat.identity(), true, true ) 
								elseif self.sv.foundItem == obj_plantables_eggplant then
									sm.shape.createPart( obj_plantables_eggplant, self.shape.worldPosition + sm.shape.getAt( self.shape ) * -1, sm.quat.identity(), true, true ) 
								elseif self.sv.foundItem == obj_interactive_propanetank_small then
									part = sm.shape.createPart( obj_interactive_propanetank_small, self.shape.worldPosition + sm.shape.getAt( self.shape ) * -1, sm.quat.identity(), true, true ) 	
									--print( part )
									--sm.physics.applyImpulse( part, sm.vec3.new( 0, -2500, 0 ), false, nil )
									
								elseif self.sv.foundItem == obj_interactive_propanetank_large then
									part = sm.shape.createPart( obj_interactive_propanetank_large, self.shape.worldPosition + sm.shape.getAt( self.shape ) * -1, sm.quat.identity(), true, true ) 									
									--sm.physics.applyImpulse( part, sm.vec3.new( 0, -2500, 0 ), false, nil )
								else
									local projectileName = "loot"
									local params = { lootUid = self.sv.foundItem, lootQuantity = 1, epic = false }
									sm.projectile.shapeCustomProjectileAttack( params, projectileName, 0, sm.vec3.new( 0, 0, 0 ), sm.vec3.new( 0, -Vacuum.LootFirePower, 0 ), self.shape, 0 )			
									self.network:sendToClients( "cl_n_onOutgoingFire", { shapesOnContainerPath = self.sv.foundContainer.shapesOnContainerPath } )					
								end							
								self.network:sendToClients( "cl_n_onOutgoingFire", { shapesOnContainerPath = self.sv.foundContainer.shapesOnContainerPath } )									
							end		
							self:server_outgoingReset()
						else
							self.network:sendToClients( "cl_n_onError", { shapesOnContainerPath = self.sv.connectedContainers[1].shapesOnContainerPath } )
						end
					else
						if tostring( sm.shape.getColor( self.shape ) ) == "cf11d2ff" then
							
							local function findContainer()
								for _, container in ipairs( self.sv.connectedContainers ) do
									if sm.exists( container.shape ) then
										if not container.shape:getInteractable():getContainer():isEmpty() then
											if sm.container.canSpend( container.shape:getInteractable():getContainer(), obj_consumable_soilbag, 1 ) then
												return container
											end
										end
									end
								end
								return nil
							end

							local container = findContainer()
							
							local function GetSoilPosition( self )
								local start = self.shape:getWorldPosition()
								local stop = self.shape:getWorldPosition() - sm.shape.getAt( self.shape ) * 1.5
								local valid, result = sm.physics.raycast( start, stop, self.shape )
								if result.type == "terrainSurface" then
									return self:getLocalBlockGridPosition( result.pointWorld )
								else
									return nil
								end
							end
							local SoilPlacePosition = GetSoilPosition( self )
							if SoilPlacePosition and container then
								sm.container.beginTransaction()
								sm.container.spend( container.shape:getInteractable():getContainer(), obj_consumable_soilbag, 1, true )
								if sm.container.endTransaction() then	
									local rot = math.random( 0, 3 ) * math.pi * 0.5
									sm.harvestable.create( hvs_soil, SoilPlacePosition, sm.quat.angleAxis( rot, sm.vec3.new( 0, 0, 1 ) ) * sm.quat.new( 0.70710678, 0, 0, 0.70710678 ) )
									sm.effect.playEffect( "Plants - SoilbagUse", SoilPlacePosition, nil, sm.quat.angleAxis( rot, sm.vec3.new( 0, 0, 1 ) ) * sm.quat.new( 0.70710678, 0, 0, 0.70710678 ) )
									self.network:sendToClients( "cl_n_onOutgoingFire", { shapesOnContainerPath = container.shapesOnContainerPath } )
								end
								self:server_outgoingReset()		
							else
								self.network:sendToClients( "cl_n_onError", { shapesOnContainerPath = self.sv.connectedContainers[1].shapesOnContainerPath } )
							end
							
						else
							local projectile = UuidToProjectile[tostring( self.sv.foundItem )]
							if projectile then
								sm.container.beginTransaction()
								sm.container.spend( self.sv.foundContainer.shape:getInteractable():getContainer(), self.sv.foundItem, 1, true )
								if sm.container.endTransaction() then
									-- If successful spend, fire an projectile
									if projectile.hvs then
										sm.projectile.shapeCustomProjectileAttack(
											{ hvs = projectile.hvs },
											projectile.uuid,
											0,
											sm.vec3.new( 0.0, 0.25, 0.0 ),
											sm.vec3.new( 0, -20, 0 ),
											self.shape )
									else
										sm.projectile.shapeFire(
											self.shape,
											projectile.uuid,
											sm.vec3.new( 0.0, 0.25, 0.0 ),
											sm.vec3.new( 0, -20, 0 ) )
									end

									self.network:sendToClients( "cl_n_onOutgoingFire", { shapesOnContainerPath = self.sv.foundContainer.shapesOnContainerPath } )
								end
								self:server_outgoingReset()
							elseif valid  then			
								if sm.item.isBlock( self.sv.foundItem ) then
									sm.container.beginTransaction()
									sm.container.spend( self.sv.foundContainer.shape:getInteractable():getContainer(), self.sv.foundItem, 1, true )
									if sm.container.endTransaction() then
										sm.construction.buildBlock( self.sv.foundItem, gridPos, obj )
										self.network:sendToClients( "cl_n_onOutgoingFire", { shapesOnContainerPath = self.sv.foundContainer.shapesOnContainerPath } )
									end
								else
									if sm.container.canSpend( self.sv.foundContainer.shape:getInteractable():getContainer(), self.sv.foundItem, 1 ) then
										local canSpawn = true
										
										if canSpawn then
											if obj ~= nil then
												local NewShape = obj.body:createPart( self.sv.foundItem, gridPos- sm.vec3.new( 2, 2, 0 ), obj.xAxis, obj.yAxis, true )
												if NewShape ~= nil then
													sm.container.beginTransaction()
													sm.container.spend( self.sv.foundContainer.shape:getInteractable():getContainer(), self.sv.foundItem, 1, true )
													if sm.container.endTransaction() then
														self.network:sendToClients( "cl_n_onOutgoingFire", { shapesOnContainerPath = self.sv.foundContainer.shapesOnContainerPath } )
													end
												end
											else				
												--print( "terrain drop" )
												if worldPos ~= nil then
													local NewShape = sm.shape.createPart( self.sv.foundItem, worldPos - sm.vec3.new( 0.9, 0.9, 0 ), sm.quat.identity(), false, true )
													if NewShape ~= nil then
														sm.container.beginTransaction()
														sm.container.spend( self.sv.foundContainer.shape:getInteractable():getContainer(), self.sv.foundItem, 1, true )
														if sm.container.endTransaction() then
															self.network:sendToClients( "cl_n_onOutgoingFire", { shapesOnContainerPath = self.sv.foundContainer.shapesOnContainerPath } )
														end
													end
												end
											end
										end
									end
								end
								
								self:server_outgoingReset()		
							else
								if self.sv.foundItem ~= sm.uuid.getNil() then	
									if not sm.item.isBlock( self.sv.foundItem ) then
										sm.container.beginTransaction()
										sm.container.spend( self.sv.foundContainer.shape:getInteractable():getContainer(), self.sv.foundItem, 1, true )
										if sm.container.endTransaction() then										
											local projectileName = "loot"
											local params = { lootUid = self.sv.foundItem, lootQuantity = 1, epic = false }
											sm.projectile.shapeCustomProjectileAttack( params, projectileName, 0, sm.vec3.new( 0, 0, 0 ), sm.vec3.new( 0, -Vacuum.LootFirePower, 0 ), self.shape, 0 )			
											self.network:sendToClients( "cl_n_onOutgoingFire", { shapesOnContainerPath = self.sv.foundContainer.shapesOnContainerPath } )									
										end		
										self:server_outgoingReset()
									else
										self.network:sendToClients( "cl_n_onError", { shapesOnContainerPath = self.sv.connectedContainers[1].shapesOnContainerPath } )
									end
								end
							end
						end
					end

				end
			end
			self.sv.parentActive = isPumpActive
		--end

	elseif self.sv.storage.mode == VacuumMode.incoming and #self.sv.connectedContainers > 0 then
		local incomingObjects = {}
		--local parent = parents --self.shape:getInteractable():getSingleParent()
		if isPumpActive then
			local function GetCollectChest()
				local CollectChestStart = self.shape:getWorldPosition()
				local CollectChestStop = self.shape:getWorldPosition() - sm.shape.getAt( self.shape ) * 1.75
				
				local CollectChestValid, CollectChestResult = sm.physics.raycast( CollectChestStart, CollectChestStop, self.shape )
				
				if CollectChestValid and CollectChestResult then
					local obj, container
					
					if CollectChestResult.type == "body" then
						FilterChestShape = CollectChestResult:getShape()
						if FilterChestShape then
							if FilterChestShape:getInteractable() then
								if FilterChestShape:getInteractable():getContainer() then
									container = FilterChestShape:getInteractable():getContainer()
									obj = CollectChestResult					
								end			
							end					
						end
					elseif CollectChestResult.type == "shape" then
						if CollectChestResult then
							if CollectChestResult:getInteractable() then
								if FilterChestShape:getInteractable():getContainer() then
									container = FilterChestShape:getInteractable():getContainer()
									obj = CollectChestResult					
								end	
							end
						end
					end		
					
					return obj, container
				end
			end
			local CollectChestPart, CollectChestContainer = GetCollectChest()

			
			

			local function CheckFilterChestItem( container, itemUid, antiFilterState )
				if not container then
					return true
				end
				if not container:isEmpty() then
					if sm.container.canSpend( container, itemUid, 1 ) then		
						if antiFilterState then
							return false 
						end
						return true 
					end
				else
					return true
				end
				if antiFilterState then
					return true 
				end
				return false 
			end
			
			if CollectChestContainer and self.sv.ChestCollectTimer <= 0 then
				
				local partUuid = nil
				local amount = 0
				for Collectslot = 0, CollectChestContainer:getSize() - 1 do
					local Collectitem = CollectChestContainer:getItem( Collectslot )											
					if Collectitem then
						if Collectitem.uuid then
							if Collectitem.quantity > 0 then								
								if CheckFilterChestItem( self.filtercontainer, Collectitem.uuid, AntiFilter ) then								
									local container = FindContainerToCollectTo( self.sv.connectedContainers, Collectitem.uuid, 1 )	
									if container then
										partUuid = Collectitem.uuid
										amount = Collectitem.quantity
										break
									end
								end
							end
						end
					end
				end			
				if partUuid and amount then
					--eprint( "UUID: " .. tostring( partUuid ) .. " - x " .. tostring( amount ) )
					local container = FindContainerToCollectTo( self.sv.connectedContainers, partUuid, amount )						
					if container ~= nil then						
						if sm.container.canSpend( CollectChestContainer, partUuid, amount ) then						
							sm.container.beginTransaction()
							sm.container.spend( CollectChestContainer, partUuid, amount, true )
							if sm.container.endTransaction() then										
								table.insert( incomingObjects, { container = container, uuid = partUuid, amount = amount, withOutSuckEffect = true } )	
								self.sv.ChestCollectTimer = Vacuum.fireDelay
								self.network:sendToClients( "cl_n_onIncomingFire", { shapesOnContainerPath = container.shapesOnContainerPath, item = partUuid, withEffect = false } )
							end			
						end					
					end		
				end
				self.sv.canFire = true
			elseif not CollectChestContainer then	
				
				local function GetFacingShape( self )
					local start = self.shape:getWorldPosition()
					local Distance = 3.5
					local Spread = 100
					local stop = self.shape:getWorldPosition() - ( sm.shape.getAt( self.shape ) * Distance )   + ( sm.shape.getRight( self.shape ) * math.random( -Spread, Spread ) / 100 ) + ( sm.shape.getUp( self.shape ) * math.random( -Spread, Spread ) / 100 )
					local valid, result = sm.physics.raycast( start, stop, self.shape )
					return result:getShape(), result.pointWorld, result:getHarvestable()
				end

				local FacingShape, HitPos, FacingHarvestable = GetFacingShape( self )
				
				if FacingShape and not FacingHarvestable and tostring( sm.shape.getColor( self.shape ) ) == "cf11d2ff" then
					local uuid = FacingShape:getShapeUuid()
					if uuid ~= sm.uuid.getNil() and CheckFilterChestItem( self.filtercontainer, uuid, AntiFilter ) and self:Fant_CheckRestriction( uuid ) ==  true and IsNotInList( FacingShape ) then										
						local container = FindContainerToCollectTo( self.sv.connectedContainers, uuid, 1 )
						if container then
							local isBlock = sm.item.isBlock( uuid )
							local blockHitPos = nil
							if isBlock then
								blockHitPos = FacingShape:getClosestBlockLocalPosition( HitPos )
								--local size = sm.vec3.new( 1, 1, 1 )
								--FacingShape:destroyBlock( blockHitPos, size, 0 )
							else
								--FacingShape:destroyShape( 0 )
							end		
							
							if isBlock then
								if blockHitPos ~= nil then
									table.insert( incomingObjects, { container = container, uuid = uuid, amount = 1, Object = FacingShape, isOil = false, destroy = false, blockHitPos = blockHitPos } )
								end
							else
								table.insert( incomingObjects, { container = container, uuid = uuid, amount = 1, Object = FacingShape, isOil = false, destroy = true } )	
							end							
						end
					end
				elseif not FacingShape and FacingHarvestable and tostring( sm.shape.getColor( self.shape ) ) == "cf11d2ff" then
					if FacingHarvestable.uuid == hvs_soil and IsNotInList( FacingHarvestable ) then
						local container = FindContainerToCollectTo( self.sv.connectedContainers, obj_consumable_soilbag, 1 )
						if container then
							table.insert( incomingObjects, { container = container, uuid = obj_consumable_soilbag, amount = 1, Object = FacingHarvestable, destroy = true, withOutSuckEffect = nil } )			
						end
					end
				else
					for _, result in ipairs(  self.sv.areaTrigger:getContents() ) do	
						if sm.exists( result ) and IsNotInList( result ) then							
							if type( result ) == "Harvestable" then	 
								if result:getType() == "mature"  then
									local data = result:getData()
									if data then
										local partUuid = data["harvest"]
										local amount = data["amount"]

										if partUuid and amount then
											partUuid = sm.uuid.new( partUuid )
											local container = FindContainerToCollectTo( self.sv.connectedContainers, partUuid, amount )
											if container then
												-- Collect seeds from harvestable
												local seedUuid = data["seed"]
												local seedIncomingObj = nil
												if seedUuid then
													local seedAmount = math.floor( math.random( 1, 3 ) ) --randomStackAmountAvg2()
													seedUuid = sm.uuid.new( seedUuid )
													local seedContainer = FindContainerToCollectTo( self.sv.connectedContainers, seedUuid, seedAmount )
													if seedContainer then
														seedIncomingObj = { container = seedContainer, uuid = seedUuid, amount = seedAmount }
													end
												end
												table.insert( incomingObjects, { container = container, harvestable = result, uuid = partUuid, amount = amount, seedIncomingObj = seedIncomingObj, Object = result } )
											end
										end
									end
									
								elseif tostring( result.uuid ) == "2ab8edca-9cfe-4b1c-9f57-5092f94ea890" and CheckFilterChestItem( self.filtercontainer, obj_resource_crudeoil, AntiFilter ) then									
									local amount = math.random( 1, 3 )
									if amount then
										local container = FindContainerToCollectTo( self.sv.connectedContainers, obj_resource_crudeoil, amount )
										if container then
											table.insert( incomingObjects, { container = container, uuid = obj_resource_crudeoil, amount = amount, Object = result, isOil = true, destroy = true } )										
										end
									end
								elseif tostring( result.uuid ) == "391b6787-c3c5-4a24-befa-58d4e37b8e8d" and CheckFilterChestItem( self.filtercontainer, obj_consumable_water, AntiFilter ) then
									local amount = math.random( 1, 3 )
									if amount then
										local container = FindContainerToCollectTo( self.sv.connectedContainers, obj_consumable_water, amount )
										if container then
											table.insert( incomingObjects, { container = container, uuid = obj_consumable_water, amount = amount, Object = result, isWater = true, destroy = true } )										
										end
									end
								elseif tostring( result.uuid ) == "30109e38-7e8c-4baf-b6ae-e0a41a74f91f" and CheckFilterChestItem( self.filtercontainer, obj_consumable_chemical, AntiFilter ) then
									local amount = math.random( 1, 3 )
									if amount then
										local container = FindContainerToCollectTo( self.sv.connectedContainers, obj_consumable_chemical, amount )
										if container then
											table.insert( incomingObjects, { container = container, uuid = obj_consumable_chemical, amount = amount, Object = result, isChemical = true, destroy = true } )										
										end
									end
								
								
								-- elseif tostring( result.uuid ) == "2ab8edca-9cfe-4b1c-9f57-5092f94ea890" and CheckFilterChestItem( self.filtercontainer, obj_resource_crudeoil, AntiFilter ) then
									-- local data = result:getData()
									-- if data then
										-- local partUuid = data["harvest"]
										-- local amount = math.random( 1, 3 )
										-- if partUuid and amount then
											-- partUuid = sm.uuid.new( partUuid )
											-- local container = FindContainerToCollectTo( self.sv.connectedContainers, partUuid, amount )
											-- if container then
												-- table.insert( incomingObjects, { container = container, uuid = partUuid, amount = amount, Object = result, isOil = true, destroy = true } )										
											-- end
										-- end
									-- end
								elseif tostring( result.uuid ) == "f7567939-d170-437e-b5c4-352ee9d5850d" and CheckFilterChestItem( self.filtercontainer, obj_resource_flower, AntiFilter ) then
									local data = result:getData()
									if data then
									
										local partUuid = data["harvest"]
										local amount = math.random( 1, 4 )
										if partUuid and amount then
											partUuid = sm.uuid.new( partUuid )
											local container = FindContainerToCollectTo( self.sv.connectedContainers, partUuid, amount )
											if container then
												table.insert( incomingObjects, { container = container, uuid = partUuid, amount = amount, Object = result, destroy = true, isFlower = true } )									
											end
										end
									end	
								elseif tostring( result.uuid ) == "39a5aeba-a021-4117-8cad-e08ad159281d" and CheckFilterChestItem( self.filtercontainer, obj_resource_corn, AntiFilter ) then
									local data = result:getData()
									if data then
										local partUuid = data["harvest"]
										local amount = math.random( 1, 4 )
										if partUuid and amount then
											partUuid = sm.uuid.new( partUuid )
											local container = FindContainerToCollectTo( self.sv.connectedContainers, partUuid, amount )
											if container then
												table.insert( incomingObjects, { container = container, uuid = partUuid, amount = amount, Object = result, destroy = true, isCorn = true } )								
											end
										end
									end	
								elseif tostring( result.uuid ) == "046a8ac8-300b-4e52-91f7-0912d53b2955" and CheckFilterChestItem( self.filtercontainer, obj_resources_slimyclam, AntiFilter ) then
									local data = result:getData()
									if data then
										local partUuid = data["harvest"]
										local amount = math.random( 1, 4 )
										if partUuid and amount then
											partUuid = sm.uuid.new( partUuid )
											local container = FindContainerToCollectTo( self.sv.connectedContainers, partUuid, amount )
											if container then
												table.insert( incomingObjects, { container = container, uuid = partUuid, amount = amount, Object = result, destroy = true, isClam = true } )									
											end
										end
									end												
								elseif tostring( result.uuid ) == "7261bb49-9c63-4097-999a-4dcab9645eb0" and CheckFilterChestItem( self.filtercontainer, obj_resource_beewax, AntiFilter )then
									local data = result:getData()
									if data then
										local partUuid = data["harvest"]
										local amount = math.random( 2, 4 )
										if partUuid and amount then
											partUuid = sm.uuid.new( partUuid )
											local container = FindContainerToCollectTo( self.sv.connectedContainers, partUuid, amount )
											if container then
												table.insert( incomingObjects, { container = container, uuid = partUuid, amount = amount, Object = result, destroy = true, isHoney = true } )									
											end
										end
									end												
								elseif tostring( result.uuid ) == "c591d94b-d7d1-4305-a9dd-76ef06d6fb49" and CheckFilterChestItem( self.filtercontainer, obj_resource_cotton, AntiFilter ) then
									local data = result:getData()
									if data then
										local partUuid = data["harvest"]
										local amount = 1
										if partUuid and amount then
											partUuid = sm.uuid.new( partUuid )
											local container = FindContainerToCollectTo( self.sv.connectedContainers, partUuid, amount )
											if container then
												table.insert( incomingObjects, { container = container, uuid = partUuid, amount = amount, Object = result, destroy = true, isCotton = true } )								
											end
										end
									end												
								elseif result:getType() == "filler" then	
									local lootObject  = result.publicData
									if lootObject then 
										local LootUuid = lootObject["uuid"]
										local amount = lootObject["quantity"]
										local container = FindContainerToCollectTo( self.sv.connectedContainers, LootUuid, amount )
										if container and CheckFilterChestItem( self.filtercontainer, LootUuid, AntiFilter ) then									
											table.insert( incomingObjects, { container = container, uuid = LootUuid, amount = amount, Object = result, destroy = true } )																		
										end			
									end					
								elseif result:getData() ~= "" then
									local data = result:getData()
									if data then
										if data["destroyEffect"] == "LootCrate - Destroy" then
											local lootTable = self.saved and self.saved.lootTable or nil
											if lootTable == nil then
												lootTable = "loot_crate_standard" 
											end
											local lootList = SelectLoot( lootTable )
											for i = 1, #lootList do								 
												local partUuid = lootList[i].uuid
												local amount = lootList[i].quantity or 1
												local container = FindContainerToCollectTo( self.sv.connectedContainers, partUuid, amount )
												if container then
													if partUuid and amount then
														table.insert( incomingObjects, { container = container, uuid = partUuid, amount = amount, Object = result, destroy = true, isLootCrate = true } )																		
													end		
												end
											end							
										end			
									end												
								else					
									--print( "Muh" )
								end		
								-- 00Fant end

							elseif type( result ) == "AreaTrigger" then
								local userData = result:getUserData()
								if userData and ( userData.water == true or userData.chemical == true or userData.oil == true )  then
									local uidLiquidType = obj_consumable_water
									if userData.chemical == true then
										uidLiquidType = obj_consumable_chemical
									elseif userData.oil == true then
										uidLiquidType = obj_resource_crudeoil
									end
									
									if CheckFilterChestItem( self.filtercontainer, uidLiquidType, AntiFilter ) then
										
										local container = FindContainerToCollectTo( self.sv.connectedContainers, uidLiquidType, 20 )
										if container then

											local waterZ = result:getWorldMax().z
											local raycastStart = self.shape:getWorldPosition() + self.shape.at
											if raycastStart.z > waterZ then

												local raycastEnd = self.shape:getWorldPosition() - self.shape.at * 4

												local hit, result = sm.physics.raycast( raycastStart, raycastEnd, self.shape:getBody(), sm.physics.filter.static + sm.physics.filter.areaTrigger )
												if hit and result.type == "areaTrigger" then
													table.insert( incomingObjects, { container = container, uuid = uidLiquidType, amount = 20 } )
												end
											else
												table.insert( incomingObjects, { container = container, uuid = uidLiquidType, amount = 20 } )
											end
										else
											local container2 = FindContainerToCollectTo( self.sv.connectedContainers, uidLiquidType, 1 )
											if container2 then

												local waterZ = result:getWorldMax().z
												local raycastStart = self.shape:getWorldPosition() + self.shape.at
												if raycastStart.z > waterZ then

													local raycastEnd = self.shape:getWorldPosition() - self.shape.at * 4

													local hit, result = sm.physics.raycast( raycastStart, raycastEnd, self.shape:getBody(), sm.physics.filter.static + sm.physics.filter.areaTrigger )
													if hit and result.type == "areaTrigger" then
														table.insert( incomingObjects, { container = container2, uuid = uidLiquidType, amount = 1 } )
													end
												else
													table.insert( incomingObjects, { container = container2, uuid = uidLiquidType, amount = 1 } )
												end
											end
										end
									end
								end
							-- elseif type( result ) == "Body" then
							-- 	for _, shape in ipairs( result:getShapes() ) do
							-- 		if shape:getBody():getCreationId() ~= self.shape:getBody():getCreationId() and shape:getBody():isDynamic() then
							-- 			local container = findContainerWithFreeSlots( shape:getShapeUuid(), 1 )
							-- 			if container then
							-- 				table.insert( incomingObjects, { container = container, shape = shape, uuid = shape:getShapeUuid(), amount = 1 } )
							-- 			end
							-- 		end
							-- 	end
							end
						end
					end
				
				end
			end
		
			if self.sv.canFire then
				local canFire = true
				for _, incomingObject in ipairs( incomingObjects ) do
					if incomingObject.container then					
						sm.container.beginTransaction()	
						sm.container.collect( incomingObject.container.shape:getInteractable():getContainer(), incomingObject.uuid, incomingObject.amount, true)
						if incomingObject.seedIncomingObj then
							sm.container.collect( incomingObject.seedIncomingObj.container.shape:getInteractable():getContainer(), incomingObject.seedIncomingObj.uuid, incomingObject.seedIncomingObj.amount, true)
						end

						if sm.container.endTransaction() and IsNotInList( incomingObject.Object ) then
							AddToDestroyList( incomingObject.Object )
							
							if incomingObject.withOutSuckEffect ~= nil then
								self.network:sendToClients( "cl_n_onIncomingFire", { shapesOnContainerPath = incomingObject.container.shapesOnContainerPath, item = incomingObject.uuid, withEffect = false } )
							else
								self.network:sendToClients( "cl_n_onIncomingFire", { shapesOnContainerPath = incomingObject.container.shapesOnContainerPath, item = incomingObject.uuid, withEffect = true  } )
							end
									
							if incomingObject.blockHitPos ~= nil and incomingObject.Object then
								incomingObject.Object:destroyBlock( incomingObject.blockHitPos, sm.vec3.new( 1, 1, 1 ), 0 )
							end
							
							if incomingObject.shape then
								incomingObject.shape:destroyShape()
							end
								
							if incomingObject.harvestable then	
								sm.effect.playEffect( "Plants - Picked", sm.harvestable.getPosition( incomingObject.harvestable ) )
								sm.harvestable.create( hvs_soil, sm.harvestable.getPosition( incomingObject.harvestable ), sm.harvestable.getRotation( incomingObject.harvestable ) )
								sm.harvestable.destroy( incomingObject.harvestable )						
							end
								
							if incomingObject.isOil then
								sm.effect.playEffect( "Oilgeyser - Picked", incomingObject.Object.worldPosition )
								sm.harvestable.create( hvs_farmables_growing_oilgeyser,  incomingObject.Object.worldPosition,  incomingObject.Object.worldRotation )
							end
													
							if incomingObject.isFlower then
								sm.effect.playEffect( "Pigmentflower - Picked", incomingObject.Object.worldPosition )
								sm.harvestable.create( hvs_farmables_growing_pigmentflower, incomingObject.Object.worldPosition, incomingObject.Object.worldRotation )
							end
								
							if incomingObject.isCorn then
								sm.effect.playEffect( "Plants - Picked", incomingObject.Object.worldPosition )	
								sm.harvestable.create( hvs_farmables_growing_cornplant, incomingObject.Object.worldPosition, incomingObject.Object.worldRotation )
							end
							
							if incomingObject.isClam then
								sm.effect.playEffect( "SlimyClam - Bubbles", incomingObject.Object.worldPosition )	
								sm.harvestable.create( hvs_farmables_slimyclam_broken, incomingObject.Object.worldPosition, incomingObject.Object.worldRotation )
							end
							
							if incomingObject.isHoney then
								sm.effect.playEffect( "beehive - beeswarm", incomingObject.Object.worldPosition )	
								sm.harvestable.create( hvs_farmables_beehive_broken, incomingObject.Object.worldPosition, incomingObject.Object.worldRotation )
							end
							
							if incomingObject.isCotton then
								sm.effect.playEffect( "Cotton - Picked", incomingObject.Object.worldPosition )	
								sm.harvestable.create( hvs_farmables_growing_cottonplant, incomingObject.Object.worldPosition, incomingObject.Object.worldRotation )
							end

							if incomingObject.isLootCrate then
								sm.effect.playEffect( "LootCrate - Destroy", incomingObject.Object.worldPosition )		
							end
						
							if incomingObject.destroy then	
								if type( incomingObject.Object ) ~= "Shape" then
									sm.harvestable.destroy( incomingObject.Object )
								else
									incomingObject.Object:destroyShape()
								end
							end
							
							
							
							canFire = false
						end
					else
						self.network:sendToClients( "cl_n_onError", { shapesOnContainerPath = self.sv.connectedContainers[1].shapesOnContainerPath } )
					end
				end

				if #incomingObjects == 0 then
					self.network:sendToClients( "cl_n_onError", { shapesOnContainerPath = self.sv.connectedContainers[1].shapesOnContainerPath } )
				end
				
			end
		end
		
		-- Synch visual feedback
		if #incomingObjects > 0 then
			self.sv.canFire = canFire
			-- Highlight the longest connection
			local longestConnection = incomingObjects[1].container
			for _, incomingObject in ipairs( incomingObjects ) do
				if #incomingObject.container.shapesOnContainerPath > #longestConnection.shapesOnContainerPath then
					longestConnection = incomingObject.container
				end
			end

			setVacuumState( PipeState.valid, longestConnection.shapesOnContainerPath )
		else
			if self.last_setVacuumStateOnAllShapes ~= PipeState.connected then
				self.last_setVacuumStateOnAllShapes = PipeState.connected 
				setVacuumStateOnAllShapes( PipeState.connected )
			end
		end
	end

	-- Storage table dirty
	if self.sv.dirtyStorageTable then
		self.storage:save( self.sv.storage )
		self.sv.dirtyStorageTable = false
	end

	-- Client table dirty
	if self.sv.dirtyClientTable then
		self.network:setClientData( { mode = self.sv.storage.mode, pipeNetwork = self.sv.client.pipeNetwork, state = self.sv.client.state, showBlockVisualization = self.sv.client.showBlockVisualization } )
		self.sv.dirtyClientTable = false
	end
	
	
end

function Vacuum.Fant_CheckRestriction( self, uuid )
	for i, restricted_uuid in pairs( self.UUIDRestrictions ) do
		if restricted_uuid == uuid then
			return false
		end
	end
	return true
end

function AddToDestroyList( object )
	if object == nil then
		return false
	end
	if DestroyList == nil then
		DestroyList = {}
	end
	table.insert( DestroyList, { obj = object, time = 1 } )
end

function IsNotInList( object )
	if DestroyList == nil then
		DestroyList = {}
		return true
	end
	if object == nil then
		return false
	end
	if #DestroyList <= 0 then
		return true
	end
	for i = 1, #DestroyList do
		if object == DestroyList[i].obj then
			return false
		end
	end
	return true
end

DestroyLoopRun = nil
DestroyLoopTimer = 0
function DestroyListLoop(self)
	if DestroyLoopRun ~= nil then
		if DestroyLoopRun.shape == nil then
			DestroyLoopRun = nil
		end
		if DestroyLoopRun ~= self then
			return
		end
	else
		DestroyLoopRun = self
	end
	if DestroyLoopRun ~= nil then
		DestroyLoopTimer = DestroyLoopTimer - 0.04
		if DestroyLoopTimer <= 0 then
			DestroyLoopTimer = 1
			DestroyLoopRun = nil
			local cleanTable = {}
			for i = 1, #DestroyList do
				if DestroyList[i] ~= nil then		
					if DestroyList[i].time > 0 then
						DestroyList[i].time = DestroyList[i].time - 0.1
						table.insert(cleanTable, DestroyList[i])
					end
				end
			end
			DestroyList = cleanTable
			if #DestroyList > 0 then
				--print("Destroy List Count: " .. tostring(#DestroyList) )
			end
			if #DestroyList <= 0 then
				DestroyLoopRun = nil
			end
		end
	end
	
end

-- Client
function Vacuum.client_onCreate( self )
	self.cl = {}

	-- Update from onClientDataUpdate
	self.cl.mode = VacuumMode.outgoing
	self.cl.pipeNetwork = {}
	self.cl.state = PipeState.off
	self.cl.showBlockVisualization = false

	self.cl.overrideUvFrameIndexTask = nil
	self.cl.poseAnimTask = nil
	self.cl.vacuumEffect = nil

	self.cl.pipeEffectPlayer = PipeEffectPlayer()
	self.cl.pipeEffectPlayer:onCreate()
	
	self.cl.startDelay = 4
	
	self.cl_antifilter = self.cl_antifilter or false
	
	self.filtercontainer = self.shape:getInteractable():getContainer(1)
	
	self.network:sendToServer( "sv_remoteInit" )
end


function Vacuum.sv_remoteInit( self )
	self.network:sendToClients( "cl_remoteInit" )
end

function Vacuum.cl_remoteInit( self )
	self.filtercontainer = self.shape:getInteractable():getContainer(1)
end

function Vacuum.client_onClientDataUpdate( self, clientData )
	if #clientData.pipeNetwork > 0 then
		assert( clientData.mode )
		assert( clientData.state )
	end
	self.cl.mode = clientData.mode
	self.cl.pipeNetwork = clientData.pipeNetwork
	self.cl.state = clientData.state
	self.cl.showBlockVisualization = clientData.showBlockVisualization
end



function Vacuum.sv_refreshFilter( self )
	self.filtercontainer = self.shape:getInteractable():getContainer(1)
	if self.filtercontainer then
		local newFilter = {}
		for Filterslot = 0, self.filtercontainer:getSize() - 1 do
			local Filteritem = self.filtercontainer:getItem( Filterslot )											
			if Filteritem then
				if Filteritem.quantity > 0 then
					table.insert( newFilter, Filteritem.uuid )
				end
			end
		end

		self.filterItems = newFilter
		self.sv.storage.filterItems = self.filterItems
		self.storage:save( self.sv.storage )
	end
end


function Vacuum.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use", true )
	sm.gui.setInteractionText( "", keyBindingText, "Flow Direction / +Crouch = Filter Switch" )
	local keyBindingText =  sm.gui.getKeyBinding( "Tinker", true )
	if self.cl_antifilter then
		sm.gui.setInteractionText( "", keyBindingText, "#ff0000Exclude Filter"  )
	else
		sm.gui.setInteractionText( "", keyBindingText, "#00ff00Include Filter"  )
	end
	return true
end

function Vacuum.client_onInteract( self, character, state )
	if character:isCrouching() then
		if state == true then
			self.network:sendToServer( "sv_antifilter" )
			--print( "AntiFilter Switch" )
		end
	else
		if state == true then
			self.network:sendToServer( "sv_n_toogle" )
		end
	end
end

function Vacuum.client_onTinker( self, character, state )
	if state == true then
		self.filtercontainer = self.shape:getInteractable():getContainer(1)
		if self.filtercontainer == nil then
			self.filtercontainer = self.shape:getInteractable():getContainer( 1 )
		end
		if self.filtercontainer == nil then
			return
		end
		local gui = sm.gui.createContainerGui( true )
		if self.cl_antifilter then
			gui:setText( "UpperName", "#ff0000Exclude Filter" )
		else
			gui:setText( "UpperName", "#00ff00Include Filter" )
		end
		
		gui:setContainer( "UpperGrid", self.filtercontainer )
		gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
		gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		
		gui:setOnCloseCallback( "cl_onClose" )
		
		gui:open()
		
		
	end
end

function Vacuum.cl_onClose( self )
	self.network:sendToServer( "sv_refreshFilter" )
end

function Vacuum.sv_antifilter( self )
	if self.antifilter then
		self.antifilter = false
	else
		self.antifilter = true
	end
	self.sv.storage.antifilter = self.antifilter
	self.storage:save( self.sv.storage )
	self.network:sendToClients( "cl_setantifilter", self.antifilter )
end

function Vacuum.cl_setantifilter( self, state )
	self.cl_antifilter = state
end

function Vacuum.server_canErase( self )
	if self.filtercontainer and not self.filtercontainer:isEmpty() then		
		return false
	end
	return true
end

function Vacuum.client_canErase( self )
	if self.filtercontainer == nil then
		self.filtercontainer = self.shape:getInteractable():getContainer(1)
	end
	if self.filtercontainer ~= nil then
		if self.filtercontainer and not self.filtercontainer:isEmpty() then
			sm.gui.displayAlertText( "Clear the Filter!", 1.5 )
			return false
		end
	end
	return true
end


function Vacuum.client_onUpdate( self, dt )
	if self.filtercontainer == nil then
		self.filtercontainer = self.shape:getInteractable():getContainer(1)
	end

	if self.cl.startDelay > 0 then
		self.cl.startDelay = self.cl.startDelay  - dt
		return
	end
	-- Update pose anims
	self:cl_updatePoseAnims( dt )

	-- Update Uv Index frames
	self:cl_updateUvIndexFrames( dt )

	-- Update effects through pipes
	self.cl.pipeEffectPlayer:update( dt )

	-- Visualize block if a block is loaded
	if self.cl.state == PipeState.connected and self.cl.showBlockVisualization then
		local valid, gridPos, localNormal, worldPos, obj = self:constructionRayCast()
		if valid then
			local function countTerrain()
				if type(obj) == "Shape" then
					return obj:getBody():isDynamic()
				end
				return false
			end
			sm.visualization.setBlockVisualization(gridPos,
				sm.physics.sphereContactCount( worldPos, sm.construction.constants.subdivideRatio_2, countTerrain() ) > 0 or not sm.construction.validateLocalPosition( blk_cardboard, gridPos, localNormal, obj ),
				obj)
		end
	end
end

-- Events

function Vacuum.cl_n_onOutgoingReload( self, data )
	-- 00Fant
	
	if not data then
		return
	end
	if not data.item then
		return
	end
	if data.item == sm.uuid.getNil() then
		return
	end
	if data.item == tool_gatling then
		return
	end
	if data.item == tool_shotgun then
		return
	end
	if data.item == tool_spudgun then
		return
	end
	if data.item == tool_spudgun_creative then
		return
	end
	if data.item == tool_weld then
		return
	end
	if data.item == tool_paint then
		return
	end
	if data.item == tool_connect then
		return
	end
	if data.item == tool_lift then
		return
	end
	if data.item == tool_sledgehammer then
		return
	end
	if data.item == hvs_soil then
		return
	end
	--print(data.item)
	-- 00Fant
	local shapeList = {}
	for idx, shape in reverse_ipairs( data.shapesOnContainerPath ) do
		table.insert( shapeList, shape )
	end
	table.insert( shapeList, self.shape )

	self.cl.pipeEffectPlayer:pushShapeEffectTask( shapeList, data.item )

	self:cl_setOverrideUvIndexFrame( shapeList, PipeState.valid )
end

function Vacuum.cl_n_onOutgoingFire( self, data )
	local shapeList = data.shapesOnContainerPath
	if shapeList then
		table.insert( shapeList, self.shape )
	end		

	self:cl_setOverrideUvIndexFrame( shapeList, PipeState.valid )
	self:cl_setPoseAnimTask( "outgoingFire" )
	if data.withoutEffect == nil or data.withoutEffect == false then
		self.cl.vacuumEffect = sm.effect.createEffect( "Vacuumpipe - Blowout", self.interactable )
		self.cl.vacuumEffect:setOffsetRotation( sm.quat.angleAxis( math.pi*0.5, sm.vec3.new( 1, 0, 0 ) ) )
		self.cl.vacuumEffect:start()
	end
end

function Vacuum.cl_n_onIncomingFire( self, data )

	table.insert( data.shapesOnContainerPath, 1, self.shape )
	if hvs_soil ~= data.item then
		self.cl.pipeEffectPlayer:pushShapeEffectTask( data.shapesOnContainerPath, data.item )
	end
	self:cl_setOverrideUvIndexFrame( data.shapesOnContainerPath, PipeState.valid )
	self:cl_setPoseAnimTask( "incomingFire" )
	if data.withEffect then
		self.cl.vacuumEffect = sm.effect.createEffect( "Vacuumpipe - Suction", self.interactable )
		self.cl.vacuumEffect:setOffsetRotation( sm.quat.angleAxis( math.pi*0.5, sm.vec3.new( 1, 0, 0 ) ) )
		self.cl.vacuumEffect:start()
	end
end

function Vacuum.cl_n_onError( self, data )
	self:cl_setOverrideUvIndexFrame( data.shapesOnContainerPath, PipeState.invalid )
end

-- State sets

function Vacuum.cl_pushEffectTask( self, shapeList, effect )
	self.cl.pipeEffectPlayer:pushEffectTask( shapeList, effect )
end

function Vacuum.cl_setOverrideUvIndexFrame( self, shapeList, state )
	local shapeMap = {}
	if shapeList then
		for _, shape in ipairs( shapeList ) do
			shapeMap[shape:getId()] = state
		end
	end
	self.cl.overrideUvFrameIndexTask = { shapeMap = shapeMap, state = state, progress = 0 }
end

function Vacuum.cl_setPoseAnimTask( self, name )
	self.cl.poseAnimTask = { name = name, progress = 0 }
end

-- Updates

PoseCurves = {}
PoseCurves["outgoingFire"] = Curve()
PoseCurves["outgoingFire"]:init({{v=0.5, t=0.0},{v=1.0, t=0.1},{v=0.5, t=0.2},{v=0.0, t=0.3},{v=0.5, t=0.6}})

PoseCurves["incomingFire"] = Curve()
PoseCurves["incomingFire"]:init({{v=0.5, t=0.0},{v=0.0, t=0.1},{v=0.5, t=0.2},{v=1.0, t=0.3},{v=0.5, t=0.6}})

function Vacuum.cl_updatePoseAnims( self, dt )

	if self.cl.poseAnimTask then

		self.cl.poseAnimTask.progress = self.cl.poseAnimTask.progress + dt

		local curve = PoseCurves[self.cl.poseAnimTask.name]
		if curve then
			self.shape:getInteractable():setPoseWeight( 0, curve:getValue( self.cl.poseAnimTask.progress ) )

			if self.cl.poseAnimTask.progress > curve:duration() then
				self.cl.poseAnimTask = nil
			end
		else
			self.cl.poseAnimTask = nil
		end
	end

end

local GlowCurve = Curve()
GlowCurve:init({{v=1.0, t=0.0}, {v=0.5, t=0.05}, {v=0.0, t=0.1}, {v=0.5, t=0.3}, {v=1.0, t=0.4}, {v=0.5, t=0.5}, {v=0.0, t=0.7}, {v=0.5, t=0.75}, {v=1.0, t=0.8}})

function Vacuum.cl_updateUvIndexFrames( self, dt )

	local glowMultiplier = 1.0

	-- Events allow for overriding the uv index frames, time it out
	if self.cl.overrideUvFrameIndexTask then
		self.cl.overrideUvFrameIndexTask.progress = self.cl.overrideUvFrameIndexTask.progress + dt

		glowMultiplier = GlowCurve:getValue( self.cl.overrideUvFrameIndexTask.progress )

		if self.cl.overrideUvFrameIndexTask.progress > 0.1 then

			self.cl.overrideUvFrameIndexTask.change = true
		end

		if self.cl.overrideUvFrameIndexTask.progress > 0.7 then

			self.cl.overrideUvFrameIndexTask.change = false
		end

		if self.cl.overrideUvFrameIndexTask.progress > GlowCurve:duration() then

			self.cl.overrideUvFrameIndexTask = nil
		end
	end

	-- Light up vacuum
	local state = self.cl.state
	if self.cl.overrideUvFrameIndexTask and self.cl.overrideUvFrameIndexTask.change == true then
		state = self.cl.overrideUvFrameIndexTask.state
	end

	VacuumFrameIndexTable = {
		[VacuumMode.outgoing] = {
			[PipeState.off] = 0,
			[PipeState.invalid] = 1,
			[PipeState.connected] = 2,
			[PipeState.valid] = 4
		},
		[VacuumMode.incoming] = {
			[PipeState.off] = 0,
			[PipeState.invalid] = 1,
			[PipeState.connected] = 3,
			[PipeState.valid] = 5
		}
	}
	assert( self.cl.mode > 0 and self.cl.mode <= 2 )
	assert( state > 0 and state <= 4 )
	local vacuumFrameIndex = VacuumFrameIndexTable[self.cl.mode][state]
	self.interactable:setUvFrameIndex( vacuumFrameIndex )
	if self.cl.overrideUvFrameIndexTask then
		self.interactable:setGlowMultiplier( glowMultiplier )
	else
		self.interactable:setGlowMultiplier( 1.0 )
	end

	local function fnOverride( pipe )

		local state = pipe.state
		local glow = 1.0

		if self.cl.overrideUvFrameIndexTask then
			local overrideState = self.cl.overrideUvFrameIndexTask.shapeMap[pipe.shape:getId()]
			if overrideState then
				if self.cl.overrideUvFrameIndexTask.change == true then
					state = overrideState
				end
				glow = glowMultiplier
			end
		end

		return state, glow
	end

	-- Light up pipes
	LightUpPipes( self.cl.pipeNetwork, fnOverride )
end