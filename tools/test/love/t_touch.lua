-- Touch input under LuaJIT (mock love, Android): tap = click, long press = right click, two finger pan = scroll,
-- istouch mouse events ignored, hover cleared on lift. Run: luajit tools/test/love/t_touch.lua
dofile("tools/test/love/mock_love.lua")
local G = dofile("build/imgui_love.lua")
local ImGui, Impl = G.ImGui, G.ImGui_ImplLove
ImGui.CreateContext()
Impl.Init({ root = "" })
ImGui.GetIO().IniFilename = nil
ImGui.GetIO().Fonts:AddFontDefault()
Impl.SetupTouchStyle(1)

local clicks, rclicks, scroll_y, hovered_after = 0, 0, 0, nil
local function frame()
    love.timer.step(1 / 60)
    Impl.NewFrame(); ImGui.NewFrame()
    ImGui.SetNextWindowPos(G.ImVec2(50, 50)); ImGui.SetNextWindowSize(G.ImVec2(300, 200))
    ImGui.Begin("T")
    if ImGui.Button("Tap me", G.ImVec2(120, 40)) then clicks = clicks + 1 end
    if ImGui.IsItemClicked(1) then rclicks = rclicks + 1 end
    for i = 1, 60 do ImGui.Text("row %d", i) end
    scroll_y = ImGui.GetScrollY()
    hovered_after = ImGui.IsAnyItemHovered()
    ImGui.End()
    ImGui.Render()
end
local function frames(n) for _ = 1, n do frame() end end
frames(3)

-- tap on the button (window title ~20px: button at about y=75..115)
Impl.TouchPressed(1, 80, 90); frames(3); Impl.TouchReleased(1, 80, 90); frames(4)
assert(clicks == 1, "tap should click once, got " .. clicks)
assert(not hovered_after, "hover must be cleared after the finger lifts")

-- the first finger also arrives as a mouse event (istouch): must be ignored
Impl.MousePressed(80, 90, 1, true); Impl.MouseReleased(80, 90, 1, true); frames(4)
assert(clicks == 1, "istouch mouse events must be ignored")

-- long press = right click, and no left click
Impl.TouchPressed(2, 80, 90); frames(3)
love.timer.step(0.6); frames(6)
Impl.TouchReleased(2, 80, 90); frames(4)
assert(clicks == 1, "long press must not left click")
assert(rclicks == 1, "long press should right click once, got " .. rclicks)

-- two finger pan scrolls the window content
local before = scroll_y
Impl.TouchPressed(3, 100, 150); Impl.TouchPressed(4, 140, 150); frames(3)
for i = 1, 20 do
    Impl.TouchMoved(3, 100, 150 - i * 6); Impl.TouchMoved(4, 140, 150 - i * 6); frames(1)
end
Impl.TouchReleased(3, 100, 30); Impl.TouchReleased(4, 140, 30); frames(4)
assert(scroll_y > before, "two finger pan up should scroll down (" .. before .. " -> " .. scroll_y .. ")")
assert(clicks == 1, "panning must not click")
print("touch OK", clicks, rclicks, scroll_y)
