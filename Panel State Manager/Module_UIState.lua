--!Type(Module)

-- Panel State Manager
-- Manages open/close state for any number of named UI panels.
-- Only one panel is open at a time; opening a new one closes all others.
--
-- SETUP:
--   1. Add this module to your project.
--   2. In each panel's UI script ClientAwake():
--        local UIState = require("Module_UIState")
--        UIState.Register("myPanel", openFn, closeFn)
--   3. To trigger from a button:
--        UIState.Toggle("myPanel")   -- opens, or closes if already open
--        UIState.Open("myPanel")     -- always opens (closes others)
--        UIState.Close("myPanel")    -- always closes

local openFns  = {}
local closeFns = {}
local isOpen   = {}

function Register(name, onOpen, onClose)
    openFns[name]  = onOpen
    closeFns[name] = onClose
end

function Open(name)
    for k in pairs(openFns) do
        if k ~= name and isOpen[k] then
            isOpen[k] = false
            if closeFns[k] then closeFns[k]() end
        end
    end
    isOpen[name] = true
    if openFns[name] then openFns[name]() end
end

function Close(name)
    isOpen[name] = false
    if closeFns[name] then closeFns[name]() end
end

function Toggle(name)
    if not openFns[name] then
        print("UIState: no panel registered for '" .. tostring(name) .. "' -- is its UI GameObject in the scene?")
        return
    end
    if isOpen[name] then Close(name) else Open(name) end
end
