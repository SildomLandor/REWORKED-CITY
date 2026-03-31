-- Values
local maps = {}
local time = 0
local votes = {}
local winmap = ""
local rtvStarted = false
local rtvEnded = false

local VoteCD = 0

-- Kiosk Theme Assets
local orange = Color(255,0,0)
local black = Color(10,10,10)
local dim = Color(0,0,0,200)
local white = Color(255,255,255)
local gray = Color(40,40,40)

surface.CreateFont("MC_TypewriterLarge",{font="Courier New",size=42,weight=700})
surface.CreateFont("MC_TypewriterMedium",{font="Courier New",size=32,weight=700})
surface.CreateFont("MC_Typewriter",{font="Courier New",size=24,weight=700})
surface.CreateFont("MC_UI",{font="Tahoma",size=18,weight=500})
surface.CreateFont("MC_UI_Small",{font="Tahoma",size=14,weight=500})

-- Background Code Flow
local codePool = {
    "RTV System Initialized...",
    "Scanning Map Database...",
    "Connecting to Vote Server...",
    "Analyzing User Input...",
    "Processing Vote...",
    "Updating Map Rotation...",
    "Calculating Probabilities...",
    "Syncing with Clients...",
    "Vote Registered.",
    "Map Selection Pending...",
    "Waiting for Consensus...",
    "System Override: User Vote",
    "Loading Map Preview...",
    "Accessing Navigation Data...",
}

local codeFlow
local function drawKioskBackground(w,h,frac)
    local t = CurTime()
    surface.SetDrawColor(black)
    surface.DrawRect(0,0,w,h)
    
    -- Grid
    local grid = 64
    local ox = (t*30)%grid
    local oy = (t*18)%grid
    local af = math.Clamp(frac or 0,0,1)
    
    surface.SetDrawColor(255,255,255,math.floor(10*af))
    for x=-grid,w+grid,grid do
        surface.DrawRect(x-ox,0,1,h)
    end
    for y=-grid,h+grid,grid do
        surface.DrawRect(0,y-oy,w,1)
    end

    -- Code Rain
    if not codeFlow or codeFlow.w ~= w or codeFlow.h ~= h then
        codeFlow = {w=w,h=h,lines={}}
        local rows = 12
        for i=1,rows do
            local text = codePool[(i-1)%#codePool+1]
            local dir = (i%2==0) and 1 or -1
            local y = math.floor(h*(0.1 + 0.07*i))
            table.insert(codeFlow.lines,{text=text,dir=dir,y=y,x=(dir==1) and -400 or w+400,speed=60+15*i,char=0,rate=32+6*i})
        end
    end

    surface.SetFont("MC_Typewriter")
    for i=1,#codeFlow.lines do
        local L = codeFlow.lines[i]
        L.char = math.min(#L.text, L.char + FrameTime()*L.rate)
        local disp = string.sub(L.text,1, math.floor(L.char))
        local tw, th = surface.GetTextSize(disp)
        
        L.x = L.x + L.dir * L.speed * FrameTime()
        if L.dir == 1 and L.x > w then L.x = -tw end
        if L.dir == -1 and L.x + tw < 0 then L.x = w end
        
        local a = math.floor(80*af)
        surface.SetTextColor(255,115,0,a)
        surface.SetTextPos(L.x, L.y)
        surface.DrawText(disp)
    end
    
    -- Scanlines
    surface.SetDrawColor(0,0,0,100)
    for y=0,h,4 do
        surface.DrawRect(0,y,w,2)
    end

    -- Vignette
    local phase = (math.sin(t*1.1)*0.5 + 0.5)
    local bandH = 160 + 120 * phase
    surface.SetDrawColor(255,115,0,math.floor((20 + 20 * phase)*af))
    surface.SetMaterial(Material("vgui/gradient-d"))
    surface.DrawTexturedRect(0, h - bandH, w, bandH)
    
    -- Darken slightly
    surface.SetDrawColor(0,0,0,math.floor(dim.a * af))
    surface.DrawRect(0,0,w,h)
end

local function typewriter(panel,text,font,x,y,color,speed)
    panel._tw = panel._tw or {i=0, last=0}
    local st = panel._tw
    
    -- Glitch effect
    if math.random() < 0.05 then
        local glitch = ""
        for k=1, #text do glitch = glitch .. string.char(math.random(33,126)) end
        surface.SetFont(font)
        surface.SetTextColor(orange)
        surface.SetTextPos(x+math.random(-2,2),y+math.random(-2,2))
        surface.DrawText(string.sub(glitch, 1, st.i))
    end

    if st.last < CurTime() then
        st.i = math.min(#text, st.i + 1)
        st.last = CurTime() + (speed or 0.02)
    end
    
    surface.SetFont(font)
    surface.SetTextColor(color)
    surface.SetTextPos(x,y)
    surface.DrawText(string.sub(text,1,st.i))
end

local function PlayUI(name)
    local sounds = {
        popup = "garrysmod/ui_click.wav",
        click = "buttons/button14.wav",
        hover = "buttons/lightswitch2.wav",
        error = "buttons/button10.wav",
        purchase = "buttons/button3.wav"
    }
    local s = sounds[name] or "garrysmod/ui_click.wav"
    surface.PlaySound(s)
end

local function GetMapIcon(mapName)
    if mapName == "random" then
        local mat = Material("icon64/random.png")
        if not mat:IsError() then return mat end
        return Material("icon64/tool.png")
    end

    -- Try standard thumb
    local mat = Material("maps/thumb/" .. mapName .. ".png")
    if not mat:IsError() then return mat end
    
    -- Try without thumb folder
    mat = Material("maps/" .. mapName .. ".png")
    if not mat:IsError() then return mat end

    -- Try finding gamemode specific icons or generic fallback
    -- Fallback to a placeholder if absolutely nothing found
    return Material("maps/thumb/noicon.png") 
end

function zb.RTVMenu()
    system.FlashWindow()
    PlayUI("popup")

    local RTVMenu = vgui.Create("DFrame")
    RTVMenu:SetSize(ScrW(), ScrH())
    RTVMenu:SetTitle("")
    RTVMenu:MakePopup()
    RTVMenu:SetDraggable(false)
    RTVMenu:ShowCloseButton(false)
    RTVMenu:SetKeyboardInputEnabled(false)
    RTVMenu._open = 0
    RTVMenu.winnerBlinkNext = 0
    
    RTVMenu.Paint = function(s,w,h)
        drawKioskBackground(w,h,s._open)
    end
    
    RTVMenu.Think = function(s)
        local dt = FrameTime()
        s._open = math.min(1, s._open + dt*4)
        
        -- Handle Winner Blinking Sound
        if winmap and winmap ~= "" then
            if CurTime() > s.winnerBlinkNext then
                 surface.PlaySound("ui/press.ogg")
                 s.winnerBlinkNext = CurTime() + 1
            end
        end
    end

    -- Main Container
    local container = vgui.Create("DPanel", RTVMenu)
    container:Dock(FILL)
    container:DockMargin(32, 32, 32, 32)
    container.Paint = function() end

    -- Header
    local header = vgui.Create("DPanel", container)
    header:Dock(TOP)
    header:SetTall(80)
    header.Paint = function(s,w,h) 
        surface.SetDrawColor(orange)
        surface.DrawRect(0, h-2, w, 2)
    end
    
    local title = vgui.Create("DPanel", header)
    title:Dock(LEFT)
    title:SetWide(500)
    title.Paint = function(s,w,h)
        typewriter(s, "ROCK THE VOTE", "MC_TypewriterLarge", 0, 10, orange, 0.03)
    end
    
    local timerLabel = vgui.Create("DLabel", header)
    timerLabel:Dock(RIGHT)
    timerLabel:SetFont("MC_Typewriter")
    timerLabel:SetTextColor(white)
    timerLabel:SetText("TIME: " .. math.ceil(time - CurTime()))
    timerLabel:SizeToContents()
    timerLabel:DockMargin(0, 20, 10, 0)
    timerLabel.Think = function(s)
        if winmap and winmap ~= "" then
            s:SetText("VOTE COMPLETE")
            s:SetTextColor(orange)
            s:SizeToContents()
            return
        end

        local remaining = math.max(0, math.ceil(time - CurTime()))
        s:SetText("TIME: " .. remaining)
        s:SizeToContents()
        
        -- Do not close menu when time ends, wait for winner or map change
    end

    -- Content Area
    local content = vgui.Create("DPanel", container)
    content:Dock(FILL)
    content:DockMargin(0, 16, 0, 0)
    content.Paint = function() end

    -- Preview Panel (Right Side)
    local previewPanel = vgui.Create("DPanel", content)
    previewPanel:SetWide(ScrW() * 0.6)
    previewPanel:Dock(RIGHT)
    previewPanel:DockMargin(16, 0, 0, 0)
    
    -- Variables for preview
    previewPanel.SelectedMap = nil
    
    previewPanel.Paint = function(s,w,h)
        surface.SetDrawColor(0,0,0,160)
        surface.DrawRect(0,0,w,h)
        surface.SetDrawColor(orange)
        surface.DrawOutlinedRect(0,0,w,h,2)
        
        -- Tech decorations
        surface.DrawRect(0,0,40,4)
        surface.DrawRect(0,0,4,40)
        surface.DrawRect(w-40,h-4,40,4)
        surface.DrawRect(w-4,h-40,4,40)

        if not s.SelectedMap then
            draw.SimpleText("SELECT A DATA CARTRIDGE", "MC_TypewriterMedium", w/2, h/2, orange, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end

        local mapData = s.SelectedMap
        local isWinner = (winmap == mapData.name)
        
        -- Winner Blink Effect
        if isWinner and math.floor(CurTime()) % 2 == 0 then
             surface.SetDrawColor(orange)
             surface.DrawRect(16, 16, w - 32, h * 0.6)
        end
        
        -- Draw Map Image
        if mapData.icon then
            surface.SetDrawColor(255,255,255,255)
            surface.SetMaterial(mapData.icon)
            local iw, ih = w - 32, h * 0.6
            surface.DrawTexturedRect(16, 16, iw, ih)
            
            -- Overlay scanlines on image
            surface.SetDrawColor(0,0,0,100)
            for y=16, 16+ih, 4 do
                surface.DrawRect(16, y, iw, 2)
            end
            
            -- Image Border
            surface.SetDrawColor(orange)
            surface.DrawOutlinedRect(16, 16, iw, ih, 2)
        end

        -- Map Name
        draw.SimpleText("TARGET: " .. mapData.dispName, "MC_TypewriterLarge", 24, h * 0.65, white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        -- Votes Bar
        local voteCount = votes[mapData.name] or 0
        local totalPlayers = math.max(1, #player.GetAll())
        local percent = math.Clamp(voteCount / totalPlayers, 0, 1)
        
        local barY = h * 0.75
        local barH = 32
        local barW = w - 48
        
        -- Bar Background
        surface.SetDrawColor(gray)
        surface.DrawRect(24, barY, barW, barH)
        
        -- Bar Fill
        surface.SetDrawColor(orange)
        surface.DrawRect(24, barY, barW * percent, barH)
        
        -- Bar Outline
        surface.SetDrawColor(white)
        surface.DrawOutlinedRect(24, barY, barW, barH, 1)
        
        draw.SimpleText("VOTES: " .. voteCount .. " / " .. totalPlayers .. " (" .. math.Round(percent * 100) .. "%)", "MC_UI", 30, barY + 6, black, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        -- Status
        if mapData.name == winmap then
             if math.floor(CurTime()) % 2 == 0 then
                draw.SimpleText("STATUS: WINNER DECLARED", "MC_TypewriterMedium", 24, h * 0.85, orange, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
             end
        elseif mapData.name == "random" then
             draw.SimpleText("STATUS: UNPREDICTABLE", "MC_TypewriterMedium", 24, h * 0.85, white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        else
             draw.SimpleText("STATUS: CANDIDATE", "MC_TypewriterMedium", 24, h * 0.85, white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end

    -- Map List (Left Side)
    local listPanel = vgui.Create("DPanel", content)
    listPanel:Dock(FILL)
    listPanel.Paint = function(s,w,h)
        surface.SetDrawColor(0,0,0,160)
        surface.DrawRect(0,0,w,h)
        surface.SetDrawColor(orange)
        surface.DrawOutlinedRect(0,0,w,h,2)
    end
    
    local scroll = vgui.Create("DScrollPanel", listPanel)
    scroll:Dock(FILL)
    scroll:DockMargin(2,2,2,2)
    local sbar = scroll:GetVBar()
    sbar:SetHideButtons(true)
    sbar.Paint = function(s,w,h) surface.SetDrawColor(0,0,0,100) surface.DrawRect(0,0,w,h) end
    sbar.btnGrip.Paint = function(s,w,h) surface.SetDrawColor(orange) surface.DrawRect(0,0,w,h) end

    -- Populate Map List
    for k, v in ipairs(maps) do
        local mapName = v
        local mapIcon = GetMapIcon(v)
        local mapDispName

        if v == "random" then
            mapDispName = "RANDOM MAP"
        else
            local txt = v
            txt = string.Explode("_", txt)
            table.remove(txt, 1)
            if txt[1] then
                txt[1] = string.upper(string.Left(txt[1], 1)) .. string.sub(txt[1], 2)
                mapDispName = string.upper(table.concat(txt, " "))
            else
                mapDispName = string.upper(v)
            end
        end

        local btn = scroll:Add("DButton")
        btn:Dock(TOP)
        btn:SetTall(48)
        btn:DockMargin(4,4,4,0)
        btn:SetText("")
        
        btn.MapData = {
            name = v,
            dispName = mapDispName,
            icon = mapIcon
        }
        
        -- Auto-select first map
        if k == 1 then
            previewPanel.SelectedMap = btn.MapData
        end

        btn.Paint = function(s,w,h)
            local isSelected = (previewPanel.SelectedMap and previewPanel.SelectedMap.name == v)
            local isWinner = (winmap == v)
            
            local col = (s:IsHovered() or isSelected) and orange or gray
            if isWinner and math.floor(CurTime()) % 2 == 0 then
                col = white
            end
            
            -- Background
            surface.SetDrawColor(col.r, col.g, col.b, (s:IsHovered() or isSelected) and 50 or 20)
            surface.DrawRect(0,0,w,h)
            
            -- Outline
            surface.SetDrawColor(col)
            surface.DrawOutlinedRect(0,0,w,h,1)
            
            -- Text
            draw.SimpleText(mapDispName, "MC_UI", 16, h/2, white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            
            -- Vote Indicator
            local voteCount = votes[v] or 0
            if voteCount > 0 then
                 draw.SimpleText("["..voteCount.."]", "MC_Typewriter", w-16, h/2, orange, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
            
            if isSelected then
                 surface.SetDrawColor(orange)
                 surface.DrawRect(0,0,4,h)
            end
        end
        
        btn.DoClick = function()
            if VoteCD > CurTime() then return end
            if winmap and winmap ~= "" then return end -- Voting locked
            
            PlayUI("click")
            net.Start("ZB_RTV_vote")
            net.WriteString(v)
            net.SendToServer()
            VoteCD = CurTime() + 1
        end
        
        btn.OnCursorEntered = function()
            PlayUI("hover")
            previewPanel.SelectedMap = btn.MapData
        end
    end
end

function zb.StartRTV()
    maps = net.ReadTable()
    time = net.ReadFloat()
    winmap = "" -- Reset winner
    zb.RTVMenu()
    rtvStarted = true
end

net.Receive("RTVMenu", function()
    zb.RTVMenu()
end)

function zb.RTVregVote()
    votes = net.ReadTable()
end

function zb.EndRTV()
    winmap = net.ReadString()
    rtvEnded = true
end

-- NETWORKING

net.Receive("ZB_RTV_start", zb.StartRTV)
net.Receive("ZB_RTV_voteCLreg", zb.RTVregVote)
net.Receive("ZB_RTV_end", zb.EndRTV)
