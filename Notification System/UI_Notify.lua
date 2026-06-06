--!Type(UI)

-- Notification toast card. Attach to a UI GameObject in your scene.
-- Listens to NotifyEvents.Notification and shows a styled card at the top
-- of the screen, auto-hiding after the specified timeout.
--
-- DEPENDENCIES: Module_NotifyEvents.lua

--!Bind
local notifyCard  : UILuaView = nil
--!Bind
local notifyIcon  : UILabel = nil
--!Bind
local notifyTitle : UILabel = nil
--!Bind
local notifyText  : UILabel = nil

local NotifyEvents = require("Module_NotifyEvents")

local DEFAULT_TIME = 4

local TYPE_CONFIG = {
    success = { icon = "OK",   class = "notify--success" },
    error   = { icon = "!!",   class = "notify--error"   },
    warning = { icon = "!",    class = "notify--warning" },
    info    = { icon = "i",    class = "notify--info"    },
    default = { icon = ">>",   class = "notify--default" },
}

local currentClass = nil

function self:ClientAwake()
    notifyCard.visible = false
end

function Notify(notifType, title, text, timeout, autoHide)
    local cfg = TYPE_CONFIG[notifType] or TYPE_CONFIG.default

    if currentClass then notifyIcon:EnableInClassList(currentClass, false) end
    currentClass = cfg.class
    notifyIcon:EnableInClassList(currentClass, true)

    notifyIcon:SetPrelocalizedText(cfg.icon)
    notifyTitle:SetPrelocalizedText(tostring(title or ""))
    notifyText:SetPrelocalizedText(tostring(text or ""))
    notifyCard.visible = true

    if autoHide ~= false then
        Timer.After(timeout or DEFAULT_TIME, function()
            notifyCard.visible = false
        end)
    end
end

NotifyEvents.Notification:Connect(function(notifType, title, text, timeout)
    Notify(notifType, title, text, timeout)
end)
