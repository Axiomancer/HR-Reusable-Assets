--!Type(Server)

-- Admin Panel server-side handlers.
-- Drop this script into your scene alongside your main server script,
-- OR copy the handler blocks directly into your existing server script.
--
-- DEPENDENCIES: Module_AdminEvents.lua
-- OPTIONAL:     Module_InventoryManager.lua (for AdminGiveCoins / AdminGiveItem)
--
-- All actions are re-validated against player.isModerator before executing.

local AdminEvents = require("Module_AdminEvents")

local function IsStaff(player)
    return player ~= nil and player.isModerator == true
end

local function FindPlayerById(targetId)
    for _, p in ipairs(server.players) do
        if p.id == targetId then return p end
    end
    return nil
end

local function Reply(sender, ok, msg)
    AdminEvents.AdminResult:FireClient(sender, ok, msg)
end

-- ── Access check ──────────────────────────────────────────────────────────────

AdminEvents.RequestAdminAccess:Connect(function(sender)
    AdminEvents.AdminAccess:FireClient(sender, IsStaff(sender))
end)

-- ── Player list ───────────────────────────────────────────────────────────────

AdminEvents.RequestPlayerList:Connect(function(sender)
    if not IsStaff(sender) then return end
    local list = {}
    for _, p in ipairs(server.players) do
        table.insert(list, { id = p.id, name = p.name })
    end
    AdminEvents.PlayerListData:FireClient(sender, list)
end)

-- ── Banned users ──────────────────────────────────────────────────────────────

AdminEvents.RequestBannedUsers:Connect(function(sender)
    if not IsStaff(sender) then return end
    Moderation.GetBannedUsers(20, nil, function(users, err)
        local list = {}
        if users then
            for _, u in ipairs(users) do
                table.insert(list, { userId = u.userId, name = u.displayName or u.userId })
            end
        end
        AdminEvents.BannedUsersData:FireClient(sender, list)
    end)
end)

-- ── Moderation actions ────────────────────────────────────────────────────────

AdminEvents.AdminKick:Connect(function(sender, targetId)
    if not IsStaff(sender) then return end
    local target = FindPlayerById(targetId)
    if not target then Reply(sender, false, "Player not found."); return end
    local ok, err = Moderation.KickPlayer(target)
    if ok then Reply(sender, true, target.name .. " kicked.")
    else Reply(sender, false, "Kick failed: " .. tostring(err)) end
end)

AdminEvents.AdminMute:Connect(function(sender, targetId, durationSecs)
    if not IsStaff(sender) then return end
    local target = FindPlayerById(targetId)
    if not target then Reply(sender, false, "Player not found."); return end
    local ok, err = Moderation.MutePlayer(target, durationSecs or 600)
    if ok then Reply(sender, true, target.name .. " muted.")
    else Reply(sender, false, "Mute failed: " .. tostring(err)) end
end)

AdminEvents.AdminUnmute:Connect(function(sender, targetId)
    if not IsStaff(sender) then return end
    local target = FindPlayerById(targetId)
    if not target then Reply(sender, false, "Player not found."); return end
    local ok, err = Moderation.UnmutePlayer(target)
    if ok then Reply(sender, true, target.name .. " unmuted.")
    else Reply(sender, false, "Unmute failed: " .. tostring(err)) end
end)

AdminEvents.AdminBan:Connect(function(sender, targetId, durationSecs, reason)
    if not IsStaff(sender) then return end
    local target = FindPlayerById(targetId)
    if not target then Reply(sender, false, "Player not found."); return end
    local isPerm = (durationSecs == -1)
    local ok, err = Moderation.BanPlayer(target, isPerm and nil or durationSecs, reason or "Banned by staff")
    if ok then Reply(sender, true, target.name .. (isPerm and " permanently banned." or " banned."))
    else Reply(sender, false, "Ban failed: " .. tostring(err)) end
end)

AdminEvents.AdminUnban:Connect(function(sender, userId)
    if not IsStaff(sender) then return end
    local ok, err = Moderation.UnbanPlayer(userId)
    if ok then Reply(sender, true, "Player unbanned.")
    else Reply(sender, false, "Unban failed: " .. tostring(err)) end
end)

-- ── Game actions ──────────────────────────────────────────────────────────────

AdminEvents.AdminTeleport:Connect(function(sender, targetId)
    if not IsStaff(sender) then return end
    -- Replace Vector3.new(0,1,0) with your actual spawn/start position.
    local target = FindPlayerById(targetId)
    if not target then Reply(sender, false, "Player not found."); return end
    -- Teleport is client-side -- fire a PlayerRespawn event or your equivalent.
    Reply(sender, true, target.name .. " teleported.")
end)

AdminEvents.AdminGiveCoins:Connect(function(sender, targetId, amount)
    if not IsStaff(sender) then return end
    local target = FindPlayerById(targetId)
    if not target then Reply(sender, false, "Player not found."); return end
    -- Wire to your currency module:
    --   CurrencyManager.Award(target, amount)
    Reply(sender, true, "Gave " .. tostring(amount) .. " coins to " .. target.name)
end)

AdminEvents.AdminGiveItem:Connect(function(sender, targetId, itemId, amount)
    if not IsStaff(sender) then return end
    local target = FindPlayerById(targetId)
    if not target then Reply(sender, false, "Player not found."); return end
    -- Wire to InventoryManager:
    --   InvMgr.QueueGive(target, itemId, amount)
    Reply(sender, true, "Gave " .. tostring(amount) .. "x " .. itemId .. " to " .. target.name)
end)

AdminEvents.AdminResetGame:Connect(function(sender)
    if not IsStaff(sender) then return end
    -- Wire to your game reset function.
    Reply(sender, true, "Game reset.")
end)
