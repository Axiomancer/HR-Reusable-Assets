--!Type(UI)

-- Activity Feed
-- A scrolling live event log shown bottom-left. Each row displays a small
-- icon alongside a text message. Entries expire after LIFETIME seconds.
-- A maximum of MAX_ENTRIES rows are shown at once (oldest drops off the top).
--
-- HOW TO ADD YOUR OWN ICON KEYS:
--   1. Add a --!SerializeField slot below (copy the pattern of the existing ones).
--   2. Add the key -> texture mapping inside ICON_MAP in ClientStart.
--   3. From your server script, fire:
--        FeedEvents.ActivityLog:FireAllClients("yourKey", "Your message")
--
-- DEPENDENCIES: Module_FeedEvents.lua

--!Bind
local feedRoot  : UILuaView = nil
-- Row text labels
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
-- Row icon Images (one per row, same order as labels)
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

-- ── Icon slots ────────────────────────────────────────────────────────────────
-- Drag a PNG from your project into each slot in the Inspector.
-- The slot name is the iconKey you pass from your server script.
-- Add as many slots as you need by copying the pattern below.
--!SerializeField
local iconDefault : Texture = nil   -- fallback when key is unrecognised
--!SerializeField
local iconJoin    : Texture = nil   -- "join"  (player arrived or left)
--!SerializeField
local iconAlert   : Texture = nil   -- "alert" (announcements, warnings)
--!SerializeField
local iconStar    : Texture = nil   -- "star"  (achievements, highlights)
--!SerializeField
local iconCoin    : Texture = nil   -- "coin"  (economy events)
--!SerializeField
local iconShield  : Texture = nil   -- "shield" (staff or moderation events)

-- ── Config ────────────────────────────────────────────────────────────────────
local MAX_ENTRIES = 5    -- max rows visible at once
local LIFETIME    = 8    -- seconds before an entry expires

-- ── Internal ─────────────────────────────────────────────────────────────────
local FeedEvents = require("Module_FeedEvents")

local labels   = { feed1,     feed2,     feed3,     feed4,     feed5     }
local iconEls  = { feed1icon, feed2icon, feed3icon, feed4icon, feed5icon }
local feedRows = {}
local entries  = {}   -- { iconKey, text, expiry }; index 1 = oldest, last = newest
local ICON_MAP = {}   -- built in ClientStart once SerializeFields are populated

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
    -- Cache row VisualElements (cannot bind VisualElement directly in Highrise)
    for i = 1, MAX_ENTRIES do
        feedRows[i] = feedRoot:Q("feed" .. i .. "row")
    end

    -- Map iconKeys to textures.
    -- Add a line here for every --!SerializeField slot you defined above.
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

    -- Expire old entries every second
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
