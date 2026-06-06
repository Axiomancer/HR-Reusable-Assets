--!Type(Server)

-- Activity Feed Demo
-- Attach this script to a GameObject in your scene alongside the feed.
-- It fires a sequence of example messages automatically when the server starts,
-- so you can see the feed working without any other game logic.
-- Remove or disable this script before shipping your world.

local FeedEvents = require("Module_FeedEvents")

-- Fire a sequence of messages with delays to simulate live game events.
-- Each entry stays visible for 8 seconds before expiring.

Timer.After(1, function()
    FeedEvents.ActivityLog:FireAllClients("join", "VirtualPlayer1 joined")
end)

Timer.After(2.5, function()
    FeedEvents.ActivityLog:FireAllClients("join", "VirtualPlayer2 joined")
end)

Timer.After(4, function()
    FeedEvents.ActivityLog:FireAllClients("coin", "VirtualPlayer1 earned 50 coins")
end)

Timer.After(5.5, function()
    FeedEvents.ActivityLog:FireAllClients("alert", "New round starting in 10 seconds")
end)

Timer.After(7, function()
    FeedEvents.ActivityLog:FireAllClients("star", "VirtualPlayer2 reached the finish line!")
end)

Timer.After(8.5, function()
    FeedEvents.ActivityLog:FireAllClients("coin", "VirtualPlayer2 earned 100 coins")
end)

Timer.After(10, function()
    FeedEvents.ActivityLog:FireAllClients("join", "VirtualPlayer3 joined")
end)

Timer.After(11.5, function()
    FeedEvents.ActivityLog:FireAllClients("shield", "VirtualPlayer1 was removed by staff")
end)

Timer.After(13, function()
    FeedEvents.ActivityLog:FireAllClients("star", "VirtualPlayer3 unlocked Gold Tier!")
end)

Timer.After(14.5, function()
    FeedEvents.ActivityLog:FireAllClients("join", "VirtualPlayer1 left")
end)

-- Wire real player join/leave events on top of the demo sequence
server.PlayerConnected:Connect(function(player)
    FeedEvents.ActivityLog:FireAllClients("join", player.name .. " joined")
end)

server.PlayerDisconnected:Connect(function(player)
    FeedEvents.ActivityLog:FireAllClients("join", player.name .. " left")
end)
