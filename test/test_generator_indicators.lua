-- Тестовый скрипт для проверки индикаторов генераторов
local Indicator = require("scripts.progress_indicator_module")
local generator_config = require("scripts.generator_config")

-- Загружаем конфигурацию генераторов
local generators = generator_config.load_generator_config()

-- Тестируем создание индикатора
local function test_indicator_creation()
    print("=== Testing Indicator Creation ===")
    
    -- Создаем индикатор в центре экрана
    local indicator = Indicator:new(vmath.vector3(480, 320, 0), vmath.vector3(0.25, 0.25, 1))
    indicator:set_color(vmath.vector4(0.2, 0.6, 1.0, 1)) -- Синий цвет
    indicator:set_progress(0.5) -- 50% прогресс
    
    print("Indicator created successfully")
    
    -- Тестируем обновление прогресса
    indicator:set_progress(0.75)
    print("Progress updated to 75%")
    
    -- Удаляем индикатор
    indicator:destroy()
    print("Indicator destroyed")
end

-- Тестируем конфигурацию генераторов
local function test_generator_config()
    print("=== Testing Generator Configuration ===")
    
    -- Проверяем генератор GEN_P-6
    local generator_id = "GEN_P-6"
    local generator = generator_config.get_generator(generator_id)
    
    if generator then
        print("Generator " .. generator_id .. " found:")
        print("  Manual capacity: " .. tostring(generator.manual.capacity))
        print("  Manual reload time: " .. tostring(generator.manual.reload_sec))
        print("  Is generator: " .. tostring(generator_config.is_generator(generator_id)))
        
        -- Тестируем активацию
        local can_activate, error_msg = generator_config.can_activate_manual(generator_id)
        print("  Can activate: " .. tostring(can_activate) .. " (" .. (error_msg or "no error") .. ")")
        
        if can_activate then
            local success = generator_config.activate_manual(generator_id)
            print("  Activation result: " .. tostring(success))
            
            local is_reloading = generator_config.is_reloading(generator_id)
            local progress = generator_config.get_reload_progress(generator_id)
            print("  Is reloading: " .. tostring(is_reloading))
            print("  Reload progress: " .. tostring(progress))
        end
    else
        print("Generator " .. generator_id .. " not found")
    end
end

-- Запускаем тесты
test_indicator_creation()
test_generator_config()

print("=== All tests completed ===") 