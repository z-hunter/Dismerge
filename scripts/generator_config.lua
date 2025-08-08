-- Generator Configuration Module
-- Модуль для загрузки конфигурации генераторов из CSV файла

local M = {}

-- Подключаем модуль логирования
local debug_logger = require("scripts.debug_logger")

-- Импортируем универсальный CSV парсер
local csv_parser = require("scripts.csv_parser")
-- Импортируем утилиты
local utils = require("scripts.utils")

-- Структура для хранения данных генераторов
local generators = {}

-- Функция для загрузки конфигурации генераторов
function M.load_generator_config()
    local file_path = "config/gen.csv"
    
    -- Определяем поля, которые нужно извлечь из CSV
    local field_names = {
        ["id"] = true,
        ["comment"] = true,
        ["Dispose after"] = true,
        ["Dispose to"] = true,
        ["M:Capacity"] = true,
        ["M:Reload(sec)"] = true,
        ["M:Output"] = true,
        ["M:Rate"] = true,
        ["A:Capacity"] = true,
        ["A:Timer(sec)"] = true,
        ["A:Reload(sec)"] = true,
        ["A:Output"] = true,
        ["A:Rate"] = true
    }
    
    -- Парсим CSV файл
    local records = csv_parser.parse_csv_file(file_path, field_names)
    if not records then
        print("GENERATOR CONFIG: ERROR - Failed to parse generator configuration file: " .. file_path)
        return nil
    end
    
    -- Группируем записи по ID генератора
    local current_generator = nil
    
    for _, record in ipairs(records) do
        local generator_id = record["id"]
        
        -- Если есть ID, начинаем новый генератор
        if generator_id and generator_id ~= "" then
            -- Сохраняем предыдущий генератор
            if current_generator then
                generators[current_generator.id] = current_generator
            end
            
            -- Создаем новый генератор
            local evo_id, level = utils.parse_token_string(generator_id)
            if evo_id and level then
                current_generator = {
                    id = generator_id,
                    evo_id = evo_id,
                    level = level,
                    comment = record["comment"] or "",
                    dispose_after = csv_parser.get_field_value(record, "Dispose after", "number"),
                    dispose_to = record["Dispose to"] or "",
                    manual = {
                        capacity = csv_parser.get_field_value(record, "M:Capacity", "number"),
                        reload_sec = csv_parser.get_field_value(record, "M:Reload(sec)", "number"),
                        outputs = {},
                        rates = {},
                        current_capacity = csv_parser.get_field_value(record, "M:Capacity", "number"), -- Инициализируем текущую емкость
                        is_reloading = false,
                        reload_start_time = 0, -- Время начала перезарядки
                        reload_end_time = 0,    -- Время окончания перезарядки
                        used_activations = 0 -- Счетчик использованных активаций
                    },
                    automatic = {
                        capacity = csv_parser.get_field_value(record, "A:Capacity", "number"),
                        timer_sec = csv_parser.get_field_value(record, "A:Timer(sec)", "number"),
                        reload_sec = csv_parser.get_field_value(record, "A:Reload(sec)", "number"),
                        outputs = {},
                        rates = {}
                    }
                }
            else
                print("GENERATOR CONFIG: WARNING - Invalid generator ID: " .. generator_id)
                current_generator = nil
            end
        end
        
        -- Добавляем выходы к текущему генератору
        if current_generator then
            -- Ручная генерация
            local m_output = record["M:Output"]
            local m_rate = csv_parser.get_field_value(record, "M:Rate", "number")
            if m_output and m_output ~= "" and m_rate then
                table.insert(current_generator.manual.outputs, m_output)
                table.insert(current_generator.manual.rates, m_rate)
            end
            
            -- Автоматическая генерация
            local a_output = record["A:Output"]
            local a_rate = csv_parser.get_field_value(record, "A:Rate", "number")
            if a_output and a_output ~= "" and a_rate then
                table.insert(current_generator.automatic.outputs, a_output)
                table.insert(current_generator.automatic.rates, a_rate)
            end
        end
    end
    
    -- Сохраняем последний генератор
    if current_generator then
        generators[current_generator.id] = current_generator
    end
    
    local count = 0
    for _ in pairs(generators) do
        count = count + 1
    end
    print("GENERATOR CONFIG: Successfully loaded " .. count .. " generators")
    return generators
end

-- Функция для получения генератора по ID
function M.get_generator(generator_id)
    return generators[generator_id]
end

-- Функция для получения генератора по evo_id и level
function M.get_generator_by_evo(evo_id, level)
    local generator_id = utils.create_token_string(evo_id, level)
    return generators[generator_id]
end

-- Функция для проверки, является ли токен генератором
function M.is_generator(token_id)
    return generators[token_id] ~= nil
end

-- Функция для получения случайной фишки из генератора по вероятностям (ручная активация)
function M.get_random_manual_output(generator_id)
    local generator = generators[generator_id]
    if not generator then
        return nil, "Generator not found"
    end
    
    -- Проверяем, есть ли ручная генерация
    if not generator.manual.capacity or #generator.manual.outputs == 0 then
        return nil, "No manual generation configured"
    end
    
    -- Проверяем, не на перезарядке ли генератор
    if generator.manual.is_reloading then
        return nil, "Generator is reloading"
    end
    
    -- Проверяем емкость
    if generator.manual.current_capacity and generator.manual.current_capacity <= 0 then
        return nil, "Generator capacity exhausted"
    end
    
    -- Вычисляем общую сумму вероятностей
    local total_rate = 0
    for _, rate in ipairs(generator.manual.rates) do
        total_rate = total_rate + rate
    end
    
    if total_rate <= 0 then
        return nil, "No valid rates found"
    end
    
    -- Генерируем случайное число от 1 до total_rate
    local random_value = math.random(1, total_rate)
    
    -- Определяем, какая фишка выпала
    local current_sum = 0
    for i, rate in ipairs(generator.manual.rates) do
        current_sum = current_sum + rate
        if random_value <= current_sum then
            return generator.manual.outputs[i], nil
        end
    end
    
    -- На всякий случай возвращаем последнюю фишку
    return generator.manual.outputs[#generator.manual.outputs], nil
end

-- Функция для валидации конфигурации генераторов
function M.validate_generator_config(evolution_tables)
    local errors = {}
    
    for generator_id, generator in pairs(generators) do
        -- Проверяем существование эволюционной цепочки
        local chain = evolution_tables.get_evolution_chain(generator.evo_id)
        if not chain then
            table.insert(errors, "Generator '" .. generator_id .. "' references non-existent evolution chain '" .. generator.evo_id .. "'")
        elseif generator.level > chain.max_grade then
            table.insert(errors, "Generator '" .. generator_id .. "' level " .. generator.level .. " exceeds max grade " .. chain.max_grade)
        end
        
        -- Проверяем dispose_to
        if generator.dispose_to and generator.dispose_to ~= "" then
            local dispose_evo_id, dispose_level = utils.parse_token_string(generator.dispose_to)
            if dispose_evo_id and dispose_level then
                local dispose_chain = evolution_tables.get_evolution_chain(dispose_evo_id)
                if not dispose_chain then
                    table.insert(errors, "Generator '" .. generator_id .. "' dispose_to references non-existent chain '" .. dispose_evo_id .. "'")
                elseif dispose_level > dispose_chain.max_grade then
                    table.insert(errors, "Generator '" .. generator_id .. "' dispose_to level " .. dispose_level .. " exceeds max grade " .. dispose_chain.max_grade)
                end
            else
                table.insert(errors, "Generator '" .. generator_id .. "' has invalid dispose_to format: " .. generator.dispose_to)
            end
        end
        
        -- Проверяем выходы ручной генерации
        for i, output in ipairs(generator.manual.outputs) do
            local output_evo_id, output_level = utils.parse_token_string(output)
            if output_evo_id and output_level then
                local output_chain = evolution_tables.get_evolution_chain(output_evo_id)
                if not output_chain then
                    table.insert(errors, "Generator '" .. generator_id .. "' manual output " .. i .. " references non-existent chain '" .. output_evo_id .. "'")
                elseif output_level > output_chain.max_grade then
                    table.insert(errors, "Generator '" .. generator_id .. "' manual output " .. i .. " level " .. output_level .. " exceeds max grade " .. output_chain.max_grade)
                end
            else
                table.insert(errors, "Generator '" .. generator_id .. "' has invalid manual output format: " .. output)
            end
        end
        
        -- Проверяем выходы автоматической генерации
        for i, output in ipairs(generator.automatic.outputs) do
            local output_evo_id, output_level = utils.parse_token_string(output)
            if output_evo_id and output_level then
                local output_chain = evolution_tables.get_evolution_chain(output_evo_id)
                if not output_chain then
                    table.insert(errors, "Generator '" .. generator_id .. "' automatic output " .. i .. " references non-existent chain '" .. output_evo_id .. "'")
                elseif output_level > output_chain.max_grade then
                    table.insert(errors, "Generator '" .. generator_id .. "' automatic output " .. i .. " level " .. output_level .. " exceeds max grade " .. output_chain.max_grade)
                end
            else
                table.insert(errors, "Generator '" .. generator_id .. "' has invalid automatic output format: " .. output)
            end
        end
    end
    
    if #errors > 0 then
        print("GENERATOR CONFIG: Validation errors:")
        for _, error in ipairs(errors) do
            print("  - " .. error)
        end
        return false, table.concat(errors, "; ")
    end
    
    return true
end

-- Функция для отладочного вывода конфигурации
function M.debug_print_config()
    print("=== Generator Configuration Debug ===")
    for generator_id, generator in pairs(generators) do
        print("Generator: " .. generator_id .. " (" .. generator.comment .. ")")
        print("  Level: " .. generator.level .. " from chain: " .. generator.evo_id)
        if generator.dispose_after then
            print("  Dispose after: " .. generator.dispose_after .. " cycles")
        end
        if generator.dispose_to and generator.dispose_to ~= "" then
            print("  Dispose to: " .. generator.dispose_to)
        end
        
        local has_manual = generator.manual.capacity and #generator.manual.outputs > 0
        local has_automatic = generator.automatic.capacity and #generator.automatic.outputs > 0
        
        if not has_manual and not has_automatic then
            print("  WARNING: Generator has no generation types configured!")
        end
        
        -- Ручная генерация
        if has_manual then
            print("  Manual Generation:")
            print("    Capacity: " .. generator.manual.capacity)
            if generator.manual.reload_sec then
                print("    Reload: " .. generator.manual.reload_sec .. " seconds")
            end
            print("    Outputs:")
            for i, output in ipairs(generator.manual.outputs) do
                print("      " .. output .. " (rate: " .. generator.manual.rates[i] .. ")")
            end
        end
        
        -- Автоматическая генерация
        if has_automatic then
            print("  Automatic Generation:")
            print("    Capacity: " .. generator.automatic.capacity)
            if generator.automatic.timer_sec then
                print("    Timer: " .. generator.automatic.timer_sec .. " seconds")
            end
            if generator.automatic.reload_sec then
                print("    Reload: " .. generator.automatic.reload_sec .. " seconds")
            end
            print("    Outputs:")
            for i, output in ipairs(generator.automatic.outputs) do
                print("      " .. output .. " (rate: " .. generator.automatic.rates[i] .. ")")
            end
        end
        print("")
    end
end

-- Функция для проверки, может ли генератор быть активирован (не на перезарядке)
function M.can_activate_manual(generator_id)
    local generator = generators[generator_id]
    if not generator then
        return false, "Generator not found"
    end
    

    
    -- Добавляем отладочную информацию (с ограничением)
    debug_logger.log_with_throttle("generator_check_" .. generator_id, 
        "GENERATOR CONFIG: Checking " .. generator_id .. " - capacity: " .. tostring(generator.manual.capacity) .. ", current: " .. tostring(generator.manual.current_capacity) .. ", reloading: " .. tostring(generator.manual.is_reloading), 
        15.0)
    
    -- Проверяем, есть ли емкость
    if not generator.manual.capacity or generator.manual.current_capacity <= 0 then
        return false, "No capacity left"
    end
    
    -- Проверяем, не на перезарядке ли
    if generator.manual.is_reloading then
        local current_time = os.clock()
        if current_time < generator.manual.reload_end_time then
            return false, "Still reloading"
        else
            -- Перезарядка закончилась
            generator.manual.is_reloading = false
            generator.manual.current_capacity = generator.manual.capacity
            print("GENERATOR CONFIG: Reload finished for " .. generator_id .. ", capacity restored to " .. generator.manual.capacity)
        end
    end
    
    return true
end

-- Функция для активации генератора (уменьшает емкость и запускает перезарядку если нужно)
function M.activate_manual(generator_id)
    local generator = generators[generator_id]
    if not generator then
        return false, "Generator not found"
    end
    
    -- Уменьшаем емкость
    generator.manual.current_capacity = generator.manual.current_capacity - 1
    
    -- Если емкость закончилась, запускаем перезарядку
    if generator.manual.current_capacity <= 0 and generator.manual.reload_sec then
        local current_time = os.clock()
        generator.manual.is_reloading = true
        generator.manual.reload_start_time = current_time
        generator.manual.reload_end_time = current_time + generator.manual.reload_sec
        print("GENERATOR CONFIG: Generator " .. generator_id .. " started reloading for " .. generator.manual.reload_sec .. " seconds")
        print("GENERATOR CONFIG: Reload start time: " .. current_time .. ", end time: " .. generator.manual.reload_end_time)
    end
    
    return true
end

-- Функция для получения прогресса перезарядки (0.0 - 1.0)
function M.get_reload_progress(generator_id)
    local generator = generators[generator_id]
    if not generator or not generator.manual.is_reloading then
        return 1.0 -- Перезарядка не нужна или завершена
    end
    
    local current_time = os.clock()
    local total_reload_time = generator.manual.reload_sec
    local elapsed_time = current_time - generator.manual.reload_start_time
    
    local progress = elapsed_time / total_reload_time
    debug_logger.log_with_throttle("generator_progress_" .. generator_id, 
        "GENERATOR CONFIG: Progress for " .. generator_id .. " - current: " .. current_time .. ", start: " .. generator.manual.reload_start_time .. ", elapsed: " .. elapsed_time .. ", progress: " .. progress, 
        10.0)
    return math.min(progress, 1.0)
end

-- Функция для получения оставшегося времени перезарядки в секундах
function M.get_reload_remaining_time(generator_id)
    local generator = generators[generator_id]
    if not generator or not generator.manual.is_reloading then
        return 0
    end
    
    local current_time = os.clock()
    local remaining = generator.manual.reload_end_time - current_time
    return math.max(remaining, 0)
end

-- Функция для проверки, находится ли генератор на перезарядке
function M.is_reloading(generator_id)
    local generator = generators[generator_id]
    if not generator then
        return false
    end
    
    if generator.manual.is_reloading then
        local current_time = os.clock()
        debug_logger.log_with_throttle("generator_reload_check_" .. generator_id, 
            "GENERATOR CONFIG: Checking reload for " .. generator_id .. " - current: " .. current_time .. ", end: " .. generator.manual.reload_end_time .. ", remaining: " .. (generator.manual.reload_end_time - current_time), 
            10.0)
        if current_time >= generator.manual.reload_end_time then
            -- Перезарядка закончилась
            generator.manual.is_reloading = false
            generator.manual.current_capacity = generator.manual.capacity
            print("GENERATOR CONFIG: Reload finished for " .. generator_id .. " in is_reloading check")
            return false
        end
        return true
    end
    
    return false
end

-- Функция для проверки, является ли генератор одноразовым
function M.is_disposable(generator_id)
    local generator = generators[generator_id]
    return generator and generator.dispose_after and generator.dispose_after > 0
end

-- Функция для получения количества оставшихся активаций
function M.get_remaining_activations(generator_id)
    local generator = generators[generator_id]
    if not generator or not generator.dispose_after then
        return nil
    end
    
    local used_activations = generator.manual.used_activations or 0
    return math.max(0, generator.dispose_after - used_activations)
end

-- Функция для увеличения счетчика использованных активаций
function M.increment_activation_count(generator_id)
    local generator = generators[generator_id]
    if not generator or not generator.dispose_after then
        return false
    end
    
    if not generator.manual.used_activations then
        generator.manual.used_activations = 0
    end
    
    generator.manual.used_activations = generator.manual.used_activations + 1
    print("GENERATOR CONFIG: Incremented activation count for " .. generator_id .. " to " .. generator.manual.used_activations .. "/" .. generator.dispose_after)
    
    return true
end

-- Функция для проверки, нужно ли уничтожить генератор
function M.should_dispose(generator_id)
    local generator = generators[generator_id]
    if not generator or not generator.dispose_after then
        return false
    end
    
    local used_activations = generator.manual.used_activations or 0
    return used_activations >= generator.dispose_after
end

-- Функция для получения ID фишки, в которую превращается генератор
function M.get_dispose_to(generator_id)
    local generator = generators[generator_id]
    if not generator then
        return nil
    end
    
    return generator.dispose_to
end

-- Функция для сброса счетчика активаций (для тестирования)
function M.reset_activation_count(generator_id)
    local generator = generators[generator_id]
    if generator then
        generator.manual.used_activations = 0
        print("GENERATOR CONFIG: Reset activation count for " .. generator_id)
    end
end

return M 