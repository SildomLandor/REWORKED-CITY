local MiniPlayer = {}

MiniPlayer.Enabled = true
MiniPlayer.X = 0
MiniPlayer.Y = ScrH() - 1070
MiniPlayer.Width = 140
MiniPlayer.Height = 200
MiniPlayer.MatWhite = Material("models/debug/debugwhite")
MiniPlayer.ModelEnt = nil
MiniPlayer.CurrentModelPath = ""

MiniPlayer.LimbStates = {
    lleg = { amputated = false, flashing = false, flashTime = 0, broken = false, dislocated = false },
    rleg = { amputated = false, flashing = false, flashTime = 0, broken = false, dislocated = false },
    larm = { amputated = false, flashing = false, flashTime = 0, broken = false, dislocated = false },
    rarm = { amputated = false, flashing = false, flashTime = 0, broken = false, dislocated = false },
}

MiniPlayer.TorsoStates = {
    chest = { broken = false },
    spine1 = { broken = false },
    spine2 = { broken = false },
    spine3 = { broken = false },
}

-- Исправленный кеш для chest: исключили Pelvis, добавили ключицы для области рёбер
MiniPlayer.TorsoBoneCache = {
    chest = {"ValveBiped.Bip01_Spine2", "ValveBiped.Bip01_Spine1", "ValveBiped.Bip01_L_Clavicle", "ValveBiped.Bip01_R_Clavicle"},
}

MiniPlayer.PrevStates = { lleg = false, rleg = false, larm = false, rarm = false }

MiniPlayer.LimbRootBones = {
    lleg = "ValveBiped.Bip01_L_Thigh",
    rleg = "ValveBiped.Bip01_R_Thigh",
    larm = "ValveBiped.Bip01_L_UpperArm",
    rarm = "ValveBiped.Bip01_R_UpperArm",
}

MiniPlayer.LimbCache = {}
MiniPlayer.TorsoCache = {}

function MiniPlayer:GetOrganism()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return nil end
    -- Иногда нужные флаги (например *dislocation) оказываются только в new_organism.
    -- Поэтому предпочитаем тот организм, где поля dislocation явно присутствуют.
    local orgOld = ply.organism
    local orgNew = ply.new_organism
    if orgNew
        and (orgNew.llegdislocation ~= nil or orgNew.rlegdislocation ~= nil or orgNew.larmdislocation ~= nil or orgNew.rarmdislocation ~= nil) then
        return orgNew
    end
    return orgOld or orgNew
end

MiniPlayer.TorsoOverrides = {}  -- для тестирования: {spine1 = true/false, ...}

function MiniPlayer:UpdateStates()
    local org = self:GetOrganism()
    if not org then return end

    for _, limb in ipairs({"lleg", "rleg", "larm", "rarm"}) do
        local isAmputated = org[limb .. "amputated"] or false
        -- dislocation может храниться как boolean true/false или как 1/0.
        local disVal = org[limb .. "dislocation"]
        local isDislocated = (disVal ~= nil and disVal ~= false and disVal ~= 0)
        local state = self.LimbStates[limb]

        if isAmputated and not self.PrevStates[limb] then
            state.flashing = true
            state.flashTime = CurTime()
            state.amputated = true
        elseif not isAmputated then
            state.amputated = false
            state.flashing = false
        end

        -- dislocation (и для рук, и для ног) подсвечиваем оранжевым
        -- перелом (value == 1) подсвечиваем красным
        state.dislocated = isDislocated or false
        state.broken = (org[limb] and org[limb] == 1) or false

        -- Оранжевый приоритетнее: если dislocated, не считаем это "переломом" (красным).
        if state.dislocated then
            state.broken = false
        end

        if state.flashing and (CurTime() - state.flashTime > 2.0) then
            state.flashing = false
        end

        self.PrevStates[limb] = isAmputated
    end

    -- Состояния торса: chest, spine
    self.TorsoStates.chest.broken   = self.TorsoOverrides.chest  ~= nil and self.TorsoOverrides.chest  or (org.chest  and org.chest  > 0.5)
    self.TorsoStates.spine1.broken  = self.TorsoOverrides.spine1 ~= nil and self.TorsoOverrides.spine1 or (org.spine1 and org.spine1 >= 1)
    self.TorsoStates.spine2.broken  = self.TorsoOverrides.spine2 ~= nil and self.TorsoOverrides.spine2 or (org.spine2 and org.spine2 >= 1)
    self.TorsoStates.spine3.broken  = self.TorsoOverrides.spine3 ~= nil and self.TorsoOverrides.spine3 or (org.spine3 and org.spine3 >= 1)
end

function MiniPlayer:GetAllChildren(ent, boneID, result)
    result = result or {}
    local boneCount = ent:GetBoneCount()
    for i = 0, boneCount - 1 do
        if ent:GetBoneParent(i) == boneID then
            result[#result + 1] = i
            self:GetAllChildren(ent, i, result)
        end
    end
    return result
end

function MiniPlayer:BuildBoneCache(ent)
    self.LimbCache = {}
    self.TorsoCache = {}

    for limb, rootName in pairs(self.LimbRootBones) do
        local rootID = ent:LookupBone(rootName)
        if not rootID then continue end
        local parentID = ent:GetBoneParent(rootID)
        local allBones = { rootID }
        self:GetAllChildren(ent, rootID, allBones)
        self.LimbCache[limb] = {
            boneIDs = allBones,
            parentID = parentID,
        }
    end

    -- Торс: собираем кости по именам
    for torsoName, boneNames in pairs(self.TorsoBoneCache) do
        local allBones = {}
        for _, boneName in ipairs(boneNames) do
            local boneID = ent:LookupBone(boneName)
            if boneID then
                allBones[#allBones + 1] = boneID
                self:GetAllChildren(ent, boneID, allBones)
            end
        end
        self.TorsoCache[torsoName] = { boneIDs = allBones }
    end
end

function MiniPlayer:UpdateModelEntity()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local targetModel = ply:GetModel()

    if self.CurrentModelPath ~= targetModel or not IsValid(self.ModelEnt) then
        if IsValid(self.ModelEnt) then self.ModelEnt:Remove() end

        self.ModelEnt = ClientsideModel(targetModel, RENDERGROUP_OTHER)
        if not IsValid(self.ModelEnt) then return end

        self.ModelEnt:SetNoDraw(true)
        self.ModelEnt:SetSkin(ply:GetSkin())
        for i = 0, ply:GetNumBodyGroups() do
            self.ModelEnt:SetBodygroup(i, ply:GetBodygroup(i))
        end

        self.CurrentModelPath = targetModel

        self.ModelEnt:SetPos(Vector(0, 0, 0))
        self.ModelEnt:SetAngles(Angle(0, 0, 0))
        local seq = self.ModelEnt:LookupSequence("idle_suitcase")
        if seq and seq > 0 then
            self.ModelEnt:ResetSequence(seq)
            self.ModelEnt:SetCycle(0)
        end
        self.ModelEnt:SetupBones()
        self:BuildBoneCache(self.ModelEnt)
    end
end

-- Список конечностей для скрытия (ампутации)
function MiniPlayer:GetHideList(mode)
    local hideList = {}
    for limb, data in pairs(self.LimbStates) do
        local shouldHide = false
        if mode == "all" then
            shouldHide = data.amputated
        elseif mode == "permanent" then
            shouldHide = data.amputated and not data.flashing
        end
        if shouldHide then
            hideList[#hideList + 1] = limb
        end
    end
    return hideList
end

function MiniPlayer:DrawWithMode(ent, mode)
    local hideList = self:GetHideList(mode)

    ent:SetupBones()

    for _, limb in ipairs(hideList) do
        local cache = self.LimbCache[limb]
        if not cache then continue end

        local parentMatrix = cache.parentID and ent:GetBoneMatrix(cache.parentID)
        if not parentMatrix then continue end

        local parentPos = parentMatrix:GetTranslation()
        local parentAng = parentMatrix:GetAngles()

        for _, boneID in ipairs(cache.boneIDs) do
            local matrix = ent:GetBoneMatrix(boneID)
            if matrix then
                matrix:SetTranslation(parentPos)
                matrix:SetAngles(parentAng)
                matrix:Scale(Vector(0, 0, 0))
                ent:SetBoneMatrix(boneID, matrix)
            end
        end
    end

    ent:DrawModel()
end

function MiniPlayer:Draw()
    if not self.Enabled then return end

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    self:UpdateStates()
    self:UpdateModelEntity()

    local ent = self.ModelEnt
    if not IsValid(ent) then return end

    local x, y, w, h = self.X, self.Y, self.Width, self.Height

    ent:SetPos(Vector(0, 0, 0))
    ent:SetAngles(Angle(0, 0, 0))

    local seq = ent:LookupSequence("idle_suitcase")
    if seq and seq > 0 then
        ent:ResetSequence(seq)
        ent:SetCycle(0)
    end

    -- Флаги состояния
    local hasFlashing = false
    local hasAmputated = false
    local hasBroken = false
    local hasBrokenTorso = false
    local hasDislocated = false
    local spine1BrokenFlag = self.TorsoStates.spine1.broken
    local spine2BrokenFlag = self.TorsoStates.spine2.broken
    local spine3BrokenFlag = self.TorsoStates.spine3.broken

    for _, s in pairs(self.LimbStates) do
        if s.flashing then hasFlashing = true end
        if s.amputated then hasAmputated = true end
        if s.broken then hasBroken = true end
        if s.dislocated then hasDislocated = true end
    end

    for _, s in pairs(self.TorsoStates) do
        if s.broken then hasBrokenTorso = true end
    end

    render.SetScissorRect(x, y, x + w, y + h, true)

    cam.Start3D(Vector(130, 0, 36), Angle(0, 180, 0), 25, x, y, w, h, 5, 4096)
        render.SuppressEngineLighting(true)
        render.MaterialOverride(self.MatWhite)

        -- Вспомогательная функция: скрыть ампутированные конечности в текущем кадре установки костей
        local function hideAmputatedArms()
            for _, limb in ipairs({"larm", "rarm", "lleg", "rleg"}) do
                if self.LimbStates[limb].amputated and self.LimbCache[limb] then
                    local cache = self.LimbCache[limb]
                    local parentMatrix = cache.parentID and ent:GetBoneMatrix(cache.parentID)
                    if parentMatrix then
                        local parentPos = parentMatrix:GetTranslation()
                        local parentAng = parentMatrix:GetAngles()
                        for _, boneID in ipairs(cache.boneIDs) do
                            local matrix = ent:GetBoneMatrix(boneID)
                            if matrix then
                                matrix:SetTranslation(parentPos)
                                matrix:SetAngles(parentAng)
                                matrix:Scale(Vector(0, 0, 0))
                                ent:SetBoneMatrix(boneID, matrix)
                            end
                        end
                    end
                end
            end
        end

        -- 0a. Spine3 сломан: всё тело кроме головы горит красным
        if spine3BrokenFlag then
            local redBoneIDs = {}
            for i = 0, ent:GetBoneCount() - 1 do
                local boneName = ent:GetBoneName(i)
                if not (boneName and string.find(boneName, "Head")) then
                    redBoneIDs[i] = true
                end
            end

            -- Базовый белый слой (без ампутированных рук)
            render.SetColorModulation(1, 1, 1)
            ent:SetupBones()
            hideAmputatedArms()
            ent:DrawModel()

            -- Красный слой для всего тела кроме головы (без ампутированных рук)
            ent:SetupBones()
            hideAmputatedArms()
            for i = 0, ent:GetBoneCount() - 1 do
                if not redBoneIDs[i] then
                    local matrix = ent:GetBoneMatrix(i)
                    if matrix then
                        matrix:Scale(Vector(0.001, 0.001, 0.001))
                        ent:SetBoneMatrix(i, matrix)
                    end
                end
            end
            render.SetColorModulation(1, 0, 0)
            ent:DrawModel()

        -- 0b. Spine2 сломан: всё тело кроме головы и шеи горит красным
        elseif spine2BrokenFlag then
            local redBoneIDs = {}
            for i = 0, ent:GetBoneCount() - 1 do
                local boneName = ent:GetBoneName(i)
                if not (boneName and (string.find(boneName, "Head") or string.find(boneName, "Neck"))) then
                    redBoneIDs[i] = true
                end
            end

            -- Базовый белый слой (без ампутированных рук)
            render.SetColorModulation(1, 1, 1)
            ent:SetupBones()
            hideAmputatedArms()
            ent:DrawModel()

            -- Красный слой для всего тела кроме головы/шеи (без ампутированных рук)
            ent:SetupBones()
            hideAmputatedArms()
            for i = 0, ent:GetBoneCount() - 1 do
                if not redBoneIDs[i] then
                    local matrix = ent:GetBoneMatrix(i)
                    if matrix then
                        matrix:Scale(Vector(0.001, 0.001, 0.001))
                        ent:SetBoneMatrix(i, matrix)
                    end
                end
            end
            render.SetColorModulation(1, 0, 0)
            ent:DrawModel()

        -- 0c. Spine1 сломан: нижняя спина + обе ноги горят красным
        elseif spine1BrokenFlag then
            local redBoneIDs = {}
            local llegs = self.LimbCache["lleg"]
            local rlegs = self.LimbCache["rleg"]
            if llegs then
                for _, boneID in ipairs(llegs.boneIDs) do
                    redBoneIDs[boneID] = true
                end
            end
            if rlegs then
                for _, boneID in ipairs(rlegs.boneIDs) do
                    redBoneIDs[boneID] = true
                end
            end

            -- Нижняя часть спины: ValveBiped.Bip01_Spine и Pelvis
            local lowerSpineBones = { "ValveBiped.Bip01_Spine", "ValveBiped.Bip01_Pelvis" }
            for _, boneName in ipairs(lowerSpineBones) do
                local boneID = ent:LookupBone(boneName)
                if boneID then
                    redBoneIDs[boneID] = true
                end
            end

            -- Базовый белый слой (без ампутированных рук)
            render.SetColorModulation(1, 1, 1)
            ent:SetupBones()
            hideAmputatedArms()
            ent:DrawModel()

            -- Красный слой для нижней спины + ног (без ампутированных рук)
            if next(redBoneIDs) ~= nil then
                ent:SetupBones()
                hideAmputatedArms()
                for i = 0, ent:GetBoneCount() - 1 do
                    if not redBoneIDs[i] then
                        local matrix = ent:GetBoneMatrix(i)
                        if matrix then
                            matrix:Scale(Vector(0.001, 0.001, 0.001))
                            ent:SetBoneMatrix(i, matrix)
                        end
                    end
                end
                render.SetColorModulation(1, 0, 0)
                ent:DrawModel()
            end

        -- 1. Если есть ампутации с миганием – используем сложный стенсил (существующая логика)
        elseif hasFlashing then
            render.ClearStencil()
            render.SetStencilEnable(true)
            render.SetStencilWriteMask(0xFF)
            render.SetStencilTestMask(0xFF)

            render.SetStencilReferenceValue(1)
            render.SetStencilCompareFunction(STENCIL_ALWAYS)
            render.SetStencilPassOperation(STENCIL_REPLACE)
            render.SetStencilFailOperation(STENCIL_KEEP)
            render.SetStencilZFailOperation(STENCIL_KEEP)

            render.SetColorModulation(1, 1, 1)
            self:DrawWithMode(ent, "permanent")

            render.SetStencilReferenceValue(2)
            render.SetStencilCompareFunction(STENCIL_ALWAYS)
            render.SetStencilPassOperation(STENCIL_REPLACE)

            render.SetColorModulation(1, 1, 1)
            self:DrawWithMode(ent, "all")

            local flash = math.abs(math.sin(CurTime() * 10))
            if flash > 0.5 then
                render.SetStencilCompareFunction(STENCIL_EQUAL)
                render.SetStencilReferenceValue(1)
                render.SetStencilPassOperation(STENCIL_KEEP)

                render.SetColorModulation(1, 0, 0)
                self:DrawWithMode(ent, "permanent")
            end

            render.SetStencilEnable(false)

        -- 2. Если есть переломы/дислокации и нет ампутаций – подсвечиваем
        -- - перелом: красным
        -- - дислокация руки: оранжевым
        elseif (hasBroken or hasBrokenTorso or hasDislocated) and not hasAmputated then
            local redBoneIDs = {}
            local orangeBoneIDs = {}

            -- 1) Сначала набираем оранжевое (dislocated руки).
            for limb, state in pairs(self.LimbStates) do
                if self.LimbCache[limb] and state.dislocated then
                    for _, boneID in ipairs(self.LimbCache[limb].boneIDs) do
                        orangeBoneIDs[boneID] = true
                    end
                end
            end

            -- 2) Затем набираем красное (broken), но не кладём в него те же кости, что orange.
            for limb, state in pairs(self.LimbStates) do
                if self.LimbCache[limb] and state.broken and not state.dislocated then
                    for _, boneID in ipairs(self.LimbCache[limb].boneIDs) do
                        redBoneIDs[boneID] = true
                    end
                end
            end

            -- Грудная клетка (chest)
            if self.TorsoStates.chest.broken and self.TorsoCache.chest then
                for _, boneID in ipairs(self.TorsoCache.chest.boneIDs) do
                    redBoneIDs[boneID] = true
                end
            end

            -- Специальные случаи позвоночника для красного
            local spine1Broken = self.TorsoStates.spine1.broken
            local spine2Broken = self.TorsoStates.spine2.broken
            local spine3Broken = self.TorsoStates.spine3.broken

            if spine2Broken or spine3Broken then
                -- Перелом верхних отделов позвоночника: подсвечиваем всё тело кроме головы/шеи (красным).
                redBoneIDs = {}
                for i = 0, ent:GetBoneCount() - 1 do
                    local boneName = ent:GetBoneName(i)
                    if not (boneName and (string.find(boneName, "Head") or string.find(boneName, "Neck"))) then
                        redBoneIDs[i] = true
                    end
                end
            elseif spine1Broken then
                -- Перелом поясничного отдела: добавляем кости ног (не заменяем, а дополняем)
                if self.LimbCache["lleg"] then
                    for _, boneID in ipairs(self.LimbCache["lleg"].boneIDs) do
                        redBoneIDs[boneID] = true
                    end
                end
                if self.LimbCache["rleg"] then
                    for _, boneID in ipairs(self.LimbCache["rleg"].boneIDs) do
                        redBoneIDs[boneID] = true
                    end
                end

                -- spine1Broken должен делать обе ноги КРАСНЫМИ даже если они dislocated (оранжевые):
                -- выкидываем кости ног из orangeBoneIDs, чтобы оранжевый не перебивал красный.
                if next(orangeBoneIDs) ~= nil then
                    if self.LimbCache["lleg"] then
                        for _, boneID in ipairs(self.LimbCache["lleg"].boneIDs) do
                            orangeBoneIDs[boneID] = nil
                        end
                    end
                    if self.LimbCache["rleg"] then
                        for _, boneID in ipairs(self.LimbCache["rleg"].boneIDs) do
                            orangeBoneIDs[boneID] = nil
                        end
                    end
                end
            end

            -- orange всегда приоритетнее: выкидываем orange-кости из red.
            for boneID, _ in pairs(orangeBoneIDs) do
                redBoneIDs[boneID] = nil
            end

            -- Базовый слой (белый)
            render.SetColorModulation(1, 1, 1)
            ent:SetupBones()
            ent:DrawModel()

            -- Оранжевый проход (если есть)
            if next(orangeBoneIDs) ~= nil then
                ent:SetupBones()
                for i = 0, ent:GetBoneCount() - 1 do
                    if not orangeBoneIDs[i] then
                        local matrix = ent:GetBoneMatrix(i)
                        if matrix then
                            matrix:Scale(Vector(0.001, 0.001, 0.001))
                            ent:SetBoneMatrix(i, matrix)
                        end
                    end
                end
                render.SetColorModulation(1, 0.5, 0)
                ent:DrawModel()
            end

            -- Красный проход (если есть)
            if next(redBoneIDs) ~= nil then
                ent:SetupBones()
                for i = 0, ent:GetBoneCount() - 1 do
                    if not redBoneIDs[i] then
                        local matrix = ent:GetBoneMatrix(i)
                        if matrix then
                            matrix:Scale(Vector(0.001, 0.001, 0.001))
                            ent:SetBoneMatrix(i, matrix)
                        end
                    end
                end
                render.SetColorModulation(1, 0, 0)
                ent:DrawModel()
            end

            -- Восстанавливать матрицы не нужно – следующий кадр начнётся с чистого листа

        -- 3. Если есть только ампутации (без мигания) – скрываем ампутированные конечности
        elseif hasAmputated then
            render.SetColorModulation(1, 1, 1)
            self:DrawWithMode(ent, "all")

        -- 4. Ничего особенного – просто белая модель
        else
            render.SetColorModulation(1, 1, 1)
            ent:SetupBones()
            ent:DrawModel()
        end

        render.MaterialOverride(nil)
        render.SuppressEngineLighting(false)
    cam.End3D()

    render.SetScissorRect(0, 0, 0, 0, false)
end

-- Тестовые команды
concommand.Add("miniplayer_test", function(ply, cmd, args)
    local limb = args[1] or "rarm"
    if MiniPlayer.LimbStates[limb] then
        MiniPlayer.LimbStates[limb].amputated = not MiniPlayer.LimbStates[limb].amputated
        MiniPlayer.LimbStates[limb].flashing = MiniPlayer.LimbStates[limb].amputated
        MiniPlayer.LimbStates[limb].flashTime = CurTime()
        print("[MiniPlayer] " .. limb .. " = " .. tostring(MiniPlayer.LimbStates[limb].amputated))
    end
end)

concommand.Add("miniplayer_test_broken", function(ply, cmd, args)
    local limb = args[1] or "rarm"
    if MiniPlayer.LimbStates[limb] then
        MiniPlayer.LimbStates[limb].broken = not MiniPlayer.LimbStates[limb].broken
        print("[MiniPlayer] " .. limb .. " broken = " .. tostring(MiniPlayer.LimbStates[limb].broken))
    end
end)

concommand.Add("miniplayer_test_dislocated", function(ply, cmd, args)
    local limb = args[1] or "rarm"
    if MiniPlayer.LimbStates[limb] then
        MiniPlayer.LimbStates[limb].dislocated = not MiniPlayer.LimbStates[limb].dislocated
        -- Оранжевый приоритетнее: dislocated не должен подсвечиваться как broken (красный).
        if MiniPlayer.LimbStates[limb].dislocated then
            MiniPlayer.LimbStates[limb].broken = false
        end
        print("[MiniPlayer] " .. limb .. " dislocated = " .. tostring(MiniPlayer.LimbStates[limb].dislocated))
    end
end)

concommand.Add("miniplayer_test_torso", function(ply, cmd, args)
    local part = args[1] or "chest"
    if MiniPlayer.TorsoStates[part] then
        -- Используем override чтобы тест не перезаписывался UpdateStates
        local current = MiniPlayer.TorsoOverrides[part]
        MiniPlayer.TorsoOverrides[part] = not (current == true)
        print("[MiniPlayer] torso " .. part .. " override = " .. tostring(MiniPlayer.TorsoOverrides[part]))
        if part == "spine1" then
            print("[MiniPlayer] spine1 broken: both legs should glow red")
        elseif part == "spine2" or part == "spine3" then
            print("[MiniPlayer] " .. part .. " broken: entire body except head will be highlighted")
        end
    end
end)

concommand.Add("miniplayer_debug", function()
    local ent = MiniPlayer.ModelEnt
    if not IsValid(ent) then print("No model") return end
    for limb, cache in pairs(MiniPlayer.LimbCache) do
        print(limb .. ": " .. #cache.boneIDs .. " bones, parent=" .. tostring(cache.parentID))
        for _, id in ipairs(cache.boneIDs) do
            print("  [" .. id .. "] " .. tostring(ent:GetBoneName(id)))
        end
    end
    for torso, cache in pairs(MiniPlayer.TorsoCache) do
        print(torso .. ": " .. #cache.boneIDs .. " bones")
        for _, id in ipairs(cache.boneIDs) do
            print("  [" .. id .. "] " .. tostring(ent:GetBoneName(id)))
        end
    end
end)

hook.Add("HUDPaint", "MiniPlayerSilhouette_Draw", function()
    MiniPlayer:Draw()
end)

hook.Add("PlayerSpawn", "MiniPlayer_Reset", function(ply)
    if ply == LocalPlayer() then
        MiniPlayer.PrevStates = { lleg = false, rleg = false, larm = false, rarm = false }
        for k, v in pairs(MiniPlayer.LimbStates) do
            v.amputated = false
            v.flashing = false
            v.broken = false
            v.dislocated = false
        end
        for k, v in pairs(MiniPlayer.TorsoStates) do
            v.broken = false
        end
    end
end)

hook.Add("ShutDown", "MiniPlayer_Cleanup", function()
    if IsValid(MiniPlayer.ModelEnt) then
        MiniPlayer.ModelEnt:Remove()
    end
end)

print("[MiniPlayer] Loaded. Commands: miniplayer_test <limb>, miniplayer_test_broken <limb>, miniplayer_test_torso <part>, miniplayer_debug")
print("[MiniPlayer] Chest now properly highlights ribs area (Spine2, Spine1, Clavicles) when broken.")