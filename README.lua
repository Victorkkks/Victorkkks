--// Configurações Gerais
getgenv().Prediction = 0.0
getgenv().AimPart = "HumanoidRootPart"
getgenv().Key = "c"
getgenv().DisableKey = "p"
getgenv().AutoPrediction = true

getgenv().FOV = true
getgenv().ShowFOV = true
getgenv().FOVSize = 30

--// Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")

--// Variáveis
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

local AimlockEnabled = true
local Locked = false
local Target = nil

--// FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Filled = false
fovCircle.Transparency = 1
fovCircle.Thickness = 1
fovCircle.Color = Color3.fromRGB(255, 255, 0)
fovCircle.NumSides = 1000

--// Função de Notificação
local function Notify(message)
    StarterGui:SetCore("SendNotification", {
        Title = "Victor's Camlock",
        Text = message,
        Duration = 5
    })
end

-- Verificar se o script já está carregado
if getgenv().Loaded then
    Notify("Aimlock já está carregado!")
    return
end
getgenv().Loaded = true

-- Atualizar FOV
local function UpdateFOV()
    if getgenv().FOV then
        fovCircle.Radius = getgenv().FOVSize * 2
        fovCircle.Visible = getgenv().ShowFOV
        fovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + GuiService:GetGuiInset().Y)
    end
end

-- Obter Jogador Mais Próximo
local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            local aimPart = player.Character:FindFirstChild(getgenv().AimPart)

            if humanoid.Health > 0 and aimPart then
                local screenPosition = Camera:WorldToViewportPoint(aimPart.Position)
                local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude

                if (getgenv().FOV and distance < fovCircle.Radius and distance < shortestDistance) or (not getgenv().FOV and distance < shortestDistance) then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end

    return closestPlayer
end

-- Configurar Predição com Base no Ping
local function UpdatePrediction()
    if getgenv().AutoPrediction then
        local ping = tonumber(string.split(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString(), "(")[1]) or 0

        if ping < 20 then
            getgenv().Prediction = 0.157
        elseif ping < 30 then
            getgenv().Prediction = 0.155
        elseif ping < 40 then
            getgenv().Prediction = 0.145
        else
            getgenv().Prediction = 0.129
        end
    end
end

-- Eventos de Teclado
Mouse.KeyDown:Connect(function(key)
    key = key:lower()
    if key == getgenv().Key then
        Locked = not Locked
        if Locked then
            Target = GetClosestPlayer()
            if Target then
                Notify("Travado em: " .. Target.Name)
            else
                Notify("Nenhum alvo encontrado.")
                Locked = false
            end
        else
            Target = nil
            Notify("Destravado!")
        end
    elseif key == getgenv().DisableKey then
        AimlockEnabled = not AimlockEnabled
        Notify(AimlockEnabled and "Aimlock ativado!" or "Aimlock desativado!")
    end
end)

-- Loop Principal
RunService.RenderStepped:Connect(function()
    UpdateFOV()
    if AimlockEnabled and Locked and Target and Target.Character and Target.Character:FindFirstChild(getgenv().AimPart) then
        local aimPart = Target.Character[getgenv().AimPart]
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPart.Position + aimPart.Velocity * getgenv().Prediction)
    end
end)

-- Loop de Predição
RunService.Heartbeat:Connect(function()
    UpdatePrediction()
end)
