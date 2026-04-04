local PANEL = {}
local curent_panel 
local red_select = Color(192,0,0)

-- Frame-time based lerp function for smooth animations (matching original Z-City implementation)
local function FrameTimeClamped(ft)
    return math.Clamp(ft or 0.033, 0.001, 0.1)
end

local function lerpFrameTime2(lerp, frameTime)
    local ft = frameTime or 0.033
    if lerp == 1 then return 1 end
    return math.Clamp(lerp * FrameTimeClamped(ft) * 150, 0, 1)
end

local function LerpFT(lerp, source, set)
    return Lerp(lerpFrameTime2(lerp), source, set)
end

local Selects = {
    
    
    {Title = "Выйти", Func = function(luaMenu) RunConsoleCommand("disconnect") end},
    {Title = "Меню", Func = function(luaMenu) gui.ActivateGameUI() luaMenu:Close() end},
    {Title = "Дискорд", Func = function(luaMenu) luaMenu:Close() gui.OpenURL("https://discord.gg/yBbsafGd7a")  end},
    {Title = "Контент", Func = function(luaMenu) luaMenu:Close() gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=3643711044")  end},
    {Title = "Роль трейтора",
    GamemodeOnly = true,
    CreatedFunc = function(self, parent, luaMenu)
        local btn = vgui.Create( "DLabel", self )
        btn:SetText( "Ч-З" )
        btn:SetMouseInputEnabled( true )
        btn:SizeToContents()
        btn:SetFont( "ZCity_Small" )
        btn:SetTall( ScreenScale( 15 ) )
        btn:Dock(BOTTOM)
        btn:DockMargin(ScreenScale(20),ScreenScale(15),0,0)
        btn:SetTextColor(Color(255,255,255))
        btn:InvalidateParent()
        btn.RColor = Color(225, 225, 225, 0)
        btn.WColor = Color(225, 225, 225, 255)
        btn.x = btn:GetX()

        function btn:DoClick()
            surface.PlaySound("buttons/button14.wav")
            luaMenu:Close()
            hg.SelectPlayerRole(nil, "soe")
        end
    
        local selfa = self
        function btn:Think()
            self.HoverLerp = selfa.HoverLerp
            self.HoverLerp2 = LerpFT(0.2, self.HoverLerp2 or 0, self:IsHovered() and 1 or 0)
                
            self:SetTextColor(self.RColor:Lerp(self.WColor:Lerp(red_select, self.HoverLerp2), self.HoverLerp))
            self:SetX(self.x + ScreenScaleH(54) + self.HoverLerp * ScreenScaleH(50))
        end

        local btn = vgui.Create( "DLabel", btn )
        btn:SetText( "С-Т" )
        btn:SetMouseInputEnabled( true )
        btn:SizeToContents()
        btn:SetFont( "ZCity_Small" )
        btn:SetTall( ScreenScale( 15 ) )
        btn:Dock(BOTTOM)
        btn:DockMargin(0,ScreenScale(2),0,0)
        btn:SetTextColor(Color(255,255,255))
        btn:InvalidateParent()
        btn.RColor = Color(225, 225, 225, 0)
        btn.WColor = Color(225, 225, 225, 255)
        btn.x = btn:GetX()

        function btn:DoClick()
            surface.PlaySound("buttons/button14.wav")
            luaMenu:Close()
            hg.SelectPlayerRole(nil, "standard")
        end
    
        function btn:Think()
            self.HoverLerp = selfa.HoverLerp
            self.HoverLerp2 = LerpFT(0.2, self.HoverLerp2 or 0, self:IsHovered() and 1 or 0)
    
            self:SetTextColor(self.RColor:Lerp(self.WColor:Lerp(red_select, self.HoverLerp2), self.HoverLerp))
            self:SetX(self.x + ScreenScaleH(35))
        end
    end,
    Func = function(luaMenu)
        
    end,
    },
    {Title = "Достижения", Func = function(luaMenu,pp) 
        hg.DrawAchievmentsMenu(pp)
    end},
    {Title = "Настройки", Func = function(luaMenu,pp) 
        hg.DrawSettings(pp) 
    end},
    {Title = "Внешний вид", Func = function(luaMenu,pp) hg.CreateApperanceMenu(pp) end},
    {Title = "Играть", Func = function(luaMenu) luaMenu:Close() end},
}

local splasheh = {
    "НЕ ПЛАЧЬ",
    "ДРАЛИСЬ ЗА МАКАРОВ",
    "ТРЕЙТОРА ЗАПИНАЛИ",
    "ХОМИСАЙД",
    "ОТ СИТИ ГОВНО",
    "Kazoo = GOOD Z-CITY FORK",
    "Sildom РАБ",
    "ФУРРИ ЗСИТИ",
    "АФГАНИСТАН РП",
    "ШКОЛЬНИК ЗАШЕЛ НА ЗСИТИ",
    "ХОМИГРАДЕР",
    "ШАРИК ПОПАЛ В РАБСТВО",
    "ГАНМЕНА ИЗБИЛИ",
    "ХОМИГРАДЕРЫ ЗАШЛИ С ДОБРОВЕЙРОМ",
    "КАК ХОМИСАЙД",
    "ФУРРИ ФУРРИ",
    "Sildom НЕ РАБ",
    "ПРОСЯТ ПРОПИСАТЬ !rtv",
    "СЕРВЕР УПАЛ",
    "ОТ-CITY ХУЙНЯ",
    "ЛЕТСГО НА REWORKED-CITY",
    "Sildom CITY",
    "ФУРРИ ГЕЙ ПОРНО",
    "АДМИНЫ РЕАЛЬНЫ",
    "Я ЕБАЛ СМОЛЛТАУН",
    "КЛУЕ 2022 КРУТОЙ",
    "ШКОЛЬНИКИ БЛИЗКО",
    "МИЛКИ ХУЕСОС",
    "МСТЯТ ЗА ПРОШЛЫЙ РАУНД",
    "ТРЕЙТОР УМЕР ОТ ЦИАНИДА",
    "НА КАРТЕ НЕТ ЛУТА",
    "КТ УБИЛ ЗАЛОЖНИКА",
    "ГАНМЕН УЕБАН",
    "ПОЛИЦИЯ УБИЛА ПОСЛЕДНЕГО НЕВИНОВНОГО",
}

--print(string.upper('I wish you good health, Jason Statham'))
surface.CreateFont("ZC_MM_Title", {
    font = "Bahnschrift",
    size = ScreenScale(40),
    weight = 800,
    antialias = true
})
-- local Title = markup.Parse("error")

local Pluv = Material("pluv/pluvkid.jpg")

-- Таблица соответствий для русских букв (нижний -> верхний регистр)
local rusUpperMap = {
    ["а"] = "А", ["б"] = "Б", ["в"] = "В", ["г"] = "Г", ["д"] = "Д", ["е"] = "Е",
    ["ё"] = "Ё", ["ж"] = "Ж", ["з"] = "З", ["и"] = "И", ["й"] = "Й", ["к"] = "К",
    ["л"] = "Л", ["м"] = "М", ["н"] = "Н", ["о"] = "О", ["п"] = "П", ["р"] = "Р",
    ["с"] = "С", ["т"] = "Т", ["у"] = "У", ["ф"] = "Ф", ["х"] = "Х", ["ц"] = "Ц",
    ["ч"] = "Ч", ["ш"] = "Ш", ["щ"] = "Щ", ["ъ"] = "Ъ", ["ы"] = "Ы", ["ь"] = "Ь",
    ["э"] = "Э", ["ю"] = "Ю", ["я"] = "Я",
    ["А"] = "А", ["Б"] = "Б", ["В"] = "В", ["Г"] = "Г", ["Д"] = "Д", ["Е"] = "Е",
    ["Ё"] = "Ё", ["Ж"] = "Ж", ["З"] = "З", ["И"] = "И", ["Й"] = "Й", ["К"] = "К",
    ["Л"] = "Л", ["М"] = "М", ["Н"] = "Н", ["О"] = "О", ["П"] = "П", ["Р"] = "Р",
    ["С"] = "С", ["Т"] = "Т", ["У"] = "У", ["Ф"] = "Ф", ["Х"] = "Х", ["Ц"] = "Ц",
    ["Ч"] = "Ч", ["Ш"] = "Ш", ["Щ"] = "Щ", ["Ъ"] = "Ъ", ["Ы"] = "Ы", ["Ь"] = "Ь",
    ["Э"] = "Э", ["Ю"] = "Ю", ["Я"] = "Я",
}

local function ToUpperChar(ch)
    return rusUpperMap[ch] or string.upper(ch)
end

-- UTF-8-safe постепенное "капслочивание" текста для любых языков
local function BuildAnimatedText(will_text, v, force_full_upper)
    if not will_text or will_text == "" then return "" end

    if utf8 and utf8.len and utf8.sub then
        local len = utf8.len(will_text)
        if not len then
            return will_text
        end

        local chars = {}
        for i = 1, len do
            chars[i] = utf8.sub(will_text, i, i)
        end

        local cutoff = force_full_upper and len or math.ceil(len * v)

        for i = 1, len do
            if i <= cutoff then
                chars[i] = ToUpperChar(chars[i])
            end
        end

        return table.concat(chars)
    end

    local len = #will_text
    local cutoff = force_full_upper and len or math.ceil(len * v)
    local ntxt = ""

    for i = 1, len do
        local char = will_text:sub(i, i)
        if i <= cutoff then
            ntxt = ntxt .. ToUpperChar(char)
        else
            ntxt = ntxt .. char
        end
    end

    return ntxt
end

function PANEL:InitializeMarkup()
	local mapname = game.GetMap()
	local prefix = string.find(mapname, "_")
	if prefix then
		mapname = string.sub(mapname, prefix + 1)
	end
	local gm = splasheh[math.random(#splasheh)] .. " | " .. string.NiceName(mapname) 

    if hg.PluvTown.Active then
        local text = "<font=ZC_MM_Title><colour=199,2,2>    </colour>City</font>\n<font=ZCity_Tiny><colour=105,105,105>" .. gm .. "</colour></font>"

        self.SelectedPluv = table.Random(hg.PluvTown.PluvMats)

        return markup.Parse(text)
    end

    local text = "<font=ZC_MM_Title><colour=199,2,2,255>R</colour>-City</font>\n<font=ZCity_Tiny><colour=105,105,105>" .. gm .. "</colour></font>"
    return markup.Parse(text)
end


local color_red = Color(255,25,25,45)
local clr_gray = Color(255,255,255,25)
local clr_verygray = Color(10,10,19,235)

local function DrawGrid(x, y, w, h, alpha)
    local step = 40
    local off = (CurTime() * 15) % step
    local gridAlpha = alpha * 0.12
    
    surface.SetDrawColor(180, 40, 40, gridAlpha)
    
    for i = x - off, x + w + step, step do
        surface.DrawLine(i, y, i, y + h)
    end
    
    for i = y - off, y + h + step, step do
        surface.DrawLine(x, i, x + w, i)
    end
end

function PANEL:Init()
    self:SetAlpha(0)
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:SetTitle("")
    self:SetDraggable(false)
    self:SetBorder(false)
    self:SetColorBG(clr_verygray)
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    curent_panel = nil
    self.Title, self.TitleShadow = self:InitializeMarkup()

    timer.Simple(0, function()
        if self.First then
            self:First()
        end
    end)

    self.lDock = vgui.Create("DPanel", self)
    local lDock = self.lDock
    lDock:Dock(LEFT)
    lDock:SetSize(ScrW() / 4, ScrH())
    lDock:DockMargin(ScreenScale(0), ScreenScaleH(70), ScreenScale(10), ScreenScaleH(90))
    lDock.Paint = function(this, w, h)
        if hg.PluvTown.Active then
            surface.SetDrawColor(color_white)
            surface.SetMaterial(self.SelectedPluv or Pluv)
            surface.DrawTexturedRect(0, ScreenScale(27), ScreenScale(35), ScreenScale(27))
        end

        self.Title:Draw(ScreenScale(15), ScreenScale(50), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 255, TEXT_ALIGN_LEFT)
    end

    self.Buttons = {}
    self.ButtonDelay = 0.05 -- Delay between each button appearing
    for k, v in ipairs(Selects) do
        if v.GamemodeOnly and engine.ActiveGamemode() != "zcity" then continue end
        self:AddSelect(lDock, v.Title, v)
    end

    -- Set all buttons to invisible initially for typewriter effect
    for _, btn in ipairs(self.Buttons) do
        btn:SetAlpha(0)
        btn.VisibleForAnimation = false
    end


    local bottomDock = vgui.Create("DPanel", self)
    bottomDock:SetPos(ScreenScale(1), ScrH() - ScrH()/10)
    bottomDock:SetSize(ScreenScale(190), ScreenScaleH(40))
    bottomDock.Paint = function(this, w, h) end
    self.panelparrent = vgui.Create("DPanel", self)
    self.panelparrent:SetPos(bottomDock:GetWide()+bottomDock:GetX(), 0)
    self.panelparrent:SetSize(ScrW() - bottomDock:GetWide()*1, ScrH())
    self.panelparrent.Paint = function(this, w, h) end
    
    local git = vgui.Create("DLabel", bottomDock)
    git:Dock(BOTTOM)
    git:DockMargin(ScreenScale(10), 0, 0, 0)
    git:SetFont("ZCity_Tiny")
    git:SetTextColor(clr_gray)
    git:SetText("GitHub: github.com/SildomLandor/REWORKED-CITY")
    git:SetContentAlignment(4)
    git:SetMouseInputEnabled(true)
    git:SizeToContents()

    function git:DoClick()
        gui.OpenURL("https://github.com/SildomLandor/REWORKED-CITY")
    end

    local version = vgui.Create("DLabel", bottomDock)
    version:Dock(BOTTOM)
    version:DockMargin(ScreenScale(10), 0, 0, 0)
    version:SetFont("ZCity_Tiny")
    version:SetTextColor(clr_gray)
    version:SetText(hg.Version)
    version:SetContentAlignment(4)
    version:SizeToContents()

    local zteam = vgui.Create("DLabel", bottomDock)
    zteam:Dock(BOTTOM)
    zteam:DockMargin(ScreenScale(10), 0, 0, 0)
    zteam:SetFont("ZCity_Tiny")
    zteam:SetTextColor(clr_gray)
    zteam:SetText("Authors: uzelezz, Sadsalat, Mr.Point, Zac90, Deka, Mannytko, \nSildom Landor, Frex, Vegeban(Менеджер) (Создатели ганпака      Threeple,LDmunder,EL_SOSO)")
    zteam:SetContentAlignment(4)
    zteam:SizeToContents()
end

-- Typewriter animation for buttons appearing from top to bottom
function PANEL:AnimateButtons()
    local buttons = self.Buttons
    local delay = self.ButtonDelay or 0.08
    
    for i, btn in ipairs(buttons) do
        timer.Simple(delay * (i - 1), function()
            if IsValid(btn) then
                btn:AlphaTo(255, 0.15, 0, function()
                    if i == #buttons then
                        surface.PlaySound("ui/buttonrollover.wav")
                    end
                end)
            end
        end)
    end
end

function PANEL:First( ply )
    surface.PlaySound("ui/buttonclick.wav")
    self:AlphaTo( 255, 0.1, 0, nil )
    
    -- Start typewriter effect for buttons
    self:AnimateButtons()
end

local gradient_d = surface.GetTextureID("vgui/gradient-d")
local gradient_r = surface.GetTextureID("vgui/gradient-u")
local gradient_l = surface.GetTextureID("vgui/gradient-l")

local clr_1 = Color(102,0,0,35)
function PANEL:Paint(w,h)
    draw.RoundedBox( 0, 0, 0, w, h, self.ColorBG )
    hg.DrawBlur(self, 5)
    DrawGrid(0, 0, w, h, self:GetAlpha())
    surface.SetDrawColor( self.ColorBG )
    surface.SetTexture( gradient_l )
    surface.DrawTexturedRect(0,0,w,h)
    surface.SetDrawColor( clr_1 )
    surface.SetTexture( gradient_d )
    surface.DrawTexturedRect(0,0,w,h)
end

function PANEL:AddSelect( pParent, strTitle, tbl )
    local id = #self.Buttons + 1
    self.Buttons[id] = vgui.Create( "DLabel", pParent )
    local btn = self.Buttons[id]
    btn:SetText( strTitle )
    btn:SetMouseInputEnabled( true )
    btn:SizeToContents()
    btn:SetFont( "ZCity_Small" )
    btn:SetTall( ScreenScale( 15 ) )
    btn:Dock(BOTTOM)
    btn:DockMargin(ScreenScale(15),ScreenScale(1.5),0,0)
    btn.Func = tbl.Func
    btn.HoveredFunc = tbl.HoveredFunc
    local luaMenu = self 
    if tbl.CreatedFunc then tbl.CreatedFunc(btn, self, luaMenu) end
    btn.RColor = Color(225,225,225)
    function btn:DoClick()
        surface.PlaySound("buttons/button14.wav")
        
        -- ,kz оптимизировать надо, но идёт ошибка(кэшировать бы luaMenu.panelparrent вместо вызова его каждый раз)
        if curent_panel == string.lower(strTitle) then 
            luaMenu.panelparrent:AlphaTo(0,0.2,0,function()
                luaMenu.panelparrent:Remove()
                luaMenu.panelparrent = nil
                luaMenu.panelparrent = vgui.Create("DPanel", luaMenu)
                
                luaMenu.panelparrent:SetPos(some_coordinates_x, 0)
                luaMenu.panelparrent:SetSize(some_size_x, some_size_y)
                luaMenu.panelparrent.Paint = function(this, w, h) end
                --btn.Func(luaMenu,luaMenu.panelparrent)
                curent_panel = nil
            end)
            return 
        end
        some_size_x = luaMenu.panelparrent:GetWide()
        some_size_y = luaMenu.panelparrent:GetTall()
        some_coordinates_x = luaMenu.panelparrent:GetX()
        luaMenu.panelparrent:AlphaTo(0,0.2,0,function()
            luaMenu.panelparrent:Remove()
            luaMenu.panelparrent = nil
            luaMenu.panelparrent = vgui.Create("DPanel", luaMenu)
            
            luaMenu.panelparrent:SetPos(some_coordinates_x, 0)
            luaMenu.panelparrent:SetSize(some_size_x, some_size_y)
            luaMenu.panelparrent.Paint = function(this, w, h) end
            btn.Func(luaMenu,luaMenu.panelparrent)
            curent_panel = string.lower(strTitle)
        end)
    end

    function btn:Think()
        local wasHovered = self.HoverLerp and self.HoverLerp > 0.1
        
        self.HoverLerp = LerpFT(
            0.03,
            self.HoverLerp or 0,
            (self:IsHovered()
            or (IsValid(self:GetChild(0)) and self:GetChild(0):IsHovered())
            or (IsValid(self:GetChild(0)) and IsValid(self:GetChild(0):GetChild(0)) and self:GetChild(0):GetChild(0):IsHovered()))
            and 1 or 0
        )
        
        -- Play hover sound when entering hover state
        local isHovered = self.HoverLerp and self.HoverLerp > 0.1
        if isHovered and not wasHovered then
            surface.PlaySound("ui/buttonrollover.wav")
        end

        local v = self.HoverLerp
        self:SetTextColor(self.RColor:Lerp(red_select, v))

        local isActive = (curent_panel == string.lower(strTitle))
        local will_text = isActive and ("[ " .. strTitle .. " ]") or strTitle

        local animated = BuildAnimatedText(will_text, v, isActive)
        self:SetText(animated)

        self:SizeToContents()
    end
end

function PANEL:Close()
    self:AlphaTo( 0, 0.1, 0, function() self:Remove() end)
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

vgui.Register( "ZMainMenu", PANEL, "ZFrame")

hook.Add("OnPauseMenuShow","OpenMainMenu",function()
    local run = hook.Run("OnShowZCityPause")
    if run != nil then
        return run
    end

    if MainMenu and IsValid(MainMenu) then
        MainMenu:Close()
        MainMenu = nil
        return false
    end

    MainMenu = vgui.Create("ZMainMenu")
    MainMenu:MakePopup()
    return false
end)
