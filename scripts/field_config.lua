-- Field Configuration Module
-- Модуль для загрузки начальной конфигурации игрового поля из CSV файла

local M = {}

-- Импортируем универсальный CSV парсер
local csv_parser = require("scripts.csv_parser")

-- Функция для парсинга строки токена в формате "evo_id-level"
local function parse_token_string(token_str)
    if not token_str or token_str == "" then
        return nil, nil
    end
    
    local evo_id, level_str = token_str:match("^([^-]+)-(%d+)$")
    if evo_id and level_str then
        local level = tonumber(level_str)
        if level and level > 0 then
            return evo_id, level
        end
    end
    
    return nil, nil
end

-- Функция для загрузки начальной конфигурации поля
function M.load_initial_field_config()
    local file_path = "config/init.csv"
    
    -- Определяем поля, которые нужно извлечь из CSV
    local field_names = {
        ["lines"] = true,
        ["1"] = true, ["2"] = true, ["3"] = true, ["4"] = true, ["5"] = true,
        ["6"] = true, ["7"] = true, ["8"] = true
    }
    
    -- Парсим CSV файл
    local records = csv_parser.parse_csv_file(file_path, field_names)
    if not records then
        print("FIELD CONFIG: ERROR - Failed to parse initial field configuration file: " .. file_path)
        return nil
    end
    
    -- Создаем 2D массив для конфигурации поля
    local field_config = {}
    
    -- Обрабатываем записи
    for _, record in ipairs(records) do
        local line_num = csv_parser.get_field_value(record, "lines", "number")
        if line_num and line_num > 0 then
            -- Создаем строку для этого номера линии
            field_config[line_num] = {}
            
            -- Заполняем столбцы (1-8)
            for col = 1, 8 do
                local token_str = record[tostring(col)]
                local evo_id, level = parse_token_string(token_str)
                
                if evo_id and level then
                    field_config[line_num][col] = token_str
                else
                    field_config[line_num][col] = ""  -- Пустая ячейка
                end
            end
        end
    end
    
    print("FIELD CONFIG: Successfully loaded initial field configuration")
    return field_config
end

-- Функция для валидации конфигурации поля
function M.validate_field_config(field_config, evolution_tables)
    if not field_config then
        return false, "Field configuration is nil"
    end
    
    local errors = {}
    
    for line_num, line in pairs(field_config) do
        for col_num, token_str in pairs(line) do
            if token_str and token_str ~= "" then
                local evo_id, level = parse_token_string(token_str)
                if evo_id and level then
                    -- Проверяем существование эволюционной цепочки
                    local chain = evolution_tables.get_evolution_chain(evo_id)
                    if not chain then
                        table.insert(errors, "Evolution chain '" .. evo_id .. "' not found at position (" .. col_num .. ", " .. line_num .. ")")
                    elseif level > chain.max_grade then
                        table.insert(errors, "Level " .. level .. " exceeds max grade " .. chain.max_grade .. " for chain '" .. evo_id .. "' at position (" .. col_num .. ", " .. line_num .. ")")
                    end
                else
                    table.insert(errors, "Invalid token format '" .. token_str .. "' at position (" .. col_num .. ", " .. line_num .. ")")
                end
            end
        end
    end
    
    if #errors > 0 then
        print("FIELD CONFIG: Validation errors:")
        for _, error in ipairs(errors) do
            print("  - " .. error)
        end
        return false, table.concat(errors, "; ")
    end
    
    return true
end

-- Функция для получения размера поля из конфигурации
function M.get_field_size(field_config)
    if not field_config then
        return 0, 0
    end
    
    local max_line = 0
    local max_col = 0
    
    for line_num, line in pairs(field_config) do
        if line_num > max_line then
            max_line = line_num
        end
        
        for col_num, _ in pairs(line) do
            if col_num > max_col then
                max_col = col_num
            end
        end
    end
    
    return max_col, max_line
end

-- Функция для отладочного вывода конфигурации
function M.debug_print_config(field_config)
    print("=== Field Configuration Debug ===")
    if not field_config then
        print("Configuration is nil")
        return
    end
    
    local max_col, max_line = M.get_field_size(field_config)
    
    for line = 1, max_line do
        local line_str = "Line " .. line .. ": "
        for col = 1, max_col do
            local token = field_config[line] and field_config[line][col] or ""
            if token == "" then
                line_str = line_str .. "[ ] "
            else
                line_str = line_str .. "[" .. token .. "] "
            end
        end
        print(line_str)
    end
end

return M 