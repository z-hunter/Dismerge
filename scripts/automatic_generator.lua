-- Автоматические генераторы - ООП система управления
-- Централизованная логика для всех автоматических генераторов

local automatic_generator = {}

-- Создание нового автоматического генератора
function automatic_generator.create(generator_id, config)
    local self = {
        -- Основные свойства
        generator_id = generator_id,
        config = config,
        
        -- Состояние генератора
        capacity = 0,  -- Стартуем в исчерпанном состоянии
        _is_reloading = true,  -- Стартуем в состоянии перезарядки
        _is_paused = false,  -- Приостановлен из-за отсутствия места
        
        -- Таймеры
        timer = 0,  -- Таймер генерации
        reload_timer = 0,  -- Таймер перезарядки
        
        -- Визуальные свойства
        reload_progress = 0,  -- Прогресс перезарядки (0-1)
    }
    
    -- Добавляем методы к объекту
    self.update = automatic_generator.update
    self.try_generate = automatic_generator.try_generate
    self.pause = automatic_generator.pause
    self.resume = automatic_generator.resume
    self.get_reload_progress = automatic_generator.get_reload_progress
    self.is_reloading = automatic_generator.is_reloading
    self.is_paused = automatic_generator.is_paused
    self.is_ready = automatic_generator.is_ready
    self.get_capacity = automatic_generator.get_capacity
    self.get_timer_progress = automatic_generator.get_timer_progress
    
    print("AUTO_GEN: Created automatic generator " .. generator_id .. " with capacity 0 (exhausted, needs reload)")
    return self
end

-- Обновление генератора (вызывается каждый кадр)
function automatic_generator.update(self, dt)
    if self._is_reloading then
        -- Генератор на перезарядке
        self.reload_timer = self.reload_timer + dt
        self.reload_progress = math.min(self.reload_timer / (self.config.reload_sec or 0), 1.0)
        
        if self.reload_timer >= (self.config.reload_sec or 0) then
            -- Перезарядка завершена
            self._is_reloading = false
            self.reload_timer = 0
            self.capacity = self.config.capacity or 0
            self.reload_progress = 0
            print("AUTO_GEN: " .. self.generator_id .. " finished reloading, restored capacity to " .. (self.config.capacity or 0))
        end
    else
        -- Генератор готов к работе
        if self.capacity > 0 then
            -- Таймер работает только если генератор не заморожен
            if not self._is_paused then
                self.timer = self.timer + dt
                
                if self.timer >= (self.config.timer_sec or 0) then
                    -- Время для генерации
                    return "generate"
                end
            end
        end
    end
    
    return "idle"
end

-- Попытка генерации одной фишки
function automatic_generator.try_generate(self)
    if self.capacity > 0 then
        local old_capacity = self.capacity
        self.capacity = self.capacity - 1
        print("AUTO_GEN: " .. self.generator_id .. " capacity reduced from " .. old_capacity .. " to " .. self.capacity)
        
        -- Если емкость закончилась, запускаем перезарядку
        if self.capacity <= 0 and self.config.reload_sec then
            self._is_reloading = true
            self.reload_timer = 0
            print("AUTO_GEN: " .. self.generator_id .. " started reloading")
        end
        
        -- Таймер будет сброшен в board.script после успешной генерации фишки
        
        return true
    end
    
    return false
end



-- Приостановка генератора (нет места для дропа)
function automatic_generator.pause(self)
    if not self._is_paused then
        self._is_paused = true
        print("AUTO_GEN: " .. self.generator_id .. " paused - no adjacent cells available")
    end
    -- Таймер НЕ сбрасываем - он останется на текущем значении
end

-- Возобновление генератора (появилось место для дропа)
function automatic_generator.resume(self)
    if self._is_paused then
        self._is_paused = false
        print("AUTO_GEN: " .. self.generator_id .. " resumed - adjacent cells available")
    end
end

-- Получение прогресса перезарядки
function automatic_generator.get_reload_progress(self)
    return self.reload_progress
end

-- Проверка, находится ли генератор на перезарядке
function automatic_generator.is_reloading(self)
    return self._is_reloading
end

-- Проверка, приостановлен ли генератор
function automatic_generator.is_paused(self)
    return self._is_paused
end

-- Проверка, готов ли генератор к работе
function automatic_generator.is_ready(self)
    return not self._is_reloading and self.capacity > 0 and not self._is_paused
end

-- Получение текущей емкости
function automatic_generator.get_capacity(self)
    return self.capacity
end

-- Получение прогресса таймера
function automatic_generator.get_timer_progress(self)
    if self._is_reloading or self._is_paused or self.capacity <= 0 then
        return 0
    end
    return math.min(self.timer / (self.config.timer_sec or 0), 1.0)
end

return automatic_generator
