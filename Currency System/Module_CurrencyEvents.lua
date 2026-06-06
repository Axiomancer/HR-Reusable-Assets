--!Type(Module)

-- Currency System event bus. Standalone.
--
-- Server -> Client: sync balance after any change
-- Payload: (balance: number)
BalanceUpdate = Event.new("BalanceUpdate")

-- Server -> Client: daily bonus is available, here is the pre-rolled amount
-- Payload: (amount: number)
DailyBonusAvailable = Event.new("DailyBonusAvailable")

-- Client -> Server: request current balance (race-safe on connect)
RequestBalance = Event.new("RequestBalance")

-- Client -> Server: request daily bonus status (race-safe on connect)
RequestDailyBonusStatus = Event.new("RequestDailyBonusStatus")

-- Client -> Server: player pressed Spin to claim their daily bonus
ClaimDailyBonus = Event.new("ClaimDailyBonus")

-- Server -> Client: daily bonus claimed, here is the amount and new balance
-- Payload: (amount: number, newBalance: number)
DailyBonusResult = Event.new("DailyBonusResult")
