-- Universal CSV Parser Module
-- Модуль для универсального парсинга CSV файлов согласно правилам из tech-spec.md
-- 
-- Правила парсинга:
-- 1. Первая строка зарезервирована для пользовательской информации и игнорируется
-- 2. Вторая строка содержит заголовки полей
-- 3. Третья и последующие строки содержат данные
-- 4. Пустые строки игнорируются

local M = {}

-- Подключаем модуль логирования
local debug_logger = require("scripts.debug_logger")

-- Функция для удаления пробелов в начале и конце строки
local function trim(str)
    return str:match("^%s*(.-)%s*$")
end

-- Функция для парсинга CSV строки с поддержкой кавычек
local function parse_csv_line(line)
    local result = {}
    local current = ""
    local in_quotes = false
    
    for i = 1, #line do
        local char = line:sub(i, i)
        
        if char == '"' then
            in_quotes = not in_quotes
        elseif char == ',' and not in_quotes then
            table.insert(result, trim(current))
            current = ""
        else
            current = current .. char
        end
    end
    
    -- Добавляем последний элемент
    table.insert(result, trim(current))
    
    return result
end

-- Проверка, является ли строка пустой
local function is_empty_line(line)
    if not line then return true end
    local trimmed = trim(line)
    return trimmed == ""
end

-- Универсальная функция для парсинга CSV файла
-- file_path: путь к CSV файлу
-- field_names: таблица с названиями полей, которые нужно извлечь
-- Возвращает: таблицу с данными или nil в случае ошибки
function M.parse_csv_file(file_path, field_names)
    -- Читаем файл
    local file = io.open(file_path, "r")
    if not file then
        debug_logger.log_error("Cannot open file: " .. file_path)
        return nil
    end
    
    local lines = {}
    for line in file:lines() do
        table.insert(lines, line)
    end
    file:close()
    
    if #lines < 3 then
        debug_logger.log_error("File too short (need at least 3 lines): " .. file_path)
        return nil
    end
    
    -- Пропускаем первую строку (зарезервирована для пользовательской информации)
    -- Вторая строка содержит заголовки полей
    local headers = parse_csv_line(lines[2])
    
    -- Находим индексы нужных полей
    local field_indices = {}
    for field_name, _ in pairs(field_names) do
        field_indices[field_name] = nil
        for i, header in ipairs(headers) do
            if header == field_name then
                field_indices[field_name] = i
                break
            end
        end
        if not field_indices[field_name] then
            debug_logger.log_important("Field '" .. field_name .. "' not found in headers")
        end
    end
    
    -- Обрабатываем строки с данными (начиная с 3-й строки)
    local result = {}
    for i = 3, #lines do
        local line = lines[i]
        
        -- Игнорируем пустые строки
        if not is_empty_line(line) then
            local fields = parse_csv_line(line)
            
            -- Создаем запись с нужными полями
            local record = {}
            for field_name, _ in pairs(field_names) do
                local index = field_indices[field_name]
                if index and fields[index] then
                    record[field_name] = fields[index]
                else
                    record[field_name] = ""
                end
            end
            
            table.insert(result, record)
        end
    end
    
    debug_logger.log_init("Successfully parsed " .. #result .. " records from " .. file_path)
    return result
end

-- Функция для получения значения поля из записи с преобразованием типа
function M.get_field_value(record, field_name, field_type)
    local value = record[field_name]
    if not value or value == "" then
        return nil
    end
    
    if field_type == "number" then
        return tonumber(value)
    elseif field_type == "boolean" then
        return value:lower() == "true" or value == "1"
    else
        return value
    end
end

-- Функция для валидации обязательных полей
function M.validate_required_fields(record, required_fields)
    for _, field_name in ipairs(required_fields) do
        if not record[field_name] or record[field_name] == "" then
            return false, "Missing required field: " .. field_name
        end
    end
    return true
end

return M 