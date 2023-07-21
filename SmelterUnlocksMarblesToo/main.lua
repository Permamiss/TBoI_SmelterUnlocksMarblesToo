-- Note:	Due to ModCallbacks.MC_USE_PILL not firing before the effect of a pill goes through, I had to do some roundabout noodly code to make this mod work.
--			One side effect of this is that using a normal Gulp! pill will trigger the ModCallback.MC_PRE_USE_ITEM for CollectibleType.COLLECTIBLE_SMELTER 2 times, and using the Smelter will
--			trigger the ModCallback.MC_PRE_USE_ITEM for CollectibleType.COLLECTIBLE_SMELTER 3 times. Sorry, this is the best I could do, hopefully this has no negative side effects on other mods.
--			Any code/item that uses the Smelter (i.e. Gulp!, Marbles) should work according to my testing. If something does not work, sorry.

-- Mod Idea: Intercept the Smelter's "Use" behavior to instead consume a Gulp! pill
local SmelterUnlocksMarblesToo = RegisterMod("SmelterUnlocksMarblesToo", 1)
local justGulped = false
local timer = 0 -- decrements each frame
local playerToGulp = Isaac.GetPlayer(0)

---@param collectibleID CollectibleType
---@param rng RNG
---@param player EntityPlayer
function SmelterUnlocksMarblesToo:OnItemUsed(collectibleID, rng, player) -- return true prevents Active effect from going through
	playerToGulp = player or Isaac.GetPlayer(0)

	-- return true unless justGulped == true, and wait 1-5 frames to see if a Gulp pill was used; if no Gulp pill used then perform a UsePill
	if not justGulped then
		timer = 2 -- triggers code in OnUpdate; has to be 2 rather than 1 or else Gulp! gets triggered twice in some cases
		return true
	end
end

function SmelterUnlocksMarblesToo:OnUpdate()
	if timer > 0 then -- decrement timer and check if a Gulp! pill has been used
		timer = timer - 1
		
		if timer ~= 0 then
			if justGulped then
				timer = 0
				playerToGulp:UseActiveItem(CollectibleType.COLLECTIBLE_SMELTER) -- triggers OnItemUsed and allows the Smelter to be used normally
				justGulped = false
			end
		else -- if reached end of timer and still no Gulp! pill usage detected, then consider it traditional Smelter Item usage and use a Gulp pill instead
			playerToGulp:UsePill(PillEffect.PILLEFFECT_GULP, PillColor.PILL_NULL, UseFlag.USE_NOANIM + UseFlag.USE_NOANNOUNCER + UseFlag.USE_NOHUD) -- make sure this only activates on a temporary condition, or else it will crash game with infinite recursion
		end
	end
end

---@param pillEffectID PillEffect
function SmelterUnlocksMarblesToo:OnGulpPillUsed(pillEffectID) -- sadly this is detected *after* the pill effect actually goes through
	justGulped = true
end

SmelterUnlocksMarblesToo:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, SmelterUnlocksMarblesToo.OnItemUsed, CollectibleType.COLLECTIBLE_SMELTER)
SmelterUnlocksMarblesToo:AddCallback(ModCallbacks.MC_POST_UPDATE, SmelterUnlocksMarblesToo.OnUpdate)
SmelterUnlocksMarblesToo:AddCallback(ModCallbacks.MC_USE_PILL, SmelterUnlocksMarblesToo.OnGulpPillUsed, PillEffect.PILLEFFECT_GULP)