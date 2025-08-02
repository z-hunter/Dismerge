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
- **Файл:** config/evo.csv
- **Кодировка:** UTF-8
- **Разделитель:** запятая
- **Обработка:** trim() для удаления пробелов

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

Эта архитектура представляет собой полноценную основу для игры типа "Merge-2" с системой эволюционных цепочек и возможностью дальнейшего развития! 🎮 