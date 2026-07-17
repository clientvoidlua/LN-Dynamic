local Games = {
    ["The Mimic"] = {
        ["Book 3"] = {
            [128715637193371] = {
                Name = "Chapter 1",
                Script = "https://raw.githubusercontent.com/clientvoidlua/LN-Dynamic/refs/heads/main/games/The%20Mimic/Book%203/chapter1.lua"
            }
        }
    }
}

local PlaceId = game.PlaceId

for _, books in pairs(Games) do
    for _, chapters in pairs(books) do
        local data = chapters[PlaceId]
        if data then
            return loadstring(game:HttpGet(data.Script))()
        end
    end
end

warn(string.format("[Dynamic Hub] Unsupported game. PlaceId: %d", PlaceId))
