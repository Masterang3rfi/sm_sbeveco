Fant_Mod_Base = class()
Fant_Mod_Base_Added = false

local oldEffect = sm.effect.createEffect
function effectHook(name, obj, bone)
    if not Fant_Mod_Base_Added and name == "SurvivalMusic" then
		dofile("$CONTENT_61d4b3e3-c5f7-454c-87fb-7a0fff5d91d0/Scripts/vanilla_overrides.lua")
		Fant_Mod_Base_Added = true
    end

	return oldEffect(name, obj, bone)
end
sm.effect.createEffect = effectHook