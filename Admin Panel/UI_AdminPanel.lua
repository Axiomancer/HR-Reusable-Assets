--!Type(UI)

-- Staff / admin panel (issue #23). Role-based: only players the server reports
-- as staff (player.isModerator) can open it, and the server re-validates every
-- action. Two tabs (Moderation / Game) with text inputs for custom amounts and
-- durations plus quick-preset chips.

--!Bind
local adminRoot      : UILuaView = nil
--!Bind
local adminTitleIcon : Image = nil
--!Bind
local adminTitle     : UILabel = nil
--!Bind
local adminClose     : UILabel = nil

--!SerializeField
local iconTitle : Texture = nil
-- Target picker
--!Bind
local targetPrev  : UILabel = nil
--!Bind
local targetLabel : UILabel = nil
--!Bind
local targetName  : UILabel = nil
--!Bind
local targetNext  : UILabel = nil
-- Tabs + status
--!Bind
local tabMod      : UILabel = nil
--!Bind
local tabGame     : UILabel = nil
--!Bind
local adminStatus : UILabel = nil
-- Moderation
--!Bind
local secDuration : UILabel = nil
--!Bind
local durChip5    : UILabel = nil
--!Bind
local durChip30   : UILabel = nil
--!Bind
local durChip60   : UILabel = nil
--!Bind
local durChip1440 : UILabel = nil
--!Bind
local btnMute     : UILabel = nil
--!Bind
local btnUnmute   : UILabel = nil
--!Bind
local btnBan      : UILabel = nil
--!Bind
local btnBanPerm  : UILabel = nil
--!Bind
local btnKick     : UILabel = nil
--!Bind
local secBanned     : UILabel = nil
--!Bind
local bannedRefresh : UILabel = nil
--!Bind
local ban1name : UILabel = nil
--!Bind
local ban1btn  : UILabel = nil
--!Bind
local ban2name : UILabel = nil
--!Bind
local ban2btn  : UILabel = nil
--!Bind
local ban3name : UILabel = nil
--!Bind
local ban3btn  : UILabel = nil
--!Bind
local ban4name : UILabel = nil
--!Bind
local ban4btn  : UILabel = nil
--!Bind
local ban5name : UILabel = nil
--!Bind
local ban5btn  : UILabel = nil
-- Game
--!Bind
local secCoins      : UILabel = nil
--!Bind
local coinChip100   : UILabel = nil
--!Bind
local coinChip500   : UILabel = nil
--!Bind
local coinChip1000  : UILabel = nil
--!Bind
local coinChip5000  : UILabel = nil
--!Bind
local btnGiveCoins  : UILabel = nil
--!Bind
local secPerks : UILabel = nil
--!Bind
local perk1 : UILabel = nil
--!Bind
local perk2 : UILabel = nil
--!Bind
local perk3 : UILabel = nil
--!Bind
local perm1 : UILabel = nil
--!Bind
local perm2 : UILabel = nil
--!Bind
local perm3 : UILabel = nil
--!Bind
local perm4 : UILabel = nil
--!Bind
local secWorld    : UILabel = nil
--!Bind
local btnTeleport : UILabel = nil
--!Bind
local btnReset    : UILabel = nil

local AdminEvents = require("Module_AdminEvents")

local function SetImg(imgEl, tex)
    if imgEl and tex then imgEl.image = tex end
end
local GameEvents  = require("Module_GameEvents")
local UIState     = require("Module_UIState")
local ShopConfig  = require("Module_ShopConfig")

local CONS = ShopConfig.CONSUMABLE_LIST
local PERM = ShopConfig.PERMANENT_LIST

-- All grantable perks (consumables first, then permanents) mapped 1:1 to the
-- seven grant buttons, so the panel adapts if the perk counts change.
local GRANTABLE = {}
for _, it in ipairs(CONS) do table.insert(GRANTABLE, it) end
for _, it in ipairs(PERM) do table.insert(GRANTABLE, it) end
local grantBtns = { perk1, perk2, perk3, perm1, perm2, perm3, perm4 }

-- Queried (not bound)
local modView, gameView   = nil, nil
local durField, coinField = nil, nil
local banRows = nil

-- State
local players  = {}
local selected = 1
local banned   = {}

local banNameLabels = nil
local banBtnLabels  = nil

-- ── Field + status helpers ────────────────────────────────────────────────────
local function SetField(field, val)
    if not field then return end
    local ok = pcall(function() field:SetValueWithoutNotify(val) end)
    if not ok then pcall(function() field.text = val end) end
end

local function FieldText(field)
    if not field then return "" end
    local ok, t = pcall(function() return field.text end)
    if ok and t then return t end
    return ""
end

local function SetStatus(msg, ok)
    adminStatus:SetPrelocalizedText(msg or "")
    adminStatus:EnableInClassList("admin-status--ok", ok == true)
    adminStatus:EnableInClassList("admin-status--error", ok == false)
end

-- ── Target ────────────────────────────────────────────────────────────────────
local function CurrentTarget()
    if #players == 0 then return nil end
    if selected < 1 then selected = #players end
    if selected > #players then selected = 1 end
    return players[selected]
end

local function RenderTarget()
    local t = CurrentTarget()
    if t then
        targetName:SetPrelocalizedText(t.name .. "   (" .. selected .. "/" .. #players .. ")")
    else
        targetName:SetPrelocalizedText("No players online")
    end
end

local function WithTarget(fn)
    local t = CurrentTarget()
    if not t then SetStatus("No player selected.", false); return end
    fn(t.id)
end

-- ── Tabs ──────────────────────────────────────────────────────────────────────
local function ShowTab(which)
    if modView  then modView:EnableInClassList("admin-view--hidden",  which ~= "mod")  end
    if gameView then gameView:EnableInClassList("admin-view--hidden", which ~= "game") end
    tabMod:EnableInClassList("admin-tab--active",  which == "mod")
    tabGame:EnableInClassList("admin-tab--active", which == "game")
end

-- ── Banned list ───────────────────────────────────────────────────────────────
local function RenderBanned()
    for i = 1, 5 do
        local entry = banned[i]
        if entry then
            banNameLabels[i]:SetPrelocalizedText(entry.name)
            banBtnLabels[i]:SetPrelocalizedText("Unban")
            if banRows[i] then banRows[i]:EnableInClassList("admin-ban-row--hidden", false) end
        else
            if banRows[i] then banRows[i]:EnableInClassList("admin-ban-row--hidden", true) end
        end
    end
    if #banned == 0 then
        banNameLabels[1]:SetPrelocalizedText("No banned users")
        banBtnLabels[1]:SetPrelocalizedText("")
        if banRows[1] then banRows[1]:EnableInClassList("admin-ban-row--hidden", false) end
    end
end

-- ── Duration / amount actions ─────────────────────────────────────────────────
local function MinutesOr(errMsg)
    local mins = tonumber(FieldText(durField))
    if not mins or mins <= 0 then SetStatus(errMsg, false); return nil end
    return math.floor(mins * 60)   -- seconds
end

-- ── Open / close ──────────────────────────────────────────────────────────────
local function Open()
    adminRoot.visible = true
    SetStatus("", nil)
    ShowTab("mod")
    AdminEvents.RequestPlayerList:FireServer()
    AdminEvents.RequestBannedUsers:FireServer()
end

local function Close()
    adminRoot.visible = false
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────
function self:ClientAwake()
    adminRoot.visible = false
    SetImg(adminTitleIcon, iconTitle)
    adminTitle:SetPrelocalizedText("Staff Panel")
    adminClose:SetPrelocalizedText("✕")

    targetPrev:SetPrelocalizedText("<")
    targetNext:SetPrelocalizedText(">")
    targetLabel:SetPrelocalizedText("TARGET PLAYER")
    targetName:SetPrelocalizedText("Loading...")

    tabMod:SetPrelocalizedText("Moderation")
    tabGame:SetPrelocalizedText("Game")
    SetStatus("", nil)

    -- Moderation labels
    secDuration:SetPrelocalizedText("DURATION (MINUTES)")
    durChip5:SetPrelocalizedText("5m")
    durChip30:SetPrelocalizedText("30m")
    durChip60:SetPrelocalizedText("1h")
    durChip1440:SetPrelocalizedText("1 day")
    btnMute:SetPrelocalizedText("Mute")
    btnUnmute:SetPrelocalizedText("Unmute")
    btnBan:SetPrelocalizedText("Ban")
    btnBanPerm:SetPrelocalizedText("Ban forever")
    btnKick:SetPrelocalizedText("Kick from world")
    secBanned:SetPrelocalizedText("BANNED USERS")
    bannedRefresh:SetPrelocalizedText("Refresh")

    -- Game labels
    secCoins:SetPrelocalizedText("GIVE SQUID COINS")
    coinChip100:SetPrelocalizedText("100")
    coinChip500:SetPrelocalizedText("500")
    coinChip1000:SetPrelocalizedText("1,000")
    coinChip5000:SetPrelocalizedText("5,000")
    btnGiveCoins:SetPrelocalizedText("Give Coins")
    secPerks:SetPrelocalizedText("GRANT PERK")
    for i, btn in ipairs(grantBtns) do
        local it = GRANTABLE[i]
        btn:SetPrelocalizedText(it and it.name or "")
    end
    secWorld:SetPrelocalizedText("WORLD")
    btnTeleport:SetPrelocalizedText("Teleport to start")
    btnReset:SetPrelocalizedText("Reset Bridge")

    UIState.Register("admin", Open, Close)
end

function self:ClientStart()
    modView   = adminRoot:Q("modView")
    gameView  = adminRoot:Q("gameView")
    durField  = adminRoot:Q("durField")
    coinField = adminRoot:Q("coinField")
    banRows = {
        adminRoot:Q("ban1row"), adminRoot:Q("ban2row"), adminRoot:Q("ban3row"),
        adminRoot:Q("ban4row"), adminRoot:Q("ban5row"),
    }
    banNameLabels = { ban1name, ban2name, ban3name, ban4name, ban5name }
    banBtnLabels  = { ban1btn,  ban2btn,  ban3btn,  ban4btn,  ban5btn  }

    if durField  then
        pcall(function() durField:SetPlaceholderText("minutes") end)
        SetField(durField, "10")   -- default: 10 minutes (one-click mute/ban)
    end
    if coinField then
        pcall(function() coinField:SetPlaceholderText("amount") end)
        SetField(coinField, "500")  -- default: 500 SC
    end

    -- No backdrop close (no overlay). Only X closes the panel.
    adminClose:RegisterPressCallback(Close)

    -- Tabs
    tabMod:RegisterPressCallback(function() ShowTab("mod") end)
    tabGame:RegisterPressCallback(function() ShowTab("game") end)

    -- Target cycling
    targetPrev:RegisterPressCallback(function() selected = selected - 1; RenderTarget() end)
    targetNext:RegisterPressCallback(function() selected = selected + 1; RenderTarget() end)

    -- Duration presets fill the field
    durChip5:RegisterPressCallback(function()    SetField(durField, "5")    end)
    durChip30:RegisterPressCallback(function()   SetField(durField, "30")   end)
    durChip60:RegisterPressCallback(function()   SetField(durField, "60")   end)
    durChip1440:RegisterPressCallback(function() SetField(durField, "1440") end)

    -- Moderation actions
    btnMute:RegisterPressCallback(function()
        WithTarget(function(id)
            local secs = MinutesOr("Enter a duration in minutes.")
            if secs then AdminEvents.AdminMute:FireServer(id, secs) end
        end)
    end)
    btnUnmute:RegisterPressCallback(function() WithTarget(function(id) AdminEvents.AdminUnmute:FireServer(id) end) end)
    btnBan:RegisterPressCallback(function()
        WithTarget(function(id)
            local secs = MinutesOr("Enter a ban duration in minutes (or use Ban forever).")
            if secs then AdminEvents.AdminBan:FireServer(id, secs, "Banned by staff") end
        end)
    end)
    btnBanPerm:RegisterPressCallback(function() WithTarget(function(id) AdminEvents.AdminBan:FireServer(id, -1, "Banned by staff") end) end)
    btnKick:RegisterPressCallback(function() WithTarget(function(id) AdminEvents.AdminKick:FireServer(id) end) end)

    -- Coin presets fill the field
    coinChip100:RegisterPressCallback(function()  SetField(coinField, "100")  end)
    coinChip500:RegisterPressCallback(function()  SetField(coinField, "500")  end)
    coinChip1000:RegisterPressCallback(function() SetField(coinField, "1000") end)
    coinChip5000:RegisterPressCallback(function() SetField(coinField, "5000") end)

    -- Game actions
    btnGiveCoins:RegisterPressCallback(function()
        WithTarget(function(id)
            local amt = tonumber(FieldText(coinField))
            if not amt or amt <= 0 then SetStatus("Enter a coin amount.", false); return end
            AdminEvents.AdminGiveCoins:FireServer(id, math.floor(amt))
        end)
    end)
    for i, btn in ipairs(grantBtns) do
        local it = GRANTABLE[i]
        if it then
            btn:RegisterPressCallback(function()
                WithTarget(function(id)
                    AdminEvents.AdminGivePerk:FireServer(id, it.storageKey, it.uses or 0, it.permanent == true)
                end)
            end)
        end
    end

    btnTeleport:RegisterPressCallback(function() WithTarget(function(id) AdminEvents.AdminTeleport:FireServer(id) end) end)
    btnReset:RegisterPressCallback(function() AdminEvents.AdminResetBridge:FireServer() end)

    -- Banned list
    bannedRefresh:RegisterPressCallback(function() AdminEvents.RequestBannedUsers:FireServer() end)
    for i = 1, 5 do
        banBtnLabels[i]:RegisterPressCallback(function()
            local entry = banned[i]
            if entry and entry.userId then AdminEvents.AdminUnban:FireServer(entry.userId) end
        end)
    end

    -- ── Server responses ─────────────────────────────────────────────────────
    AdminEvents.PlayerListData:Connect(function(list)
        players = list or {}
        if selected > #players then selected = 1 end
        RenderTarget()
    end)
    AdminEvents.BannedUsersData:Connect(function(list)
        banned = list or {}
        RenderBanned()
    end)
    AdminEvents.AdminResult:Connect(function(ok, message)
        SetStatus(message, ok)
        if ok then
            AdminEvents.RequestPlayerList:FireServer()
            AdminEvents.RequestBannedUsers:FireServer()
        end
    end)
end
