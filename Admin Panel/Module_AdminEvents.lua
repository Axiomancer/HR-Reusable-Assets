--!Type(Module)

-- Admin Panel event bus. Standalone.
-- All actions are re-validated server-side against player.isModerator.
--
-- USAGE:
--   Fire from client (UI):   AdminEvents.AdminKick:FireServer(targetId)
--   Listen on server:        AdminEvents.AdminKick:Connect(function(sender, targetId) end)

-- Client -> Server: request access check (server replies with AdminAccess)
RequestAdminAccess = Event.new("RequestAdminAccess")

-- Server -> Client: whether this player has staff access
-- Payload: (isStaff: boolean)
AdminAccess = Event.new("AdminAccess")

-- Client -> Server: request online player list
RequestPlayerList = Event.new("RequestPlayerList")

-- Server -> Client: online player list
-- Payload: (players: { {id, name} })
PlayerListData = Event.new("PlayerListData")

-- Client -> Server: request banned users list
RequestBannedUsers = Event.new("RequestBannedUsers")

-- Server -> Client: banned users
-- Payload: (users: { {userId, name} })
BannedUsersData = Event.new("BannedUsersData")

-- Moderation actions (target identified by player connection id)
-- Payload: (targetId: string, durationSeconds: number, reason: string)
AdminKick   = Event.new("AdminKick")
AdminMute   = Event.new("AdminMute")
AdminUnmute = Event.new("AdminUnmute")
AdminBan    = Event.new("AdminBan")    -- durationSeconds = -1 for permanent
AdminUnban  = Event.new("AdminUnban")  -- Payload: (userId: string)

-- Game actions
AdminResetGame  = Event.new("AdminResetGame")   -- Payload: none
AdminTeleport   = Event.new("AdminTeleport")    -- Payload: (targetId: string) -- teleports to start
AdminGiveCoins  = Event.new("AdminGiveCoins")   -- Payload: (targetId: string, amount: number)

-- Optional: grant an inventory item to a player
-- Payload: (targetId: string, itemId: string, amount: number)
AdminGiveItem   = Event.new("AdminGiveItem")

-- Server -> Client: result of the last admin action
-- Payload: (success: boolean, message: string)
AdminResult = Event.new("AdminResult")
