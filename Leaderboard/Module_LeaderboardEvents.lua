--!Type(Module)

-- Leaderboard event bus. Standalone.
--
-- Tab types are whatever strings you pass -- they map 1:1 to your
-- Highrise leaderboard keys defined in Module_LeaderboardConfig.

-- Client -> Server: request data for a tab
-- Payload: (boardType: string)
RequestLeaderboard = Event.new("RequestLeaderboard")

-- Server -> Client: leaderboard results
-- Payload: (boardType, entries: { {name, score, rank} }, selfRank, selfScore)
LeaderboardData = Event.new("LeaderboardData")
