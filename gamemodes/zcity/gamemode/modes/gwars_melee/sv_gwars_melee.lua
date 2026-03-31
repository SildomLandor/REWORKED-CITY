MODE.name = "gwars_melee"
MODE.PrintName = "Gwars Melee"

MODE.ForBigMaps = false
MODE.ROUND_TIME = 180

MODE.Chance = 0.02

MODE.OverideSpawnPos = true
MODE.LootSpawn = false

function MODE:CanLaunch()
	local points = zb.GetMapPoints( "HMCD_TDM_T" )
	local points2 = zb.GetMapPoints( "HMCD_TDM_CT" )
    return (#points > 0) and (#points2 > 0)
end

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	return 1, true--returning true so guilt bans
end

util.AddNetworkString("gwars_start")
function MODE:Intermission()
	game.CleanUpMap()

	self.CTPoints = {}
	table.CopyFromTo(zb.GetMapPoints( "HMCD_TDM_CT" ),self.CTPoints)
	self.TPoints = {}
	table.CopyFromTo(zb.GetMapPoints( "HMCD_TDM_T" ),self.TPoints)
	
	for i, ply in ipairs(player.GetAll()) do
		ply:SetupTeam(ply:Team())
	end

	net.Start("gwars_start")
	net.Broadcast()
end

function MODE:CheckAlivePlayers()
	return zb:CheckAliveTeams(true)
end

function MODE:ShouldRoundEnd()
	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())

	return endround or boringround
end

function MODE:BoringRoundFunction()		
	timer.Simple(2, function()
		//PrintMessage(HUD_PRINTTALK, "IT IS A GANG BEATDOWN FFS...")
	end)
end

local swatSpawned = false

function MODE:RoundStart()
    swatSpawned = false 
end

local riotWeapons = {
    "weapon_leadpipe",
    "weapon_brick",
    "weapon_hammer",
    "weapon_pocketknife",
    "weapon_pan",
	"weapon_fury13variant",
    "weapon_hg_shovel",
    "weapon_bat",
    "weapon_batmetal",
    "weapon_hg_axe",
    "weapon_hg_bottle",
    "weapon_hg_chainsaw",
    "weapon_hg_cleaver",
    "weapon_hg_crowbar",
    "weapon_hg_fireaxe",
    "weapon_hg_glassshard",
    "weapon_hg_kukri",
    "weapon_hg_machete",
    "weapon_hg_pickaxe",
    "weapon_hg_sledgehammer",
    "weapon_hg_spear",
    "weapon_hg_spear_knife",
    "weapon_hg_spear_pro",
    "weapon_tomahawk",
}

local lawWeapons = {
    "weapon_hg_tonfa",
    "weapon_taser",
    "weapon_walkie_talkie",
    "weapon_handcuffs",
    "weapon_handcuffs_key"
}

local tblarmors = {
	[0] = {
		{"ent_armor_vest3","ent_armor_helmet2"}
	},
	[1] = {
		{"ent_armor_vest3","ent_armor_helmet2"}
	}
}

function MODE:GetPlySpawn(ply)
end

function MODE:GiveEquipment()
	self.CTPoints = {}
	table.CopyFromTo(zb.GetMapPoints( "HMCD_TDM_CT" ),self.CTPoints)
	self.TPoints = {}
	table.CopyFromTo(zb.GetMapPoints( "HMCD_TDM_T" ),self.TPoints)
	timer.Simple(0.1,function()
		local teamArmorCount = { [0] = 0, [1] = 0 } 

		for _, ply in ipairs(player.GetAll()) do
			if not ply:Alive() then continue end
			ply:SetSuppressPickupNotices(true)
			ply.noSound = true

			if ply:Team() == 0 then
				ply:SetPlayerClass("bloodz")
				zb.GiveRole(ply, "Bloodz", Color(190,0,0))
				ply:SetNetVar("CurPluv", "pluvred")
				
				local wep = ply:Give(riotWeapons[math.random(#riotWeapons)])
				ply:SelectWeapon(wep:GetClass())

				if math.random() < 0.05 then
					ply:Give("weapon_drill") -- rare drill
				end
				
				local hands = ply:Give("weapon_hands_sh")
			elseif ply:Team() == 1 then
				ply:SetPlayerClass("groove")
				zb.GiveRole(ply, "Groove", Color(0,190,0))
				ply:SetNetVar("CurPluv", "pluvgreen")

				local wep = ply:Give(riotWeapons[math.random(#riotWeapons)])
				ply:SelectWeapon(wep:GetClass())

				if math.random() < 0.05 then
					ply:Give("weapon_drill") -- rare drill
				end

				local hands = ply:Give("weapon_hands_sh")
			end

			// Spawn melee belt and brass knuckles for all players
			local playerPos = ply:GetPos()
			local playerAngles = ply:GetAngles()
			
			// Spawn hg_melee_belt entity
			local meleeBelt = ents.Create("hg_melee_belt")
			if IsValid(meleeBelt) then
				meleeBelt:SetPos(playerPos + playerAngles:Forward() * 30 + Vector(0, 0, 10))
				meleeBelt:SetAngles(playerAngles)
				meleeBelt:Spawn()
				// Auto-pickup after a short delay
				timer.Simple(0.2, function()
					if IsValid(meleeBelt) and IsValid(ply) then
						meleeBelt:TakeByPlayer(ply)
					end
				end)
			end
			
			// Spawn hg_brassknuckles entity
			local brassKnuckles = ents.Create("hg_brassknuckles")
			if IsValid(brassKnuckles) then
				brassKnuckles:SetPos(playerPos + playerAngles:Right() * 30 + Vector(0, 0, 10))
				brassKnuckles:SetAngles(playerAngles)
				brassKnuckles:Spawn()
				// Auto-pickup after a short delay
				timer.Simple(0.3, function()
					if IsValid(brassKnuckles) and IsValid(ply) then
						brassKnuckles:TakeByPlayer(ply)
					end
				end)
			end

			timer.Simple(0.1,function()
				ply.noSound = false
			end)

			ply:SetSuppressPickupNotices(false)
		end
	end)
end

function MODE:RoundThink()
    if not swatSpawned and (CurTime() - zb.ROUND_BEGIN) >= 120 then
        local deadPlayers = {}

        for _, ply in ipairs(player.GetAll()) do
            if not ply:Alive() and ply:Team() != TEAM_SPECTATOR then
                table.insert(deadPlayers, ply)
            end
        end

		local startpos = self.TPoints and #self.TPoints > 0 and self.TPoints[1].pos or zb:GetRandomSpawn()

		for i = 1, math.min(4, #deadPlayers) do
            local ply = deadPlayers[i]

            //if self.TPoints and #self.TPoints > 0 then
                ply:Spawn()
				ply:SetTeam(2)
				if !startpos then
					startpos = ply:GetPos()
				else
					hg.tpPlayer(startpos, ply, i, 0)
				end

                ply:SetPlayerClass("swat")
				zb.GiveRole(ply, "SWAT", Color(0,0,122))
				
				local wep = ply:Give(lawWeapons[math.random(#lawWeapons)])
                ply:SelectWeapon(wep:GetClass())

                hg.AddArmor(ply, "ent_armor_helmet1")
                hg.AddArmor(ply, "ent_armor_vest4")

                local hands = ply:Give("weapon_hands_sh")
				local wep = ply:Give(lawWeapons[math.random(#lawWeapons)])
                ply:SelectWeapon(wep:GetClass())
            //end
        end

        swatSpawned = true
    end
end

function MODE:GetTeamSpawn()
	return zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_T" )), zb.TranslatePointsToVectors(zb.GetMapPoints( "HMCD_TDM_CT" ))
end

function MODE:CanSpawn()
end

util.AddNetworkString("gwars_roundend")
function MODE:EndRound()
	timer.Simple(2,function()
		net.Start("gwars_roundend")
		net.Broadcast()
	end)

	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())
	for k,ply in player.Iterator() do
		if ply:Team() == winner then
			ply:GiveExp(math.random(15,30))
			ply:GiveSkill(math.Rand(0.1,0.15))
			--print("give",ply)
		else
			--print("take",ply)
			ply:GiveSkill(-math.Rand(0.05,0.1))
		end
	end
end

function MODE:PlayerDeath(_,ply)
end