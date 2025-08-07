-- Модуль для управления круговыми индикаторами прогресса
local Indicator = {}
Indicator.__index = Indicator

-- Путь к фабрике (через holder в main collection)
local FACTORY_URL = "main:/indicator_factory_holder#collectionfactory"

function Indicator:new(position, scale)
    local ids = collectionfactory.create(FACTORY_URL, position or vmath.vector3(0,0,0))
    local self = setmetatable({}, Indicator)
    self.ids = ids
    self.root = ids[hash("/indicator_root")]
    scale = scale or vmath.vector3(1, 1, 1)
    for _, id in pairs(ids) do
        go.set_scale(scale, id)
    end
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