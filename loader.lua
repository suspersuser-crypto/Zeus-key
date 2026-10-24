local SERVER_URL = "https://zeus-key-mjep.onrender.com/version"
local SELECTED_TYPE = "lite"

local function fetchVersion()
    local url = SERVER_URL .. "?type=" .. SELECTED_TYPE
    local ok, response = pcall(function() return game:HttpGet(url, true) end)
    if not ok or not response or response == "" then return nil, "нет соединения с сервером" end
    local okDecode, data = pcall(function() return game:GetService("HttpService"):JSONDecode(response) end)
    if not okDecode or not data.ok then return nil, "ошибка сервера" end
    return data.url, data.version
end

local function runScript()
    print("[Zeus-X Loader] Запрос версии...")
    local scriptUrl, version = fetchVersion()
    if not scriptUrl then print("[Zeus-X Loader] Ошибка: " .. tostring(version)) return end
    print("[Zeus-X Loader] Версия: " .. tostring(version) .. ". Загрузка...")
    local ok, code = pcall(function() return game:HttpGet(scriptUrl, true) end)
    if not ok or not code or code == "" then print("[Zeus-X Loader] Ошибка скачивания") return end
    local func, err = loadstring(code)
    if not func then print("[Zeus-X Loader] Ошибка компиляции: " .. tostring(err)) return end
    print("[Zeus-X Loader] Запуск...")
    pcall(func)
end
runScript()