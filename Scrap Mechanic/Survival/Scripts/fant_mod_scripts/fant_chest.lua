dofile( "$SURVIVAL_DATA/Scripts/game/util/Curve.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/util/pipes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_loot.lua")

Fant_Chest = class()
Fant_Chest.poseWeightCount = 1
Fant_Chest.maxParentCount = 1
Fant_Chest.connectionInput = sm.interactable.connectionType.logic
Fant_Chest.maxChildCount = 255
Fant_Chest.connectionOutput = sm.interactable.connectionType.logic
Fant_Chest.CollectDelay = 40
Fant_Chest.colorNormal = sm.color.new( 0x808000ff )
Fant_Chest.colorHighlight = sm.color.new( 0xffff00ff )

Fant_Chest.DisplayIndexes = {}
Fant_Chest.DisplayIndexes[ "off" ] = 0
Fant_Chest.DisplayIndexes[ "no_blueprint" ] = 1
Fant_Chest.DisplayIndexes[ "no_materials" ] = 2
Fant_Chest.DisplayIndexes[ "no_inventory_space" ] = 3
Fant_Chest.DisplayIndexes[ "ready" ] = 4
Fant_Chest.DisplayIndexes[ "0" ] = 5
Fant_Chest.DisplayIndexes[ "0.1" ] = 6
Fant_Chest.DisplayIndexes[ "0.2" ] = 7
Fant_Chest.DisplayIndexes[ "0.3" ] = 8
Fant_Chest.DisplayIndexes[ "0.4" ] = 9
Fant_Chest.DisplayIndexes[ "0.5" ] = 10
Fant_Chest.DisplayIndexes[ "0.6" ] = 11
Fant_Chest.DisplayIndexes[ "0.7" ] = 12
Fant_Chest.DisplayIndexes[ "0.8" ] = 13
Fant_Chest.DisplayIndexes[ "0.9" ] = 14
Fant_Chest.DisplayIndexes[ "1" ] = 15

function Fant_Chest.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { filterItem = nil } 
		self.storage:save( self.sv.storage )
	end
	self.filterItem = self.sv.storage.filterItem
	self.timer = 0
	self.cl_timer = 0
	self.container = self.shape:getInteractable():getContainer(0)
	if not self.container then
		self.container = self.shape:getInteractable():addContainer( 0, 25, 256 )
	end
	self.container:setFilters( {} )
	self.filtercontainer = self.shape:getInteractable():getContainer(1)
	if not self.filtercontainer then
		self.filtercontainer = self.shape:getInteractable():addContainer( 0, 1, 1 )
	end
	
	if self.filterItem ~= nil then
		sm.container.beginTransaction()
		sm.container.setItem( self.filtercontainer, 0, self.filterItem, 1 )
		if sm.container.endTransaction() then
			--print( "Smart Chest Filter Item Loaded: "..tostring(self.filterItem) )
		end
	end	
	self.HasError = false
	self.loadDelay = 2
	self.sv.client = {}
	self.sv.client.pipeNetwork = {}
	self.sv.client.state = PipeState.off
	self.sv.client.showBlockVisualization = false
	self.sv.dirtyClientTable = false
	self.sv.dirtyStorageTable = false
	self.sv.connectedContainers = {}
	self.sv.foundItem = sm.uuid.getNil()
	self.sv.foundContainer = nil
	self:sv_buildPipeNetwork()
	self.sv.ChangedPipPipeNetwork = false
end

function Fant_Chest.client_onCreate( self )
	--self.sv = {}
	self.timer = 0
	self.cl_timer = 0
	self.network:sendToServer( "GetData" )
	
	self.cl = {}
	self.cl.pipeNetwork = {}
	self.cl.state = PipeState.off
	self.cl.showBlockVisualization = false
	self.cl.pipeEffectPlayer = PipeEffectPlayer()
	self.cl.pipeEffectPlayer:onCreate()
	self.displayIndex = 0
end

function Fant_Chest.GetData( self )	
	self.network:sendToClients( "SetData", { container = self.container, filtercontainer = self.filtercontainer, filterItem = self.filterItem } )	
end

function Fant_Chest.SetData( self, data )
	self.container = data.container
	self.filtercontainer = data.filtercontainer
	self.filterItem = data.filterItem
end

function Fant_Chest.server_onDestroy( self )
	--print( "Smart Chest Unloaded")
	self.sv.storage = { filterItem = self.filterItem } 
	self.storage:save( self.sv.storage )
end

function Fant_Chest.SortChest( self )
	local container = self.shape:getInteractable():getContainer(0)
	if container then
		if not container:isEmpty() then
			local sortedItems = {}
			sm.container.beginTransaction()
			for slot_a = 0, container:getSize() do									
				local item_a = container:getItem( slot_a )
				if item_a then
					if item_a.quantity > 0 then
						for slot_b = slot_a, container:getSize() do			
							local item_b = container:getItem( slot_b )
							if item_b then
								if item_b.quantity > 0 then
									if item_a.uuid == item_b.uuid then
										table.insert( sortedItems, item_b )
										sm.container.setItem( container, slot_b, sm.uuid.getNil(), 0 )
									end
								end
							end
						end
					end
				end
			end
			sm.container.endTransaction()
			-- print("____________________")
			-- for index, item in pairs( sortedItems ) do				
				-- print( index, item.uuid )
			-- end
			sm.container.beginTransaction()
			for index, item in pairs( sortedItems ) do				
				sm.container.collect( container, item.uuid, item.quantity, true )
			end
			sm.container.endTransaction()
		end
	end
end

function Fant_Chest.server_onFixedUpdate( self )
	if self.timer < 1 then
		self.timer = self.timer + 0.04
		
	else
		self.timer = 0
		if getContainerFillValue( self ) < 1 then
			sm.interactable.setActive( self.interactable, false )
		else		
			sm.interactable.setActive( self.interactable, true )
		end
		RefreshFilter( self )		
		--self:SortChest()
	end
	
	

	if self.sv.CollectTimer == nil then
		self.sv.CollectTimer = 0
	end
	if self.sv.CollectTimer > 0 then
		self.sv.CollectTimer = self.sv.CollectTimer - 1
	end
	
	local parent = self.shape:getInteractable():getSingleParent()
	
	
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
	
	if parent then
		if parent.active then
			if self.sv.ChangedPipPipeNetwork then
				self:sv_buildPipeNetwork()
				self.sv.ChangedPipPipeNetwork = false
				self.lastChangedPipPipeNetwork = 1
			end
		end
	end
	
	if parent and self.sv.CollectTimer <= 0 then
		if parent.active then			
			local function findFirstContainerAndItem()			
				if self.sv.connectedContainers == nil then
					self:sv_buildPipeNetwork()
					return nil, sm.uuid.getNil(), 0
				end
				for _, container in ipairs( self.sv.connectedContainers ) do
					if sm.exists( container.shape ) then
						if not container.shape:getInteractable():getContainer():isEmpty() then
							for slot = 0, container.shape:getInteractable():getContainer():getSize() - 1 do
								local foundItem = false										
								local item = container.shape:getInteractable():getContainer():getItem( slot )
								if item then
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
									if foundItem then
										if item.quantity > 0 then
											return container, item.uuid, item.quantity
										end
									end
								end
							end
						end
					end
				end
				return nil, sm.uuid.getNil(), 0
			end
			local container, item, amount = findFirstContainerAndItem()
			if self:server_outgoingShouldReload( container, item ) then
				self:server_outgoingReload( container, item )
			end
			if self.sv.foundItem ~= sm.uuid.getNil() and sm.container.canCollect( self.container, self.sv.foundItem, amount )	then					
				sm.container.beginTransaction()
				sm.container.spend( self.sv.foundContainer.shape:getInteractable():getContainer(), self.sv.foundItem, amount, true )
				if sm.container.endTransaction() then
					sm.container.beginTransaction()
					sm.container.collect( self.container, self.sv.foundItem, amount, true)	
					if sm.container.endTransaction() then
						self.network:sendToClients( "cl_n_onOutgoingFire", { shapesOnContainerPath = self.sv.foundContainer.shapesOnContainerPath } )						
					end					
				end		
				self:server_outgoingReset()		
			end
			self.sv.CollectTimer = self.CollectDelay
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

function Fant_Chest.client_canCarry( self )
	local container = self.shape.interactable:getContainer( 0 )
	if container and sm.exists( container ) then
		return not container:isEmpty()
	end
	return false
end

function Fant_Chest.server_canErase( self )
	if self.filtercontainer and not self.filtercontainer:isEmpty() then
		
		return false
	end
	return true
end

function Fant_Chest.client_canErase( self )
	if self.filtercontainer and not self.filtercontainer:isEmpty() then
		sm.gui.displayAlertText( "#{INFO_BUSY}", 1.5 )
		return false
	end
	return true
end

function Fant_Chest.client_onUpdate( self, dt )
	if self.cl_timer < 1 then
		self.cl_timer = self.cl_timer + 0.04
		
	else
		self.cl_timer = 0
		self:cl_setDisplay( getContainerFillValue( self ) )
	end		
	
	
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

function Fant_Chest.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use", true )
	sm.gui.setInteractionText( "", keyBindingText, "Inventory" )
	local keyBindingText =  sm.gui.getKeyBinding( "Tinker", true )
	sm.gui.setInteractionText( "", keyBindingText, "Filter" )
	return true
end

function Fant_Chest.client_onInteract(self, character, state)
	if state == true then
		self.gui = sm.gui.createContainerGui( true )
		self.network:sendToServer( "SortChest" )	
		self.gui:setText( "UpperName", "Smart Chest" )
		self.gui:setContainer( "UpperGrid", self.container )		
		self.gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
		self.gui:setVisible( "TakeAll", true )
		self.gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		self.gui:open()
	end
end

function Fant_Chest.client_onTinker( self, character, state )
	if state then
		self.gui = sm.gui.createContainerGui( true )
		self.gui:setText( "UpperName", "Smart Chest Filter" )
		self.gui:setContainer( "UpperGrid", self.filtercontainer )
		self.gui:setVisible( "TakeAll", true )
		self.gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
		self.gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		self.gui:open()
	end
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
			--print( "Smart Chest Filter Item: "..tostring(self.filterItem ) )
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

function Fant_Chest.cl_FilterFail(self, state )
	if state then
		if self.guiInfo == nil then
			self.guiInfo = sm.gui.createNameTagGui()
		end
		self.guiInfo:setRequireLineOfSight( false )
		self.guiInfo:open()
		self.guiInfo:setMaxRenderDistance( 50 )
		self.guiInfo:setWorldPosition( self.shape.worldPosition + sm.vec3.new( 0, 0, 0 ) )
		self.guiInfo:setText( "Text", "#ff0000".. "Chest Content is differnt to Filter Item.\nClear the Chest or Filter! Filter OFF!" )
	else
		if self.guiInfo then
			self.guiInfo:close()
			self.guiInfo = nil
		end
	end
end

function getContainerFillValue( self )
	if not self.container then
		return 0
	end
	local fillValue = 0
	if not self.container:isEmpty() then
		for slot = 0, self.container:getSize() - 1 do
			local item = self.container:getItem( slot )											
			if item then
				if item.quantity > 0 then
					fillValue = fillValue + 1
				end
			end
		end
	end	
	return fillValue / self.container:getSize()
end


function Fant_Chest.cl_setDisplay( self, displayValue )
	local DisplayIndex = 0
	if displayValue > 0 and displayValue < 0.1 then
		displayValue = 0.1
	end
	local nval = ( math.floor( displayValue * 10 ) / 10 )
	DisplayIndex = self.DisplayIndexes[ tostring( nval ) ]
	if DisplayIndex == 5 then
		DisplayIndex = 2
	end
	if self.displayIndex ~= DisplayIndex then
		self.displayIndex = DisplayIndex
		self.shape:getInteractable():setUvFrameIndex( self.displayIndex )
	end
end


function Fant_Chest.sv_buildPipeNetwork( self )
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
	table.sort( self.sv.connectedContainers, function(a, b) return a.distance < b.distance end )
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

function Fant_Chest.sv_markClientTableAsDirty( self )
	self.sv.dirtyClientTable = true
end

function Fant_Chest.sv_markStorageTableAsDirty( self )
	self.sv.dirtyStorageTable = true
	self:sv_markClientTableAsDirty()
end

function Fant_Chest.server_outgoingReload( self, container, item )
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

function Fant_Chest.server_outgoingReset( self )
	self.sv.foundContainer = nil
	self.sv.foundItem = sm.uuid.getNil()
	if self.sv.client.showBlockVisualization then
		self.sv.client.showBlockVisualization = false
		self:sv_markClientTableAsDirty()
	end
end

function Fant_Chest.server_outgoingShouldReload( self, container, item )
	return self.sv.foundItem ~= item
end

function Fant_Chest.cl_n_onOutgoingFire( self, data )
	if data.shapesOnContainerPath then
		table.insert( data.shapesOnContainerPath, self.shape )
	end		
end

function Fant_Chest.cl_n_onOutgoingReload( self, data )
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

function Fant_Chest.cl_pushEffectTask( self, shapeList, effect )
	self.cl.pipeEffectPlayer:pushEffectTask( shapeList, effect )
end

function Fant_Chest.client_onClientDataUpdate( self, clientData )
	if #clientData.pipeNetwork > 0 then
		assert( clientData.state )
	end
	self.cl.pipeNetwork = clientData.pipeNetwork
	self.cl.state = clientData.state
	self.cl.showBlockVisualization = clientData.showBlockVisualization
end

function Fant_Chest.cl_n_onError( self, data )
	self:cl_setOverrideUvIndexFrame( data.shapesOnContainerPath, PipeState.invalid )
end

function Fant_Chest.cl_setOverrideUvIndexFrame( self, shapeList, state )
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

function Fant_Chest.cl_updateUvIndexFrames( self, dt )

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






