--
hg = hg or {}
hg.WeaponSelector = hg.WeaponSelector or {}
local WS = hg.WeaponSelector

function WS.GetPrintName( self )
	local class = self:GetClass()
	local phrase = language.GetPhrase(class)
	return phrase ~= class and phrase or self:GetPrintName()
end

WS.Show = 0
WS.Transparent = 0
WS.LastSelectedSlot = 0
WS.LastSelectedSlotPos = 0

WS.SelectedSlot = 0
WS.SelectedSlotPos = 0

-- Switch animation variables
WS.Switching = false
WS.SwitchTime = 0
WS.SwitchDuration = 0.3
WS.ScreenShake = 0
WS.BloodSplatter = {}

-- Horror theme colors
local HORROR_RED = Color(180, 20, 20)
local HORROR_DARK_RED = Color(80, 0, 0)
local HORROR_BLOOD = Color(139, 0, 0)
local HORROR_BLACK = Color(10, 5, 5)
local HORROR_GRAY = Color(40, 35, 35)

function WS.DrawText(text, font, posX, posY, color, textAlign)
	-- Blood drip shadow effect
	draw.DrawText( text, font, posX + 3, posY + 4, ColorAlpha(Color(60, 0, 0), WS.Transparent * 200), textAlign )
	-- Main text with glow
	draw.DrawText( text, font, posX, posY, ColorAlpha(color, WS.Transparent * 255), textAlign )
end

function WS.GetSelectedWeapon()
	if not IsValid( LocalPlayer() ) or not LocalPlayer():Alive() then return end
	local Weapons = WS.GetWeaponTable( LocalPlayer() )
	return Weapons[WS.SelectedSlot] and Weapons[WS.SelectedSlot][WS.SelectedSlotPos] or Weapons[WS.LastSelectedSlot][WS.LastSelectedSlotPos] or Weapons[0][0]
end

function WS.GetWeaponTable( ply )
	if not IsValid( ply ) or not ply:Alive() then return end
	local WeaponsGet = ply:GetWeapons()
	local FormatedTable = {
		[0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {},
	}

	table.sort(WeaponsGet, function(a, b) return (a.SlotPos or 0) > (b.SlotPos or 0) end)

	for k,wep in ipairs(WeaponsGet) do
		local tTbl = FormatedTable[wep.Slot or 0]
		local iMinPos = math.min( (wep.SlotPos and wep.SlotPos) or 1, ((#tTbl or 0) + 1)) - 1
		local iPos = tTbl[ iMinPos ] and #tTbl + 1 or iMinPos
		tTbl[ iPos ] = wep
	end
	return FormatedTable
end

local scrW, scrH = ScrW(), ScrH()

-- Using built-in gradient materials that are always available
local gradient_u = Material("vgui/gradient-d")
local gradient_up = Material("vgui/gradient-u")

-- Horror-themed fonts
surface.CreateFont("HorrorWeaponTitle", {
	font = "Courier New",
	size = ScreenScale(10),
	weight = 800,
	antialias = true,
	shadow = true
})

surface.CreateFont("HorrorWeaponSmall", {
	font = "Courier New",
	size = 18,
	weight = 600,
	antialias = true,
	shadow = true
})

-- Blood splatter particles
WS.BloodParticles = WS.BloodParticles or {}

local function AddBloodParticle(x, y)
	table.insert(WS.BloodParticles, {
		x = x + math.random(-20, 20),
		y = y + math.random(-10, 5),
		vx = math.random(-30, 30),
		vy = math.random(-50, -20),
		size = math.random(2, 6),
		life = 1.0,
		alpha = 255
	})
end

-- Flicker effect for horror atmosphere
local function GetFlickerAlpha(baseAlpha)
	local flicker = math.sin(CurTime() * 8) * 0.1 + math.sin(CurTime() * 13.7) * 0.05
	return baseAlpha * (0.85 + flicker * 0.3)
end

-- Glitch offset for selected item
local function GetGlitchOffset()
	local time = CurTime()
	if math.random() < 0.05 then
		return math.random(-3, 3), math.random(-2, 2)
	end
	return 0, math.sin(time * 20) * 0.5
end

function WS.WeaponSelectorDraw( ply, shakeX, shakeY )
	if not IsValid( ply ) or not ply:Alive() then return end
	if WS.Show < CurTime() then 
		WS.SelectedSlot = WS.LastSelectedSlot 
		WS.SelectedSlotPos = -1
		
		return 
	end
	
	local Weapons = WS.GetWeaponTable( ply )
	local SelectedWep = WS.GetSelectedWeapon()
	if not IsValid(SelectedWep) then return end
	
	WS.Transparent = LerpFT( 0.2, WS.Transparent, math.min( WS.Show - CurTime(), 1 ) )
	
	local SuperAmmout = 0
	local AmmoutSlots = 0
	for i = 0, #Weapons do
		local slotTbl = Weapons[i]
		if table.Count(slotTbl) < 1 then continue end
		AmmoutSlots = AmmoutSlots + 1
	end


	for i = 0, #Weapons do
		local slotTbl = Weapons[i]
		if table.Count(slotTbl) < 1 then continue end
		local sizeX = scrW * 0.1
		local position = scrW / 2 + ((SuperAmmout - (AmmoutSlots / 2)) * sizeX)
		
		-- Slot number with blood drip effect
		local slotAlpha = GetFlickerAlpha(WS.Transparent * 255)
		local glitchX, glitchY = 0, 0
		if i == WS.SelectedSlot then
			glitchX, glitchY = GetGlitchOffset()
		end
		
		WS.DrawText(i + 1, "HorrorWeaponTitle", position + sizeX / 2 + glitchX + (shakeX or 0), scrH * 0.02 + glitchY + (shakeY or 0), 
			ColorAlpha(HORROR_RED, slotAlpha), TEXT_ALIGN_CENTER)
		
		-- Blood line under slot number
		if i == WS.SelectedSlot then
			local lineAlpha = GetFlickerAlpha(WS.Transparent * 180)
			surface.SetDrawColor(HORROR_BLOOD.r, HORROR_BLOOD.g, HORROR_BLOOD.b, lineAlpha)
			surface.DrawRect(position + (shakeX or 0), scrH * 0.045 + (shakeY or 0), sizeX, 2)
		end

		local Ammout = 0
		local lastPos = 0
		for Id = 0, #slotTbl do
			local wepId = Id
			local wep = slotTbl[wepId]
			if not wep then continue end
			
			local sizeH = SelectedWep == wep and (scrH * 0.12) or (scrH * 0.025)
			local LastSelected = 0
			if slotTbl[wepId - 1] and SelectedWep == slotTbl[wepId - 1] then
				lastPos = (scrH * 0.095)
			end
			
			local yPos = (scrH * 0.025) * (Ammout) + (scrH * 0.05) + lastPos
			
			-- Dark background box with rough edges
			local boxAlpha = WS.Transparent * (SelectedWep == wep and 220 or 150)
			surface.SetDrawColor(HORROR_BLACK.r, HORROR_BLACK.g, HORROR_BLACK.b, boxAlpha)
			surface.DrawRect(position + 1 + (shakeX or 0), yPos + 1 + (shakeY or 0), sizeX - 2, sizeH - 1)
			
			-- Blood-red border for selected weapon
			if SelectedWep == wep then
				local borderAlpha = GetFlickerAlpha(WS.Transparent * 200)
				surface.SetDrawColor(HORROR_RED.r, HORROR_RED.g, HORROR_RED.b, borderAlpha)
				surface.DrawOutlinedRect(position + (shakeX or 0), yPos + (shakeY or 0), sizeX, sizeH, 2)
				
				-- Inner glow effect
				local glowAlpha = WS.Transparent * 40
				surface.SetDrawColor(HORROR_RED.r, HORROR_RED.g, HORROR_RED.b, glowAlpha)
				surface.DrawRect(position + 2 + (shakeX or 0), yPos + 2 + (shakeY or 0), sizeX - 4, sizeH - 4)
			else
				-- Subtle border for unselected
				surface.SetDrawColor(HORROR_GRAY.r, HORROR_GRAY.g, HORROR_GRAY.b, WS.Transparent * 80)
				surface.DrawOutlinedRect(position + (shakeX or 0), yPos + (shakeY or 0), sizeX, sizeH, 1)
			end
			
			-- Gradient overlay
			local gradAlpha = WS.Transparent * (SelectedWep == wep and 150 or 50)
			surface.SetDrawColor(30, 0, 0, gradAlpha)
			surface.SetMaterial(gradient_up)
			surface.DrawTexturedRect(position + (shakeX or 0), yPos + (shakeY or 0), sizeX, sizeH)
			
			local textYPos = yPos + 2.5
			local textColor = ColorAlpha(color_white, WS.Transparent * 200)
			
			if SelectedWep == wep then
				local time = CurTime()
				-- Creepy pulsing red effect
				local pulse = math.sin(time * 3) * 0.3 + 0.7
				local trigger = math.sin(time * 0.5)
				
				if trigger > 0.7 then
					-- Occasional glitch flash
					local t = (math.sin(time * 40) + 1) / 2
					local gb = 255 * (1 - t)
					textColor = ColorAlpha(Color(255 * pulse, gb * 0.3, gb * 0.3), WS.Transparent * 255)
					
					-- Spawn blood particles occasionally
					if math.random() < 0.1 then
						AddBloodParticle(position + sizeX / 2, textYPos)
					end
				else
					textColor = ColorAlpha(Color(200 * pulse, 50, 50), WS.Transparent * 255)
				end
			end
			
			-- Draw weapon name with horror styling
			local nameGlitchX, nameGlitchY = 0, 0
			if SelectedWep == wep then
				nameGlitchX, nameGlitchY = GetGlitchOffset()
			end
			
			WS.DrawText(WS.GetPrintName(wep), "HorrorWeaponSmall", 
				position + sizeX / 2 + nameGlitchX + (shakeX or 0), textYPos + nameGlitchY + (shakeY or 0), 
				textColor, TEXT_ALIGN_CENTER)
			
			Ammout = Ammout + 1

			-- Draw weapon icon if available
			if SelectedWep == wep and wep.DrawWeaponSelection then
				wep:DrawWeaponSelection(position + 5 + (shakeX or 0), (scrH * 0.025) * (Ammout) + (scrH * 0.055) + lastPos + (shakeY or 0), 
					sizeX - 10, sizeH, WS.Transparent * 255)
			end
		end
		SuperAmmout = SuperAmmout + 1
	end
	
	-- Draw and update blood particles
	for i = #WS.BloodParticles, 1, -1 do
		local p = WS.BloodParticles[i]
		p.x = p.x + p.vx * FrameTime()
		p.y = p.y + p.vy * FrameTime()
		p.vy = p.vy + 200 * FrameTime() -- gravity
		p.life = p.life - FrameTime() * 0.5
		p.alpha = p.life * 255
		
		if p.life <= 0 then
			table.remove(WS.BloodParticles, i)
		else
			surface.SetDrawColor(HORROR_BLOOD.r, HORROR_BLOOD.g, HORROR_BLOOD.b, p.alpha * WS.Transparent)
			surface.DrawRect(p.x, p.y, p.size, p.size)
		end
	end
	
end

-- Changer
local tAcceptKeys = {
	["slot1"] = 1,
	["slot2"] = 2,
	["slot3"] = 3,
	["slot4"] = 4,
	["slot5"] = 5,
	["slot6"] = 6,
}

local function GetUpper(Weapons)
	if #LocalPlayer():GetWeapons() < 1 then return end
	WS.SelectedSlot = WS.SelectedSlot < 0 and #Weapons or WS.SelectedSlot - 1
	WS.SelectedSlotPos = Weapons[WS.SelectedSlot] and #Weapons[WS.SelectedSlot] or 0

	if Weapons[WS.SelectedSlot] == nil or Weapons[WS.SelectedSlot][WS.SelectedSlotPos] == nil then
		GetUpper(Weapons)
	end
end

local function GetDown(Weapons)
	if #LocalPlayer():GetWeapons() < 1 then return end
	WS.SelectedSlot = WS.SelectedSlot > #Weapons and 0 or WS.SelectedSlot + 1
	WS.SelectedSlotPos = 0

	if Weapons[WS.SelectedSlot] == nil or Weapons[WS.SelectedSlot][WS.SelectedSlotPos] == nil then
		GetDown(Weapons)
	end
end

local LastSelected = 0

local function get_active_tool(ply, tool)
	local activeWep = ply:GetActiveWeapon()
	if not IsValid(activeWep) or activeWep:GetClass() ~= "gmod_tool" or activeWep.Mode ~= tool then return end
	return activeWep:GetToolObject(tool)
end

local function canUseSelector(ply)
	local wep = ply:GetActiveWeapon()
	local tool = get_active_tool(ply, "submaterial")
	if tool and IsValid(ply:GetEyeTraceNoCursor().Entity) then
		return true
	end

	return IsAiming(ply) or (IsValid(wep) and wep:GetClass() == "weapon_physgun" and ply:KeyDown(IN_ATTACK)) or (lply.organism and lply.organism.pain and lply.organism.pain > 100)
end

function WS.ChangeSelectionWep( ply, key )
	if not IsValid( ply ) or not ply:Alive() then return end
	if ply.organism and ply.organism.otrub then return end
	if canUseSelector( ply ) then return end
	
	local iPos = tAcceptKeys[ key ]
	if iPos or key == "invnext" or key == "invprev" or key == "lastinv" then

		local Weapons = WS.GetWeaponTable( ply )

		WS.Show = CurTime() + 4
		
		-- Trigger switch animation
		WS.Switching = true
		WS.SwitchTime = CurTime()
		WS.ScreenShake = 5.0
		
		-- Horror-themed sound effects
		if math.random() < 0.3 then
			surface.PlaySound("weapons/switch"..math.random(1,3)..".ogg")
		else
			surface.PlaySound("items/ammocrate_close"..math.random(1,2)..".ogg")
		end
		
		if iPos then
			iPos = iPos - 1
			if LastSelected ~= iPos then 
				WS.SelectedSlotPos = -1
			end
			WS.SelectedSlotPos = (Weapons[iPos] and LastSelected == iPos and WS.SelectedSlotPos + 1 > #Weapons[iPos] and 0 or math.min( WS.SelectedSlotPos + 1, #Weapons[iPos] )) or 0
			WS.SelectedSlot = iPos
			LastSelected = iPos
		elseif key == "invprev" then
			WS.SelectedSlotPos = WS.SelectedSlotPos - 1
			if Weapons[WS.SelectedSlot] and WS.SelectedSlotPos < 0  then
				GetUpper(Weapons)
			end
		elseif key == "invnext" then
			WS.SelectedSlotPos = WS.SelectedSlotPos + 1
			if Weapons[WS.SelectedSlot] and WS.SelectedSlotPos > #Weapons[WS.SelectedSlot] then
				GetDown(Weapons)
			end
		elseif key == "lastinv" and IsValid(WS.LastInv) then
			WS.Show = 0
			WS.LastInv = WS.LastInv ~= ply:GetActiveWeapon() and WS.LastInv or ply:GetActiveWeapon()
			input.SelectWeapon( WS.LastInv )
			WS.LastInv = oldwep
		end
	end
end

function WS.SetActuallyWeapon( ply, cmd )
	if not IsValid( ply ) or not ply:Alive() then return end
	if (cmd:KeyDown( IN_ATTACK ) or cmd:KeyDown( IN_ATTACK2 )) and WS.Show > CurTime() then

		if WS.Selected and WS.Selected > CurTime() then 
			cmd:RemoveKey(IN_ATTACK) 
			cmd:RemoveKey(IN_ATTACK2) 
		else
			cmd:RemoveKey(IN_ATTACK)
			cmd:RemoveKey(IN_ATTACK2) 
			
			if IsValid(WS.GetSelectedWeapon()) then
				WS.LastInv = WS.LastInv ~= ply:GetActiveWeapon() and WS.LastInv or ply:GetActiveWeapon()
				input.SelectWeapon( WS.GetSelectedWeapon() )
			end
			cmd:RemoveKey(IN_ATTACK)
			cmd:RemoveKey(IN_ATTACK2) 

			WS.LastSelectedSlot = WS.SelectedSlot
			WS.LastSelectedSlotPos = WS.SelectedSlotPos
			WS.Selected = CurTime() + 0.2
			WS.Show = CurTime() + 0.2
			
			-- Horror weapon select sound
			surface.PlaySound("weapons/physcannon_pickup"..math.random(1,3)..".ogg")
		end
	end
end

hook.Add( "PlayerBindPress", "WeaponSelector_PlayerBindPress", WS.ChangeSelectionWep )

hook.Add( "HUDPaint", "WeaponSelector_Draw", function()
	-- Apply screen shake during switch
	local shakeX, shakeY = 0, 0
	if WS.Switching and CurTime() - WS.SwitchTime < WS.SwitchDuration then
		shakeX = math.random(-WS.ScreenShake, WS.ScreenShake)
		shakeY = math.random(-WS.ScreenShake, WS.ScreenShake)
		WS.ScreenShake = math.max(0, WS.ScreenShake - 20 * FrameTime())
	else
		WS.Switching = false
	end
	
	
	-- Draw main weapon selector with shake offset
	WS.WeaponSelectorDraw( LocalPlayer(), shakeX, shakeY )
end)

hook.Add( "StartCommand", "WeaponSelector_StartCommand", WS.SetActuallyWeapon )

local tHideElements = {
	["CHudWeaponSelection"] = true
}

hook.Add("HUDShouldDraw", "WeaponSelector_HUDShouldDraw", function(sElementName)
	if tHideElements[sElementName] then return false end
end)

-- Horror redesign complete
-- The weapon selector now features:
-- - Blood-red color scheme with dark backgrounds
-- - Flickering/glowing effects for selected items
-- - Blood particle effects
-- - Glitch text effects
-- - Creepy atmospheric text
-- - Horror-themed sounds
-- [[
--     /\_/\
--     |x_x|  <-- DEAD CAT
--     |   |__
--    /_|_____\ -- IT'S SO OVER
-- ]]
