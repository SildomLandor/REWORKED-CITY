util.AddNetworkString("ZovGame_Detection")

-- Настраиваем функцию бана
local function BanCheater(ply, reason)
    if not IsValid(ply) then return end
    
    local steamid = ply:SteamID()
    local name = ply:Nick()
    
    -- Логируем в консоль сервера
    MsgC(Color(255, 0, 0), "[AntiCheat] Игрок " .. name .. " (" .. steamid .. ") обнаружен с читом ZovGame! Причина: " .. reason .. "\n")
    
    -- Баним навсегда (0 минут = пермабан)
    -- Используй стандартную функцию бана или адаптbруй под свой бан-менеджер (SAM, bAdmin, ULX)
    ply:Ban(0, "Cheating Detected: ZG Signature (" .. reason .. ")")
    
    -- Кикаем сразу же
    ply:Kick("Вы были заблокированы за использование стороннего ПО.")
end

net.Receive("ZovGame_Detection", function(len, ply)
    -- Проверка на спам/подмену пакетов
    if (ply.LastZVDetection or 0) > CurTime() then return end
    ply.LastZVDetection = CurTime() + 5

    local detectionType = net.ReadString()
    
    -- Если клиент прислал сигнал, баним его
    BanCheater(ply, detectionType)
end)