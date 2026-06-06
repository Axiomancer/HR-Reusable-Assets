--!Type(Module)

-- Shop event bus. Standalone.

-- Client -> Server: player wants to buy an item with in-game currency
-- Payload: (itemId: string)
ShopPurchase = Event.new("ShopPurchase")

-- Server -> Client: result of a purchase attempt
-- Payload: (itemId: string, success: boolean, newBalance: number, usesGranted: number)
ShopPurchaseResult = Event.new("ShopPurchaseResult")

-- Server -> Client or Client -> Server: sync owned/inventory state
-- Payload: (inventory: { [itemId] = amount })
InventorySync = Event.new("InventorySync")

-- Client -> Server: request a fresh inventory sync (e.g. on shop open)
RequestInventorySync = Event.new("RequestInventorySync")

-- Server -> Client: balance changed (sync the displayed balance)
-- Payload: (balance: number)
BalanceUpdate = Event.new("BalanceUpdate")

-- Client -> Server: request current balance (race-safe)
RequestBalance = Event.new("RequestBalance")
