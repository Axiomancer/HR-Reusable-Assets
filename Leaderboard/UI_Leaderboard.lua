--!Type(UI)

-- Leaderboard panel with 3 tabs (Wins / Deaths / Coins).
-- Leaderboard API is server-only, so data is fetched via RequestLeaderboard
-- and returned through LeaderboardData. Empty entries show 0 when unranked.

--!Bind
local lbRoot      : UILuaView = nil
--!Bind
local lbTitleIcon : Image = nil
--!Bind
local lbTitle     : UILabel = nil
--!Bind
local lbClose     : UILabel = nil

--!SerializeField
local iconTitle : Texture = nil
--!Bind
local tabWins    : UILabel = nil
--!Bind
local tabDeaths  : UILabel = nil
--!Bind
local tabCoins   : UILabel = nil
--!Bind
local lb1rank    : UILabel = nil
--!Bind
local lb1name    : UILabel = nil
--!Bind
local lb1score   : UILabel = nil
--!Bind
local lb2rank    : UILabel = nil
--!Bind
local lb2name    : UILabel = nil
--!Bind
local lb2score   : UILabel = nil
--!Bind
local lb3rank    : UILabel = nil
--!Bind
local lb3name    : UILabel = nil
--!Bind
local lb3score   : UILabel = nil
--!Bind
local lb4rank    : UILabel = nil
--!Bind
local lb4name    : UILabel = nil
--!Bind
local lb4score   : UILabel = nil
--!Bind
local lb5rank    : UILabel = nil
--!Bind
local lb5name    : UILabel = nil
--!Bind
local lb5score   : UILabel = nil
--!Bind
local lbSelfRank  : UILabel = nil
--!Bind
local lbSelfName  : UILabel = nil
--!Bind
local lbSelfScore : UILabel = nil

local GameEvents = require("Module_GameEvents")
local UIState    = require("Module_UIState")

local function SetImg(imgEl, tex)
    if imgEl and tex then imgEl.image = tex end
end

local RANK_EMOJIS = { "1", "2", "3", "4.", "5." }

-- Tab definitions: boardType, button, label, score unit
local TABS = {
    { type = "wins",   label = "Wins",   unit = "wins"   },
    { type = "deaths", label = "Deaths", unit = "deaths" },
    { type = "coins",  label = "Coins",  unit = "SC"     },
}

local rankLabels  = { lb1rank,  lb2rank,  lb3rank,  lb4rank,  lb5rank  }
local nameLabels  = { lb1name,  lb2name,  lb3name,  lb4name,  lb5name  }
local scoreLabels = { lb1score, lb2score, lb3score, lb4score, lb5score }

local currentTab = "wins"

local function TabButton(boardType)
    if boardType == "wins"   then return tabWins   end
    if boardType == "deaths" then return tabDeaths end
    if boardType == "coins"  then return tabCoins  end
end

local function UnitFor(boardType)
    for _, t in ipairs(TABS) do
        if t.type == boardType then return t.unit end
    end
    return ""
end

local function ClearRows()
    for i = 1, 5 do
        rankLabels[i]:SetPrelocalizedText(RANK_EMOJIS[i])
        nameLabels[i]:SetPrelocalizedText("—")
        scoreLabels[i]:SetPrelocalizedText("")
    end
end

local function HighlightTab(boardType)
    for _, t in ipairs(TABS) do
        local btn = TabButton(t.type)
        if btn then btn:EnableInClassList("lb-tab--active", t.type == boardType) end
    end
end

local function RequestTab(boardType)
    currentTab = boardType
    HighlightTab(boardType)
    ClearRows()
    GameEvents.RequestLeaderboard:FireServer(boardType)
end

local function Open()
    lbRoot.visible = true
    RequestTab(currentTab)
end

local function Close()
    lbRoot.visible = false
end

function self:ClientAwake()
    lbRoot.visible = false
    SetImg(lbTitleIcon, iconTitle)
    lbTitle:SetPrelocalizedText("Leaderboard")
    lbClose:SetPrelocalizedText("✕")
    tabWins:SetPrelocalizedText("Wins")
    tabDeaths:SetPrelocalizedText("Deaths")
    tabCoins:SetPrelocalizedText("Coins")
    ClearRows()
    lbSelfName:SetPrelocalizedText(client.localPlayer and client.localPlayer.name or "You")
    lbSelfRank:SetPrelocalizedText("—")
    lbSelfScore:SetPrelocalizedText("0")

    UIState.Register("leaderboard", Open, Close)
end

function self:ClientStart()
    lbClose:RegisterPressCallback(Close)
    lbRoot:RegisterPressCallback(Close)
    local card = lbRoot:Q("lbCard")
    if card then card:RegisterPressCallback(function() end) end  -- absorb clicks inside card

    tabWins:RegisterPressCallback(function()   RequestTab("wins")   end)
    tabDeaths:RegisterPressCallback(function() RequestTab("deaths") end)
    tabCoins:RegisterPressCallback(function()  RequestTab("coins")  end)

    -- Server response: only apply if it matches the tab being viewed
    GameEvents.LeaderboardData:Connect(function(boardType, entries, selfRank, selfScore)
        if boardType ~= currentTab then return end
        local unit = UnitFor(boardType)

        ClearRows()
        for i, entry in ipairs(entries) do
            if i > 5 then break end
            rankLabels[i]:SetPrelocalizedText(RANK_EMOJIS[i] or tostring(i) .. ".")
            nameLabels[i]:SetPrelocalizedText(entry.name or "—")
            scoreLabels[i]:SetPrelocalizedText(tostring(entry.score or 0) .. " " .. unit)
        end

        -- Local player own row: default to 0 when no entry exists
        lbSelfName:SetPrelocalizedText(client.localPlayer and client.localPlayer.name or "You")
        if selfRank and selfRank > 0 then
            lbSelfRank:SetPrelocalizedText("#" .. tostring(selfRank))
        else
            lbSelfRank:SetPrelocalizedText("—")
        end
        lbSelfScore:SetPrelocalizedText(tostring(selfScore or 0) .. " " .. unit)
    end)
end
