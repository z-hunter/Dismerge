-- Отладочный модуль для тестирования механики выделения клеток
local debugger = {}

-- Функция для тестирования выделения клеток
function debugger.test_cell_selection()
    print("=== DEBUGGER: Testing cell selection ===")
    
    -- Отправляем тестовое сообщение о клике на ячейку
    msg.post("main:/board_factorys#board", "cell_clicked", {
        grid_x = 3,
        grid_y = 4,
        cell_id = "test_cell"
    })
    
    print("DEBUGGER: Sent test click to cell (3, 4)")
end

-- Функция для тестирования координат
function debugger.test_coordinates()
    print("=== DEBUGGER: Testing coordinate system ===")
    
    -- Тестируем преобразование координат
    local test_positions = {
        {x = 300, y = 300}, -- центр поля
        {x = 300 + 64, y = 300}, -- правее центра
        {x = 300, y = 300 + 64}, -- выше центра
        {x = 300 - 64, y = 300}, -- левее центра
        {x = 300, y = 300 - 64}  -- ниже центра
    }
    
    for i, pos in ipairs(test_positions) do
        print("DEBUGGER: Testing screen position (" .. pos.x .. ", " .. pos.y .. ")")
        -- Здесь можно добавить вызов find_cell_at_position если она доступна
    end
end

-- Функция для вывода состояния доски
function debugger.print_board_state()
    print("=== DEBUGGER: Board state ===")
    
    -- Отправляем сообщение в board для получения состояния
    msg.post("main:/board_factorys#board", "debug_get_state")
end

return debugger 