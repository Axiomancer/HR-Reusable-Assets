--!Type(Module)

-- Currency Manager (Server only)
-- Manages a named in-game currency backed by Highrise Inventory.
-- Includes daily login bonus with a configurable weighted spin table.
--
-- DEPENDENCIES: Module_InventoryManager.lua, Module_CurrencyEvents.lua
--
-- SETUP:
--   1. Set CURRENCY_ITEM to your Inventory item ID.
--   2. Set LEADERBOARD_KEY to your leaderboard key (or nil to disable).
--   3. Adjust SPIN_TABLE weights and amounts for your game's economy.
--   4. Wire up server hooks (see bottom of file).
--
-- USAGE (call from your server script):
--   CurrencyManager.LoadBalance(player)
--   CurrencyManager.Award(player, amount)
--   CurrencyManager.Deduct(player, amount) -> bool
--   CurrencyManager.GetBalance(player)     -> number
--   CurrencyManager.CheckDailyBonus(player)
--   CurrencyManager.GrantDailyBonus(player)
--   CurrencyManager.SendBalance(player)

local InvMgr   = require("Module_InventoryManager")
local CurrEvents = require("Module_CurrencyEvents")

-- ── CONFIG -- edit these for your game ───────────────────────────────────────

local CURRENCY_ITEM    = "game_coins"        -- Inventory item ID for your currency
local LEADERBOARD_KEY  = nil                 -- Leaderboard key, or nil to disable
local DAILY_KEY        = "daily_last_claim"  -- Inventory item ID tracking last claim day

-- Spin wheel: weights must sum to 100.
local SPIN_TABLE = {
    { amount = 50,  weight = 35 },
    { amount = 75,  weight = 25 },
    { amount = 100, weight = 20 },
    { amount = 150, weight = 12 },
    { amount = 200, weight = 5  },
    { amount = 300, weight = 3  },
}

-- ── Internal ─────────────────────────────────────────────────────────────────

local pendingBonuses = {}  -- [player.id] = pre-rolled amount

local function SyncToClient(player)
    local balance = InvMgr.GetAmount(player, CURRENCY_ITEM)
    CurrEvents.BalanceUpdate:FireClient(player, balance)
    if LEADERBOARD_KEY then
        Leaderboard.SetScoreForPlayer(LEADERBOARD_KEY, player, balance, function() end)
    end
end

local function RollBonus()
    local roll = math.random(1, 100)
    local cumulative = 0
    for _, entry in ipairs(SPIN_TABLE) do
        cumulative = cumulative + entry.weight
        if roll <= cumulative then return entry.amount end
    end
    return SPIN_TABLE[1].amount
end

-- ── Public API ────────────────────────────────────────────────────────────────

function LoadBalance(player)
    SyncToClient(player)
end

function GetBalance(player)
    return InvMgr.GetAmount(player, CURRENCY_ITEM)
end

function Award(player, amount)
    InvMgr.QueueGive(player, CURRENCY_ITEM, amount)
    SyncToClient(player)
end

function Deduct(player, amount)
    local ok = InvMgr.QueueTake(player, CURRENCY_ITEM, amount)
    if ok then SyncToClient(player) end
    return ok
end

function SendBalance(player)
    SyncToClient(player)
end

-- Check eligibility and pre-roll the daily bonus. Does NOT grant yet.
-- Fires DailyBonusAvailable to the client if eligible.
function CheckDailyBonus(player)
    local today = math.floor(os.time() / 86400)
    local last  = InvMgr.GetAmount(player, DAILY_KEY)
    if today > last then
        local amount = RollBonus()
        pendingBonuses[player.id] = amount
        CurrEvents.DailyBonusAvailable:FireClient(player, amount)
    end
end

-- Re-send availability to a client that requests it after their UI is ready.
function SendDailyBonusStatus(player)
    local amount = pendingBonuses[player.id]
    if amount then CurrEvents.DailyBonusAvailable:FireClient(player, amount) end
end

-- Grant the pre-rolled daily bonus when the player presses Spin.
function GrantDailyBonus(player)
    local amount = pendingBonuses[player.id]
    if not amount then return end
    pendingBonuses[player.id] = nil

    local today = math.floor(os.time() / 86400)
    local last  = InvMgr.GetAmount(player, DAILY_KEY)
    if today > last then InvMgr.QueueGive(player, DAILY_KEY, today - last) end

    InvMgr.QueueGive(player, CURRENCY_ITEM, amount)
    SyncToClient(player)

    local newBalance = InvMgr.GetAmount(player, CURRENCY_ITEM)
    CurrEvents.DailyBonusResult:FireClient(player, amount, newBalance)
end

-- ── Server-side event hooks -- wire these in your Server script ───────────────
--
--   CurrEvents.RequestBalance:Connect(function(sender)
--       CurrencyManager.SendBalance(sender)
--   end)
--
--   CurrEvents.RequestDailyBonusStatus:Connect(function(sender)
--       CurrencyManager.SendDailyBonusStatus(sender)
--   end)
--
--   CurrEvents.ClaimDailyBonus:Connect(function(sender)
--       CurrencyManager.GrantDailyBonus(sender)
--   end)
