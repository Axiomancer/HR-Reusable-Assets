--!Type(Module)

-- Shop Configuration Template. Copy this file, rename it Module_ShopConfig.lua,
-- and fill in your items. Reference this from UI_Shop.lua and your server script.
--
-- goldIwpId: the In-World Purchase ID you set in the Highrise Creator Portal.
-- storageKey: the Inventory item ID used to track ownership / uses.
-- permanent: true means the item is bought once and owned forever.
-- uses: for consumables, how many uses are granted per purchase (0 for permanent).

-- Consumable items
-- Players can buy these multiple times. Uses are tracked in Inventory.
CONSUMABLES = {
    {
        id          = "item_one",
        storageKey  = "item_one",
        name        = "Item One",
        description = "Does something useful for a limited number of steps.",
        scPrice     = 300,
        goldIwpId   = "gb_item_one",
        goldLabel   = "25g",
        uses        = 3,
        permanent   = false,
    },
}

-- Permanent items
-- Bought once. Subsequent buy attempts are blocked by the Owned state.
PERMANENTS = {
    {
        id          = "perm_item_one",
        storageKey  = "perm_item_one",
        name        = "Permanent Item One",
        description = "Unlocked forever. Grants a passive bonus every round.",
        scPrice     = 5000,
        scLabel     = "5,000",
        goldIwpId   = "gb_perm_item_one",
        goldLabel   = "250g",
        permanent   = true,
        uses        = 0,
    },
}

-- Ordered lists (used by UI to render rows in sequence)
CONSUMABLE_LIST = CONSUMABLES
PERMANENT_LIST  = PERMANENTS
