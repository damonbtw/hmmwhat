dx9.ShowConsole(false) -- Opens console automatically

--// Damon is king 
local Lib = loadstring(dx9.Get("https://raw.githubusercontent.com/soupg/DXLibUI/main/main.lua"))()

local Window = Lib:CreateWindow({
    Title = "Prince owns you - crossmyheart0551",
    Size = {0,0},
    Resizable = false,
    ToggleKey = "[F5]",
    FooterMouseCoords = false
})

local Tab1 = Window:AddTab("Main")
local Groupbox1 = Tab1:AddMiddleGroupbox("Fuck you Elijah")

local espEnabled = Groupbox1:AddToggle({Default = true, Text = "ESP Enabled"}):OnChanged(function(value)
    Lib:Notify(value and "Dummy ESP Enabled" or "Dummy ESP Disabled", 1)
end)

local tracerEnabled = Groupbox1:AddToggle({Default = true, Text = "Tracers Enabled"}):OnChanged(function(value)
    Lib:Notify(value and "Tracers Enabled" or "Tracers Disabled", 1)
end)

local healthbarEnabled = Groupbox1:AddToggle({Default = true, Text = "Health Bars"}):OnChanged(function(value)
    Lib:Notify(value and "Health Bars Enabled" or "Health Bars Disabled", 1)
end)

local healthtextEnabled = Groupbox1:AddToggle({Default = true, Text = "Health Text"}):OnChanged(function(value)
    Lib:Notify(value and "Health Text Enabled" or "Health Text Disabled", 1)
end)

local dynamicHealthColor = Groupbox1:AddToggle({Default = true, Text = "Dynamic Health Color"}):OnChanged(function(value)
    Lib:Notify(value and "Dynamic Color ON" or "Dynamic Color OFF", 1)
end)

local colorPicker = Groupbox1:AddColorPicker({Default = {255, 100, 100}, Text = "ESP Color"})

local distSlider = Groupbox1:AddSlider({Default = 5000, Text = "Distance Limit", Min = 0, Max = 10000, Rounding = 0})

--// Folder path - Workspace > WorldInfo > Live
local NPC_folder = dx9.FindFirstChild(
    dx9.FindFirstChild(
        dx9.FindFirstChild(dx9.GetDatamodel(), "Workspace"),
        "WorldInfo"
    ),
    "Live"
)

if not NPC_folder then
    Lib:Notify("Live folder not found - check name/case", 3)
    return
end

--// Distance func
function GetDistanceFromPlayer(v)
    local lp = dx9.get_localplayer()
    if not lp then return 99999 end
    local v1 = lp.Position
    local a = (v1.x - v.x) ^ 2 + (v1.y - v.y) ^ 2 + (v1.z - v.z) ^ 2
    return math.floor(math.sqrt(a) + 0.5)
end

--// BoxESP with real health bar
function BoxESP(params)
    local target = params.Target
    local box_color = colorPicker.Value

    if type(target) ~= "number" or dx9.GetChildren(target) == nil then return end

    local hrp = dx9.FindFirstChild(target, "HumanoidRootPart")
    if not hrp then return end

    local torso = dx9.GetPosition(hrp)
    if not torso then return end

    local dist = GetDistanceFromPlayer(torso)
    if dist > distSlider.Value then return end

    local HeadPosY = torso.y + 3
    local LegPosY = torso.y - 3.5
    local Top = dx9.WorldToScreen({torso.x, HeadPosY, torso.z})
    local Bottom = dx9.WorldToScreen({torso.x, LegPosY, torso.z})

    if not (Top and Bottom and Top.x > 0 and Top.y > 0 and Bottom.y > Top.y) then return end

    local height = Bottom.y - Top.y
    local width = height / 2.4

    -- Corner box (fixed directions)
    local lines = {
        {{Top.x - width, Top.y}, {Top.x - width + (width/2), Top.y}},
        {{Top.x - width, Top.y}, {Top.x - width, Top.y + (height/4)}},
        {{Top.x + width, Top.y}, {Top.x + width - (width/2), Top.y}},
        {{Top.x + width, Top.y}, {Top.x + width, Top.y + (height/4)}},
        {{Top.x - width, Bottom.y}, {Top.x - width + (width/2), Bottom.y}},
        {{Top.x - width, Bottom.y}, {Top.x - width, Bottom.y - (height/4)}},
        {{Top.x + width, Bottom.y}, {Top.x + width - (width/2), Bottom.y}},
        {{Top.x + width, Bottom.y}, {Top.x + width, Bottom.y - (height/4)}}
    }
    for _, line in ipairs(lines) do
        dx9.DrawLine(line[1], line[2], box_color)
    end

    -- Distance
    local dist_str = tostring(dist)
    dx9.DrawString({Bottom.x - (dx9.CalcTextWidth(dist_str) / 2), Bottom.y + 4}, box_color, dist_str)

    -- Name
    local name = dx9.GetName(target) or "Dummy"
    dx9.DrawString({Top.x - (dx9.CalcTextWidth(name) / 2), Top.y - 20}, box_color, name)

    -- Health
    local humanoid = dx9.FindFirstChild(target, "Humanoid")
    local hp = 100
    local maxhp = 100

    if humanoid then
        hp = dx9.GetHealth(humanoid) or 100
        maxhp = dx9.GetMaxHealth(humanoid) or 100
        print("[HEALTH] " .. name .. ": " .. math.floor(hp) .. "/" .. math.floor(maxhp))  -- Debug console
    else
        print("[DEBUG] No Humanoid in " .. name .. " - using 100/100")
    end

    -- Health Text (above head)
    if healthtextEnabled.Value then
        local h_str = math.floor(hp) .. "/" .. math.floor(maxhp)
        dx9.DrawString({Top.x - (dx9.CalcTextWidth(h_str) / 2), Top.y - 38}, box_color, h_str)
    end

    -- Health Bar (right side, vertical fill like your snippet)
    if healthbarEnabled.Value then
        local tl = {Top.x + width - 5, Top.y + 1}   -- Top-left of bar
        local br = {Top.x + width - 1, Bottom.y - 1}  -- Bottom-right

        -- Outer outline
        dx9.DrawBox({tl[1] - 1, tl[2] - 1}, {br[1] + 1, br[2] + 1}, box_color)

        -- Black background
        dx9.DrawFilledBox({tl[1], tl[2]}, {br[1], br[2]}, {0,0,0})

        -- Fill calculation (dynamic height from bottom)
        if maxhp > 0 then
            local addon = ((height + 2) / (maxhp / math.max(0, math.min(maxhp, hp))))
            local fill_top = br[2] - addon  -- from bottom up

            local fill_color
            if dynamicHealthColor.Value then
                fill_color = {255 - (255 * (hp / maxhp)), 255 * (hp / maxhp), 0}
            else
                fill_color = box_color
            end

            dx9.DrawFilledBox({tl[1] + 1, fill_top}, {br[1] - 1, br[2] + 1}, fill_color)
        end
    end

    -- Tracer
    if tracerEnabled.Value then
        local loc = {dx9.size().width / 2, dx9.size().height}
        local mid_bottom = {Top.x, Bottom.y}
        dx9.DrawLine(loc, mid_bottom, box_color)
    end
end

--// Continuous loop
coroutine.wrap(function()
    while true do
        if espEnabled.Value and NPC_folder then
            local npcs = dx9.GetChildren(NPC_folder)
            for _, npc in next, npcs do
                pcall(BoxESP, {Target = npc})
            end
        end
        dx9.Sleep(0)  -- Smooth; change to 1 if laggy
    end
end)()

Lib:Notify("Prince ESP Loaded - Real Health Bar Integrated! 👑", 5)
print("[DEBUG] Script running - Check console for HP values")
