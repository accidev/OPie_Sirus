local L, _, T = 0, ...
if T.SkipLocalActionBook then return end
L, T.ActionBook.LW = T.ActionBook.LW, nil

local C, z, V, K = GetLocale(), nil
V =
    C == "ruRU" and { -- 42/44 (95%)
      "Способности", "Использовать предметы с таким же именем", z, z, "Боевой питомец", "Боевые питомцы", "Календарь", "Пользовательские макросы", "Средство передвижения для полётов на драконе", "Комплект экипировки",
      "Ячейка экипировки", "Комплекты экипировки", "Надето", "Дополнительная кнопка действия", "Воздушные средства передвижения", "Главное меню", "Наземные средства передвижения", "Панель интерфейса", "Предмет", "Предметы",
      "Макрос", "Макросы", "Разное", "Средство передвижения", "Средства передвижения", "Новый Макрос", "Показывать только если надет", "Снаряжение", "Модели", "Способности питомца",
      "Способности питомцев", "Рейдовая метка", "Метка на местности", "Рейдовые метки", "Всегда показывать этот фрагмент", "Заклинание", "Игрушки", "Игрушки", "Панели пользовательского интерфейса", "Используйте ещё раз, чтобы разрешить изменять этот облик по ситуации.",
      "Используйте ещё раз, чтобы запретить изменять этот облик по ситуации.", "Использовать наивысший изученный ранг", "Способности местности", "Метки на местности",
    } or nil

K = V and {
      "Abilities", "Also use items with the same name", "Appearance locked", "Appearance unlocked", "Battle Pet", "Battle pets", "Calendar", "Custom Macro", "Dragonriding Mount", "Equipment Set",
      "Equipment Slot", "Equipment sets", "Equipped", "Extra Action Button", "Flying Mount", "Game Menu", "Ground Mount", "Interface Panel", "Item", "Items",
      "Macro", "Macros", "Miscellaneous", "Mount", "Mounts", "New Macro", "Only show when equipped", "Outfit", "Outfits", "Pet Ability",
      "Pet abilities", "Raid Marker", "Raid World Marker", "Raid markers", "Show a placeholder when unavailable", "Spell", "Toy", "Toys", "UI panels", "Use again to allow this apperance to be replaced by a Situation.",
      "Use again to prevent this apperance from being replaced by a Situation.", "Use the highest known rank", "Zone Abilities", "Raid world markers",
}

for i=1,K and #K or 0 do
	L[K[i]] = V[i]
end