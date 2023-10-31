dofile( "$CONTENT_61d4b3e3-c5f7-454c-87fb-7a0fff5d91d0/Scripts/partUUIDs.lua" )
dofile "$SURVIVAL_DATA/Scripts/game/survival_items.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_survivalobjects.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_constants.lua"
dofile "$SURVIVAL_DATA/Scripts/util.lua"
dofile "$SURVIVAL_DATA/Scripts/game/util/pipes.lua"

Fant_PumpPipe = class()
Fant_PumpPipe.maxParentCount = 1
Fant_PumpPipe.connectionInput = sm.interactable.connectionType.logic

function Fant_PumpPipe.server_onCreate( self )
	self:sv_init()
end

function Fant_PumpPipe.uuidAddCheck( self )
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
		obj_interactive_mcp3,
		sm.uuid.new( "6b1cab58-c103-48cd-8cb3-314cc57cf959" )
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


function Fant_PumpPipe.server_onRefresh( self )
	self.network:setClientData( { pipeGraphs = {} })
	self:sv_init()
end

function Fant_PumpPipe.client_onCreate( self )
	self:cl_init()
end

function Fant_PumpPipe.sv_init( self )
	self:uuidAddCheck()
	self.UpdatebuildPipesAndContainerGraph = true
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { filterItems = nil, AntiFilter = false } 
		self.storage:save( self.sv.storage )
	end
	self.filtercontainer = self.shape:getInteractable():getContainer(1)
	if not self.filtercontainer then
		self.filtercontainer = self.shape:getInteractable():addContainer( 0, 30, 1 )
	end
	if self.sv.storage.filterItems ~= nil then
		sm.container.beginTransaction()
		for i, filterItem in pairs( self.sv.storage.filterItems ) do
			sm.container.setItem( self.filtercontainer, i - 1, filterItem.uuid, 1 )
		end
		if sm.container.endTransaction() then
		end
	end
	self.sv.clientDataDirty = false
	self:sv_buildPipesAndContainerGraph()
	self.pumpTimer = 0
	self.network:sendToClients( "cl_filterSwitch", self.sv.storage.AntiFilter )
end

function Fant_PumpPipe.sv_markClientDataDirty( self )
	self.sv.clientDataDirty = true
end

function Fant_PumpPipe.sv_sendClientData( self )
	if self.sv.clientDataDirty == true then
		local count = 0
		for i, k in pairs( self.sv.pipeGraphs ) do
			for i2, k2 in pairs( k ) do
				for i3, k3 in pairs( k2 ) do
					count = count + 1
				end
			end
		end
		--print( count )
		if count < 100 then
			self.network:setClientData( { pipeGraphs = self.sv.pipeGraphs } )
		else
			self.network:setClientData( { pipeGraphs = {} } )
		end
		
	end
	self.sv.clientDataDirty = false
end

function Fant_PumpPipe.sv_buildPipesAndContainerGraph( self )
	if self.UpdatebuildPipesAndContainerGraph == nil then
		return
	end
	self.UpdatebuildPipesAndContainerGraph = nil
	self.sv.pipeGraphs = { output = { containers = {}, pipes = {} }, input = { containers = {}, pipes = {} } }
	local function fnOnContainerWithFilter( vertex, parent, fnFilter, graph )
		local container = {
			shape = vertex.shape,
			distance = vertex.distance,
			shapesOnContainerPath = vertex.shapesOnPath
		}
		if parent.distance == 0 then
			local shapeInCrafterPos = parent.shape:transformPoint( vertex.shape:getWorldPosition() )
			if not fnFilter( shapeInCrafterPos.z ) then
				return false
			end
		end
		table.insert( graph.containers, container )
		return true
	end
	local function fnOnPipeWithFilter( vertex, parent, fnFilter, graph )
		local pipe = {
			shape = vertex.shape,
			state = PipeState.off
		}
		if parent.distance == 0 then
			local shapeInCrafterPos = parent.shape:transformPoint( vertex.shape:getWorldPosition() )
			if not fnFilter( shapeInCrafterPos.z ) then
				return false
			end
		end
		table.insert( graph.pipes, pipe )
		return true
	end
	local function fnOnVertex( vertex, parent )
		if isAnyOf( vertex.shape:getShapeUuid(), ContainerUuids ) then -- Is Container
			assert( vertex.shape:getInteractable():getContainer() )
			return fnOnContainerWithFilter( vertex, parent, function( value ) return value > 0 end, self.sv.pipeGraphs["input"] )
		elseif isAnyOf( vertex.shape:getShapeUuid(), PipeUuids ) then -- Is Pipe
			return fnOnPipeWithFilter( vertex, parent, function( value ) return value > 0 end, self.sv.pipeGraphs["input"] )
		end
		return true
	end
	ConstructPipedShapeGraph( self.shape, fnOnVertex )
	local function fnOnVertex( vertex, parent )
		if isAnyOf( vertex.shape:getShapeUuid(), ContainerUuids ) then -- Is Container
			assert( vertex.shape:getInteractable():getContainer() )
			return fnOnContainerWithFilter( vertex, parent, function( value ) return value <= 0 end, self.sv.pipeGraphs["output"] )
		elseif isAnyOf( vertex.shape:getShapeUuid(), PipeUuids ) then -- Is Pipe
			return fnOnPipeWithFilter( vertex, parent, function( value ) return value <= 0 end, self.sv.pipeGraphs["output"] )
		end
		return true
	end
	ConstructPipedShapeGraph( self.shape, fnOnVertex )
	table.sort( self.sv.pipeGraphs["input"].containers, function(a, b) return a.distance < b.distance end )
	table.sort( self.sv.pipeGraphs["output"].containers, function(a, b) return a.distance < b.distance end )
	for _, container in ipairs( self.sv.pipeGraphs["input"].containers ) do
		for _, shape in ipairs( container.shapesOnContainerPath ) do
			for _, pipe in ipairs( self.sv.pipeGraphs["input"].pipes ) do
				if pipe.shape:getId() == shape:getId() then
					pipe.state = PipeState.connected
				end
			end
		end
	end
	for _, container in ipairs( self.sv.pipeGraphs["output"].containers ) do
		for _, shape in ipairs( container.shapesOnContainerPath ) do
			for _, pipe in ipairs( self.sv.pipeGraphs["output"].pipes ) do
				if pipe.shape:getId() == shape:getId() then
					pipe.state = PipeState.connected
				end
			end
		end
	end
	self:sv_markClientDataDirty()
end

function Fant_PumpPipe.cl_init( self )
	self.cl = {}
	self.cl.pipeGraphs = { output = { containers = {}, pipes = {} }, input = { containers = {}, pipes = {} } }
	self.cl.pipeEffectPlayer = PipeEffectPlayer()
	self.cl.pipeEffectPlayer:onCreate()
	self.cl_Antifilter = self.cl_Antifilter or false
	self.network:sendToServer( "sv_getFilterContainer" )
end

function Fant_PumpPipe.sv_getFilterContainer( self )
	self.network:sendToClients( "cl_setFilterContainer", self.filtercontainer )
end

function Fant_PumpPipe.cl_setFilterContainer( self, container )
	self.filtercontainer = container
end

function Fant_PumpPipe.client_onClientDataUpdate( self, data )
	self.cl.pipeGraphs = data.pipeGraphs
end

function Fant_PumpPipe.server_onFixedUpdate( self, dt )
	local parents = self.interactable:getParents()
	local isActive = true
	if parents[1] then
		isActive = parents[1]:isActive()
	end
	if self.shape:getBody():hasChanged( sm.game.getCurrentTick() - 1 ) and isActive then
		self.UpdatebuildPipesAndContainerGraph = true
		self:sv_buildPipesAndContainerGraph()
	end
	if isActive then
		if self.pumpTimer > 0 then
			self.pumpTimer = self.pumpTimer - dt
		else
			self:pumpItem()
			self.pumpTimer = 0.25
		end
	else
		self.pumpTimer = 0
	end
	self:sv_sendClientData()
end

function Fant_PumpPipe.client_onUpdate( self, deltaTime )
	if self.cl.pipeGraphs.input then
		LightUpPipes( self.cl.pipeGraphs.input.pipes )
	end
	if self.cl.pipeGraphs.output then
		LightUpPipes( self.cl.pipeGraphs.output.pipes )
	end
	self.cl.pipeEffectPlayer:update( deltaTime )
end

function Fant_PumpPipe.cl_n_FromChest( self, params )
	for _, tbl in ipairs( params ) do
		local shapeList = {}
		for _, shape in reverse_ipairs( tbl.shapesOnContainerPath ) do
			table.insert( shapeList, shape )
		end
		local endNode = PipeEffectNode()
		endNode.shape = self.shape
		endNode.point = sm.vec3.new( 0, 0, 0.0 ) * sm.construction.constants.subdivideRatio
		table.insert( shapeList, endNode )
		self.cl.pipeEffectPlayer:pushShapeEffectTask( shapeList, tbl.itemId )
	end
end

function Fant_PumpPipe.cl_n_ToChest( self, params )
	local startNode = PipeEffectNode()
	startNode.shape = self.shape
	startNode.point = sm.vec3.new( 0, 0, 0.0 ) * sm.construction.constants.subdivideRatio
	table.insert( params.shapesOnContainerPath, 1, startNode)
	self.cl.pipeEffectPlayer:pushShapeEffectTask( params.shapesOnContainerPath, params.itemId )
end

function Fant_PumpPipe.server_canErase( self )
	if self.filtercontainer and not self.filtercontainer:isEmpty() then
		return false
	end
	return true
end

function Fant_PumpPipe.client_canErase( self )
	if self.filtercontainer and not self.filtercontainer:isEmpty() then
		sm.gui.displayAlertText( "#{INFO_BUSY}", 1.5 )
		return false
	end
	return true
end

function Fant_PumpPipe.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use", true )
	sm.gui.setInteractionText( "", keyBindingText, "Filter" )
	local keyBindingText =  sm.gui.getKeyBinding( "Tinker", true )
	sm.gui.setInteractionText( "", keyBindingText, "Anti Filter: " .. tostring( self.cl_Antifilter ) )
	return true
end

function Fant_PumpPipe.client_onInteract(self, character, state)
	if state == true then
		if self.filtercontainer == nil then
			self.network:sendToServer( "sv_getFilterContainer" )
		end
		if self.filtercontainer ~= nil then
			self.gui = sm.gui.createContainerGui( true )
			self.gui:setText( "UpperName", "Pumppipe Filter" )
			self.gui:setContainer( "UpperGrid", self.filtercontainer )
			self.gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
			self.gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
			self.gui:setOnCloseCallback( "cl_onClose" )
			self.gui:open()
		end
	end
end

function Fant_PumpPipe.client_onTinker( self, character, state )
	if state then
		self.network:sendToServer( "sv_filterSwitch" )
	end
end

function Fant_PumpPipe.sv_filterSwitch( self )
	self.sv.storage.AntiFilter = not self.sv.storage.AntiFilter
	self.network:sendToClients( "cl_filterSwitch", self.sv.storage.AntiFilter )
	self:server_save()
end

function Fant_PumpPipe.cl_filterSwitch( self, state )
	self.cl_Antifilter = state
end

function Fant_PumpPipe.cl_onClose( self )
	self.network:sendToServer( "server_save" )
end

function Fant_PumpPipe.FilterAllowItem( self, uuid )
	if self.filtercontainer then
		if not self.filtercontainer:isEmpty() then
			for slot = 0, self.filtercontainer:getSize() do									
				local filterItem = self.filtercontainer:getItem( slot )
				if filterItem ~= nil then
					if filterItem.quantity > 0 then
						if filterItem.uuid == uuid then
							return not self.sv.storage.AntiFilter
						end
					end
				end
			end
		else
			return not self.sv.storage.AntiFilter
		end
	end
	return self.sv.storage.AntiFilter
end

function Fant_PumpPipe.pumpItem( self )
	local containerArray = {}
	local hasInputContainers = #self.sv.pipeGraphs.input.containers > 0
	if hasInputContainers then
		for _, container in ipairs( self.sv.pipeGraphs.input.containers ) do
			if container.shape ~= nil and sm.exists( container.shape ) then
				local findContainer = container.shape:getInteractable():getContainer()
				if findContainer ~= nil and sm.exists( findContainer ) then
					if not findContainer:isEmpty() then
						for slot = 0, findContainer:getSize() do									
							local item = findContainer:getItem( findContainer:getSize() - slot )
							if item ~= nil then
								if item.quantity > 0 then
									if item ~= nil then
										if self:FilterAllowItem( item.uuid ) then	
											local containerObj = FindContainerToCollectTo( self.sv.pipeGraphs["output"].containers, item.uuid, item.quantity )
											if containerObj and containerObj.shape:getInteractable():getContainer() ~= findContainer then
												if sm.container.canCollect( containerObj.shape:getInteractable():getContainer(), item.uuid, item.quantity ) and sm.container.canSpend( container.shape:getInteractable():getContainer(), item.uuid, item.quantity ) then
													sm.container.beginTransaction()
													sm.container.collect( containerObj.shape:getInteractable():getContainer(), item.uuid, item.quantity )
													if sm.container.endTransaction() then
														self.network:sendToClients( "cl_n_ToChest", { shapesOnContainerPath = containerObj.shapesOnContainerPath, itemId = item.uuid } )						
														sm.container.beginTransaction()
														if item ~= nil then
															table.insert( containerArray, { shapesOnContainerPath = container.shapesOnContainerPath, itemId = item.uuid } )
															sm.container.spend( container.shape:getInteractable():getContainer(), item.uuid, item.quantity , true )
														end
														if sm.container.endTransaction() then
															self:sv_markClientDataDirty()
															if #containerArray > 0 then
																self.network:sendToClients( "cl_n_FromChest", containerArray )
															end		
															return
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
		end
	end
end

function Fant_PumpPipe.server_onDestroy( self )
	self:server_save()
end

function Fant_PumpPipe.server_save( self )
	self.sv.storage.filterItems = nil
	if self.filtercontainer ~= nil and sm.exists( self.filtercontainer ) then
		if not self.filtercontainer:isEmpty() then
			self.sv.storage.filterItems = {}
			for slot = 0, self.filtercontainer:getSize() do									
				local filterItem = self.filtercontainer:getItem( slot )
				if filterItem ~= nil then
					if filterItem.quantity > 0 then
						table.insert( self.sv.storage.filterItems, filterItem )
					end
				end
			end
		end
	end
	self.storage:save( self.sv.storage )
end
