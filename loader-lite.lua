-- Zeus-X Lite Loader · сразу грузит lite, без меню
local SERVER_URL = "https://zeus-key-mjep.onrender.com/version"

local function fetchVersion(verType)
    local url = SERVER_URL .. "?type=" .. verType
    local ok, response = pcall(function() return game:HttpGet(url, true) end)
    if not ok or not response or response == "" then return nil, "нет соединения" end
    local okDecode, data = pcall(function() return game:GetService("HttpService"):JSONDecode(response) end)
    if not okDecode or not data.ok then return nil, "ошибка сервера" end
    return data.url, data.version
end

local function runScript(verType)
    local scriptUrl, version = fetchVersion(verType)
    if not scriptUrl then
        print("[Zeus-X Loader] Ошибка: " .. tostring(version))
        return
    end
    print("[Zeus-X Loader] Загрузка " .. string.upper(verType) .. " v" .. tostring(version) .. "...")
    local ok, code = pcall(function() return game:HttpGet(scriptUrl, true) end)
    if not ok or not code or code == "" then
        print("[Zeus-X Loader] Ошибка скачивания")
        return
    end
    local func, err = loadstring(code)
    if not func then
        print("[Zeus-X Loader] Ошибка компиляции: " .. tostring(err))
        return
    end
    pcall(func)
end

runScript("lite")