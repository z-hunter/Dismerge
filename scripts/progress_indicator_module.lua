-- Модуль для управления круговыми индикаторами прогресса
local Indicator = {}
Indicator.__index = Indicator

-- Путь к фабрике (локальный для коллекции)
local FACTORY_URL = "indicator_factory_holder#collectionfactory"

function Indicator:new(position)
    local ids = collectionfactory.create(FACTORY_URL, position or vmath.vector3(0,0,0))
    local self = setmetatable({}, Indicator)
    self.ids = ids
    self.root = ids[hash("/indicator_root")]
    return self
end

function Indicator:set_progress(value)
    if self.root then
        msg.post(self.root, "set_progress", { progress = value })
    end
end

function Indicator:set_color(color)
    if self.root then
        msg.post(self.root, "set_color", { color = color })
    end
end

function Indicator:destroy()
    if self.ids then
        for _, id in pairs(self.ids) do
            go.delete(id)
        end
        self.ids = nil
        self.root = nil
    end
end

return Indicator 