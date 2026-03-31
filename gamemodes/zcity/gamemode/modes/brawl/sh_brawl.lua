local MODE = MODE
MODE.name = "brawl"
MODE.PrintName = "Brawl"
MODE.Description = "Free-for-all melee progression. Get kills to unlock new melee and win with the final weapon."
MODE.Chance = 0.04
MODE.randomSpawns = true

MODE.DefaultWeaponPool = {
    "weapon_leadpipe",
    "weapon_hg_wrench",
    "weapon_hammer",
    "weapon_pocketknife",
    "weapon_pan",
    "weapon_hg_taiga",
    "weapon_hg_shovel",
    "weapon_bat",
    "weapon_batmetal",
    "weapon_hg_axe",
    "weapon_hg_bayonet",
    "weapon_hg_chainsaw",
    "weapon_hg_cleaver",
    "weapon_hg_crowbar",
    "weapon_hg_fireaxe",
    "weapon_hg_razor",
    "weapon_hg_kukri",
    "weapon_hg_katana",
    "weapon_hg_fubar",
    "weapon_hg_machete",
    "weapon_hg_pickaxe",
    "weapon_hg_zweihander",
	"weapon_hg_mace",
	"weapon_hg_crovel",
    "weapon_hg_sledgehammer",
    "weapon_hg_spear",
    "weapon_hg_pitchfork",
    "weapon_hg_spear_pro",
    "weapon_tomahawk"
}

MODE.FinalWeaponDefault = "weapon_derringer"

function MODE:GetWeaponPool()
    local pool = {}
    for _, cls in ipairs(self.DefaultWeaponPool) do
        if weapons.GetStored(cls) ~= nil then
            pool[#pool + 1] = cls
        end
    end
    if #pool == 0 then
        pool = {"weapon_hg_crowbar"}
    end
    return pool
end

function MODE:GetFinalWeapon()
    local cls = self.FinalWeaponDefault
    if weapons.GetStored(cls) then
        return cls
    end
    return "weapon_hg_crowbar"
end
