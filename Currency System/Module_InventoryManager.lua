--!Type(Module)

-- Wraps the Highrise Inventory API with:
--   - Per-player in-memory cache (loaded on connect, fast sync reads)
--   - Batched transaction queue committed every 3 seconds
--
-- Usage (Server only):
--   InventoryManager.LoadInventory(player, callback)
--   InventoryManager.GetAmount(player, itemId)       -> number
--   InventoryManager.QueueGive(player, itemId, amount)
--   InventoryManager.QueueTake(player, itemId, amount) -> bool (false = insufficient)
--   InventoryManager.UnloadInventory(player)

local FETCH_LIMIT  = 100
local COMMIT_EVERY = 3   -- seconds

-- State
local cache        = {}   -- [player.id]  = { [itemId] = amount }
local pendingGives = {}   -- { playerId, itemId, amount }
local pendingTakes = {}   -- { playerId, itemId, amount }

-- Internal commit
local function CommitPending()
    if #pendingGives == 0 and #pendingTakes == 0 then return end

    local tx = InventoryTransaction.new()
    for _, g in ipairs(pendingGives) do tx:Give(g.playerId, g.itemId, g.amount) end
    for _, t in ipairs(pendingTakes) do tx:Take(t.playerId, t.itemId, t.amount) end

    Inventory.CommitTransaction(tx)

    pendingGives = {}
    pendingTakes = {}
end

-- Start the commit timer once when the module is first required
Timer.Every(COMMIT_EVERY, CommitPending)

-- Public API

-- Load all inventory items for a player into the local cache.
-- callback(playerCache) fires once all pages are fetched.
function LoadInventory(player, callback)
    local playerCache = {}
    cache[player.id] = playerCache

    local function fetchPage(cursor)
        Inventory.GetPlayerItems(player, FETCH_LIMIT, cursor, function(items, nextCursor, err)
            if items then
                for _, item in ipairs(items) do
                    playerCache[item.id] = item.amount
                end
            end
            if nextCursor then
                fetchPage(nextCursor)
            else
                print("InventoryManager: Loaded inventory for " .. player.name)
                if callback then callback(playerCache) end
            end
        end)
    end

    fetchPage(nil)
end

-- Return cached item amount. Returns 0 if not in inventory or not yet loaded.
function GetAmount(player, itemId)
    local c = cache[player.id]
    return c and (c[itemId] or 0) or 0
end

-- Queue a Give. Updates cache immediately; actual commit happens in next batch.
function QueueGive(player, itemId, amount)
    local c = cache[player.id]
    if c then c[itemId] = (c[itemId] or 0) + amount end
    table.insert(pendingGives, { playerId = player.user.id, itemId = itemId, amount = amount })
end

-- Queue a Take. Updates cache immediately if player has enough.
-- Returns true on success, false if insufficient balance.
function QueueTake(player, itemId, amount)
    local c = cache[player.id]
    if not c then return false end

    local current = c[itemId] or 0
    if current < amount then return false end

    c[itemId] = current - amount
    table.insert(pendingTakes, { playerId = player.user.id, itemId = itemId, amount = amount })
    return true
end

-- Remove a player's cache when they leave.
function UnloadInventory(player)
    cache[player.id] = nil
end
