hg = hg or {}
hg.DynaMusic = hg.DynaMusic or {}
local DMusic = hg.DynaMusic

DMusic.MusicMeta = DMusic.MusicMeta or {}
local musMeta = DMusic.MusicMeta

DMusic.CurrentPack = DMusic.CurrentPack or "mirrors_edge"
DMusic.Tracks = DMusic.Tracks or nil
DMusic.FearTracks = DMusic.FearTracks or nil
DMusic.CurrentMode = DMusic.CurrentMode or "default"
DMusic.AmbientVolume = DMusic.AmbientVolume or 0.3
DMusic.DynamicLevel = DMusic.DynamicLevel or 0
DMusic.FearLevel = DMusic.FearLevel or 0
DMusic.LastDamageTime = DMusic.LastDamageTime or 0
DMusic.TransitionSpeed = DMusic.TransitionSpeed or 1
DMusic.IsPlayingFearTrack = DMusic.IsPlayingFearTrack or false

-- ConVars for client settings
local hg_sound = CreateClientConVar("hg_dmusic", "1", true, false, "Enable dynamic music", 0, 1)
local hg_ambient_volume = CreateClientConVar("hg_dmusic_ambient_vol", "0.3", true, false, "Ambient music volume (0-1)", 0, 1)
local hg_dynamic_sensitivity = CreateClientConVar("hg_dmusic_sensitivity", "1", true, false, "Dynamic transition sensitivity (0.5-2)", 0.5, 2)
local hg_default_pack = CreateClientConVar("hg_dmusic_default_pack", "mirrors_edge", true, false, "Default music pack for modes without specific music")
local hg_fear_threshold = CreateClientConVar("hg_dmusic_fear_threshold", "3", true, false, "Fear level threshold to trigger fear tracks", 0, 10)
local hg_fear_volume = CreateClientConVar("hg_dmusic_fear_volume", "1", true, false, "Fear track volume multiplier", 0, 2)

-- Mode to music pack mapping
DMusic.ModePacks = DMusic.ModePacks or {
    ["coop"] = "hl_coop",
    ["dm"] = "mirrors_edge",
    ["tdm"] = "mirrors_edge",
    ["combine"] = "combine",
    ["zombie"] = "hl_coop",
    ["defense"] = "splinter_cell",
    ["homicide"] = "swat4",
    ["riot"] = "swat4",
    ["brawl"] = "mirrors_edge",
    ["shooter"] = "mirrors_edge",
    ["sfd"] = "mirrors_edge",
    ["gwars"] = "mirrors_edge",
    ["scugarena"] = "mirrors_edge",
    ["default"] = "mirrors_edge"
}

-- Initialize ambient volume from convar
DMusic.AmbientVolume = hg_ambient_volume:GetFloat()

-- Network strings
if SERVER then
    util.AddNetworkString("DMusic_Sync")
    util.AddNetworkString("DMusic_Mode")
    util.AddNetworkString("DMusic_Panic")
    util.AddNetworkString("DMusic_SetPack")
    util.AddNetworkString("DMusic_Fear")
else
    net.Receive("DMusic_Sync", function()
        local mode = net.ReadString()
        local pack = net.ReadString()
        DMusic.CurrentMode = mode
        if pack and pack ~= "" then
            DMusic:SetPack(pack)
        end
    end)
    
    net.Receive("DMusic_Mode", function()
        local mode = net.ReadString()
        DMusic.CurrentMode = mode
        DMusic:ApplyModePack()
    end)
    
    net.Receive("DMusic_Panic", function()
        local amount = net.ReadFloat()
        DMusic:AddPanic(amount)
    end)
    
    net.Receive("DMusic_SetPack", function()
        local pack = net.ReadString()
        DMusic:SetPack(pack)
    end)
    
    net.Receive("DMusic_Fear", function()
        local amount = net.ReadFloat()
        DMusic:AddFear(amount)
    end)
end

-- Music pack constructor functions
function DMusic:AddPack(strName)
    DMusic.Pack = DMusic.Pack or {}
    DMusic.Pack[strName] = {}
end

function DMusic:AddSequence(strPackName, strName, tblMusic)
    if not DMusic.Pack[strPackName] then
        DMusic:AddPack(strPackName)
    end
    DMusic.Pack[strPackName][strName] = tblMusic
end

function DMusic:SetPack(strPackName)
    if DMusic.Pack and DMusic.Pack[strPackName] then
        DMusic.CurrentPack = strPackName
        DMusic:Start(strPackName)
    end
end

function DMusic:ApplyModePack()
    local mode = DMusic.CurrentMode or "default"
    local pack = DMusic.ModePacks[mode] or DMusic.ModePacks["default"]
    
    -- Check if player is combine
    local ply = LocalPlayer()
    if IsValid(ply) and ply:IsPlayer() then
        local playerClass = ""
        if ply.GetPlayerClass then
            playerClass = ply:GetPlayerClass() or ""
        end
        if string.find(string.lower(playerClass), "combine") then
            pack = DMusic.ModePacks["combine"] or pack
        end
    end
    
    DMusic:SetPack(pack)
end

-- Start music playback
function DMusic:Start(strPack, strTrack)
    DMusic.CurrentPack = strPack or DMusic.CurrentPack
    DMusic.Tracks = DMusic.Tracks or {}
    
    -- Stop existing tracks
    for k, v in pairs(DMusic.Tracks) do
        if IsValid(v[1]) then 
            v[1]:Stop() 
            v[1] = nil 
        end
    end
    table.Empty(DMusic.Tracks)
    
    -- Load new tracks
    local packData = DMusic.Pack and DMusic.Pack[DMusic.CurrentPack]
    if not packData then return end
    
    local tracks = strTrack and packData[strTrack] or table.Random(packData)
    if not tracks then return end
    
    for k, song in pairs(tracks) do
        if not song[1] then return end
        sound.PlayFile("sound/" .. song[1], "noplay noblock", function(station)
            if not IsValid(station) then return end
            DMusic.Tracks[k] = {station, song[2], song[3] or 1, song[4] or 0}
            station:SetVolume(0)
        end)
    end
end

-- Start fear track playback
function DMusic:StartFearTrack(strPack, strTrack)
    DMusic.FearTracks = DMusic.FearTracks or {}
    
    -- Stop existing fear tracks
    for k, v in pairs(DMusic.FearTracks) do
        if IsValid(v[1]) then 
            v[1]:Stop() 
            v[1] = nil 
        end
    end
    table.Empty(DMusic.FearTracks)
    
    -- Load fear tracks
    local packData = DMusic.Pack and DMusic.Pack[strPack or DMusic.CurrentPack]
    if not packData then return end
    
    -- Find high-intensity tracks (level 3+)
    local fearTracks = {}
    for seqName, tracks in pairs(packData) do
        for level, trackData in pairs(tracks) do
            if level >= 3 then
                table.insert(fearTracks, trackData)
            end
        end
    end
    
    if #fearTracks == 0 then return end
    
    -- Play a random fear track
    local track = fearTracks[math.random(#fearTracks)]
    if not track or not track[1] then return end
    
    sound.PlayFile("sound/" .. track[1], "noplay noblock", function(station)
        if not IsValid(station) then return end
        DMusic.FearTracks[1] = {station, track[2], track[3] or 1, track[4] or 0}
        station:SetVolume(0)
        DMusic.IsPlayingFearTrack = true
    end)
end

-- Stop music playback
function DMusic:Stop()
    DMusic.Tracks = DMusic.Tracks or {}
    for k, v in pairs(DMusic.Tracks) do
        if IsValid(v[1]) then 
            v[1]:Stop() 
            v[1] = nil 
        end
    end
    table.Empty(DMusic.Tracks)
    DMusic.DynamicLevel = 0
    
    -- Also stop fear tracks
    DMusic:StopFearTracks()
end

-- Stop fear tracks
function DMusic:StopFearTracks()
    DMusic.FearTracks = DMusic.FearTracks or {}
    for k, v in pairs(DMusic.FearTracks) do
        if IsValid(v[1]) then 
            v[1]:Stop() 
            v[1] = nil 
        end
    end
    table.Empty(DMusic.FearTracks)
    DMusic.IsPlayingFearTrack = false
end

-- Add panic/dynamic level (for damage transitions)
function DMusic:AddPanic(amount)
    DMusic.DynamicLevel = math.min((DMusic.DynamicLevel or 0) + amount, 5)
    DMusic.LastDamageTime = CurTime()
end

-- Add fear level
function DMusic:AddFear(amount)
    DMusic.FearLevel = math.min((DMusic.FearLevel or 0) + amount, 10)
end

-- Skip current track
function DMusic:SkipTrack()
    if not DMusic.Tracks then return end
    for _, song in pairs(DMusic.Tracks) do
        song[3] = false
    end
end

-- Get current dynamic level based on adrenaline and damage
function DMusic:GetDynamicLevel()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return 0 end
    
    local org = ply.organism
    if not org then return 0 end
    
    local level = 0
    
    -- Adrenaline contribution
    local adrenaline = (org.adrenalineAdd or 0) + (org.adrenaline or 0)
    level = level + adrenaline * 2
    
    -- Noradrenaline contribution
    local noradrenaline = org.noradrenaline or 0
    level = level + noradrenaline * 1.5
    
    -- Berserk contribution
    local berserk = org.berserk or 0
    level = level + berserk * 3
    
    -- Recent damage contribution
    local timeSinceDamage = CurTime() - (DMusic.LastDamageTime or 0)
    if timeSinceDamage < 5 then
        local damageFade = 1 - (timeSinceDamage / 5)
        level = level + (DMusic.DynamicLevel or 0) * damageFade
    end
    
    -- Decay dynamic level over time
    DMusic.DynamicLevel = math.max((DMusic.DynamicLevel or 0) - FrameTime() * 0.5, 0)
    
    -- Apply sensitivity setting
    local sensitivity = hg_dynamic_sensitivity:GetFloat()
    level = level * sensitivity
    
    return math.min(level, 5)
end

-- Get current fear level from organism
function DMusic:GetFearLevel()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return 0 end
    
    local org = ply.organism
    if not org then return 0 end
    
    local fear = org.fear or 0
    local fearadd = org.fearadd or 0
    
    -- Decay fear over time
    DMusic.FearLevel = math.max((DMusic.FearLevel or 0) - FrameTime() * 0.3, 0)
    
    -- Combine organism fear with music system fear
    local totalFear = fear + fearadd + (DMusic.FearLevel or 0)
    
    return math.min(totalFear, 10)
end

-- Main think function for music updates
DMusic.threaded = 0.0
hook.Add("Think", "DMusic.Think", function()
    if not DMusic.Tracks then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    -- Check if music is enabled
    if not hg_sound:GetBool() then
        DMusic.threaded = 0
        for _, song in pairs(DMusic.Tracks) do
            if IsValid(song[1]) and song[1]:GetState() == GMOD_CHANNEL_PLAYING then
                song[1]:Pause()
            end
        end
        DMusic:StopFearTracks()
        return
    end
    
    -- Update ambient volume from convar
    DMusic.AmbientVolume = hg_ambient_volume:GetFloat()
    
    -- Get dynamic level
    local dynamicLevel = DMusic:GetDynamicLevel()
    
    -- Get fear level
    local fearLevel = DMusic:GetFearLevel()
    local fearThreshold = hg_fear_threshold:GetFloat()
    
    -- Check if we should play fear tracks
    if fearLevel >= fearThreshold and not DMusic.IsPlayingFearTrack then
        DMusic:StartFearTrack()
    elseif fearLevel < fearThreshold and DMusic.IsPlayingFearTrack then
        DMusic:StopFearTracks()
    end
    
    -- Calculate transition speed based on dynamic level
    local transitionSpeed = 1 + dynamicLevel * 0.5
    DMusic.TransitionSpeed = transitionSpeed
    
    -- Update threaded level (smooth transition)
    local targetLevel = dynamicLevel
    DMusic.threaded = Lerp(FrameTime() * transitionSpeed, DMusic.threaded, targetLevel)
    
    -- Music volume from gmod settings
    local MusicVolume = GetConVar("snd_musicvolume")
    local musicVolume = MusicVolume and MusicVolume:GetFloat() or 1
    
    -- Process each track
    local Keys = table.GetKeys(DMusic.Tracks)
    local i = 1
    
    for adr, song in pairs(DMusic.Tracks) do
        if not IsValid(song[1]) then 
            DMusic.Tracks[adr] = nil
            continue 
        end
        
        -- Check if track should play
        local shouldPlay = false
        local nextKey = Keys[i + 1] or 5
        
        if ply:Alive() and 
           not (ply.organism and ply.organism.otrub) and
           DMusic.threaded < nextKey and
           DMusic.threaded >= adr and
           song[3] then
            shouldPlay = true
        end
        
        -- Handle track looping
        if shouldPlay and song[1]:GetTime() > song[1]:GetLength() - 1 then
            if song[3] and song[3] >= song[4] then
                song[3] = false
            else
                song[3] = song[3] + 1
            end
            song[1]:SetTime(1)
        end
        
        -- Play or pause track
        if shouldPlay then
            if song[1]:GetState() != GMOD_CHANNEL_PLAYING then
                song[1]:Play()
            end
            
            -- Calculate target volume
            local baseVolume = song[2] or 1
            local ambientMix = DMusic.AmbientVolume
            local dynamicMix = 1 - ambientMix
            
            -- Mix ambient and dynamic based on current level
            local targetVolume = baseVolume * musicVolume
            if adr == 0 then
                -- Ambient track
                targetVolume = targetVolume * (ambientMix + dynamicMix * (1 - DMusic.threaded / 5))
            else
                -- Dynamic track
                targetVolume = targetVolume * (dynamicMix * (DMusic.threaded / 5))
            end
            
            -- Reduce volume when fear track is playing
            if DMusic.IsPlayingFearTrack then
                targetVolume = targetVolume * 0.3
            end
            
            -- Smooth volume transition
            local currentVolume = song[1]:GetVolume()
            local newVolume = Lerp(FrameTime() * transitionSpeed * 2, currentVolume, targetVolume)
            song[1]:SetVolume(math.max(newVolume, 0))
        else
            -- Fade out and pause
            local currentVolume = song[1]:GetVolume()
            if currentVolume > 0.01 then
                local newVolume = Lerp(FrameTime() * transitionSpeed * 2, currentVolume, 0)
                song[1]:SetVolume(newVolume)
            else
                if song[1]:GetState() == GMOD_CHANNEL_PLAYING then
                    song[1]:Pause()
                    if not song[3] then
                        DMusic:Start(DMusic.CurrentPack)
                    end
                end
            end
        end
        
        i = i + 1
    end
    
    -- Process fear tracks
    if DMusic.FearTracks then
        for _, song in pairs(DMusic.FearTracks) do
            if not IsValid(song[1]) then 
                DMusic.FearTracks[_] = nil
                continue 
            end
            
            local shouldPlay = ply:Alive() and 
                              not (ply.organism and ply.organism.otrub) and
                              fearLevel >= fearThreshold
            
            if shouldPlay then
                if song[1]:GetState() != GMOD_CHANNEL_PLAYING then
                    song[1]:Play()
                end
                
                -- Calculate fear track volume
                local baseVolume = song[2] or 1
                local fearVolumeMul = hg_fear_volume:GetFloat()
                local fearIntensity = math.min(fearLevel / 10, 1)
                local targetVolume = baseVolume * musicVolume * fearVolumeMul * fearIntensity
                
                -- Smooth volume transition
                local currentVolume = song[1]:GetVolume()
                local newVolume = Lerp(FrameTime() * transitionSpeed * 2, currentVolume, targetVolume)
                song[1]:SetVolume(math.max(newVolume, 0))
            else
                -- Fade out fear track
                local currentVolume = song[1]:GetVolume()
                if currentVolume > 0.01 then
                    local newVolume = Lerp(FrameTime() * transitionSpeed * 2, currentVolume, 0)
                    song[1]:SetVolume(newVolume)
                else
                    if song[1]:GetState() == GMOD_CHANNEL_PLAYING then
                        song[1]:Pause()
                        DMusic.IsPlayingFearTrack = false
                    end
                end
            end
        end
    end
end)

-- Hook for damage events to trigger dynamic transitions
hook.Add("HomigradDamage", "DMusic.Damage", function(ply, dmgInfo, hitgroup, ent, harm, hitBoxs, inputHole)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local damage = dmgInfo:GetDamage()
    local damageType = dmgInfo:GetDamageType()
    
    -- Calculate panic amount based on damage
    local panicAmount = damage * 25
    
    -- Melee damage causes more panic
    if damageType == DMG_CLUB or damageType == DMG_SLASH then
        panicAmount = panicAmount * 1.5
    end
    
    -- Explosion damage causes significant panic
    if damageType == DMG_BLAST then
        panicAmount = panicAmount * 2
    end
    
    -- Send panic to victim
    if ply == LocalPlayer() then
        DMusic:AddPanic(panicAmount)
        -- Also add fear from damage
        DMusic:AddFear(damage * 0.5)
    end
    
    -- Send panic to attacker
    local attacker = dmgInfo:GetAttacker()
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= ply then
        if attacker == LocalPlayer() then
            DMusic:AddPanic(panicAmount * 0.3)
        else
            -- Network to attacker
            if SERVER then
                net.Start("DMusic_Panic")
                    net.WriteFloat(panicAmount * 0.3)
                net.Send(attacker)
            end
        end
    end
end)

-- Hook for organism changes to sync with server mode
hook.Add("Org Think", "DMusic.Sync", function(owner, org, timeValue)
    if not IsValid(owner) or not owner:IsPlayer() then return end
    if owner ~= LocalPlayer() then return end
    
    -- Check for mode changes (this would be set by server)
    if owner.GetNW2String then
        local serverMode = owner:GetNW2String("GameMode", "")
        if serverMode ~= "" and serverMode ~= DMusic.CurrentMode then
            DMusic.CurrentMode = serverMode
            DMusic:ApplyModePack()
        end
    end
    
    -- Update fear from organism
    if org.fearadd and org.fearadd > 0 then
        DMusic:AddFear(org.fearadd * 0.1)
    end
end)

-- Hook for witnessing deaths (increases fear)
hook.Add("PlayerDeath", "DMusic.Fear", function(victim, inflictor, attacker)
    if victim == LocalPlayer() then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    -- Check if player can see the death
    local dist = ply:GetPos():Distance(victim:GetPos())
    if dist < 1000 then
        local visible = ply:Visible(victim)
        if visible then
            DMusic:AddFear(1)
        end
    end
end)

-- Hook for hearing sounds (increases fear for scary sounds)
hook.Add("EntityEmitSound", "DMusic.FearSound", function(data)
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local soundName = data.SoundName or ""
    
    -- Check for scary sounds
    local scaryPatterns = {
        "scream",
        "cry",
        "groan",
        "moan",
        "death",
        "pain",
        "horror",
        "scary"
    }
    
    for _, pattern in ipairs(scaryPatterns) do
        if string.find(soundName:lower(), pattern) then
            local dist = ply:GetPos():Distance(data.Pos or Vector(0,0,0))
            if dist < 500 then
                DMusic:AddFear(0.5)
            end
            break
        end
    end
end)

-- Console commands
concommand.Add("hg_dmusic_setpack", function(ply, cmd, args)
    if not args[1] then return end
    DMusic:SetPack(args[1])
end, nil, "Set the current music pack")

concommand.Add("hg_dmusic_setmode", function(ply, cmd, args)
    if not args[1] then return end
    DMusic.CurrentMode = args[1]
    DMusic:ApplyModePack()
end, nil, "Set the current game mode for music")

concommand.Add("hg_dmusic_skip", function()
    DMusic:SkipTrack()
end, nil, "Skip the current music track")

concommand.Add("hg_dmusic_stop", function()
    DMusic:Stop()
end, nil, "Stop all music")

concommand.Add("hg_dmusic_fear", function(ply, cmd, args)
    if not args[1] then return end
    DMusic:AddFear(tonumber(args[1]) or 1)
end, nil, "Add fear level")

concommand.Add("hg_dmusic_list", function()
    print("=== Available Music Packs ===")
    if DMusic.Pack then
        for name, _ in pairs(DMusic.Pack) do
            print("- " .. name)
        end
    end
    print("\n=== Current Settings ===")
    print("Music Enabled: " .. tostring(hg_sound:GetBool()))
    print("Ambient Volume: " .. hg_ambient_volume:GetFloat())
    print("Dynamic Sensitivity: " .. hg_dynamic_sensitivity:GetFloat())
    print("Fear Threshold: " .. hg_fear_threshold:GetFloat())
    print("Fear Volume: " .. hg_fear_volume:GetFloat())
    print("Current Pack: " .. DMusic.CurrentPack)
    print("Current Mode: " .. DMusic.CurrentMode)
    print("Dynamic Level: " .. DMusic.DynamicLevel)
    print("Fear Level: " .. DMusic.FearLevel)
    print("Playing Fear Track: " .. tostring(DMusic.IsPlayingFearTrack))
end, nil, "List available music packs and current settings")

-- Auto-apply mode pack on spawn
hook.Add("PlayerSpawn", "DMusic.Spawn", function(ply)
    if ply ~= LocalPlayer() then return end
    timer.Simple(1, function()
        if IsValid(ply) then
            DMusic:ApplyModePack()
        end
    end)
end)

-- Initialize on first load
hook.Add("InitPostEntity", "DMusic.Init", function()
    timer.Simple(2, function()
        DMusic:ApplyModePack()
    end)
end)
