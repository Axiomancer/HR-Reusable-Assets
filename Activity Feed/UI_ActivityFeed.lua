--!Type(UI)

-- Live event feed. Bottom-left, up to 5 rows, each with a small PNG icon + text.
-- Fire from any server script: FeedEvents.ActivityLog:FireAllClients("iconKey", "message")
-- Add icon keys by adding a SerializeField slot and a line in ICON_MAP (ClientStart).

--!Bind
local feedRoot  : UILuaView = nil
--!Bind
local feed1 : UILabel = nil
--!Bind
local feed2 : UILabel = nil
--!Bind
local feed3 : UILabel = nil
--!Bind
local feed4 : UILabel = nil
--!Bind
local feed5 : UILabel = nil
--!Bind
local feed1icon : Image = nil
--!Bind
local feed2icon : Image = nil
--!Bind
local feed3icon : Image = nil
--!Bind
local feed4icon : Image = nil
--!Bind
local feed5icon : Image = nil

--!SerializeField
local iconDefault : Texture = nil
--!SerializeField
local iconJoin : Texture = nil
--!SerializeField
local iconAlert : Texture = nil
--!SerializeField
local iconStar : Texture = nil
--!SerializeField
local iconCoin : Texture = nil
--!SerializeField
local iconShield : Texture = nil

local FeedEvents = require("Module_FeedEvents")

local MAX_ENTRIES = 5
local LIFETIME    = 8

local labels   = { feed1,     feed2,     feed3,     feed4,     feed5     }
local iconEls  = { feed1icon, feed2icon, feed3icon, feed4icon, feed5icon }
local feedRows = {}
local entries  = {}
local ICON_MAP = {}

local function SetImg(imgEl, tex)
    if imgEl and tex then imgEl.image = tex end
end

local function Render()
    local count = #entries
    for slot = 1, MAX_ENTRIES do
        local lbl  = labels[slot]
        local icon = iconEls[slot]
        local row  = feedRows[slot]
        if not lbl then break end

        local entryIdx = count - (MAX_ENTRIES - slot)
        local e = (entryIdx >= 1) and entries[entryIdx] or nil

        if e then
            lbl:SetPrelocalizedText(e.text)
            SetImg(icon, ICON_MAP[e.iconKey] or iconDefault)
            if row then
                row:EnableInClassList("feed-row--empty", false)
                row:EnableInClassList("feed-row--new",   entryIdx == count)
            end
        else
            lbl:SetPrelocalizedText("")
            if row then
                row:EnableInClassList("feed-row--empty", true)
                row:EnableInClassList("feed-row--new",   false)
            end
        end
    end
end

local function AddEntry(iconKey, text)
    table.insert(entries, { iconKey = iconKey, text = text, expiry = os.time() + LIFETIME })
    while #entries > MAX_ENTRIES do table.remove(entries, 1) end
    Render()
end

function self:ClientAwake()
    feedRoot.visible = true
    Render()
end

function self:ClientStart()
    for i = 1, MAX_ENTRIES do
        feedRows[i] = feedRoot:Q("feed" .. i .. "row")
    end

    ICON_MAP = {
        join   = iconJoin,
        alert  = iconAlert,
        star   = iconStar,
        coin   = iconCoin,
        shield = iconShield,
    }

    FeedEvents.ActivityLog:Connect(function(iconKey, message)
        AddEntry(iconKey, message)
    end)

    Timer.Every(1, function()
        local now = os.time()
        local changed = false
        for i = #entries, 1, -1 do
            if now >= entries[i].expiry then
                table.remove(entries, i)
                changed = true
            end
        end
        if changed then Render() end
    end)
end
