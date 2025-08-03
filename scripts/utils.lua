-- Utilities Module
-- Модуль с общими утилитарными функциями для всего проекта

local M = {}

-- Функция для парсинга строки токена в формате "evo_id-level"
-- token_str: строка в формате "evo_id-level" или пустая строка
-- Возвращает: evo_id, level или nil, nil в случае ошибки
function M.parse_token_string(token_str)
	if not token_str or token_str == "" then
		return nil, nil
	end
	
	local evo_id, level_str = token_str:match("^([^-]+)-(%d+)$")
	if not evo_id or not level_str then
		return nil, nil
	end
	
	local level = tonumber(level_str)
	if not level or level <= 0 then
		return nil, nil
	end
	
	return evo_id, level
end

-- Функция для создания строки токена в формате "evo_id-level"
-- evo_id: ID эволюционной цепочки
-- level: уровень токена
-- Возвращает: строка в формате "evo_id-level" или nil в случае ошибки
function M.create_token_string(evo_id, level)
	if not evo_id or evo_id == "" then
		return nil
	end
	
	if not level or type(level) ~= "number" or level <= 0 then
		return nil
	end
	
	return evo_id .. "-" .. tostring(level)
end

-- Функция для валидации строки токена
-- token_str: строка для валидации
-- Возвращает: true если строка корректна, false иначе
function M.is_valid_token_string(token_str)
	local evo_id, level = M.parse_token_string(token_str)
	return evo_id ~= nil and level ~= nil
end

-- Функция для получения ключа токена по координатам сетки
-- grid_x, grid_y: координаты в сетке
-- Возвращает: строковый ключ в формате "x_y"
function M.get_token_key(grid_x, grid_y)
	if not grid_x or not grid_y then
		return nil
	end
	return tostring(grid_x) .. "_" .. tostring(grid_y)
end

-- Функция для парсинга ключа токена обратно в координаты
-- key: ключ в формате "x_y"
-- Возвращает: grid_x, grid_y или nil, nil в случае ошибки
function M.parse_token_key(key)
	if not key or type(key) ~= "string" then
		return nil, nil
	end
	
	local grid_x_str, grid_y_str = key:match("^(%d+)_(%d+)$")
	if not grid_x_str or not grid_y_str then
		return nil, nil
	end
	
	local grid_x = tonumber(grid_x_str)
	local grid_y = tonumber(grid_y_str)
	
	if not grid_x or not grid_y then
		return nil, nil
	end
	
	return grid_x, grid_y
end

return M 