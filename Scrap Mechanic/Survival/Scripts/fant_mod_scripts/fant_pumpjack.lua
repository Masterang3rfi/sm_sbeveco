Fant_Pumpjack = class( nil )

local AnimationSpeed = 0.5
local RefillSpeed = 2

g_Pumpjacks = g_Pumpjacks or {}

local FluidTypes =  {}
FluidTypes[ #FluidTypes + 1 ] = obj_consumable_chemical
FluidTypes[ #FluidTypes + 1 ] = obj_consumable_water
FluidTypes[ #FluidTypes + 1 ] = obj_resource_crudeoil


function Fant_Pumpjack.server_onCreate( self )
	self.data = self.storage:load()
	--print( self.data ) 
	if self.data == nil then
		self.data = { g_Pumpjacks = g_Pumpjacks, mode = "water" }
	end
	if g_Pumpjacks == nil then
		g_Pumpjacks = {}
	end
	if self.data.g_Pumpjacks ~= nil and self.data.g_Pumpjacks ~= {} then
		local newList = {}
		for i, k in pairs( self.data.g_Pumpjacks ) do 
			newList[ i ] = k
		end
		for i, k in pairs( g_Pumpjacks ) do 
			newList[ i ] = k
		end
		g_Pumpjacks = newList
	end
	self.isPumpjack = false
	self.id = self:getPos()
	
	if self.shape:getShapeUuid() == obj_interactive_fant_pumpjack then
		self.isPumpjack = true
		self.type = "empty"
		self.init = true	
		self.run = false
		self.areaTrigger = sm.areaTrigger.createAttachedBox( self.shape:getInteractable(), sm.vec3.new( 1, 1, 1 ), sm.vec3.new(0.0, 0, 0.0), sm.quat.identity(), sm.areaTrigger.filter.all )			

		g_Pumpjacks[ tostring( self.id ) ] = { type = self.type }
	else
		self.container = self.shape.interactable:getContainer( 0 )
		if not self.container then
			self.container = self.shape:getInteractable():addContainer( 0, 5, 256 )
		end
		self.refillTimer = 0
		
		g_Pumpjacks[ tostring( self.id ) ] = { type = "outlet_"..self.data.mode }
		self.container:setFilters( FluidTypes )
	end
	
	
	self.loaded = true
	self.data.g_Pumpjacks = g_Pumpjacks
	self.storage:save( self.data )
	--print( "g_Pumpjacks", g_Pumpjacks )	
end

function Fant_Pumpjack.server_onUnload( self )
	if self.loaded then
		self.loaded = false
	end
end

function Fant_Pumpjack.server_onDestroy( self )
	if self.loaded then
		g_Pumpjacks[ tostring( self.id ) ] = "empty"			
	end	
	self.data.g_Pumpjacks = g_Pumpjacks
	self.storage:save( self.data )
end

function Fant_Pumpjack.server_onFixedUpdate( self, dt )
	if not self.shape:getBody():isStatic() then
		return
	end
	self:Init()
	
	if not self.isPumpjack then
		self.refillTimer = self.refillTimer - ( dt * RefillSpeed )
		if self.refillTimer <= 0 then
			self.refillTimer = 1

			local hasSource = false
			local WaterPumps = 0
			local ChemicalPumps = 0
			local OilPumps = 0
			local WaterOutlets = 0
			local ChemicalOutlets = 0
			local OilOutlets = 0
			
			for i, k in pairs( g_Pumpjacks ) do
				if k.type == self.data.mode then
					hasSource = true				
				end
				if k.type == "water" then
					WaterPumps = WaterPumps + 1			
				end
				if k.type == "chemical" then
					ChemicalPumps = ChemicalPumps + 1			
				end
				if k.type == "oil" then
					OilPumps = OilPumps + 1			
				end
				if k.type == "outlet_water" then
					WaterOutlets = WaterOutlets + 1			
				end
				if k.type == "outlet_chemical" then
					ChemicalOutlets = ChemicalOutlets + 1			
				end
				if k.type == "outlet_oil" then
					OilOutlets = OilOutlets + 1			
				end
			end			
			local Pumpamount = 20
			local typeUUID = nil
			
			if self.data.mode == "water" then
				typeUUID = obj_consumable_water
				if WaterPumps > 0 and WaterOutlets > 0 then
					Pumpamount = Pumpamount * WaterPumps
					Pumpamount = Pumpamount / WaterOutlets
				end
			end
			if self.data.mode == "chemical" then
				typeUUID = obj_consumable_chemical		
				if ChemicalPumps > 0 and ChemicalOutlets > 0 then
					Pumpamount = Pumpamount * ChemicalPumps
					Pumpamount = Pumpamount / ChemicalOutlets
				end
			end
			if self.data.mode == "oil" then
				typeUUID = obj_resource_crudeoil	
				if OilPumps > 0 and OilOutlets > 0 then
					Pumpamount = Pumpamount * OilPumps
					Pumpamount = Pumpamount / OilOutlets
				end
			end
			
			if typeUUID ~= nil and hasSource then
				for i = 1, WaterPumps + ChemicalPumps + OilPumps do
					if not self.container:canCollect( typeUUID, Pumpamount ) and Pumpamount > 20 then
						Pumpamount = Pumpamount - 20
					end
				end
				sm.container.beginTransaction()
				sm.container.collect( self.container, typeUUID, Pumpamount, true )
				sm.container.endTransaction()
			end		
			-- print( "Pumpjack Data" )
			-- print( "WaterPumps", WaterPumps )
			-- print( "ChemicalPumps", ChemicalPumps )
			-- print( "OilPumps", OilPumps )
			-- print( "WaterOutlets", WaterOutlets )
			-- print( "ChemicalOutlets", ChemicalOutlets )
			-- print( "OilOutlets", OilOutlets )
			-- print( "hasSource", hasSource )
		end
	end
end

function Fant_Pumpjack.client_onCreate(self)
	if self.shape:getShapeUuid() == obj_interactive_fant_pumpjack then
		self.interactable:setAnimEnabled( "pumping", true )	
		self.interactable:setAnimProgress( "pumping", 0 )
		self.animationTime = 0
		self.cl_run = false
		self.cl_mode = "nil"
	end		
	self.network:sendToServer( "sv_getData" )
end

function Fant_Pumpjack.sv_getData( self )
	self.network:sendToClients( "cl_setData", { run = self.run, mode = self.data.mode } )
end

function Fant_Pumpjack.cl_setData( self, data )
	self.cl_run = data.run
	self.cl_mode = data.mode
end

function Fant_Pumpjack.client_onDestroy(self)

end

function Fant_Pumpjack.client_onUpdate(self, dt)
	if self.shape:getShapeUuid() == obj_interactive_fant_pumpjack then
		if self.cl_run then
			self.animationTime = self.animationTime + ( dt * AnimationSpeed )
			if self.animationTime > 1 then
				self.animationTime = 0
				local offset = self.shape:getAt() * 1
				sm.effect.playEffect( "Steam - quench", self.shape.worldPosition + offset, sm.vec3.new( 0, 0, 0 ), self.shape.worldRotation )
			end
			local animationTimer = math.floor( self.animationTime * 100 ) / 100
			self.interactable:setAnimProgress( "pumping", animationTimer )
			--print(  animationTimer )
		end
	end
end

function Fant_Pumpjack.getPos( self )
	local x = math.floor( self.shape.worldPosition.x * 10 ) / 10
	local y = math.floor( self.shape.worldPosition.y * 10 ) / 10
	local z = math.floor( self.shape.worldPosition.z * 10 ) / 10
	return sm.vec3.new( x, y, z )
end

function Fant_Pumpjack.Init( self )
	if self.init then
		if self.isPumpjack then
			for _, result in ipairs( self.areaTrigger:getContents() ) do
				if sm.exists( result ) then			
					if type( result ) == "AreaTrigger" then				
						local userData = result:getUserData()
						if userData then							
							if userData.water == true then
								self.type = "water"														
							end
							if userData.chemical == true then
								self.type = "chemical"
							end
							if userData.oil == true then
								self.type = "oil"
							end
							
						end
					end
				end			
			end	
			if self.type ~= "empty" then			
				self.init = false
				self.run = true
				self.network:sendToClients( "cl_setData", { run = self.run } )
				
				g_Pumpjacks[ tostring( self.id ) ] = { type = self.type }
				self.data.g_Pumpjacks = g_Pumpjacks
				self.storage:save( self.data )
				self.loaded = true
				--print( "g_Pumpjacks", g_Pumpjacks )
			end
		end
	end
end

function Fant_Pumpjack.client_canInteract( self, character )
	if self.isPumpjack then
		local keyBindingText2 =  sm.gui.getKeyBinding( "Tinker", true )
		sm.gui.setInteractionText( "", keyBindingText2,  "Ignore Me" )
		return false
	end
	if self.cl_mode == nil then
		self.cl_mode = "water"
	end
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use", true )
	sm.gui.setInteractionText( "", keyBindingText, "Inventory"  )

	local keyBindingText2 =  sm.gui.getKeyBinding( "Tinker", true )
	sm.gui.setInteractionText( "", keyBindingText2,  "Fluid: " .. self.cl_mode )
	return true
end

function Fant_Pumpjack.client_onInteract(self, character, state)
	if self.isPumpjack then
		return true
	end
	if state == true then
		self.cl_container = self.shape:getInteractable():getContainer()
		self.gui = sm.gui.createContainerGui( true )	
		self.gui:setText( "UpperName", "Pumpjack Out" )
		self.gui:setContainer( "UpperGrid", self.cl_container )			
		self.gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
		self.gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		self.gui:open()
	end
end

function Fant_Pumpjack.client_onTinker( self, character, state )
	if self.isPumpjack then
		return false
	end
	if state == true then	
		self.network:sendToServer( "sv_changeMode" )	
	end
end

function Fant_Pumpjack.sv_changeMode( self )
	if self.data.mode == "water" then
		self.data.mode = "chemical"
		self.container:setFilters( { obj_consumable_chemical } )
	elseif self.data.mode == "chemical" then
		self.data.mode = "oil"
		self.container:setFilters( { obj_resource_crudeoil } )
	else
		self.data.mode = "water"
		self.container:setFilters( { obj_consumable_water } )
	end
	self.network:sendToClients( "cl_setMode", { mode = self.data.mode } )	
	g_Pumpjacks[ tostring( self.id ) ] = { type = "outlet_"..self.data.mode }
	self.data.g_Pumpjacks = g_Pumpjacks
	self.storage:save( self.data )
end

function Fant_Pumpjack.cl_setMode( self, data )
	self.cl_mode = data.mode
end

function Fant_Pumpjack.client_canCarry( self )
	local container = self.shape.interactable:getContainer()
	if container and sm.exists( container ) then
		return not container:isEmpty()
	end
	return false
end

function Fant_Pumpjack.server_canCarry( self )
	local container = self.shape.interactable:getContainer()
	if container and sm.exists( container ) then
		return not container:isEmpty()
	end
	return false
end
