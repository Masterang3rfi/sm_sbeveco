dofile( "$SURVIVAL_DATA/Scripts/game/util/Curve.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/util/pipes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_loot.lua")

Fant_FluidConnector = class()
Fant_FluidConnector.maxChildCount = 255
Fant_FluidConnector.connectionOutput = sm.interactable.connectionType.water + sm.interactable.connectionType.gasoline + sm.interactable.connectionType.electricity + sm.interactable.connectionType.ammo
Fant_FluidConnector.colorNormal = sm.color.new( 0xff8000ff )
Fant_FluidConnector.colorHighlight = sm.color.new( 0xff9f3aff )

local FluidTypes =  {}
FluidTypes[ #FluidTypes + 1 ] = obj_consumable_chemical
FluidTypes[ #FluidTypes + 1 ] = obj_consumable_water
FluidTypes[ #FluidTypes + 1 ] = obj_consumable_gas
FluidTypes[ #FluidTypes + 1 ] = obj_consumable_battery
FluidTypes[ #FluidTypes + 1 ] = obj_plantables_potato
FluidTypes[ #FluidTypes + 1 ] = obj_plantables_banana
FluidTypes[ #FluidTypes + 1 ] = obj_consumable_glowstick

local FluidTypeNames =  {}
FluidTypeNames[ #FluidTypeNames + 1 ] = "Chemical"
FluidTypeNames[ #FluidTypeNames + 1 ] = "Water"
FluidTypeNames[ #FluidTypeNames + 1 ] = "Gas"
FluidTypeNames[ #FluidTypeNames + 1 ] = "Battery"
FluidTypeNames[ #FluidTypeNames + 1 ] = "Potato"
FluidTypeNames[ #FluidTypeNames + 1 ] = "Banana"
FluidTypeNames[ #FluidTypeNames + 1 ] = "Glowstick"


Fant_FluidConnector.PumpAmount = {
	1000,
	100,
	50,
	20,
	10,
	5,
	1
}

function Fant_FluidConnector.server_onCreate( self )
	self.timer = 0
	self.connectedContainer = nil
	self.container = self.shape.interactable:getContainer( 0 )
	if not self.container then
		self.container = self.shape:getInteractable():addContainer( 0, 1, 256 )
	end
	
	
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { mode = 1 } 
		self.storage:save( self.sv.storage )
	end
	
	self.container:setFilters( { FluidTypes[ self.sv.storage.mode ] } )
end

function Fant_FluidConnector.client_onCreate( self )
	self.cl_storage = {}
	self.network:sendToServer( "getStorage" )	
end

function Fant_FluidConnector.getStorage( self )
	self.network:sendToClients( "cl_setStorage", self.sv.storage )	
end

function Fant_FluidConnector.cl_setStorage( self, storage )
	self.cl_storage = storage
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use", true )
	sm.gui.setInteractionText( "", keyBindingText, "PRESS (U)" )
	local keyBindingText =  sm.gui.getKeyBinding( "Tinker", true )
	sm.gui.setInteractionText( "", keyBindingText, "Type: " .. FluidTypeNames[ self.cl_storage.mode ] )
end

function Fant_FluidConnector.server_onDestroy( self )
	self.storage:save( self.sv.storage )
	-- if self.connectedContainer ~= nil then
		-- local item = self.container:getItem( 0 )
		-- if item then
			-- if item.quantity > 0 then
				-- sm.container.beginTransaction()
				-- sm.container.collect( self.connectedContainer, item.uuid, item.quantity, true )
				-- sm.container.endTransaction()
			-- end
		-- end
	-- end
end

function Fant_FluidConnector.server_onFixedUpdate( self, dt )
	if self.timer > 0 then
		self.timer = self.timer - dt
		return
	end
	self.timer = 0.1
	self.connectedContainer = self:getConnectedContainer()
	if self.connectedContainer == nil then
		return
	end
	self.container = self.shape.interactable:getContainer( 0 )
	if self.container == nil then
		return
	end
	for amountindex, amount in pairs( self.PumpAmount ) do 
		for index, fluid in pairs( FluidTypes ) do 
			if sm.container.canCollect( self.container, fluid, amount ) then
				sm.container.beginTransaction()
				sm.container.spend( self.connectedContainer, fluid, amount, true )
				if sm.container.endTransaction() then
					sm.container.beginTransaction()
					sm.container.collect( self.container, fluid, amount, true )
					sm.container.endTransaction()
					return
				end
			end
		end
	end
end

function Fant_FluidConnector.getConnectedContainer( self )
	local Valid, Result = sm.physics.raycast( self.shape:getWorldPosition(), ( self.shape:getWorldPosition() - sm.shape.getUp( self.shape ) * 1.75 ), self.shape )
	if Valid and Result then
		if Result.type == "body" then
			FilterChestShape = Result:getShape()
			if FilterChestShape then
				if FilterChestShape:getInteractable() then
					if FilterChestShape:getInteractable():getContainer() then
						return FilterChestShape:getInteractable():getContainer()				
					end			
				end					
			end
		elseif Result.type == "shape" then
			if Result then
				if Result:getInteractable() then
					if FilterChestShape:getInteractable():getContainer() then
						return FilterChestShape:getInteractable():getContainer()					
					end	
				end
			end
		end		
	end
end

function Fant_FluidConnector.client_canInteract( self, character )
	if self.cl_storage.mode == nil then
		self.cl_storage.mode = 1
	end
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use", true )
	sm.gui.setInteractionText( "", keyBindingText, "PRESS (U)" )
	local keyBindingText =  sm.gui.getKeyBinding( "Tinker", true )
	sm.gui.setInteractionText( "", keyBindingText, "Type: " .. FluidTypeNames[ self.cl_storage.mode ] )
	return true
end

function Fant_FluidConnector.client_onInteract(self, _, state)
	if state == true then	
		
	end
end

function Fant_FluidConnector.client_onTinker( self, character, state )
	if state == true then	
		self.network:sendToServer( "sv_changeMode" )	
	end
end




function Fant_FluidConnector.sv_changeMode( self )
	self.sv.storage.mode = self.sv.storage.mode + 1
	if self.sv.storage.mode > #FluidTypes then
		self.sv.storage.mode = 1
	end
	self.storage:save( self.sv.storage )
	self.network:sendToClients( "cl_setStorage", self.sv.storage )	
	
	
	
	self.connectedContainer = self:getConnectedContainer()
	if self.connectedContainer == nil then
		return
	end
	self.container = self.shape.interactable:getContainer( 0 )
	if self.container == nil then
		return
	end
	for amountindex, amount in pairs( self.PumpAmount ) do 
		for index, fluid in pairs( FluidTypes ) do 
			if sm.container.canCollect( self.connectedContainer, fluid, amount ) then
				sm.container.beginTransaction()
				sm.container.spend( self.container, fluid, amount, true )
				if sm.container.endTransaction() then
					sm.container.beginTransaction()
					sm.container.collect( self.connectedContainer, fluid, amount, true )
					sm.container.endTransaction()					
				end
			end
		end
	end
	
	self.container:setFilters( { FluidTypes[ self.sv.storage.mode ] } )
end