Fant_Trashcan = class( nil )
Fant_Trashcan.maxParentCount = 1
Fant_Trashcan.connectionInput = sm.interactable.connectionType.logic
Fant_Trashcan.colorNormal = sm.color.new( 0x0000680ff )
Fant_Trashcan.colorHighlight = sm.color.new( 0x0000ff0ff )

function Fant_Trashcan.server_onCreate( self )
	self.container = self.shape.interactable:getContainer( 0 )
	if not self.container then
		self.container = self.shape:getInteractable():addContainer( 0, 1, 256 )
	end
end

function Fant_Trashcan.server_onFixedUpdate( self, dt )
	local parent = self.interactable:getSingleParent()
	if parent ~= nil then
		if parent:isActive() == false then
			return
		end
	end
	if self.container == nil then
		self.container = self.shape:getInteractable():getContainer()
	end
	if self.container ~= nil then
		local item = self.container:getItem( 0 )
		if item ~= nil then
			if item.quantity ~= nil then
				if item.quantity > 0 then
					sm.container.beginTransaction()
					sm.container.spend( self.container, item.uuid, item.quantity, true )
					sm.container.endTransaction()
				end
			end
		end
	end
end

function Fant_Trashcan.client_onInteract(self, character, state)
	if state == true then
		self.cl_container = self.shape:getInteractable():getContainer()
		self.gui = sm.gui.createContainerGui( true )	
		self.gui:setText( "UpperName", "Trash can" )
		self.gui:setContainer( "UpperGrid", self.cl_container )			
		self.gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
		self.gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		self.gui:open()
	end
end
