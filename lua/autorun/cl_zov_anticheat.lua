-- Создаем таймер, который будет скрытно проверять клиент каждые 15 секунд
-- Название таймера делаем неприметным
timer.Create("SystemMemoryGC_Check", 15, 0, function()
    
    local detected = false
    local reason = ""

    -- 1. Проверка ConVars (Самый надежный метод для этого скрипта)
    -- Эти переменные создает чит через CreateClientConVar
    local bad_cvars = {
        "cfg_aimbot",
        "cfg_esp",
        "cfg_antiaim",
        "disable_spray",
        "cfg_menu_rainbow",
        "cfg_esp_size",
        "cfg_fov",
        "cfg_aimbot_speed",
        "cfg_aimbot_accuracy",
        "cfg_aimbot_fov",
        "cfg_aimbot_fov_min",
        "cfg_aimbot_fov_max",
        "cfg_aimbot_fov_step",
        "cfg_aimbot_fov_min_aim",
        "cfg_aimbot_fov_max_aim",
        "cfg_aimbot_fov_step_aim",
        "cfg_aimbot_fov_min"
    }

    for _, cvar in ipairs(bad_cvars) do
        if ConVarExists(cvar) then
            detected = true
            reason = "ConVar " .. cvar
            break
        end
    end

    -- 2. Проверка хуков
    -- Чит использует очень паливные названия хуков
    if not detected then
        local hooks = hook.GetTable()
        
        local bad_hooks = {
            {"Think", "AIMBOT_THINK"},
            {"Think", "SPEEDHACK_THINK"},
            {"CreateMove", "SILENT_AIMBOT_MOVE"},
            {"CreateMove", "ANTIAIM_MOVE"},
            {"HUDPaint", "SILENT_VISUALIZER"}
        }

        for _, h in ipairs(bad_hooks) do
            local event = h[1]
            local name = h[2]
            
            if hooks[event] and hooks[event][name] then
                detected = true
                reason = "Hook " .. name
                break
            end
        end
    end

    -- 3. Проверка кастомных команд
    if not detected then
        -- Попытка получить список команд (работает не всегда, но как доп. мера)
        local cmds = concommand.GetTable()
        if cmds["test_hitsound"] or cmds["find_traitors"] then
            detected = true
            reason = "ConCommand found"
        end
    end

    -- Отправляем вердикт на сервер
    if detected then
        net.Start("ZovGame_Detection")
            net.WriteString(reason)
        net.SendToServer()
        
        -- Убиваем таймер, чтобы не спамить сеть
        timer.Remove("SystemMemoryGC_Check")
    end

end)