if getgenv().esp_running then
    for _, drawings in pairs(getgenv().esp_cache or {}) do
        for _, drawing in pairs(drawings) do
            drawing:Remove()
        end
    end
    getgenv().esp_cache = {}

    local run_service = game:GetService("RunService")
    if run_service then
        pcall(function()
            run_service:UnbindFromRenderStep("esp_render")
        end)
    end
end
getgenv().esp_running = true  


local settings = {
   default_color = Color3.fromRGB(255, 255, 255),
   team_check = false,
   outline_thickness = 1,
   r6_y_offset = 2.5, 
   r15_height_scale = 6, 
   width_scale = 5, 
}


local run_service = game:GetService("RunService")
local players = game:GetService("Players")


local local_player = players.LocalPlayer
local camera = workspace.CurrentCamera


local new_vector2, new_drawing = Vector2.new, Drawing.new
local tan, rad = math.tan, math.rad
local round = function(...) 
    local result = {} 
    for i, v in next, table.pack(...) do 
        result[i] = math.round(v) 
    end 
    return unpack(result) 
end
local world_to_viewport = function(...) 
    local pos, on_screen, depth = camera:WorldToViewportPoint(...)
    return new_vector2(pos.X, pos.Y), on_screen, pos.Z
end


getgenv().esp_cache = {}




local function create_esp(player)
    local drawings = {}


    drawings.box = new_drawing("Square")
    drawings.box.Thickness = 1
    drawings.box.Filled = false
    drawings.box.Color = settings.default_color
    drawings.box.Visible = false
    drawings.box.ZIndex = 2

   
    drawings.outline = new_drawing("Square")
    drawings.outline.Thickness = settings.outline_thickness
    drawings.outline.Filled = false
    drawings.outline.Color = Color3.new(0, 0, 0)
    drawings.outline.Visible = false
    drawings.outline.ZIndex = 1


    drawings.inner_outline = new_drawing("Square")
    drawings.inner_outline.Thickness = settings.outline_thickness
    drawings.inner_outline.Filled = false
    drawings.inner_outline.Color = Color3.new(0, 0, 0)
    drawings.inner_outline.Visible = false
    drawings.inner_outline.ZIndex = 1

    getgenv().esp_cache[player] = drawings
end


local function remove_esp(player)
    if getgenv().esp_cache[player] then
        for _, drawing in pairs(getgenv().esp_cache[player]) do
            drawing:Remove()
        end
        getgenv().esp_cache[player] = nil
    end
end


local function update_esp(player, esp)
    local character = player and player.Character
    if character then
        local root_part = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
        if root_part then
            local cframe = root_part.CFrame
            local position, visible, depth = world_to_viewport(cframe.Position)

            if visible then
                local scale_factor = 1 / (depth * tan(rad(camera.FieldOfView / 2)) * 2) * 1000
                
        
                local width = round(settings.width_scale * scale_factor)
                local height = round(
                    (character:FindFirstChild("Torso") and not character:FindFirstChild("HumanoidRootPart") and settings.r6_y_offset or settings.r15_height_scale) * scale_factor
                )

                local x, y = round(position.X, position.Y)

              
                if character:FindFirstChild("Torso") and not character:FindFirstChild("HumanoidRootPart") then
                    y = y + (settings.r6_y_offset * height / 2)
                end

              
                esp.box.Size = new_vector2(width, height)
                esp.box.Position = new_vector2(x - width / 2, y - height / 2)
                esp.box.Color = settings.default_color
                esp.box.Visible = true

              
                esp.outline.Size = esp.box.Size + new_vector2(2, 2)
                esp.outline.Position = esp.box.Position - new_vector2(1, 1)
                esp.outline.Visible = true


                esp.inner_outline.Size = esp.box.Size - new_vector2(1, 1)
                esp.inner_outline.Position = esp.box.Position + new_vector2(1, 1)
                esp.inner_outline.Visible = true
            else
                esp.box.Visible = false
                esp.outline.Visible = false
                esp.inner_outline.Visible = false
            end
        end
    else
        esp.box.Visible = false
        esp.outline.Visible = false
        esp.inner_outline.Visible = false
    end
end

for _, player in pairs(players:GetPlayers()) do
    if player ~= local_player then
        create_esp(player)
    end
end

players.PlayerAdded:Connect(create_esp)
players.PlayerRemoving:Connect(remove_esp)

run_service:BindToRenderStep("esp_render", Enum.RenderPriority.Camera.Value, function()
    for player, drawings in pairs(getgenv().esp_cache) do
        if settings.team_check and player.Team == local_player.Team then
            drawings.box.Visible = false
            drawings.outline.Visible = false
            drawings.inner_outline.Visible = false
        else
            update_esp(player, drawings)
        end
    end
end)
