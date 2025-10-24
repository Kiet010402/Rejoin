-- Load UI Library với error handling
local success, err = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    InterfaceManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)

if not success then
    warn("Lỗi khi tải UI Library: " .. tostring(err))
    return
end

-- Đợi đến khi Fluent được tải hoàn tất
if not Fluent then
    warn("Không thể tải thư viện Fluent!")
    return
end

-- Hệ thống lưu trữ cấu hình
local ConfigSystem = {}
ConfigSystem.FileName = "HTHubAllStar_" .. game:GetService("Players").LocalPlayer.Name .. ".json"
ConfigSystem.DefaultConfig = {
    -- Webhook Settings
    WebhookEnabled = false,
    WebhookUrl = "",
    AutoHideUIEnabled = false,
    LastPumpkins = 0,
}
ConfigSystem.CurrentConfig = {}

-- Hàm để lưu cấu hình
ConfigSystem.SaveConfig = function()
    local success, err = pcall(function()
        writefile(ConfigSystem.FileName, game:GetService("HttpService"):JSONEncode(ConfigSystem.CurrentConfig))
    end)
    if success then
        print("Đã lưu cấu hình thành công!")
    else
        warn("Lưu cấu hình thất bại:", err)
    end
end

-- Hàm để tải cấu hình
ConfigSystem.LoadConfig = function()
    local success, content = pcall(function()
        if isfile(ConfigSystem.FileName) then
            return readfile(ConfigSystem.FileName)
        end
        return nil
    end)

    if success and content then
        local data = game:GetService("HttpService"):JSONDecode(content)
        ConfigSystem.CurrentConfig = data
        return true
    else
        ConfigSystem.CurrentConfig = table.clone(ConfigSystem.DefaultConfig)
        ConfigSystem.SaveConfig()
        return false
    end
end

-- Tải cấu hình khi khởi động
ConfigSystem.LoadConfig()

-- Biến lưu trạng thái của tab Webhook
local webhookEnabled = ConfigSystem.CurrentConfig.WebhookEnabled or false
local webhookUrl = ConfigSystem.CurrentConfig.WebhookUrl or ""

-- Biến lưu trạng thái Auto Hide UI
local autoHideUIEnabled = ConfigSystem.CurrentConfig.AutoHideUIEnabled or false

-- Biến lưu số Pumpkins trước đó để tính Reward
local lastPumpkins = ConfigSystem.CurrentConfig.LastPumpkins or 0

-- Lấy tên người chơi
local playerName = game:GetService("Players").LocalPlayer.Name

-- Cấu hình UI
local Window = Fluent:CreateWindow({
    Title = "HT HUB | All Star Tower Defense",
    SubTitle = "",
    TabWidth = 80,
    Size = UDim2.fromOffset(300, 220),
    Acrylic = true,
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Hệ thống Tạo Tab

-- Tạo Tab Webhook
local WebhookTab = Window:AddTab({ Title = "Webhook", Icon = "rbxassetid://13311802307" })
-- Tạo Tab Settings
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "rbxassetid://13311798537" })

-- Tab Webhook
-- Section Webhook Settings trong tab Webhook
local WebhookSection = WebhookTab:AddSection("Webhook Settings")
-- Section Script Settings trong tab Settings
local SettingsSection = SettingsTab:AddSection("Script Settings")

-- Thêm Input để nhập Webhook URL
WebhookSection:AddInput("WebhookURLInput", {
    Title = "Webhook URL",
    Default = webhookUrl,
    Placeholder = "Dán link webhook Discord của bạn",
    Callback = function(val)
        webhookUrl = tostring(val or "")
        ConfigSystem.CurrentConfig.WebhookUrl = webhookUrl
        ConfigSystem.SaveConfig()
        print("Webhook URL set:", webhookUrl)
    end
})

-- Thêm Toggle Enable Webhook
WebhookSection:AddToggle("EnableWebhookToggle", {
    Title = "Enable Webhook",
    Description = "Gửi webhook khi có kết quả game",
    Default = webhookEnabled,
    Callback = function(enabled)
        webhookEnabled = enabled
        ConfigSystem.CurrentConfig.WebhookEnabled = webhookEnabled
        ConfigSystem.SaveConfig()
        if webhookEnabled then
            print("Webhook enabled")
        else
            print("Webhook disabled")
        end
    end
})

-- Hàm format số với dấu chấm
local function formatNumber(num)
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
        if k == 0 then
            break
        end
    end
    return formatted
end

-- Hàm gửi webhook về Discord
local function sendWebhook()
    if not webhookEnabled or webhookUrl == "" then return end
    local player = game:GetService("Players").LocalPlayer
    local gems = 0
    local pumpkins = 0
    local name = player.Name
    pcall(function()
        gems = player._stats.gem_amount.Value or 0
    end)
    pcall(function()
        pumpkins = player._stats._resourcePumkinToken.Value or 0
    end)

    -- Tính Reward Pumpkins
    local pumpkinReward = pumpkins - lastPumpkins
    local rewardText = ""
    if pumpkinReward > 0 then
        rewardText = "🎃 Pumpkins +" .. formatNumber(pumpkinReward)
    elseif pumpkinReward < 0 then
        rewardText = "🎃 Pumpkins " .. formatNumber(pumpkinReward)
    end

    -- Cập nhật số Pumpkins cuối cùng
    lastPumpkins = pumpkins
    ConfigSystem.CurrentConfig.LastPumpkins = lastPumpkins
    ConfigSystem.SaveConfig()

    -- Tạo danh sách fields
    local fields = {
        {
            name = "👤 Player",
            value = name,
            inline = false
        },
        {
            name = "💎 Gems",
            value = formatNumber(gems),
            inline = false
        },
        {
            name = "🎃 Pumpkins",
            value = formatNumber(pumpkins),
            inline = false
        }
    }

    -- Thêm Reward nếu có
    if rewardText ~= "" then
        table.insert(fields, {
            name = "Reward",
            value = rewardText,
            inline = false
        })
    end

    -- Tạo embed đẹp
    local data = {
        embeds = {
            {
                title = "Anime Crusaders - Game Results",
                description = "Kết quả game mới nhất",
                color = 0x9932CC, -- Màu tím đẹp
                fields = fields,
                footer = {
                    text = "Kaihon Anime Crusaders",
                    icon_url =
                    "https://images-ext-1.discordapp.net/external/CmlSOppXAMnvaaK2XVHV8FZlQDakSJQGop2XAPbhPyw/%3Fsize%3D4096/https/cdn.discordapp.com/avatars/1269841484090179636/a6032236a677c176d236a53ac480c586.png?format=webp&quality=lossless&width=930&height=930"
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                thumbnail = {
                    url =
                    "https://images-ext-1.discordapp.net/external/CmlSOppXAMnvaaK2XVHV8FZlQDakSJQGop2XAPbhPyw/%3Fsize%3D4096/https/cdn.discordapp.com/avatars/1269841484090179636/a6032236a677c176d236a53ac480c586.png?format=webp&quality=lossless&width=930&height=930"
                }
            }
        }
    }

    local http = game:GetService("HttpService")
    local payload = http:JSONEncode(data)
    print("Sending webhook with embed! Data:", data)
    pcall(function()
        request({
            Url = webhookUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = payload
        })
    end)
end

-- Watcher ResultsUI để gửi webhook khi Enabled = true
local lastResultSent = false
local function watchResultsUI()
    local player = game:GetService("Players").LocalPlayer
    local gui = player.PlayerGui:FindFirstChild("ResultsUI")
    if not gui then return end
    if gui:GetAttribute("_hooked") then return end
    gui:SetAttribute("_hooked", true)
    gui:GetPropertyChangedSignal("Enabled"):Connect(function()
        if gui.Enabled and webhookEnabled and not lastResultSent then
            sendWebhook()
            lastResultSent = true
        elseif not gui.Enabled then
            lastResultSent = false
        end
    end)
    if gui.Enabled and webhookEnabled and not lastResultSent then
        sendWebhook()
        lastResultSent = true
    end
end

-- Tự động theo dõi khi có ResultsUI
local player = game:GetService("Players").LocalPlayer
local pg = player:WaitForChild("PlayerGui")
pg.ChildAdded:Connect(function(child)
    if child.Name == "ResultsUI" then
        watchResultsUI()
    end
end)
if pg:FindFirstChild("ResultsUI") then
    watchResultsUI()
end

-- Hàm tự động ẩn UI sau 3 giây khi bật
local function autoHideUI()
    if not Window then return end
    task.spawn(function()
        print("Auto Hide UI: Sẽ tự động ẩn sau 3 giây...")
        task.wait(3)
        if Window.Minimize then
            Window:Minimize()
            print("UI đã được ẩn!")
        else
            print("Không thể ẩn UI - Window không có phương thức Minimize")
        end
    end)
end

-- Thêm Toggle Auto Hide UI vào Settings tab
SettingsSection:AddToggle("AutoHideUIToggle", {
    Title = "Auto Hide UI",
    Description = "Tự động ẩn UI sau 3 giây khi bật",
    Default = autoHideUIEnabled,
    Callback = function(enabled)
        autoHideUIEnabled = enabled
        ConfigSystem.CurrentConfig.AutoHideUIEnabled = autoHideUIEnabled
        ConfigSystem.SaveConfig()
        if autoHideUIEnabled then
            autoHideUI()
        else
            print("Auto Hide UI đã tắt")
        end
    end
})

-- Integration with SaveManager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Thay đổi cách lưu cấu hình để sử dụng tên người chơi
InterfaceManager:SetFolder("HTHubAllStar")
SaveManager:SetFolder("HTHubAllStar/" .. playerName)

-- Thêm thông tin vào tab Settings
SettingsTab:AddParagraph({
    Title = "Cấu hình tự động",
    Content = "Cấu hình của bạn đang được tự động lưu theo tên nhân vật: " .. playerName
})

SettingsTab:AddParagraph({
    Title = "Phím tắt",
    Content = "Nhấn LeftControl để ẩn/hiện giao diện"
})

-- Auto Save Config
local function AutoSaveConfig()
    spawn(function()
        while wait(5) do -- Lưu mỗi 5 giây
            pcall(function()
                ConfigSystem.SaveConfig()
            end)
        end
    end)
end

-- Thực thi tự động lưu cấu hình
AutoSaveConfig()

-- Thêm event listener để lưu ngay khi thay đổi giá trị
local function setupSaveEvents()
    for _, tab in pairs({ MainTab, SettingsTab }) do
        if tab and tab._components then
            for _, element in pairs(tab._components) do
                if element and element.OnChanged then
                    element.OnChanged:Connect(function()
                        pcall(function()
                            ConfigSystem.SaveConfig()
                        end)
                    end)
                end
            end
        end
    end
end

-- Thiết lập events
setupSaveEvents()

-- Tạo logo để mở lại UI khi đã minimize
task.spawn(function()
    local success, errorMsg = pcall(function()
        if not getgenv().LoadedMobileUI == true then
            getgenv().LoadedMobileUI = true
            local OpenUI = Instance.new("ScreenGui")
            local ImageButton = Instance.new("ImageButton")
            local UICorner = Instance.new("UICorner")

            -- Kiểm tra môi trường
            if syn and syn.protect_gui then
                syn.protect_gui(OpenUI)
                OpenUI.Parent = game:GetService("CoreGui")
            elseif gethui then
                OpenUI.Parent = gethui()
            else
                OpenUI.Parent = game:GetService("CoreGui")
            end

            OpenUI.Name = "OpenUI"
            OpenUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

            ImageButton.Parent = OpenUI
            ImageButton.BackgroundColor3 = Color3.fromRGB(105, 105, 105)
            ImageButton.BackgroundTransparency = 0.8
            ImageButton.Position = UDim2.new(0.9, 0, 0.1, 0)
            ImageButton.Size = UDim2.new(0, 50, 0, 50)
            ImageButton.Image = "rbxassetid://13099788281" -- Logo HT Hub
            ImageButton.Draggable = true
            ImageButton.Transparency = 0.2

            UICorner.CornerRadius = UDim.new(0, 200)
            UICorner.Parent = ImageButton

            -- Khi click vào logo sẽ mở lại UI
            ImageButton.MouseButton1Click:Connect(function()
                if Window and Window.Minimize then
                    -- Nếu window đang minimized thì maximize lại
                    if Window.Minimized then
                        Window:Maximize()
                    else
                        -- Nếu không minimized thì minimize rồi maximize để đảm bảo hiện
                        Window:Minimize()
                        task.wait(0.1)
                        Window:Maximize()
                    end
                end
            end)
        end
    end)

    if not success then
        warn("Lỗi khi tạo nút Logo UI: " .. tostring(errorMsg))
    end
end)

print("HT Hub All Star Tower Defense Script đã tải thành công!")
print("Sử dụng Left Ctrl để thu nhỏ/mở rộng UI")
