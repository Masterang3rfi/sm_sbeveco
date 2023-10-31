Fant_Vpump_Controler = class()
Fant_Vpump_Controler.maxParentCount = 2
Fant_Vpump_Controler.connectionInput = sm.interactable.connectionType.logic
Fant_Vpump_Controler.maxChildCount = 255
Fant_Vpump_Controler.connectionOutput = sm.interactable.connectionType.logic

function Fant_Vpump_Controler.server_onCreate( self )
	self.lastActive = false
	self.lastSwitch = false
	self.init = true
	self.container = self.shape:getInteractable():getContainer( 0 )
	if not self.container then
		self.container = self.shape:getInteractable():addContainer( 0, 20, 1 )
	end
end

function Fant_Vpump_Controler.getInputs( self )
	local ActiveButtonInput = false
	local ArrowSwitchInput = false
	for index, parent in pairs( sm.interactable.getParents( self.shape:getInteractable() ) ) do
		if tostring( sm.shape.getColor( sm.interactable.getShape( parent ) ) ) == "d02525ff" then  --Red
			ArrowSwitchInput = parent.active 
		else
			ActiveButtonInput = parent.active 
		end
	end
	return ActiveButtonInput, ArrowSwitchInput
end

function Fant_Vpump_Controler.server_onFixedUpdate( self, dt )
	local Active, Switch = self:getInputs()
	if self.lastActive ~= Active or self.lastSwitch ~= Switch or self.init then
		self.lastActive = Active
		self.lastSwitch = Switch
		self.init = false
		self.interactable:setPublicData( { active = Active, switch = Switch } )
	end
end

function Fant_Vpump_Controler.client_onInteract(self, character, state)
	if state == true then
		self.gui = sm.gui.createContainerGui( true )
		self.gui:setText( "UpperName", "Vacuum Controler" )
		self.gui:setContainer( "UpperGrid", self.shape:getInteractable():getContainer( 0 ) )		
		self.gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
		self.gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		self.gui:open()
	end
end