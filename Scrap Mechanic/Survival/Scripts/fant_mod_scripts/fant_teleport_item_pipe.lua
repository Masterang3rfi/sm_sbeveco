dofile( "$SURVIVAL_DATA/Scripts/game/util/Curve.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/util/pipes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_loot.lua")

Fant_Teleport_Item_Pipes = {} or Fant_Teleport_Item_Pipes

Fant_Teleport_Item_Pipe = class()
Fant_Teleport_Item_Pipe.TeleportInterval = 0.5
Fant_Teleport_Item_Pipe.maxParentCount = 1
Fant_Teleport_Item_Pipe.connectionInput = sm.interactable.connectionType.logic

function Fant_Teleport_Item_Pipe.server_onCreate( self )
	self.sv = {}
	self.sv.client = {}
	self.sv.client.pipeNetwork = {}
	self.sv.client.state = PipeState.off
	self.sv.client.showBlockVisualization = false
	self.sv.dirtyClientTable = false
	self.sv.dirtyStorageTable = false
	self.sv.connectedContainers = {}
	self.sv.foundItem = sm.uuid.getNil()
	self.sv.foundContainer = nil
	self.timer = 0
	self.connectedContainer = nil
	self.HasError = false
	self.loadDelay = 2
	self.sv.startDelay = 4
	self.UpdatePipeSystem = false
	
	self.container = self.shape.interactable:getContainer( 0 )
	if not self.container then
		self.container = self.shape:getInteractable():addContainer( 0, 10, 256 )
	end
	self.filtercontainer = self.shape:getInteractable():getContainer(1)
	if not self.filtercontainer then
		self.filtercontainer = self.shape:getInteractable():addContainer( 0, 1, 1 )
	end
	
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { filterItem = nil } 
		self.storage:save( self.sv.storage )
	end
	self.filterItem = self.sv.storage.filterItem
	if self.filterItem ~= nil then
		sm.container.beginTransaction()
		sm.container.setItem( self.filtercontainer, 0, self.filterItem, 1 )
		if sm.container.endTransaction() then
			--print( "Teleport Pipe Filter Item Loaded: "..tostring(self.filterItem) )
		end
	end	
	
	self.isSender = true
	if self.shape.uuid == obj_interactive_fant_teleport_pipe_out then
		self.isSender = false
		self:RefreshPipeData( true )
	end	
	self:sv_buildPipeNetwork()
	
	self.initPipeTimer = 0.5
end

function Fant_Teleport_Item_Pipe.server_onDestroy( self )
	self:RefreshPipeData( false )
end

function Fant_Teleport_Item_Pipe.RefreshPipeData( self, keep )
	local Fant_Teleport_Item_Pipes_Count = 0
	if self.shape and self.isSender == false then
		local newList = {}
		for index, data in pairs( Fant_Teleport_Item_Pipes ) do		
			if data ~= {} then
				if data.shape then
					if data.shape ~= self.shape then
						table.insert( newList, data )
						Fant_Teleport_Item_Pipes_Count = Fant_Teleport_Item_Pipes_Count + 1
					end
				end
			end
		end
		Fant_Teleport_Item_Pipes = newList
		if keep then
			table.insert( Fant_Teleport_Item_Pipes, { shape = self.shape } )
			Fant_Teleport_Item_Pipes_Count = Fant_Teleport_Item_Pipes_Count + 1
		end
	end
	self.sv.storage = { filterItem = self.filterItem } 
	self.storage:save( self.sv.storage )
	--print( "Teleport Pipe Count: " .. tostring( Fant_Teleport_Item_Pipes_Count ) )
end

function RefreshFilter( self )
	if not self.container or not self.filtercontainer then
		return
	end
	if self.filterFail and self.filterFail > 0 then
		self.filterFail = self.filterFail - 1
	end
	local filterItemUUID = nil
	local isChestFree = true
	if not self.filtercontainer:isEmpty() then
		local filterItem = self.filtercontainer:getItem(0)
		if filterItem then
			filterItemUUID = filterItem.uuid
		end
	end	
	
	if self.loadDelay > 0 then
		self.loadDelay = self.loadDelay - 1
	else
		if not self.filtercontainer:isEmpty() then
			if not self.container:isEmpty() then
				for slot = 0, self.container:getSize() - 1 do
					local item = self.container:getItem( slot )											
					if item then
						if item.quantity > 0 then
							if item.uuid ~= filterItemUUID and filterItemUUID then
								isChestFree = false
								filterItemUUID = nil
								if not self.filterFail or self.filterFail <= 0 then
									self.filterFail = 3
									if not self.HasError then
										self.HasError = true
										self.network:sendToClients( "cl_FilterFail", true  )	
									end
								end
								break
							end
						end
					end
				end
			end	
		end	
	end
	if isChestFree then	
		if self.HasError then
			self.HasError = false
			self.network:sendToClients( "cl_FilterFail", false  )	
		end
		if self.filterItem ~= filterItemUUID then		
			self.filterItem = filterItemUUID
			self.sv.storage = { filterItem = self.filterItem } 
			self.storage:save( self.sv.storage )
		end
	end
	if filterItemUUID then		
		self.container:setFilters( { self.filterItem } )
	else
		self.container:setFilters( {} )
	end	
end

function Fant_Teleport_Item_Pipe.cl_FilterFail(self, state )
	if state then
		if self.guiInfo == nil then
			self.guiInfo = sm.gui.createNameTagGui()
		end
		self.guiInfo:setRequireLineOfSight( false )
		self.guiInfo:open()
		self.guiInfo:setMaxRenderDistance( 50 )
		self.guiInfo:setWorldPosition( self.shape.worldPosition + sm.vec3.new( 0, 0, 0 ) )
		self.guiInfo:setText( "Text", "#ff0000".. "Teleportpipe Content is differnt to Filter Item.\nClear the Teleportpipe or Filter! Filter OFF!" )
	else
		if self.guiInfo then
			self.guiInfo:close()
			self.guiInfo = nil
		end
	end
end

function Fant_Teleport_Item_Pipe.filterOk( self, itemuuid )
	if self.filterItem ~= nil then
		if self.filterItem ~= itemuuid then
			return false
		end
	end
	return true
end

function Fant_Teleport_Item_Pipe.server_onFixedUpdate( self, dt )
	if self.initPipeTimer > 0 then
		self.initPipeTimer = self.initPipeTimer - dt
		if self.initPipeTimer <= 0 then
			self:sv_buildPipeNetwork()
		end
	end
	
	if self.sv.startDelay > 0 then
		self.sv.startDelay = self.sv.startDelay  - dt
		return
	end
	if self.shape:getBody():hasChanged( sm.game.getCurrentTick() - 1 ) then
		self.UpdatePipeSystem = true
	end	
	if self.timer > 0 then
		self.timer = self.timer - dt
		return
	end
	self.timer = self.TeleportInterval
	

	
	local HasPipeUpdated = false
	
	local parent = self.shape:getInteractable():getSingleParent()
	if parent and self.sv.connectedContainers and self.sv.connectedContainers ~= {} then
		if parent.active then
			if not self.isSender then
				for index, externalContainerShape in pairs( self.sv.connectedContainers ) do
					if externalContainerShape ~= nil then					
						if sm.exists( externalContainerShape.shape ) then
							local externalContainer = externalContainerShape.shape:getInteractable():getContainer()
							if externalContainer then
								for slot = 0, externalContainer:getSize() - 1 do								
									local externalItem = externalContainer:getItem( slot )
									if externalItem then
										if externalItem.quantity > 0 and self:filterOk( externalItem.uuid ) then
											if self.UpdatePipeSystem and not HasPipeUpdated then
												HasPipeUpdated = true
												self.UpdatePipeSystem = false
												self:RefreshPipeData( true )
												self:sv_buildPipeNetwork()
											end
											sm.container.beginTransaction()
											sm.container.collect( self.container, externalItem.uuid, externalItem.quantity, true )
											if sm.container.endTransaction() then
												sm.container.beginTransaction()
												sm.container.spend( externalContainer, externalItem.uuid, externalItem.quantity, true )
												if sm.container.endTransaction() then
													if self:server_outgoingShouldReload( externalContainerShape, externalItem.uuid ) then
														self:server_outgoingReload( externalContainerShape, externalItem.uuid )
													end
													self.network:sendToClients( "cl_n_onOutgoingFire", { shapesOnContainerPath = externalContainerShape.shapesOnContainerPath } )	
													self:server_outgoingReset()	
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
		end
	end
	RefreshFilter( self )		
	if self.isSender then
		self.container = self.shape.interactable:getContainer( 0 )
		if self.container ~= nil then
			self.colorstring = tostring( sm.shape.getColor( self.shape ) )
			local foundShapes = {}
			for index, telepipedata in pairs( Fant_Teleport_Item_Pipes ) do	
				if telepipedata then
					if telepipedata.shape then
						if self.colorstring == tostring( sm.shape.getColor( telepipedata.shape ) )then
							table.insert( foundShapes, telepipedata )
						end
					end
				end
			end
			if foundShapes ~= {} then
				local randomShape = foundShapes[ math.random( 1, #foundShapes + 1 ) ]
				if randomShape then
					--print( "Ingoing -> Request Items from Teleport Pipe: " .. tostring( randomShape["id"] ) )
					local TeleportContainer = randomShape.shape.interactable:getContainer( 0 )
					if TeleportContainer then
						for slot = 0, TeleportContainer:getSize() - 1 do								
							local item = TeleportContainer:getItem( slot )
							if item then
								if item.quantity > 0 and self:filterOk( item.uuid ) then
									if self.UpdatePipeSystem and not HasPipeUpdated then
										HasPipeUpdated = true
										self.UpdatePipeSystem = false
										self:RefreshPipeData( true )
										self:sv_buildPipeNetwork()
									end
									local FindContainerCanCollect = false
									local SelfContainerCanCollect = sm.container.canCollect( self.container, item.uuid, item.quantity )
									local FindContainer = nil
									if self.sv.connectedContainers and self.sv.connectedContainers ~= nil and self.sv.connectedContainers ~= {} then
										FindContainer = FindContainerToCollectTo( self.sv.connectedContainers, item.uuid, item.quantity )
									end					
									if FindContainer then
										FindContainerCanCollect = sm.container.canCollect( FindContainer.shape:getInteractable():getContainer(), item.uuid, item.quantity )
									end		
									if FindContainerCanCollect and parent and parent.active then									
										sm.container.beginTransaction()
										sm.container.collect( FindContainer.shape:getInteractable():getContainer(), item.uuid, item.quantity, true )
										if sm.container.endTransaction() then									
											self.network:sendToClients( "cl_n_onIncomingFire", { shapesOnContainerPath = FindContainer.shapesOnContainerPath, item =  item.uuid } )
											sm.container.beginTransaction()
											sm.container.spend( TeleportContainer, item.uuid, item.quantity, true )
											sm.container.endTransaction()
										end		
									else
										if SelfContainerCanCollect then
											sm.container.beginTransaction()
											sm.container.collect( self.container, item.uuid, item.quantity, true )
											if sm.container.endTransaction() then
												sm.container.beginTransaction()
												sm.container.spend( TeleportContainer, item.uuid, item.quantity, true )
												sm.container.endTransaction()
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
	end

	if self.sv.dirtyStorageTable then
		self.storage:save( self.sv.storage )
		self.sv.dirtyStorageTable = false
	end
	if self.sv.dirtyClientTable then
		self.network:setClientData( { pipeNetwork = self.sv.client.pipeNetwork, state = self.sv.client.state, showBlockVisualization = self.sv.client.showBlockVisualization } )
		self.sv.dirtyClientTable = false
	end
end

function Fant_Teleport_Item_Pipe.client_canCarry( self )
	local container = self.shape.interactable:getContainer( 0 )
	if container and sm.exists( container ) then
		return not container:isEmpty()
	end
	return false
end


function Fant_Teleport_Item_Pipe.server_canErase( self )
	if self.filtercontainer and not self.filtercontainer:isEmpty() then
		
		return false
	end
	return true
end

function Fant_Teleport_Item_Pipe.client_canErase( self )
	if self.filtercontainer and not self.filtercontainer:isEmpty() then
		sm.gui.displayAlertText( "#{INFO_BUSY}", 1.5 )
		return false
	end
	return true
end


function Fant_Teleport_Item_Pipe.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use", true )
	sm.gui.setInteractionText( "", keyBindingText, "Inventory" )
	local keyBindingText =  sm.gui.getKeyBinding( "Tinker", true )
	sm.gui.setInteractionText( "", keyBindingText, "Filter" )
	return true
end

function Fant_Teleport_Item_Pipe.client_onInteract(self, character, state)
	if state == true then
		self.gui = sm.gui.createContainerGui( true )
		self.gui:setText( "UpperName", "Teleport Pipe Storage" )
		self.gui:setContainer( "UpperGrid", self.container )		
		self.gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
		self.gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		self.gui:open()
	end
end

function Fant_Teleport_Item_Pipe.client_onTinker( self, character, state )
	if state then
		self.gui = sm.gui.createContainerGui( true )
		self.gui:setText( "UpperName", "Teleport Pipe Filter" )
		self.gui:setContainer( "UpperGrid", self.filtercontainer )
		self.gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
		self.gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		self.gui:open()
	end
end






function Fant_Teleport_Item_Pipe.server_outgoingReload( self, container, item )
	self.sv.foundContainer, self.sv.foundItem = container, item
	local isBlock = sm.item.isBlock( self.sv.foundItem )
	if self.sv.client.showBlockVisualization ~= isBlock then
		self.sv.client.showBlockVisualization = isBlock
		self:sv_markClientTableAsDirty()
	end
	if self.sv.foundContainer then
		self.network:sendToClients( "cl_n_onOutgoingReload", { shapesOnContainerPath = self.sv.foundContainer.shapesOnContainerPath, item = self.sv.foundItem } )
	end
end

function Fant_Teleport_Item_Pipe.server_outgoingReset( self )
	self.sv.foundContainer = nil
	self.sv.foundItem = sm.uuid.getNil()
	if self.sv.client.showBlockVisualization then
		self.sv.client.showBlockVisualization = false
		self:sv_markClientTableAsDirty()
	end
end

function Fant_Teleport_Item_Pipe.server_outgoingShouldReload( self, container, item )
	return self.sv.foundItem ~= item
end

function Fant_Teleport_Item_Pipe.cl_n_onOutgoingFire( self, data )
	if data.shapesOnContainerPath then
		table.insert( data.shapesOnContainerPath, self.shape )
	end		
end

function Fant_Teleport_Item_Pipe.cl_n_onOutgoingReload( self, data )
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
	local shapeList = {}
	for idx, shape in reverse_ipairs( data.shapesOnContainerPath ) do
		table.insert( shapeList, shape )
	end
	table.insert( shapeList, self.shape )
	self.cl.pipeEffectPlayer:pushShapeEffectTask( shapeList, data.item )
end

function Fant_Teleport_Item_Pipe.client_onCreate( self )
	self.cl = {}
	self.cl.pipeNetwork = {}
	self.cl.state = PipeState.off
	self.cl.showBlockVisualization = false
	self.cl.overrideUvFrameIndexTask = nil
	self.cl.poseAnimTask = nil
	self.cl.pipeEffectPlayer = PipeEffectPlayer()
	self.cl.pipeEffectPlayer:onCreate()
	self.network:sendToServer( "GetData" )
end

function Fant_Teleport_Item_Pipe.GetData( self )	
	self.network:sendToClients( "SetData", { container = self.container, filtercontainer = self.filtercontainer } )	
end

function Fant_Teleport_Item_Pipe.SetData( self, data )
	self.container = data.container
	self.filtercontainer = data.filtercontainer
end

function Fant_Teleport_Item_Pipe.client_onUpdate( self, dt )
	self:cl_updateUvIndexFrames( dt )
	self.cl.pipeEffectPlayer:update( dt )
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

function Fant_Teleport_Item_Pipe.cl_n_onIncomingFire( self, data )
	table.insert( data.shapesOnContainerPath, 1, self.shape )
	self.cl.pipeEffectPlayer:pushShapeEffectTask( data.shapesOnContainerPath, data.item )
	self:cl_setOverrideUvIndexFrame( data.shapesOnContainerPath, PipeState.valid )
	self:cl_setPoseAnimTask( "incomingFire" )
end

function Fant_Teleport_Item_Pipe.cl_setPoseAnimTask( self, name )
	self.cl.poseAnimTask = { name = name, progress = 0 }
end

function Fant_Teleport_Item_Pipe.sv_buildPipeNetwork( self )
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
	--table.sort( self.sv.connectedContainers, function(a, b) return a.distance < b.distance end )
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
	--print( self.shape["id"] .. "sv_buildPipeNetwork")
end

function Fant_Teleport_Item_Pipe.sv_markClientTableAsDirty( self )
	self.sv.dirtyClientTable = true
end

function Fant_Teleport_Item_Pipe.sv_markStorageTableAsDirty( self )
	self.sv.dirtyStorageTable = true
	self:sv_markClientTableAsDirty()
end

function Fant_Teleport_Item_Pipe.cl_pushEffectTask( self, shapeList, effect )
	self.cl.pipeEffectPlayer:pushEffectTask( shapeList, effect )
end

function Fant_Teleport_Item_Pipe.client_onClientDataUpdate( self, clientData )
	if #clientData.pipeNetwork > 0 then
		assert( clientData.state )
	end
	self.cl.pipeNetwork = clientData.pipeNetwork
	self.cl.state = clientData.state
	self.cl.showBlockVisualization = clientData.showBlockVisualization
end

function Fant_Teleport_Item_Pipe.cl_n_onError( self, data )
	self:cl_setOverrideUvIndexFrame( data.shapesOnContainerPath, PipeState.invalid )
end

PoseCurves = {}
PoseCurves["outgoingFire"] = Curve()
PoseCurves["outgoingFire"]:init({{v=0.5, t=0.0},{v=1.0, t=0.1},{v=0.5, t=0.2},{v=0.0, t=0.3},{v=0.5, t=0.6}})
PoseCurves["incomingFire"] = Curve()
PoseCurves["incomingFire"]:init({{v=0.5, t=0.0},{v=0.0, t=0.1},{v=0.5, t=0.2},{v=1.0, t=0.3},{v=0.5, t=0.6}})


function Fant_Teleport_Item_Pipe.cl_setOverrideUvIndexFrame( self, shapeList, state )
	local shapeMap = {}
	if shapeList then
		for _, shape in ipairs( shapeList ) do
			shapeMap[shape:getId()] = state
		end
	end
	self.cl.overrideUvFrameIndexTask = { shapeMap = shapeMap, state = state, progress = 0 }
end

local GlowCurve = Curve()
GlowCurve:init({{v=1.0, t=0.0}, {v=0.5, t=0.05}, {v=0.0, t=0.1}, {v=0.5, t=0.3}, {v=1.0, t=0.4}, {v=0.5, t=0.5}, {v=0.0, t=0.7}, {v=0.5, t=0.75}, {v=1.0, t=0.8}})


function Fant_Teleport_Item_Pipe.cl_updateUvIndexFrames( self, dt )

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

	assert( state > 0 and state <= 4 )


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



