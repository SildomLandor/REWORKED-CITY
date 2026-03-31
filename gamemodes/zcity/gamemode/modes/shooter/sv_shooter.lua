MODE.name = "shooter"
MODE.PrintName = "Active Shooter"

MODE.ForBigMaps = false
MODE.ROUND_TIME = 480
MODE.LootSpawn = true

MODE.Chance = 0.05

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	return 1, true--returning true so guilt bans
end

function shuffle(tbl)
	local len = #tbl
	for i = len, 2, -1 do
	  local j = math.random(i)
	  tbl[i], tbl[j] = tbl[j], tbl[i]
	end
end

function MODE:AssignTeams()
    local players = player.GetAll()
    local numPlayers = #players
    shuffle(players)
    if numPlayers == 0 then return end
    if IsValid(players[1]) then players[1]:SetTeam(2) end
    for i = 2, numPlayers do
        if IsValid(players[i]) then players[i]:SetTeam(1) end
    end
end

util.AddNetworkString("criresp_start")
function MODE:Intermission()
    game.CleanUpMap()
    hg.UpdateRoundTime(self.ROUND_TIME)
    self:AssignTeams()

    for k, ply in ipairs(player.GetAll()) do
        if ply:Team() == TEAM_SPECTATOR or ply:Team() == 0 or ply:Team() == 2 then ply:KillSilent() continue end
        ply:SetupTeam(ply:Team())
    end

	net.Start("criresp_start")
	net.Broadcast()

end

function MODE:CheckAlivePlayers()
    local swatPlayers = {}
    local victimPlayers = {}
    local shooterPlayers = {}

    for _, ply in ipairs(team.GetPlayers(0)) do
        if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
            table.insert(swatPlayers, ply)
        end
    end

    for _, ply in ipairs(team.GetPlayers(1)) do
        if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
            table.insert(victimPlayers, ply)
        end
    end

    for _, ply in ipairs(team.GetPlayers(2)) do
        if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
            table.insert(shooterPlayers, ply)
        end
    end

    return {swatPlayers, victimPlayers, shooterPlayers}
end





function MODE:ShouldRoundEnd()
    if zb.ROUND_START + 61 > CurTime() then return false end
    local aliveTeams = self:CheckAlivePlayers()
    -- end the round once SWAT is present and shooter is gone
    if CurTime() >= (zb.ROUND_START + 240) and table.Count(aliveTeams[3]) == 0 then
        return true
    end
    local endround = zb:CheckWinner(aliveTeams)
    return endround
end



function MODE:RoundStart()
    
end

local tblweps = {
	[0] = { 
		{"weapon_m4a1", {"holo15","grip3","laser4"} }, 
		{"weapon_hk416", {"holo15","grip3","laser4"} },
		{"weapon_p90", {} },
		{"weapon_mp7", {"holo14"} },
		{"weapon_m4a1", {"optic2","grip3","supressor7"} }
	},
	[1] = { 
		"weapon_deagle",
		"weapon_glock17",
		"weapon_revolver2",
		"weapon_p22",
		"weapon_revolver2",
		"weapon_hk_usp",
		"weapon_remington870",
		"weapon_mac11",
		"weapon_skorpion",
	}
}

local tblotheritems = {
	[0] = { 
		"weapon_medkit_sh", 
		"weapon_tourniquet",
		"weapon_walkie_talkie",
        "weapon_melee",
		"weapon_handcuffs",
		"weapon_hg_flashbang_tpik"
	},
	[1] = { 
		"weapon_bigconsumable", 
		"weapon_bandage_sh",
		"weapon_painkillers",
        "weapon_sogknife",
		"weapon_ducttape",
		"weapon_hammer"

	}
}


local tblarmors = {
	[0] = { 
		{"ent_armor_vest8","ent_armor_helmet6"} 
	},
	[1] = { 
		{"ent_armor_vest8","ent_armor_helmet6"} 
	}
}

function MODE:CanLaunch()
    return true
end

function MODE:GiveEquipment()
    timer.Simple(0.5,function()
        self.SWATQueue = {}
        self.SWATQueueSet = {}

        for i, ply in ipairs(player.GetAll()) do
            if ply:Team() == TEAM_SPECTATOR then continue end

            if ply:Team() == 2 then
                timer.Create("ShooterSpawn"..ply:EntIndex(), 60, 1, function()
                    ply:Spawn()
                    ply:SetSuppressPickupNotices(true)
                    ply.noSound = true

                    ply:SetupTeam(ply:Team())
                    ply:SetPlayerClass()

                    zb.GiveRole(ply, "Shooter", Color(190,0,0))

                    hg.AddArmor(ply, {"ent_armor_vest4","ent_armor_helmet2"})

                    local inv = ply:GetNetVar("Inventory") or {}
                    inv["Weapons"] = inv["Weapons"] or {}
                    inv["Weapons"]["hg_sling"] = true
                    inv["Weapons"]["hg_melee_belt"] = true
                    inv["Weapons"]["hg_flashlight"] = true
                    inv["Weapons"]["hg_brassknuckles"] = true
                    ply:SetNetVar("Inventory", inv)

                    local function giveWithReserve(class)
                        local wep = ply:Give(class)
                        if IsValid(wep) and wep.GetMaxClip1 and wep.GetPrimaryAmmoType and wep:GetMaxClip1() > 0 then
                            ply:GiveAmmo(wep:GetMaxClip1() * 2, wep:GetPrimaryAmmoType(), true)
                        end
                    end

                    giveWithReserve("weapon_ruger")
                    giveWithReserve("weapon_handmadesmg")
                    giveWithReserve("weapon_hg_pipebomb_tpik")
                    ply:Give("weapon_hg_molotov_tpik")
                    giveWithReserve("weapon_traitor_suit")
                    giveWithReserve("weapon_drill")
                    giveWithReserve("weapon_fentanyl")

                    ply:Give("weapon_hands_sh")

                    ply:SetSuppressPickupNotices(false)
                    ply.noSound = false
                end)
            else
                ply:SetSuppressPickupNotices(true)
                ply.noSound = true

                ply:SetPlayerClass()

                zb.GiveRole(ply, "Victim", Color(255,255,255))

                ply:Give("weapon_hands_sh")

                ply:SetSuppressPickupNotices(false)
                ply.noSound = false
            end

			timer.Simple(0.5,function()
				ply.noSound = false
			end)

			ply:SetSuppressPickupNotices(false)
		end

        timer.Create("SWATArrival", 240, 1, function()
            for _, ply in ipairs(self.SWATQueue or {}) do
                if IsValid(ply) then
                    self:SpawnSWAT(ply)
                end
            end
            self.SWATQueue = {}
            self.SWATQueueSet = {}
        end)
    end)
end

function MODE:SpawnSWAT(ply)
    if not IsValid(ply) then return end
    ply:SetTeam(0)
    ply:Spawn()
    ply:SetSuppressPickupNotices(true)
    ply.noSound = true

    ply:SetupTeam(ply:Team())
    ply:SetPlayerClass("swat")

    local inv = ply:GetNetVar("Inventory") or {}
    inv["Weapons"] = inv["Weapons"] or {}
    inv["Weapons"]["hg_sling"] = true
    ply:SetNetVar("Inventory",inv)

    hg.AddArmor(ply, tblarmors[0][math.random(#tblarmors[0])]) 
    zb.GiveRole(ply, "SWAT", Color(0,0,190))

    local wep = tblweps[0][math.random(#tblweps[0])]
    local gun = ply:Give(wep[1])
    if IsValid(gun) and gun.GetMaxClip1 then
        hg.AddAttachmentForce(ply,gun,wep[2])
        ply:GiveAmmo(gun:GetMaxClip1() * 3,gun:GetPrimaryAmmoType(),true)
    end

    local pistol = ply:Give("weapon_glock17")
    if IsValid(pistol) and pistol.GetMaxClip1 then
        ply:GiveAmmo(pistol:GetMaxClip1() * 3,pistol:GetPrimaryAmmoType(),true)
    end

    for _, item in ipairs(tblotheritems[0]) do
        ply:Give(item)
    end

    ply:Give("weapon_hands_sh")
    ply:SetSuppressPickupNotices(false)
    ply.noSound = false
end

function MODE:RoundThink()
end

function MODE:GetTeamSpawn()
	return {zb:GetRandomSpawn()}, {zb:GetRandomSpawn()}
end

function MODE:CanSpawn()
end

util.AddNetworkString("cri_roundend")
function MODE:EndRound()
	for k,ply in player.Iterator() do
		if timer.Exists("SWATSpawn"..ply:EntIndex()) then
			timer.Remove("SWATSpawn"..ply:EntIndex())
		end
		if timer.Exists("ShooterSpawn"..ply:EntIndex()) then
			timer.Remove("ShooterSpawn"..ply:EntIndex())
		end
	end
	if timer.Exists("SWATSpawn") then
		timer.Remove("SWATSpawn")
	end
	if timer.Exists("SWATArrival") then
		timer.Remove("SWATArrival")
	end
	self.SWATQueue = {}
	self.SWATQueueSet = {}

    local aliveTeams = self:CheckAlivePlayers()
    local endround, winner = zb:CheckWinner(aliveTeams)
    -- force SWAT win if shooter is eliminated after SWAT arrival
    if CurTime() >= (zb.ROUND_START + 240) and table.Count(aliveTeams[3]) == 0 then
        endround = true
        winner = 0
    end

	timer.Simple(2,function()
		net.Start("cri_roundend")
			net.WriteBool(winner)
		net.Broadcast()
	end)

	for k,ply in player.Iterator() do
		if ply:Team() == winner then
			ply:GiveExp(math.random(15,30))
			ply:GiveSkill(math.Rand(0.1,0.15))
		else
			ply:GiveSkill(-math.Rand(0.05,0.1))
		end
	end
end

function MODE:PlayerDeath(_, ply)
    if not IsValid(ply) then return end
    if ply:Team() ~= 1 then return end
    if CurTime() > (zb.ROUND_START + 240) then return end
    if self.SWATQueueSet and self.SWATQueueSet[ply] then return end
    self.SWATQueue = self.SWATQueue or {}
    self.SWATQueueSet = self.SWATQueueSet or {}
    table.insert(self.SWATQueue, ply)
    self.SWATQueueSet[ply] = true
    ply:SetTeam(0)
end
