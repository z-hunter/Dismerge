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
        debug_logger.log_error("Failed to parse generator configuration file: " .. file_path)
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
                        rates = {}
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
                debug_logger.log_important("Invalid generator ID: " .. generator_id)
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
    debug_logger.log_init("Successfully loaded " .. count .. " generators")
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

-- Функция для получения случайной фишки из генератора по вероятностям (автоматическая активация)
function M.get_random_automatic_output(generator_id)
    local generator = generators[generator_id]
    if not generator then
        return nil, "Generator not found"
    end
    
    -- Проверяем, есть ли автоматическая генерация
    if not generator.automatic.capacity or #generator.automatic.outputs == 0 then
        return nil, "No automatic generation configured"
    end
    
    -- Вычисляем общую сумму вероятностей
    local total_rate = 0
    for _, rate in ipairs(generator.automatic.rates) do
        total_rate = total_rate + rate
    end
    
    if total_rate <= 0 then
        return nil, "No valid rates found"
    end
    
    -- Генерируем случайное число от 1 до total_rate
    local random_value = math.random(1, total_rate)
    
    -- Определяем, какая фишка выпала
    local current_sum = 0
    for i, rate in ipairs(generator.automatic.rates) do
        current_sum = current_sum + rate
        if random_value <= current_sum then
            return generator.automatic.outputs[i], nil
        end
    end
    
    -- На всякий случай возвращаем последнюю фишку
    return generator.automatic.outputs[#generator.automatic.outputs], nil
end

-- Функция для проверки, является ли генератор одноразовым
function M.is_disposable(generator_id)
    local generator = generators[generator_id]
    return generator and generator.dispose_after and generator.dispose_after > 0
end

-- Функция для получения ID фишки, в которую превращается генератор
function M.get_dispose_to(generator_id)
    local generator = generators[generator_id]
    if not generator then
        return nil
    end
    
    return generator.dispose_to
end

-- Функция для валидации конфигурации генераторов
function M.validate_generator_config(evolution_tables)
    if not evolution_tables then
        return false, "Evolution tables not provided"
    end
    
    local errors = {}
    
    for generator_id, generator in pairs(generators) do
        -- Проверяем, существует ли эволюционная цепочка
        local chain = evolution_tables.get_evolution_chain(generator.evo_id)
        if not chain then
            table.insert(errors, "Generator " .. generator_id .. " references non-existent evolution chain: " .. generator.evo_id)
        elseif generator.level > chain.max_grade then
            table.insert(errors, "Generator " .. generator_id .. " level " .. generator.level .. " exceeds max grade " .. chain.max_grade .. " for chain: " .. generator.evo_id)
        end
        
        -- Проверяем ручную генерацию
        if generator.manual.capacity and generator.manual.capacity > 0 then
            if #generator.manual.outputs == 0 then
                table.insert(errors, "Generator " .. generator_id .. " has manual capacity but no outputs")
            end
            if #generator.manual.rates == 0 then
                table.insert(errors, "Generator " .. generator_id .. " has manual capacity but no rates")
            end
            if #generator.manual.outputs ~= #generator.manual.rates then
                table.insert(errors, "Generator " .. generator_id .. " has mismatched manual outputs and rates count")
            end
        end
        
        -- Проверяем автоматическую генерацию
        if generator.automatic.capacity and generator.automatic.capacity > 0 then
            if #generator.automatic.outputs == 0 then
                table.insert(errors, "Generator " .. generator_id .. " has automatic capacity but no outputs")
            end
            if #generator.automatic.rates == 0 then
                table.insert(errors, "Generator " .. generator_id .. " has automatic capacity but no rates")
            end
            if #generator.automatic.outputs ~= #generator.automatic.rates then
                table.insert(errors, "Generator " .. generator_id .. " has mismatched automatic outputs and rates count")
            end
        end
        
        -- Проверяем dispose_to
        if generator.dispose_to and generator.dispose_to ~= "" then
            local dispose_evo_id, dispose_level = utils.parse_token_string(generator.dispose_to)
            if not dispose_evo_id or not dispose_level then
                table.insert(errors, "Generator " .. generator_id .. " has invalid dispose_to format: " .. generator.dispose_to)
            else
                local dispose_chain = evolution_tables.get_evolution_chain(dispose_evo_id)
                if not dispose_chain then
                    table.insert(errors, "Generator " .. generator_id .. " dispose_to references non-existent evolution chain: " .. dispose_evo_id)
                elseif dispose_level > dispose_chain.max_grade then
                    table.insert(errors, "Generator " .. generator_id .. " dispose_to level " .. dispose_level .. " exceeds max grade " .. dispose_chain.max_grade .. " for chain: " .. dispose_evo_id)
                end
            end
        end
    end
    
    if #errors > 0 then
        local error_msg = "Generator configuration validation failed:\n" .. table.concat(errors, "\n")
        return false, error_msg
    end
    
    return true
end

-- Функция для отладочного вывода конфигурации
function M.debug_print_config()
    print("=== GENERATOR CONFIGURATION ===")
    for generator_id, generator in pairs(generators) do
        print("Generator: " .. generator_id)
        print("  Comment: " .. (generator.comment or "none"))
        print("  Dispose after: " .. (generator.dispose_after or "never"))
        print("  Dispose to: " .. (generator.dispose_to or "nothing"))
        
        if generator.manual.capacity then
            print("  Manual:")
            print("    Capacity: " .. generator.manual.capacity)
            print("    Reload time: " .. (generator.manual.reload_sec or "none") .. "s")
            print("    Outputs: " .. #generator.manual.outputs)
            for i, output in ipairs(generator.manual.outputs) do
                print("      " .. output .. " (rate: " .. (generator.manual.rates[i] or 0) .. ")")
            end
        end
        
        if generator.automatic.capacity then
            print("  Automatic:")
            print("    Capacity: " .. generator.automatic.capacity)
            print("    Timer: " .. (generator.automatic.timer_sec or "none") .. "s")
            print("    Reload time: " .. (generator.automatic.reload_sec or "none") .. "s")
            print("    Outputs: " .. #generator.automatic.outputs)
            for i, output in ipairs(generator.automatic.outputs) do
                print("      " .. output .. " (rate: " .. (generator.automatic.rates[i] or 0) .. ")")
            end
        end
        print()
    end
    print("=== END GENERATOR CONFIGURATION ===")
end

return M 