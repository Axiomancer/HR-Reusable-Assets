--!Type(Module)

-- Leaderboard configuration. Edit this file for your game.
--
-- Each tab needs:
--   type  -- the string passed to RequestLeaderboard (must be unique)
--   label -- text shown on the tab button
--   board -- your Highrise leaderboard key
--   unit  -- label appended to the score (e.g. "wins", "SC", "kills")

TABS = {
    { type = "wins",   label = "Wins",   board = "MyGameWins",   unit = "wins"   },
    { type = "deaths", label = "Deaths", board = "MyGameDeaths", unit = "deaths" },
    { type = "coins",  label = "Coins",  board = "MyGameCoins",  unit = "SC"     },
}

-- Map from type -> config (built at module load)
TAB_MAP = {}
for _, t in ipairs(TABS) do TAB_MAP[t.type] = t end
