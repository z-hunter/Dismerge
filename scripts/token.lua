-- Token Module - ООП система для фишек
-- Централизованная логика для всех фишек с вложенными компонентами

local token = {}
local automatic_generator = require("scripts.automatic_generator")
local generator_config = require("scripts.generator_config")
local utils = require("scripts.utils")

-- Создание нового объекта фишки
function token.create(evo_id, level, grid_x, grid_y, token_id)
    local self = {
        -- Основные свойства
        evo_id = evo_id,
        level = level,
        grid_x = grid_x,
        grid_y = grid_y,
        token_id = token_id,  -- ID игрового объекта
        
        -- Компоненты
        automatic_generator = nil,
        manual_generator = nil,
        icon_animation = nil,
        
        -- Визуальные компоненты
        generator_icon_id = nil,
        indicator_id = nil,
        auto_indicator_id = nil,
    }
    
    -- Инициализируем компоненты на основе конфигурации
    local generator_id = utils.create_token_string(evo_id, level)
    local generator = generator_config.get_generator(generator_id)
    
    if generator then
        -- Инициализируем автоматический генератор
        if generator.automatic then
            self.automatic_generator = automatic_generator.create(generator_id, generator.automatic)
        end
        
        -- Инициализируем ручной генератор
        if generator.manual then
            self.manual_generator = {
                current_capacity = generator.manual.capacity or 0,
                is_reloading = false,
                reload_start_time = 0,
                reload_end_time = 0,
                completed_cycles = 0,  -- Для одноразовых генераторов
            }
        end
    end
    
    -- Добавляем методы к объекту
    self.update = token.update
    self.move_to = token.move_to
    self.get_key = token.get_key
    self.is_generator = token.is_generator
    self.is_manual_generator = token.is_manual_generator
    self.is_automatic_generator = token.is_automatic_generator
    self.is_disposable = token.is_disposable
    self.activate_manual_generator = token.activate_manual_generator
    self.update_visual = token.update_visual
    self.cleanup = token.cleanup
    
    print("TOKEN: Created token " .. generator_id .. " at (" .. grid_x .. ", " .. grid_y .. ")")
    return self
end

-- Обновление фишки (вызывается каждый кадр)
function token.update(self, dt)
    -- Обновляем автоматический генератор
    if self.automatic_generator then
        local result = self.automatic_generator:update(dt)
        if result == "generate" then
            -- Автоматический генератор готов к генерации
            -- Возвращаем сигнал для обработки в board.script
            return "generate"
        end
    end
    
    -- Обновляем анимацию иконки
    if self.icon_animation then
        self:update_icon_animation(dt)
    end
    
    -- Обновляем ручной генератор (проверка перезарядки)
    if self.manual_generator and self.manual_generator.is_reloading then
        local current_time = os.clock()
        if current_time >= self.manual_generator.reload_end_time then
            self.manual_generator.is_reloading = false
            self.manual_generator.reload_start_time = 0
            self.manual_generator.reload_end_time = 0
            print("TOKEN: Manual generator " .. utils.create_token_string(self.evo_id, self.level) .. " finished reloading")
        end
    end
end

-- Перемещение фишки
function token.move_to(self, new_grid_x, new_grid_y)
    self.grid_x = new_grid_x
    self.grid_y = new_grid_y
    print("TOKEN: Moved token " .. utils.create_token_string(self.evo_id, self.level) .. " to (" .. new_grid_x .. ", " .. new_grid_y .. ")")
end

-- Получение ключа фишки
function token.get_key(self)
    return utils.get_token_key(self.grid_x, self.grid_y)
end

-- Проверка, является ли фишка генератором
function token.is_generator(self)
    local generator_id = utils.create_token_string(self.evo_id, self.level)
    return generator_config.is_generator(generator_id)
end

-- Проверка, является ли фишка ручным генератором
function token.is_manual_generator(self)
    return self.manual_generator ~= nil
end

-- Проверка, является ли фишка автоматическим генератором
function token.is_automatic_generator(self)
    return self.automatic_generator ~= nil
end

-- Проверка, является ли фишка одноразовым генератором
function token.is_disposable(self)
    local generator_id = utils.create_token_string(self.evo_id, self.level)
    return generator_config.is_disposable(generator_id)
end

-- Активация ручного генератора
function token.activate_manual_generator(self)
    if not self.manual_generator or self.manual_generator.is_reloading then
        return false
    end
    
    if self.manual_generator.current_capacity <= 0 then
        return false
    end
    
    -- Уменьшаем емкость
    self.manual_generator.current_capacity = self.manual_generator.current_capacity - 1
    
    -- Если емкость закончилась, запускаем перезарядку
    if self.manual_generator.current_capacity <= 0 then
        local generator_id = utils.create_token_string(self.evo_id, self.level)
        local generator = generator_config.get_generator(generator_id)
        
        if generator and generator.manual and generator.manual.reload_sec then
            self.manual_generator.is_reloading = true
            local current_time = os.clock()
            self.manual_generator.reload_start_time = current_time
            self.manual_generator.reload_end_time = current_time + generator.manual.reload_sec
            print("TOKEN: Manual generator " .. generator_id .. " started reloading")
        end
    end
    
    return true
end

-- Обновление визуальных компонентов
function token.update_visual(self)
    -- Обновляем индикаторы прогресса
    if self.manual_generator and self.manual_generator.is_reloading then
        local current_time = os.clock()
        local progress = 0
        if self.manual_generator.reload_end_time > self.manual_generator.reload_start_time then
            progress = (current_time - self.manual_generator.reload_start_time) / 
                      (self.manual_generator.reload_end_time - self.manual_generator.reload_start_time)
            progress = math.min(progress, 1.0)
        end
        -- Здесь можно обновить визуальный индикатор
    end
    
    -- Обновляем индикатор автоматического генератора
    if self.automatic_generator then
        local is_reloading = self.automatic_generator:is_reloading()
        local progress = self.automatic_generator:get_reload_progress()
        -- Здесь можно обновить визуальный индикатор
    end
end

-- Обновление анимации иконки
function token.update_icon_animation(self, dt)
    if not self.icon_animation or not self.generator_icon_id or not go.exists(self.generator_icon_id) then
        return
    end
    
    -- Обновляем таймер анимации
    self.icon_animation.timer = self.icon_animation.timer + dt
    
    local phase_progress = 0
    local current_scale = self.icon_animation.original_scale
    
    -- Определяем текущую фазу и прогресс
    if self.icon_animation.phase == 0 then
        -- Фаза 0: Уменьшение до 0.7
        local current_phase_duration = self.icon_animation.animation_duration
        phase_progress = math.min(self.icon_animation.timer / current_phase_duration, 1.0)
        current_scale = vmath.lerp(phase_progress, self.icon_animation.original_scale, vmath.vector3(0.35, 0.35, 1))
        
        if self.icon_animation.timer >= current_phase_duration then
            self.icon_animation.phase = 1
            self.icon_animation.timer = 0
        end
        
    elseif self.icon_animation.phase == 1 then
        -- Фаза 1: Увеличение до 1.3
        local current_phase_duration = self.icon_animation.animation_duration
        phase_progress = math.min(self.icon_animation.timer / current_phase_duration, 1.0)
        current_scale = vmath.lerp(phase_progress, vmath.vector3(0.35, 0.35, 1), vmath.vector3(0.65, 0.65, 1))
        
        if self.icon_animation.timer >= current_phase_duration then
            self.icon_animation.phase = 2
            self.icon_animation.timer = 0
        end
        
    elseif self.icon_animation.phase == 2 then
        -- Фаза 2: Уменьшение до 0.8
        local current_phase_duration = self.icon_animation.animation_duration
        phase_progress = math.min(self.icon_animation.timer / current_phase_duration, 1.0)
        current_scale = vmath.lerp(phase_progress, vmath.vector3(0.65, 0.65, 1), vmath.vector3(0.4, 0.4, 1))
        
        if self.icon_animation.timer >= current_phase_duration then
            self.icon_animation.phase = 3
            self.icon_animation.timer = 0
        end
        
    elseif self.icon_animation.phase == 3 then
        -- Фаза 3: Возврат к оригинальному размеру
        local current_phase_duration = self.icon_animation.animation_duration
        phase_progress = math.min(self.icon_animation.timer / current_phase_duration, 1.0)
        current_scale = vmath.lerp(phase_progress, vmath.vector3(0.4, 0.4, 1), self.icon_animation.original_scale)
        
        if self.icon_animation.timer >= current_phase_duration then
            self.icon_animation.phase = 4
            self.icon_animation.timer = 0
        end
        
    elseif self.icon_animation.phase == 4 then
        -- Фаза 4: Пауза 5 секунд
        if self.icon_animation.timer >= self.icon_animation.pause_duration then
            self.icon_animation.phase = 0
            self.icon_animation.timer = 0
        end
    end
    
    -- Применяем текущий размер
    go.set_scale(current_scale, self.generator_icon_id)
end

-- Создание анимации иконки
function token.create_icon_animation(self)
    if not self.icon_animation then
        self.icon_animation = {
            timer = 0,
            phase = 0,
            original_scale = vmath.vector3(1.0, 1.0, 1),
            animation_duration = 0.2,
            pause_duration = 5.0
        }
        print("TOKEN: Created icon animation for " .. utils.create_token_string(self.evo_id, self.level))
    end
end

-- Очистка ресурсов
function token.cleanup(self)
    -- Удаляем визуальные компоненты
    if self.generator_icon_id and go.exists(self.generator_icon_id) then
        go.delete(self.generator_icon_id)
    end
    
    if self.indicator_id and go.exists(self.indicator_id) then
        go.delete(self.indicator_id)
    end
    
    if self.auto_indicator_id and go.exists(self.auto_indicator_id) then
        go.delete(self.auto_indicator_id)
    end
    
    -- Очищаем компоненты
    self.automatic_generator = nil
    self.manual_generator = nil
    self.icon_animation = nil
    
    print("TOKEN: Cleaned up token " .. utils.create_token_string(self.evo_id, self.level))
end

return token
