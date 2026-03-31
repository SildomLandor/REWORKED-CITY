--[[
    Dynamic Music System - Music Packs
    Defines all available music packs and their tracks
--]]

hg = hg or {}
hg.DynaMusic = hg.DynaMusic or {}
local DMusic = hg.DynaMusic

DMusic.MusicMeta = DMusic.MusicMeta or {}
local musMeta = DMusic.MusicMeta

-- Music metadata structure
function musMeta:AddMusic(tbl, adrLevel, strPath, volMul, intRepeats)
    if not tbl or not strPath then return end
    tbl[adrLevel] = {strPath, volMul or 1, intRepeats and 1 or nil, intRepeats}
end

-- Create empty music table structure
local musMetaTbl = {
    ["ambient"] = {},      -- Level 0: Calm ambient music
    ["suspense"] = {},     -- Level 0.5: Suspenseful music
    ["combat_1"] = {},     -- Level 1: Light combat
    ["combat_2"] = {},     -- Level 2: Medium combat
    ["combat_3"] = {},     -- Level 3: Intense combat
    ["fear"] = {},         -- Level 4: Fear/horror music
    ["extreme"] = {}       -- Level 5: Extreme intensity
}

function musMeta:CreateTbl()
    return table.Copy(musMetaTbl)
end

-- Initialize pack storage
DMusic.Pack = DMusic.Pack or {}

-- Pack constructor functions
function DMusic:AddPack(strName)
    DMusic.Pack[strName] = {}
end

function DMusic:AddSequence(strPackName, strName, tblMusic)
    if not DMusic.Pack[strPackName] then
        DMusic:AddPack(strPackName)
    end
    DMusic.Pack[strPackName][strName] = tblMusic
end

--====================================================================================
-- MIRRORS EDGE PACK
--====================================================================================
DMusic:AddPack("mirrors_edge")

local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 0, "zc_dyna_music/medge/a1.mp3", 0.1)
musMeta:AddMusic(Music, 1, "zc_dyna_music/medge/c1.mp3")
DMusic:AddSequence("mirrors_edge", "01", Music)

local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 0, "zc_dyna_music/medge/a2.mp3", 0.1)
musMeta:AddMusic(Music, 1, "zc_dyna_music/medge/c2.mp3")
DMusic:AddSequence("mirrors_edge", "02", Music)

local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 0, "zc_dyna_music/medge/a3.mp3", 0.1)
musMeta:AddMusic(Music, 1, "zc_dyna_music/medge/c4.mp3")
musMeta:AddMusic(Music, 4, "zc_dyna_music/medge/c3.mp3")
DMusic:AddSequence("mirrors_edge", "03", Music)

local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 0, "zc_dyna_music/medge/a4.mp3", 0.1)
musMeta:AddMusic(Music, 1, "zc_dyna_music/medge/c6.mp3")
musMeta:AddMusic(Music, 4, "zc_dyna_music/medge/c5.mp3")
DMusic:AddSequence("mirrors_edge", "04", Music)

local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 0, "zc_dyna_music/medge/a5.mp3", 0.1)
musMeta:AddMusic(Music, 1, "zc_dyna_music/medge/c6.mp3")
musMeta:AddMusic(Music, 4, "zc_dyna_music/medge/c7.mp3")
DMusic:AddSequence("mirrors_edge", "05", Music)

local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 0, "zc_dyna_music/medge/a6.mp3", 0.1)
musMeta:AddMusic(Music, 1, "zc_dyna_music/medge/c10.mp3")
musMeta:AddMusic(Music, 4, "zc_dyna_music/medge/c9.mp3")
DMusic:AddSequence("mirrors_edge", "06", Music)

local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 0, "zc_dyna_music/medge/a7.mp3", 0.1)
musMeta:AddMusic(Music, 1, "zc_dyna_music/medge/c9.mp3")
musMeta:AddMusic(Music, 4, "zc_dyna_music/medge/c10.mp3")
DMusic:AddSequence("mirrors_edge", "07", Music)

local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 0, "zc_dyna_music/medge/a8.mp3", 0.1)
musMeta:AddMusic(Music, 1, "zc_dyna_music/medge/c12.mp3")
musMeta:AddMusic(Music, 4, "zc_dyna_music/medge/c13.mp3")
DMusic:AddSequence("mirrors_edge", "08", Music)

local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 0, "zc_dyna_music/medge/a9.mp3", 0.1)
musMeta:AddMusic(Music, 1, "zc_dyna_music/medge/c15.mp3")
musMeta:AddMusic(Music, 4, "zc_dyna_music/medge/c14.mp3")
DMusic:AddSequence("mirrors_edge", "09", Music)

--====================================================================================
-- SWAT 4 PACK
--====================================================================================
DMusic:AddPack("swat4")

for i = 1, 7 do
    local Music = musMeta:CreateTbl()
    musMeta:AddMusic(Music, 0, "zc_dyna_music/swat4/a"..i..".mp3", 0.25)
    musMeta:AddMusic(Music, 1, "zc_dyna_music/swat4/c"..i..".mp3", 1, 3)
    DMusic:AddSequence("swat4", "0"..i, Music)
end

--====================================================================================
-- HALF-LIFE COOP PACK
--====================================================================================
DMusic:AddPack("hl_coop")

for i = 1, 15 do
    local Music = musMeta:CreateTbl()
    musMeta:AddMusic(Music, 1, "zc_dyna_music/hl_coop/c"..i..".mp3")
    DMusic:AddSequence("hl_coop", "0"..i, Music)
end

local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 1, "zc_dyna_music/hl_coop/c8.mp3")
DMusic:AddSequence("hl_coop", "09", Music)

--====================================================================================
-- SPLINTER CELL PACK
--====================================================================================
DMusic:AddPack("splinter_cell")

-- Bank
local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 0, "am_music/background/bank(calm).mp3", 0.3)
musMeta:AddMusic(Music, 0.5, "am_music/suspense/bank(suspense).mp3", 0.7)
musMeta:AddMusic(Music, 1, "am_music/battle/bank(stress).mp3")
musMeta:AddMusic(Music, 3, "am_music/battle_intensive/bank(intense).mp3")
DMusic:AddSequence("splinter_cell", "Bank", Music)

-- Battery
local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 0, "am_music/background/battery(calm).mp3", 0.3)
musMeta:AddMusic(Music, 0, "am_music/background/battery(calm2).mp3", 0.3)
musMeta:AddMusic(Music, 0.5, "am_music/suspense/battery(suspense).mp3", 0.7)
musMeta:AddMusic(Music, 1, "am_music/battle/battery(stress).mp3")
musMeta:AddMusic(Music, 3, "am_music/battle_intensive/battery(intense).mp3")
DMusic:AddSequence("splinter_cell", "Battery", Music)

-- Displace
local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 0, "am_music/background/displace(calm).mp3", 0.3)
musMeta:AddMusic(Music, 0.5, "am_music/suspense/displace(suspense).mp3", 0.7)
musMeta:AddMusic(Music, 1, "am_music/battle/displace(stress).mp3")
musMeta:AddMusic(Music, 3, "am_music/battle_intensive/displace(intense).mp3")
DMusic:AddSequence("splinter_cell", "Displace", Music)

-- Lighthouse
local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 0, "am_music/background/lighthouse(calm).mp3", 0.3)
musMeta:AddMusic(Music, 0, "am_music/background/lighthouse(calm2).mp3", 0.3)
musMeta:AddMusic(Music, 0.5, "am_music/suspense/lighthouse(suspense).mp3", 0.7)
musMeta:AddMusic(Music, 1, "am_music/battle/lighthouse(stress).mp3")
musMeta:AddMusic(Music, 3, "am_music/battle_intensive/lighthouse(intense).mp3")
musMeta:AddMusic(Music, 3, "am_music/battle_intensive/lighthouse(intense2).mp3")
DMusic:AddSequence("splinter_cell", "Lighthouse", Music)

-- Penthouse
local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 0, "am_music/background/penthouse(calm).mp3", 0.3)
musMeta:AddMusic(Music, 0.5, "am_music/suspense/penthouse(suspense).mp3", 0.7)
musMeta:AddMusic(Music, 1, "am_music/battle/penthouse(stress).mp3")
musMeta:AddMusic(Music, 3, "am_music/battle_intensive/penthouse(intense).mp3")
DMusic:AddSequence("splinter_cell", "Penthouse", Music)

--====================================================================================
-- COMBINE TEAM PACK
--====================================================================================
DMusic:AddPack("combine")

-- Combine ambient tracks
local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 0, "zc_dyna_music/combine/ambient1.mp3", 0.2)
musMeta:AddMusic(Music, 0.5, "zc_dyna_music/combine/suspense1.mp3", 0.5)
musMeta:AddMusic(Music, 1, "zc_dyna_music/combine/combat1.mp3")
musMeta:AddMusic(Music, 3, "zc_dyna_music/combine/intense1.mp3")
musMeta:AddMusic(Music, 4, "zc_dyna_music/combine/fear1.mp3")
DMusic:AddSequence("combine", "01", Music)

local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 0, "zc_dyna_music/combine/ambient2.mp3", 0.2)
musMeta:AddMusic(Music, 0.5, "zc_dyna_music/combine/suspense2.mp3", 0.5)
musMeta:AddMusic(Music, 1, "zc_dyna_music/combine/combat2.mp3")
musMeta:AddMusic(Music, 3, "zc_dyna_music/combine/intense2.mp3")
musMeta:AddMusic(Music, 4, "zc_dyna_music/combine/fear2.mp3")
DMusic:AddSequence("combine", "02", Music)

local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 0, "zc_dyna_music/combine/ambient3.mp3", 0.2)
musMeta:AddMusic(Music, 0.5, "zc_dyna_music/combine/suspense3.mp3", 0.5)
musMeta:AddMusic(Music, 1, "zc_dyna_music/combine/combat3.mp3")
musMeta:AddMusic(Music, 3, "zc_dyna_music/combine/intense3.mp3")
musMeta:AddMusic(Music, 4, "zc_dyna_music/combine/fear3.mp3")
DMusic:AddSequence("combine", "03", Music)

--====================================================================================
-- HORROR/FEAR PACK
--====================================================================================
DMusic:AddPack("horror")

-- Horror tracks for high fear situations
local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 3, "zc_dyna_music/horror/fear1.mp3", 1.5)
musMeta:AddMusic(Music, 4, "zc_dyna_music/horror/terror1.mp3", 2)
DMusic:AddSequence("horror", "01", Music)

local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 3, "zc_dyna_music/horror/fear2.mp3", 1.5)
musMeta:AddMusic(Music, 4, "zc_dyna_music/horror/terror2.mp3", 2)
DMusic:AddSequence("horror", "02", Music)

local Music = musMeta:CreateTbl()
musMeta:AddMusic(Music, 3, "zc_dyna_music/horror/fear3.mp3", 1.5)
musMeta:AddMusic(Music, 4, "zc_dyna_music/horror/terror3.mp3", 2)
DMusic:AddSequence("horror", "03", Music)

--====================================================================================
-- NETWORKING
--====================================================================================
if SERVER then
    util.AddNetworkString("DMusic")
    
    function DMusic:AddPanic(ply, amount)
        net.Start("DMusic")
            net.WriteFloat(amount)
        net.Send(ply)
    end
    
    function DMusic:AddFear(ply, amount)
        net.Start("DMusic_Fear")
            net.WriteFloat(amount)
        net.Send(ply)
    end
elseif CLIENT then
    net.Receive("DMusic", function()
        local amount = net.ReadFloat()
        DMusic.threaded = DMusic.threaded + amount
    end)
    
    net.Receive("DMusic_Fear", function()
        local amount = net.ReadFloat()
        DMusic:AddFear(amount)
    end)
end

--====================================================================================
-- DAMAGE HOOKS
--====================================================================================
hook.Add("HomigradDamage", "DMusic.Damage", function(ply, dmgInfo, hitgroup, ent, harm, hitBoxs, inputHole)
    if ent:IsPlayer() then
        -- Add panic from damage
        hg.DynaMusic:AddPanic(ply, dmgInfo:GetDamage() * 25)
        
        -- Add fear from taking damage
        if SERVER then
            hg.DynaMusic:AddFear(ply, dmgInfo:GetDamage() * 0.3)
        end
        
        -- Attacker also gets some panic
        if dmgInfo:GetAttacker():IsPlayer() then
            hg.DynaMusic:AddPanic(dmgInfo:GetAttacker(), dmgInfo:GetDamage() * 5)
        end
    end
end)

-- Hook for witnessing deaths
hook.Add("PlayerDeath", "DMusic.FearDeath", function(victim, inflictor, attacker)
    if SERVER then
        for _, ply in ipairs(player.GetAll()) do
            if ply ~= victim and ply ~= attacker then
                local dist = ply:GetPos():Distance(victim:GetPos())
                if dist < 1000 and ply:Visible(victim) then
                    hg.DynaMusic:AddFear(ply, 1)
                end
            end
        end
    end
end)
