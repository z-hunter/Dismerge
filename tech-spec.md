# 📋 **Техническая спецификация проекта Dismerge**

## 🏗️ **Общая архитектура**

### **Паттерн: Entity-Component-System (ECS) с централизованным управлением**
- **Board** - центральный контроллер игры
- **Cell** - статичные элементы сетки
- **Token** - игровые фишки с состоянием
- **UI** - система отображения информации

---

## 🎯 **Основные сущности (Entities)**

### **1. Board (Доска)**
**Файл:** `scripts/board.script`
**Роль:** Центральный контроллер игры

**Состояния:**
- `is_dragging` - флаг перетаскивания
- `dragged_token` - ID перетаскиваемой фишки
- `dragged_from` - исходная позиция {x, y}
- `dragged_level` - уровень перетаскиваемой фишки
- `dragged_evo_id` - ID эволюционной цепочки перетаскиваемой фишки

**Данные:**
- `cells[x][y]` - массив ячеек
- `tokens[key]` - словарь фишек по ключу "x_y"

**Методы:**
- `start_drag()` - начало перетаскивания
- `handle_token_release()` - обработка отпускания
- `perform_merge()` - выполнение мерджа
- `perform_move()` - выполнение перемещения
- `perform_return()` - выполнение возврата
- `clear_drag_state()` - очистка состояния
- `show_token_info()` - отображение информации о фишке
- `hide_token_info()` - скрытие информации о фишке

### **2. Cell (Ячейка)**
**Файл:** `scripts/item_script.script`
**Роль:** Статичный элемент сетки

**Свойства:**
- `grid_x`, `grid_y` - координаты в сетке

**Компоненты:**
- `sprite` - визуальное отображение

**Методы:**
- `on_message("clicked")` - обработка клика

### **3. Token (Фишка)**
**Файл:** `scripts/token.script`
**Роль:** Игровая фишка с уровнем и эволюционной цепочкой

**Свойства:**
- `level` - уровень фишки (1-12)
- `evo_id` - ID эволюционной цепочки
- `grid_x`, `grid_y` - позиция в сетке
- `is_dragging` - состояние перетаскивания
- `move_target` - цель движения

**Компоненты:**
- `sprite` - визуальное отображение
- `label` - текст с уровнем

**Методы:**
- `update_level_visual()` - обновление визуала
- Обработка сообщений: `start_drag`, `stop_drag`, `set_position`, `move_to`, `set_grid_position`, `update_level`, `update_evo_id`, `get_token_info`

### **4. UI (Пользовательский интерфейс)**
**Файл:** `scripts/ui.script`
**Роль:** Отображение информации о фишках

**Компоненты:**
- `info_label` - label для отображения текста

**Методы:**
- `on_message("show_token_info")` - показ информации о фишке
- `on_message("hide_token_info")` - скрытие информации

---

## 🔄 **Система эволюционных цепочек**

### **1. Конфигурация (config/evo.csv)**
**Структура CSV:**
```csv
Evo_ID,Name_str,NextEvo_ID,MaxGrade,1,2,3,4,5,6,7,8,9,10,11,12
TLS,Tools,CNS,8,гвоздь,отвёртка,топор,нож,ножовка,гаечный ключ,плоскогубцы,домкрат
FNS,Finishing Tools,,9,тряпка,кисточка,валик для краски,закрытая банка краски,открытая банка краски,клей для обоев,обои,плитка для пола,паркет
```

**Поля:**
- `Evo_ID` - уникальный идентификатор цепочки
- `Name_str` - название цепочки
- `NextEvo_ID` - ID следующей цепочки (для продолжения)
- `MaxGrade` - максимальный уровень в цепочке
- `1-12` - названия предметов для каждого уровня

### **2. Модуль evolution_tables (scripts/evolution_tables.lua)**
**Основные функции:**
- `load_evolution_tables()` - загрузка данных из CSV
- `get_evolution_chain(evo_id)` - получение цепочки по ID
- `get_item_name(evo_id, level)` - получение названия предмета
- `get_max_grade(evo_id)` - получение максимального уровня
- `get_next_evolution_id(evo_id)` - получение ID следующей цепочки
- `get_merge_result(evo_id, level)` - получение результата мерджа

**Структура данных:**
```lua
evolution_tables = {
    ["TLS"] = {
        id = "TLS",
        name = "Tools",
        next_evo_id = "CNS",
        max_grade = 8,
        levels = {
            [1] = "гвоздь",
            [2] = "отвёртка",
            -- ...
        }
    }
}
```

### **3. Логика мерджа**
**Правила:**
1. Мердж возможен только между фишками одного уровня и одной цепочки
2. Результат мерджа - следующий уровень той же цепочки
3. При мердже максимального уровня - первый уровень следующей цепочки
4. Если нет следующей цепочки - мердж невозможен

**Алгоритм:**
```lua
function get_merge_result(evo_id, level)
    local chain = evolution_tables[evo_id]
    if level < chain.max_grade then
        return { evo_id = evo_id, level = level + 1 }
    elseif chain.next_evo_id then
        return { evo_id = chain.next_evo_id, level = 1 }
    else
        return nil -- тупиковая цепочка
    end
end
```

---

## 🎨 **Визуальная система**

### **1. Цветовая схема эволюционных цепочек:**
- **TLS (Tools):** Красный
- **FNS (Finishing Tools):** Зеленый
- **SPR (Spare Parts):** Синий
- **CNS (Construction Materials):** Желтый
- **LGH (Light):** Пурпурный
- **ELC (Electrics):** Оранжевый

### **2. Отображение информации о фишках:**
**Триггер:** Клик или начало перетаскивания фишки
**Формат:** "Название цепочки - Уровень X - Название предмета"
**Пример:** "Tools - Уровень 1 - гвоздь"

**Поток данных:**
```
Клик на фишку → board.start_drag() → 
show_token_info(evo_id, level) → 
evolution_tables.get_evolution_chain() + get_item_name() → 
msg.post("main:/ui", "show_token_info") → 
ui.on_message() → label.set_text()
```

### **3. Масштабирование:**
- **Базовый размер:** 0.8 + level * 0.1
- **При перетаскивании:** 1.2x

### **4. Z-координаты:**
- **Ячейки:** z = 0
- **Фишки:** z = 1 (поверх ячеек)
- **UI:** z = 1 (поверх всего)

---

## 🔄 **Поток данных и взаимодействий**

### **1. Инициализация:**
```
main.collection → board_factorys.go → board.script
board.script создает:
- cells[x][y] через cell_factory
- tokens[key] через token_factory (с evo_id)
evolution_tables.load_evolution_tables() → загрузка CSV
```

### **2. Обработка ввода:**
```
Mouse Input → board.on_input() → 
├─ action.pressed → start_drag()
└─ action.released → handle_token_release()
```

### **3. Перетаскивание:**
```
start_drag() → 
├─ Удаление из self.tokens[key]
├─ msg.post(token, "start_drag")
├─ show_token_info(evo_id, level) → отображение информации
└─ Установка состояния перетаскивания

update() → 
└─ msg.post(token, "set_position") для следования за курсором
```

### **4. Отпускание фишки:**
```
handle_token_release() → 
├─ МЕРДЖ: perform_merge() → evolution_tables.get_merge_result() → создание новой фишки
├─ ПЕРЕМЕЩЕНИЕ: perform_move() → перемещение на пустую ячейку
└─ ВОЗВРАТ: perform_return() → возврат на исходную позицию

clear_drag_state() → 
├─ msg.post(token, "stop_drag")
└─ hide_token_info() → скрытие информации
```

### **5. Отображение информации:**
```
Клик на фишку → 
board.show_token_info(evo_id, level) → 
evolution_tables.get_evolution_chain() + get_item_name() → 
msg.post("main:/ui", "show_token_info") → 
ui.on_message() → label.set_text("#info_label", info_text)
```

---

## 🗺️ **Система координат**

### **1. Сетка:**
- **Размер:** 7x9 ячеек
- **Размер ячейки:** 64 пикселя
- **Смещение:** FIX_X = 300, FIX_Y = 300

### **2. Преобразования:**
- `grid_to_screen(gx, gy)` - сетка → экран
- `find_cell_at_position(screen_x, screen_y)` - экран → сетка

### **3. Ключи данных:**
- `tokens[x .. "_" .. y]` - ключ для хранения фишек

---

## 🔧 **Технические особенности**

### **1. Фабрики (Factories):**
- `cell_factory` - создание ячеек
- `token_factory` - создание фишек (с параметрами evo_id)

### **2. Система сообщений:**
- `msg.post()` - отправка сообщений между объектами
- `on_message()` - обработка входящих сообщений
- `msg.post("main:/ui", ...)` - отправка в UI систему

### **3. Анимация:**
- **Скорость:** 2500 пикселей/секунду
- **Интерполяция:** vmath.lerp для плавности

### **4. Ввод:**
- **Действие:** "touch" (MOUSE_BUTTON_1)
- **Обработка:** board.script получает фокус ввода

### **5. CSV парсинг:**
- **Файлы:** config/evo.csv, config/init.csv
- **Кодировка:** UTF-8
- **Разделитель:** запятая
- **Обработка:** trim() для удаления пробелов

#### Правила парсинга CSV файлов, использующихся в игре
Первая строка таблицы зарезервирована для пользовательской информации и всегда должна игнорироваться.
Вторая строка содержит заголовки полей, позволяющие находить нужные столбцы в таблице. Например, если во втором столбце содержится строка "id", значит параметр id находится в строках данных во втором столбце.
Третья и все остальные строки содержат данные. При этом, некоторые из строк могут быть пустыми (все столбцы ничего не содержат), они должны быть проигнорировны.

---

## 🎯 **Архитектурные принципы**

### **1. Централизованное управление:**
- Board контролирует всю игровую логику
- Ячейки и фишки - пассивные объекты
- UI система - отдельный модуль

### **2. Разделение ответственности:**
- Board - игровая логика и мердж
- Token - визуал и анимация
- Cell - статичное отображение
- UI - отображение информации
- evolution_tables - данные эволюционных цепочек

### **3. Конфигурируемость:**
- Эволюционные цепочки настраиваются через CSV
- Легко добавлять новые цепочки и предметы
- Гибкая система связей между цепочками

### **4. Расширяемость:**
- Легко добавить новые уровни фишек
- Простое добавление новых механик
- Модульная архитектура

---

## 🚀 **Потенциал для расширения**

### **1. Возможные улучшения:**
- Система очков за мерджи
- Анимации эффектов при мердже
- Звуковые эффекты
- Сохранение прогресса
- Множественные уровни
- Специальные фишки (бонусы, препятствия)
- Система достижений

### **2. Архитектурная готовность:**
- Чистая структура данных
- Модульная система сообщений
- Простые интерфейсы между компонентами
- Конфигурируемые эволюционные цепочки

---

## 📁 **Структура файлов**

```
Dismerge/
├── main/
│   ├── main.collection          # Главная коллекция
│   ├── board_factorys.go        # Фабрики для доски
│   ├── board.go                 # Прототип доски
│   ├── cell.go                  # Прототип ячейки
│   ├── token.go                 # Прототип фишки
│   ├── ui.go                    # Прототип UI
│   ├── cell_factory.factory     # Фабрика ячеек
│   └── token_factory.factory    # Фабрика фишек
├── scripts/
│   ├── board.script             # Основная игровая логика
│   ├── token.script             # Логика фишек
│   ├── item_script.script       # Логика ячеек
│   ├── ui.script                # Логика UI
│   └── evolution_tables.lua     # Модуль эволюционных таблиц
├── config/
│   └── evo.csv                  # Конфигурация эволюционных цепочек
|   └── init.csv                 # Начальная конфигурация игрового поля
├── assets/
│   ├── tile.atlas               # Атлас текстур
│   ├── tile.png                 # Текстура ячеек
│   └── token.png                # Текстура фишек
├── input/
│   └── game.input_binding       # Настройки ввода
├── game.project                 # Конфигурация проекта
└── tech-spec.md                 # Техническая документация
```

---

## 🔍 **Ключевые алгоритмы**

### **1. Определение мерджа с эволюционными цепочками:**
```lua
-- Проверка возможности мерджа
if target_token and 
   target_token.level == self.dragged_level and 
   target_token.evo_id == self.dragged_evo_id then
    -- Выполнить мердж
    local merge_result = evolution_tables.get_merge_result(evo_id, level)
    if merge_result then
        -- Создать новую фишку с результатом мерджа
    end
end
```

### **2. Отображение информации о фишке:**
```lua
function show_token_info(self, evo_id, level)
    local chain = evolution_tables.get_evolution_chain(evo_id)
    local item_name = evolution_tables.get_item_name(evo_id, level)
    local info_text = chain.name .. " - Уровень " .. level .. " - " .. item_name
    msg.post("main:/ui", "show_token_info", {
        chain_name = chain.name,
        level = level,
        item_name = item_name
    })
end
```

### **3. Плавное движение:**
```lua
-- В token.script
if self.move_target then
    local direction = self.move_target - current_pos
    local movement = vmath.normalize(direction) * move_speed * dt
    go.set_position(current_pos + movement, ".")
end
```

### **4. Поиск ячейки по позиции:**
```lua
-- В board.script
local function find_cell_at_position(screen_x, screen_y)
    for x = 1, GRID_WIDTH do
        for y = 1, GRID_HEIGHT do
            local cell_pos = grid_to_screen(x, y)
            local distance = vmath.length(vmath.vector3(screen_x, screen_y, 0) - cell_pos)
            if distance <= CELL_SIZE / 2 then
                return { x = x, y = y }
            end
        end
    end
    return nil
end
```

### **5. Парсинг CSV файла:**
```lua
function parse_csv_line(line)
    local result = {}
    local current = ""
    local in_quotes = false
    
    for i = 1, #line do
        local char = line:sub(i, i)
        if char == '"' then
            in_quotes = not in_quotes
        elseif char == ',' and not in_quotes then
            table.insert(result, current)
            current = ""
        else
            current = current .. char
        end
    end
    table.insert(result, current)
    return result
end
```

---

## ⚠️ **Технические проблемы и найденные решения**

### **Проблема: Неожиданное поведение множественных спрайтов в одном Game Object**

**Суть:** При управлении несколькими спрайтами внутри одного Game Object их поведение становится непредсказуемым - изменение позиции одного спрайта влияет на позицию других, операции с дочерними компонентами перемещают весь родительский объект.

**Решение:** Использовать отдельные Game Objects для каждого спрайта, управляемые через контроллер-скрипт.

**Архитектура:**
```
❌ НЕ ДЕЛАТЬ:          ✅ ДЕЛАТЬ:
Game Object             Collection
├── sprite1             ├── object1 (+ sprite)
└── sprite2             ├── object2 (+ sprite)
                        └── controller (+ script)
```

**Принцип:** Один независимый элемент = один Game Object.

### **Проблемы с factory/collectionfactory и их решения**

**Проблема 1: Неправильная обработка возвращаемых значений**
- **Симптом:** Ошибки при обращении к созданным объектам, "Object not found"
- **Причина:** collectionfactory.create() возвращает таблицу ID, а не один ID
- **Решение:** Использовать ключ hash("/имя_корня") для доступа к корневому объекту:
```lua
local result = collectionfactory.create("factory_name#collectionfactory", pos)
local root_id = result[hash("/root_name")]  -- Правильно
-- local root_id = result  -- Неправильно
```

**Проблема 2: Конфликты при создании множественных объектов**
- **Симптом:** Объекты создаются в неправильных позициях или не создаются
- **Причина:** Одновременное создание объектов с одинаковыми параметрами
- **Решение:** Добавлять уникальные идентификаторы или задержки между созданиями

### **Проблемы синхронизации и анимации множественных объектов**

**Проблема 1: Синхронная анимация всех объектов**
- **Симптом:** Все объекты анимируются одновременно с одинаковой скоростью
- **Причина:** Использование одной переменной времени для всех объектов
- **Решение:** Каждый объект должен иметь свой таймер:
```lua
-- Неправильно:
self.timer = self.timer + dt
local progress = (self.timer / duration) % 1
for i, obj in ipairs(self.objects) do
    animate_object(obj, progress)  -- Все объекты синхронны
end

-- Правильно:
for i, obj in ipairs(self.objects) do
    self.timers[i] = (self.timers[i] or 0) + dt
    local progress = (self.timers[i] / duration) % 1
    animate_object(obj, progress)  -- Каждый объект независим
end
```

**Проблема 2: Потеря состояния при управлении множественными объектами**
- **Симптом:** Объекты "забывают" свои параметры, анимация прерывается
- **Причина:** Отсутствие индивидуального состояния для каждого объекта
- **Решение:** Хранить состояние в таблицах с индексами или ID объектов:
```lua
self.object_states = {}  -- Таблица состояний по ID
self.object_states[object_id] = {
    timer = 0,
    progress = 0,
    color = "blue"
}
```

**Проблема 3: Конфликты при изменении позиции и Z-координат**
- **Симптом:** При изменении Z-координаты теряются X и Y координаты
- **Причина:** go.set_position(x, y, z) перезаписывает все координаты
- **Решение:** Сохранять текущие координаты при изменении Z:
```lua
local pos = go.get_position(".")
go.set_position(vmath.vector3(pos.x, pos.y, new_z), ".")
```

### **Правила Z-слоистости для визуальных элементов**

**Принцип:** Более высокие Z-координаты = ближе к камере (поверх других элементов).

**Стандартная схема слоев:**
```
z = 0.0   - Фоновые элементы (самые дальние)
z = 0.1   - Основные игровые объекты
z = 0.2   - Элементы интерфейса
z = 0.3   - Эффекты и анимации
z = 0.4   - UI элементы (ближайшие к камере)
```

**Правила перекрытия:**
- Элемент с большим Z закрывает элемент с меньшим Z
- Для создания эффекта "под/за" используйте промежуточные Z-значения
- Рекомендуемый шаг между слоями: 0.1-0.25

**Пример:** Индикатор прогресса с тремя слоями:
```
z = 0.0   - Фоновый полукруг (самый дальний)
z = 0.25  - Прогресс-полукруг (средний слой)
z = 0.5   - Передний полукруг (ближайший к камере)
```

### **Система координат экрана**

**Размеры экрана:** 960x640 пикселей

**Ключевые точки:**
- **Начало координат (0, 0):** Левый нижний угол экрана
- **Центр экрана:** (480, 320)
- **Правый верхний угол:** (960, 640)
- **Положительная ось X:** вправо
- **Положительная ось Y:** вверх
- **Положительная ось Z:** ближе к камере

**Игровая сетка:**
- **Смещение сетки:** (300, 300) от начала координат
- **Размер ячейки:** 64 пикселя
- **Центр сетки:** примерно (524, 588)

### **Модульный круговой индикатор прогресса**

**Файлы:**
- `modules/progress_indicator/progress_indicator.script` — скрипт индикатора
- `modules/progress_indicator/progress_indicator.collection` — коллекция индикатора
- `modules/progress_indicator/indicator_factory.collectionfactory` — collectionfactory для создания индикаторов
- `scripts/progress_indicator_module.lua` — ООП-модуль для управления индикаторами

**Использование (ООП API):**
```lua
local Indicator = require "scripts.progress_indicator_module"

-- Создать индикатор в заданной позиции и масштабе
local ind = Indicator:new(vmath.vector3(100, 100, 0), vmath.vector3(1.5, 1.5, 1))

-- Установить прогресс (0.0 - 1.0)
ind:set_progress(0.75)

-- Установить цвет (RGBA, значения 0..1)
ind:set_color(vmath.vector4(1, 0, 0, 1)) -- красный

-- Удалить индикатор
ind:destroy()
```

**Методы объекта индикатора:**
- `:set_progress(value)` — установить прогресс (от 0.0 до 1.0)
- `:set_color(color)` — установить цвет вращающегося сектора (vmath.vector4)
- `:destroy()` — удалить индикатор (все части)

**Особенности:**
- Каждый индикатор — независимый объект (таблица с методами)
- Поддержка любого количества индикаторов на сцене
- Масштаб и цвет задаются при создании и могут меняться динамически
- Удаление полностью очищает все части индикатора
- Вся логика управления скрыта внутри модуля

**Пример создания трёх индикаторов разного размера и цвета:**
```lua
local ind1 = Indicator:new(vmath.vector3(100, 100, 0), vmath.vector3(0.7, 0.7, 1))
ind1:set_color(vmath.vector4(0.2, 0.6, 1.0, 1)) -- синий

local ind2 = Indicator:new(vmath.vector3(300, 100, 0), vmath.vector3(1, 1, 1))
ind2:set_color(vmath.vector4(0.2, 1.0, 0.2, 1)) -- зелёный

local ind3 = Indicator:new(vmath.vector3(500, 100, 0), vmath.vector3(1.5, 1.5, 1))
ind3:set_color(vmath.vector4(1.0, 0.2, 0.2, 1)) -- красный
```

---

