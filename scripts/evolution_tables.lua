-- Evolution Tables Module
-- Модуль для работы с эволюционными таблицами из CSV файла

local M = {}

-- Импортируем универсальный CSV парсер
local csv_parser = require("scripts.csv_parser")

-- Структура для хранения данных эволюционных таблиц
local evolution_tables = {}

-- Функция для загрузки эволюционных таблиц из CSV файла
function M.load_evolution_tables()
    local file_path = "config/evo.csv"
    
    -- Определяем поля, которые нужно извлечь из CSV
    local field_names = {
        ["Evo_ID"] = true,
        ["Name_str"] = true,
        ["NextEvo_ID"] = true,
        ["MaxGrade"] = true,
        ["1"] = true, ["2"] = true, ["3"] = true, ["4"] = true, ["5"] = true, ["6"] = true,
        ["7"] = true, ["8"] = true, ["9"] = true, ["10"] = true, ["11"] = true, ["12"] = true
    }
    
    -- Парсим CSV файл
    local records = csv_parser.parse_csv_file(file_path, field_names)
    if not records then
        print("ERROR: Failed to parse evolution tables file: " .. file_path)
        return false
    end
    
    -- Обрабатываем записи
    for _, record in ipairs(records) do
        local evo_id = record["Evo_ID"]
        local name_str = record["Name_str"]
        local next_evo_id = record["NextEvo_ID"]
        local max_grade = csv_parser.get_field_value(record, "MaxGrade", "number") or 0
        
        if evo_id and evo_id ~= "" then
            -- Создаем таблицу для этой цепочки эволюции
            local evolution_chain = {
                id = evo_id,
                name = name_str or "Unknown",
                next_evo_id = (next_evo_id and next_evo_id ~= "") and next_evo_id or nil,
                max_grade = max_grade,
                levels = {}
            }
            
            -- Заполняем названия уровней
            for level = 1, 12 do
                local level_name = record[tostring(level)]
                if level_name and level_name ~= "" then
                    evolution_chain.levels[level] = level_name
                end
            end
            
            -- Сохраняем цепочку
            evolution_tables[evo_id] = evolution_chain
            
            print("Loaded evolution chain: " .. evo_id .. " - " .. name_str .. " (max grade: " .. max_grade .. ")")
        end
    end
    
    -- Правильно подсчитываем количество загруженных цепочек
    local chain_count = 0
    for _ in pairs(evolution_tables) do
        chain_count = chain_count + 1
    end
    print("Evolution tables loaded successfully. Total chains: " .. chain_count)
    
    -- Создаем таблицу соответствия evo_id и индексов для цветов
    local chain_index = 0
    for evo_id, _ in pairs(evolution_tables) do
        chain_index = chain_index + 1
        evolution_tables[evo_id].color_index = chain_index
        print("Chain " .. evo_id .. " assigned color index: " .. chain_index)
    end
    
    return true
end

-- Получить цепочку эволюции по ID
function M.get_evolution_chain(evo_id)
    return evolution_tables[evo_id]
end

-- Получить название предмета по ID цепочки и уровню
function M.get_item_name(evo_id, level)
    local chain = evolution_tables[evo_id]
    if chain and chain.levels[level] then
        return chain.levels[level]
    end
    -- Возвращаем fallback название вместо nil
    return "Неизвестный предмет"
end

-- Получить максимальный уровень для цепочки
function M.get_max_grade(evo_id)
    local chain = evolution_tables[evo_id]
    return chain and chain.max_grade or 0
end

-- Получить ID следующей цепочки
function M.get_next_evolution_id(evo_id)
    local chain = evolution_tables[evo_id]
    return chain and chain.next_evo_id or nil
end

-- Проверить, является ли уровень максимальным для цепочки
function M.is_max_level(evo_id, level)
    local max_grade = M.get_max_grade(evo_id)
    return level >= max_grade
end

-- Получить цвет для эволюционной цепочки
function M.get_chain_color(evo_id)
    local chain = evolution_tables[evo_id]
    if not chain or not chain.color_index then
        return vmath.vector4(1, 1, 1, 1)  -- Белый цвет по умолчанию
    end
    
    -- Цвета для первых 6 цепочек
    local colors = {
        vmath.vector4(1, 0, 0, 1),    -- Красный
        vmath.vector4(0, 1, 0, 1),    -- Зеленый
        vmath.vector4(0, 0, 1, 1),    -- Синий
        vmath.vector4(1, 1, 0, 1),    -- Желтый
        vmath.vector4(1, 0, 1, 1),    -- Пурпурный
        vmath.vector4(0, 1, 1, 1),    -- Голубой
    }
    
    -- Возвращаем цвет по индексу (1-6), или белый для остальных
    if chain.color_index <= 6 then
        return colors[chain.color_index]
    else
        return vmath.vector4(1, 1, 1, 1)  -- Белый для цепочек после 6-й
    end
end

-- Получить результат слияния двух предметов одного уровня
function M.get_merge_result(evo_id, level)
    local chain = evolution_tables[evo_id]
    if not chain then
        return nil
    end
    
    -- Если это не максимальный уровень, возвращаем следующий уровень в той же цепочке
    if level < chain.max_grade then
        return {
            evo_id = evo_id,
            level = level + 1
        }
    end
    
    -- Если это максимальный уровень и есть следующая цепочка
    if chain.next_evo_id then
        return {
            evo_id = chain.next_evo_id,
            level = 1
        }
    end
    
    -- Тупиковая цепочка
    return nil
end

-- Получить все загруженные цепочки эволюции
function M.get_all_chains()
    return evolution_tables
end

-- Отладочная функция для вывода всех цепочек
function M.debug_print_chains()
    print("=== Evolution Chains Debug ===")
    for evo_id, chain in pairs(evolution_tables) do
        print("Chain: " .. evo_id .. " - " .. chain.name)
        print("  Max Grade: " .. chain.max_grade)
        print("  Next Chain: " .. (chain.next_evo_id or "None"))
        print("  Levels:")
        for level, name in pairs(chain.levels) do
            print("    " .. level .. ": " .. name)
        end
        print("")
    end
end

return M 