--!Type(Server)

-- Leaderboard server-side handler.
-- DEPENDENCIES: Module_LeaderboardEvents.lua, Module_LeaderboardConfig.lua

local LbEvents = require("Module_LeaderboardEvents")
local LbConfig = require("Module_LeaderboardConfig")

LbEvents.RequestLeaderboard:Connect(function(sender, boardType)
    local tab = LbConfig.TAB_MAP[boardType]
    if not tab then return end

    Leaderboard.GetEntries(tab.board, 0, 5, function(entries, err)
        local top = {}
        if entries and err == 0 then
            for i, e in ipairs(entries) do
                top[i] = { name = e.name or "?", score = e.score or 0, rank = e.rank or i }
            end
        end

        local selfRank, selfScore = 0, 0
        Leaderboard.GetPlayerScore(tab.board, sender, function(score, rank, err2)
            if err2 == 0 then
                selfRank  = rank  or 0
                selfScore = score or 0
            end
            LbEvents.LeaderboardData:FireClient(sender, boardType, top, selfRank, selfScore)
        end)
    end)
end)
