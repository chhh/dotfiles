-- -- This prints AppName (E) where E=5 every time a window is focused
-- appWatcher = hs.application.watcher.new(function(appName, eventType, appObject)
--     if eventType == hs.application.watcher.launched or
--        eventType == hs.application.watcher.activated then
--         print("Application event: " .. appName .. " (" .. eventType .. ")")
--     end
-- end)

-- Track last screen used by iTerm2
local lastTerminalScreen = nil

-- Watch for iTerm2 events (focus, move, activate)
local termWatcher = hs.window.filter.new("iTerm2")
termWatcher:subscribe({
    hs.window.filter.windowFocused,
    hs.window.filter.windowMoved,
    hs.window.filter.windowActivated
}, function(win)
    if win and win:screen() then
        lastTerminalScreen = win:screen()
        print("Updated last iTerm2 screen: " .. lastTerminalScreen:name())
    end
end)

-- Watch for wish window creation
local wf = hs.window.filter.new()
wf:subscribe(hs.window.filter.windowCreated, function(win, appName)
    if win and appName and appName:lower() == "wish" then
        local targetScreen = lastTerminalScreen or win:screen() or hs.screen.mainScreen()

        -- Get frames
        local screenFrame = targetScreen:frame()
        local winFrame = win:frame()

        -- Center the window on the chosen screen
        winFrame.x = screenFrame.x + (screenFrame.w - winFrame.w) / 2
        winFrame.y = screenFrame.y + (screenFrame.h - winFrame.h) / 2

        win:setFrame(winFrame)
        print("Moved 'wish' window to screen: " .. targetScreen:name())
    end
end)




-- Generic function to focus or launch an application
-- @param appName: string - The name of the application
-- @param shouldLaunch: boolean - Whether to launch the app if it's not running
local function focusOrLaunchApp(appName, shouldLaunch)
    local app = hs.application.get(appName)
    
    if app then
        -- App is running, unhide and activate it
        if app:isHidden() then
            app:unhide()
        end
        app:activate()
    elseif shouldLaunch then
        -- App is not running, try to launch it
        hs.application.launchOrFocus(appName)
    else
        -- App is not running and we're not supposed to launch it
        hs.alert.show(appName .. " is not running")
    end
end



-- Generic function to focus or launch an application
-- @param appName: string - The name of the application
-- @param shouldLaunch: boolean - Whether to launch the app if it's not running
local function focusOrLaunchApp(appName, shouldLaunch)
    local app = hs.application.get(appName)
    
    if app then
        -- App is running, unhide and activate it
        if app:isHidden() then
            app:unhide()
        end
        app:activate()
    elseif shouldLaunch then
        -- App is not running, try to launch it
        hs.application.launchOrFocus(appName)
    else
        -- App is not running and we're not supposed to launch it
        hs.alert.show(appName .. " is not running")
    end
end

-- Function to focus the first running app from a list of possible names
-- @param appNames: table - Array of possible application names to try
-- @param shouldLaunch: boolean - Whether to launch the first app name if none are running
-- @param launchName: string (optional) - Specific name to use for launching (defaults to first in list)
local function focusOrLaunchFromList(appNames, shouldLaunch, launchName)
    local foundApp = nil
    local foundName = nil
    
    -- Try to find the first running app from the list
    for _, appName in ipairs(appNames) do
        local app = hs.application.get(appName)
        if app then
            foundApp = app
            foundName = appName
            break
        end
    end
    
    if foundApp then
        -- Found a running app, focus it
        if foundApp:isHidden() then
            foundApp:unhide()
        end
        foundApp:activate()
        print("Focused: " .. foundName)
    elseif shouldLaunch then
        -- No app found running, try to launch
        local nameToLaunch = launchName or appNames[1]
        hs.application.launchOrFocus(nameToLaunch)
        print("Launching: " .. nameToLaunch)
    else
        -- No app found and we're not supposed to launch
        local displayNames = table.concat(appNames, ", ")
        hs.alert.show("None of these apps are running: " .. displayNames)
    end
end

-- Focus iTerm2 with CMD+CTRL+I
hs.hotkey.bind({"cmd", "ctrl"}, "i", function()
    focusOrLaunchApp("iTerm2", true)
end)

hs.hotkey.bind({"cmd", "ctrl"}, "c", function()
    focusOrLaunchApp("Cursor", true)
end)

hs.hotkey.bind({"cmd", "ctrl"}, "l", function()
    focusOrLaunchApp("Logseq", true)
end)

hs.hotkey.bind({"cmd", "ctrl"}, "f", function()
    focusOrLaunchApp("Finder", false)
end)

hs.hotkey.bind({"cmd", "ctrl"}, "s", function()
    focusOrLaunchApp("Slack", true)
end)

hs.hotkey.bind({"cmd", "ctrl"}, "z", function()
    focusOrLaunchApp("Zoom", true)
end)

-- Focus PyCharm with CMD+CTRL+P (try multiple possible names)
hs.hotkey.bind({"cmd", "ctrl"}, "p", function()
    focusOrLaunchFromList({
        "PyCharm Professional", 
        "PyCharm", 
        "PyCharm CE",
        "PyCharm Community Edition"
    }, true, "PyCharm")  -- Launch "PyCharm" if none are found
end)

-- Focus any browser with CMD+CTRL+B or launch Chrome if no browser is running
hs.hotkey.bind({"cmd", "ctrl"}, "b", function()
    focusOrLaunchFromList({
        "Google Chrome",
        "Safari",
        "Firefox",
        "Arc",
        "Brave Browser"
    }, true, "Google Chrome")  -- Launch Chrome if no browser is running
end)