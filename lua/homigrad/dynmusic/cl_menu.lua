--[[
    Dynamic Music System - Settings Menu
    Provides UI for music configuration
--]]

hg = hg or {}
hg.DynaMusic = hg.DynaMusic or {}
local DMusic = hg.DynaMusic

-- Menu panel
local PANEL = {}

function PANEL:Init()
    self:SetSize(600, 500)
    self:SetTitle("Dynamic Music Settings")
    self:Center()
    self:MakePopup()
    
    -- Create tabs
    self.Tabs = vgui.Create("DPropertySheet", self)
    self.Tabs:Dock(FILL)
    self.Tabs:DockMargin(5, 5, 5, 5)
    
    -- General settings tab
    self.GeneralTab = vgui.Create("DPanel")
    self.GeneralTab.Paint = function() end
    self.Tabs:AddSheet("General", self.GeneralTab, "icon16/music.png")
    
    -- Music packs tab
    self.PacksTab = vgui.Create("DPanel")
    self.PacksTab.Paint = function() end
    self.Tabs:AddSheet("Music Packs", self.PacksTab, "icon16/folder.png")
    
    -- Fear tracks tab
    self.FearTab = vgui.Create("DPanel")
    self.FearTab.Paint = function() end
    self.Tabs:AddSheet("Fear Tracks", self.FearTab, "icon16/emoticon_unhappy.png")
    
    -- Mode mapping tab
    self.ModeTab = vgui.Create("DPanel")
    self.ModeTab.Paint = function() end
    self.Tabs:AddSheet("Mode Mapping", self.ModeTab, "icon16/chart_organisation.png")
    
    self:BuildGeneralTab()
    self:BuildPacksTab()
    self:BuildFearTab()
    self:BuildModeTab()
end

function PANEL:BuildGeneralTab()
    local scroll = vgui.Create("DScrollPanel", self.GeneralTab)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 10, 10, 10)
    
    -- Enable/Disable music
    local enableCheck = vgui.Create("DCheckBoxLabel", scroll)
    enableCheck:Dock(TOP)
    enableCheck:DockMargin(0, 0, 0, 10)
    enableCheck:SetText("Enable Dynamic Music")
    enableCheck:SetConVar("hg_dmusic")
    enableCheck:SetValue(GetConVar("hg_dmusic"):GetBool())
    
    -- Ambient volume slider
    local ambientLabel = vgui.Create("DLabel", scroll)
    ambientLabel:Dock(TOP)
    ambientLabel:DockMargin(0, 10, 0, 5)
    ambientLabel:SetText("Ambient Music Volume")
    
    local ambientSlider = vgui.Create("DNumSlider", scroll)
    ambientSlider:Dock(TOP)
    ambientSlider:DockMargin(0, 0, 0, 10)
    ambientSlider:SetConVar("hg_dmusic_ambient_vol")
    ambientSlider:SetMin(0)
    ambientSlider:SetMax(1)
    ambientSlider:SetDecimals(2)
    ambientSlider:SetText("Volume")
    
    -- Dynamic sensitivity slider
    local sensLabel = vgui.Create("DLabel", scroll)
    sensLabel:Dock(TOP)
    sensLabel:DockMargin(0, 10, 0, 5)
    sensLabel:SetText("Dynamic Transition Sensitivity")
    
    local sensSlider = vgui.Create("DNumSlider", scroll)
    sensSlider:Dock(TOP)
    sensSlider:DockMargin(0, 0, 0, 10)
    sensSlider:SetConVar("hg_dmusic_sensitivity")
    sensSlider:SetMin(0.5)
    sensSlider:SetMax(2)
    sensSlider:SetDecimals(2)
    sensSlider:SetText("Sensitivity")
    
    -- Default pack selection
    local defaultLabel = vgui.Create("DLabel", scroll)
    defaultLabel:Dock(TOP)
    defaultLabel:DockMargin(0, 10, 0, 5)
    defaultLabel:SetText("Default Music Pack")
    
    local defaultCombo = vgui.Create("DComboBox", scroll)
    defaultCombo:Dock(TOP)
    defaultCombo:DockMargin(0, 0, 0, 10)
    defaultCombo:SetConVar("hg_dmusic_default_pack")
    
    if DMusic.Pack then
        for name, _ in pairs(DMusic.Pack) do
            defaultCombo:AddChoice(name, name)
        end
    end
    
    defaultCombo:SetValue(GetConVar("hg_dmusic_default_pack"):GetString())
    defaultCombo.OnSelect = function(self, index, value, data)
        RunConsoleCommand("hg_dmusic_default_pack", data)
    end
    
    -- Current status
    local statusLabel = vgui.Create("DLabel", scroll)
    statusLabel:Dock(TOP)
    statusLabel:DockMargin(0, 20, 0, 5)
    statusLabel:SetText("Current Status:")
    statusLabel:SetFont("DermaDefaultBold")
    
    local statusText = vgui.Create("DLabel", scroll)
    statusText:Dock(TOP)
    statusText:DockMargin(0, 0, 0, 5)
    statusText:SetText("Pack: " .. (DMusic.CurrentPack or "None"))
    
    local modeText = vgui.Create("DLabel", scroll)
    modeText:Dock(TOP)
    modeText:DockMargin(0, 0, 0, 5)
    modeText:SetText("Mode: " .. (DMusic.CurrentMode or "default"))
    
    local levelText = vgui.Create("DLabel", scroll)
    levelText:Dock(TOP)
    levelText:DockMargin(0, 0, 0, 5)
    levelText.Think = function(self)
        self:SetText("Dynamic Level: " .. string.format("%.2f", DMusic.DynamicLevel or 0))
    end
    
    -- Skip track button
    local skipBtn = vgui.Create("DButton", scroll)
    skipBtn:Dock(TOP)
    skipBtn:DockMargin(0, 20, 0, 5)
    skipBtn:SetText("Skip Current Track")
    skipBtn.DoClick = function()
        RunConsoleCommand("hg_dmusic_skip")
    end
    
    -- Stop music button
    local stopBtn = vgui.Create("DButton", scroll)
    stopBtn:Dock(TOP)
    stopBtn:DockMargin(0, 0, 0, 5)
    stopBtn:SetText("Stop All Music")
    stopBtn.DoClick = function()
        RunConsoleCommand("hg_dmusic_stop")
    end
end

function PANEL:BuildPacksTab()
    local scroll = vgui.Create("DScrollPanel", self.PacksTab)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 10, 10, 10)
    
    local packLabel = vgui.Create("DLabel", scroll)
    packLabel:Dock(TOP)
    packLabel:DockMargin(0, 0, 0, 10)
    packLabel:SetText("Available Music Packs:")
    packLabel:SetFont("DermaLarge")
    
    if DMusic.Pack then
        for packName, sequences in pairs(DMusic.Pack) do
            local packPanel = vgui.Create("DPanel", scroll)
            packPanel:Dock(TOP)
            packPanel:DockMargin(0, 0, 0, 10)
            packPanel:SetTall(100)
            packPanel.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 200))
                draw.RoundedBox(4, 2, 2, w - 4, h - 4, Color(60, 60, 60, 200))
            end
            
            local packNameLabel = vgui.Create("DLabel", packPanel)
            packNameLabel:Dock(TOP)
            packNameLabel:DockMargin(10, 5, 0, 0)
            packNameLabel:SetText(packName)
            packNameLabel:SetFont("DermaDefaultBold")
            
            local seqCount = 0
            for _ in pairs(sequences) do seqCount = seqCount + 1 end
            
            local seqLabel = vgui.Create("DLabel", packPanel)
            seqLabel:Dock(TOP)
            seqLabel:DockMargin(10, 0, 0, 0)
            seqLabel:SetText("Sequences: " .. seqCount)
            
            local selectBtn = vgui.Create("DButton", packPanel)
            selectBtn:Dock(BOTTOM)
            selectBtn:DockMargin(10, 0, 10, 10)
            selectBtn:SetTall(25)
            selectBtn:SetText("Select Pack")
            selectBtn.DoClick = function()
                RunConsoleCommand("hg_dmusic_setpack", packName)
            end
        end
    end
end

function PANEL:BuildFearTab()
    local scroll = vgui.Create("DScrollPanel", self.FearTab)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 10, 10, 10)
    
    local fearLabel = vgui.Create("DLabel", scroll)
    fearLabel:Dock(TOP)
    fearLabel:DockMargin(0, 0, 0, 10)
    fearLabel:SetText("Fear-Based Music Tracks")
    fearLabel:SetFont("DermaLarge")
    
    local descLabel = vgui.Create("DLabel", scroll)
    descLabel:Dock(TOP)
    descLabel:DockMargin(0, 0, 0, 10)
    descLabel:SetWrap(true)
    descLabel:SetAutoStretchVertical(true)
    descLabel:SetText("These tracks play when the player experiences high fear levels. Fear is increased by witnessing deaths, being injured, or being in dangerous situations.")
    
    -- Fear threshold slider
    local thresholdLabel = vgui.Create("DLabel", scroll)
    thresholdLabel:Dock(TOP)
    thresholdLabel:DockMargin(0, 10, 0, 5)
    thresholdLabel:SetText("Fear Track Threshold")
    
    local thresholdSlider = vgui.Create("DNumSlider", scroll)
    thresholdSlider:Dock(TOP)
    thresholdSlider:DockMargin(0, 0, 0, 10)
    thresholdSlider:SetConVar("hg_dmusic_fear_threshold")
    thresholdSlider:SetMin(0)
    thresholdSlider:SetMax(10)
    thresholdSlider:SetDecimals(1)
    thresholdSlider:SetText("Threshold")
    
    -- Create fear tracks convar if it doesn't exist
    if not ConVarExists("hg_dmusic_fear_threshold") then
        CreateClientConVar("hg_dmusic_fear_threshold", "3", true, false, "Fear level threshold to trigger fear tracks", 0, 10)
    end
    
    -- Fear volume multiplier
    local fearVolLabel = vgui.Create("DLabel", scroll)
    fearVolLabel:Dock(TOP)
    fearVolLabel:DockMargin(0, 10, 0, 5)
    fearVolLabel:SetText("Fear Track Volume Multiplier")
    
    local fearVolSlider = vgui.Create("DNumSlider", scroll)
    fearVolSlider:Dock(TOP)
    fearVolSlider:DockMargin(0, 0, 0, 10)
    fearVolSlider:SetConVar("hg_dmusic_fear_volume")
    fearVolSlider:SetMin(0)
    fearVolSlider:SetMax(2)
    fearVolSlider:SetDecimals(2)
    fearVolSlider:SetText("Volume")
    
    -- Create fear volume convar if it doesn't exist
    if not ConVarExists("hg_dmusic_fear_volume") then
        CreateClientConVar("hg_dmusic_fear_volume", "1", true, false, "Fear track volume multiplier", 0, 2)
    end
    
    -- Current fear level display
    local currentFearLabel = vgui.Create("DLabel", scroll)
    currentFearLabel:Dock(TOP)
    currentFearLabel:DockMargin(0, 20, 0, 5)
    currentFearLabel:SetText("Current Fear Level:")
    currentFearLabel:SetFont("DermaDefaultBold")
    
    local currentFearText = vgui.Create("DLabel", scroll)
    currentFearText:Dock(TOP)
    currentFearText:DockMargin(0, 0, 0, 5)
    currentFearText.Think = function(self)
        local ply = LocalPlayer()
        if IsValid(ply) and ply.organism then
            local fear = ply.organism.fear or 0
            self:SetText(string.format("%.2f", fear))
        else
            self:SetText("N/A")
        end
    end
    
    -- Fear tracks list
    local tracksLabel = vgui.Create("DLabel", scroll)
    tracksLabel:Dock(TOP)
    tracksLabel:DockMargin(0, 20, 0, 5)
    tracksLabel:SetText("Available Fear Tracks:")
    tracksLabel:SetFont("DermaDefaultBold")
    
    -- Display fear tracks from packs
    if DMusic.Pack then
        for packName, sequences in pairs(DMusic.Pack) do
            for seqName, tracks in pairs(sequences) do
                for level, trackData in pairs(tracks) do
                    if tonumber(level) and tonumber(level) >= 3 then -- High intensity tracks
                        local trackPanel = vgui.Create("DPanel", scroll)
                        trackPanel:Dock(TOP)
                        trackPanel:DockMargin(0, 0, 0, 5)
                        trackPanel:SetTall(30)
                        trackPanel.Paint = function(self, w, h)
                            draw.RoundedBox(2, 0, 0, w, h, Color(50, 30, 30, 200))
                        end
                        
                        local trackLabel = vgui.Create("DLabel", trackPanel)
                        trackLabel:Dock(FILL)
                        trackLabel:DockMargin(5, 0, 0, 0)
                        trackLabel:SetText(string.format("[%s] %s - Level %d", packName, seqName, level))
                    end
                end
            end
        end
    end
end

function PANEL:BuildModeTab()
    local scroll = vgui.Create("DScrollPanel", self.ModeTab)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 10, 10, 10)
    
    local modeLabel = vgui.Create("DLabel", scroll)
    modeLabel:Dock(TOP)
    modeLabel:DockMargin(0, 0, 0, 10)
    modeLabel:SetText("Game Mode Music Mapping")
    modeLabel:SetFont("DermaLarge")
    
    local descLabel = vgui.Create("DLabel", scroll)
    descLabel:Dock(TOP)
    descLabel:DockMargin(0, 0, 0, 10)
    descLabel:SetWrap(true)
    descLabel:SetAutoStretchVertical(true)
    descLabel:SetText("Map game modes to specific music packs. When a mode is active, its assigned pack will play automatically.")
    
    -- Mode mapping list
    if DMusic.ModePacks then
        for mode, pack in pairs(DMusic.ModePacks) do
            local modePanel = vgui.Create("DPanel", scroll)
            modePanel:Dock(TOP)
            modePanel:DockMargin(0, 0, 0, 5)
            modePanel:SetTall(40)
            modePanel.Paint = function(self, w, h)
                draw.RoundedBox(2, 0, 0, w, h, Color(40, 40, 40, 200))
            end
            
            local modeName = vgui.Create("DLabel", modePanel)
            modeName:Dock(LEFT)
            modeName:DockMargin(10, 0, 0, 0)
            modeName:SetWide(150)
            modeName:SetText(mode)
            modeName:SetFont("DermaDefaultBold")
            
            local packCombo = vgui.Create("DComboBox", modePanel)
            packCombo:Dock(RIGHT)
            packCombo:DockMargin(0, 5, 10, 5)
            packCombo:SetWide(200)
            packCombo:SetValue(pack)
            
            if DMusic.Pack then
                for packName, _ in pairs(DMusic.Pack) do
                    packCombo:AddChoice(packName, packName)
                end
            end
            
            packCombo.OnSelect = function(self, index, value, data)
                DMusic.ModePacks[mode] = data
            end
        end
    end
    
    -- Add new mode mapping
    local addPanel = vgui.Create("DPanel", scroll)
    addPanel:Dock(TOP)
    addPanel:DockMargin(0, 20, 0, 0)
    addPanel:SetTall(40)
    addPanel.Paint = function(self, w, h)
        draw.RoundedBox(2, 0, 0, w, h, Color(30, 50, 30, 200))
    end
    
    local modeEntry = vgui.Create("DTextEntry", addPanel)
    modeEntry:Dock(LEFT)
    modeEntry:DockMargin(10, 5, 0, 5)
    modeEntry:SetWide(150)
    modeEntry:SetPlaceholderText("Mode name")
    
    local packEntry = vgui.Create("DTextEntry", addPanel)
    packEntry:Dock(LEFT)
    packEntry:DockMargin(5, 5, 0, 5)
    packEntry:SetWide(150)
    packEntry:SetPlaceholderText("Pack name")
    
    local addBtn = vgui.Create("DButton", addPanel)
    addBtn:Dock(RIGHT)
    addBtn:DockMargin(0, 5, 10, 5)
    addBtn:SetWide(80)
    addBtn:SetText("Add")
    addBtn.DoClick = function()
        local mode = modeEntry:GetValue()
        local pack = packEntry:GetValue()
        if mode ~= "" and pack ~= "" then
            DMusic.ModePacks[mode] = pack
            modeEntry:SetValue("")
            packEntry:SetValue("")
        end
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 240))
end

vgui.Register("DMusicSettings", PANEL, "DFrame")

-- Console command to open menu
concommand.Add("hg_dmusic_menu", function()
    vgui.Create("DMusicSettings")
end, nil, "Open Dynamic Music Settings")

-- Add to spawn menu
hook.Add("PopulateToolMenu", "DMusic.Menu", function()
    spawnmenu.AddToolMenuOption("Options", "Homigrad", "DMusicSettings", "Dynamic Music", "", "", function(panel)
        panel:ClearControls()
        
        panel:Button("Open Music Settings", "hg_dmusic_menu")
        panel:ControlHelp("\nQuick Settings:")
        
        panel:CheckBox("Enable Music", "hg_dmusic")
        panel:NumSlider("Ambient Volume", "hg_dmusic_ambient_vol", 0, 1, 2)
        panel:NumSlider("Sensitivity", "hg_dmusic_sensitivity", 0.5, 2, 2)
        panel:NumSlider("Fear Threshold", "hg_dmusic_fear_threshold", 0, 10, 1)
        panel:NumSlider("Fear Volume", "hg_dmusic_fear_volume", 0, 2, 2)
        
        panel:Button("Skip Track", "hg_dmusic_skip")
        panel:Button("Stop Music", "hg_dmusic_stop")
    end)
end)
