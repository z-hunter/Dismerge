-- Модуль для ограниченного логирования
local M = {}

-- Таблица для хранения времени последнего вывода для каждого типа сообщений
local last_log_times = {}

-- Флаги для включения/отключения различных типов логирования
local LOG_SETTINGS = {
    PROGRESS_INDICATOR = false,  -- Отключаем логи индикаторов прогресса
    INDICATOR_MESSAGES = false,  -- Отключаем логи сообщений индикаторов
    GENERATOR_CONFIG = false,    -- Отключаем логи конфигурации генераторов
    IMPORTANT = true,            -- Оставляем важные сообщения
    ERRORS = true,               -- Оставляем ошибки
    INIT = true                  -- Оставляем инициализацию
}

-- Функция для логирования с ограничением по времени
function M.log_with_throttle(message_type, message, throttle_seconds)
    -- Проверяем, не отключены ли логи конфигурации генераторов
    if message_type:find("generator_") and not LOG_SETTINGS.GENERATOR_CONFIG then
        return -- Отключено
    end
    
    throttle_seconds = throttle_seconds or 10.0 -- По умолчанию 10 секунд
    
    local current_time = os.clock()
    local last_time = last_log_times[message_type] or 0
    
    if current_time - last_time >= throttle_seconds then
        print(message)
        last_log_times[message_type] = current_time
    end
end

-- Функция для логирования прогресса индикатора (с ограничением)
function M.log_progress_indicator(progress, id)
    if not LOG_SETTINGS.PROGRESS_INDICATOR then
        return -- Отключено
    end
    M.log_with_throttle("progress_indicator_" .. tostring(id), 
        string.format("[PROGRESS INDICATOR] Progress: %.3f, ID: %s", progress, tostring(id)), 
        30.0) -- Увеличили до 30 секунд
end

-- Функция для логирования сообщений индикатора (с ограничением)
function M.log_indicator_message(message_id, progress, id)
    if not LOG_SETTINGS.INDICATOR_MESSAGES then
        return -- Отключено
    end
    M.log_with_throttle("indicator_message_" .. tostring(id), 
        string.format("[PROGRESS INDICATOR] Message: %s, Progress: %.3f, ID: %s", 
            tostring(message_id), progress or 0, tostring(id)), 
        30.0) -- Увеличили до 30 секунд
end

-- Функция для логирования инициализации (без ограничений)
function M.log_init(message)
    if not LOG_SETTINGS.INIT then
        return -- Отключено
    end
    print(message)
end

-- Функция для логирования ошибок (без ограничений)
function M.log_error(message)
    if not LOG_SETTINGS.ERRORS then
        return -- Отключено
    end
    print("[ERROR] " .. message)
end

-- Функция для логирования важных событий (с ограничением)
function M.log_important(message, throttle_seconds)
    if not LOG_SETTINGS.IMPORTANT then
        return -- Отключено
    end
    M.log_with_throttle("important", "[IMPORTANT] " .. message, throttle_seconds or 5.0)
end

-- Функция для управления настройками логирования
function M.set_log_setting(setting_name, enabled)
    if LOG_SETTINGS[setting_name] ~= nil then
        LOG_SETTINGS[setting_name] = enabled
        print("DEBUG LOGGER: Setting '" .. setting_name .. "' " .. (enabled and "enabled" or "disabled"))
    else
        print("DEBUG LOGGER: Unknown setting '" .. setting_name .. "'")
    end
end

-- Функция для получения текущих настроек
function M.get_log_settings()
    return LOG_SETTINGS
end

return M 