--!Type(UI)

-- Shop with a single Buy button per item. Consumables/permanents open a
-- payment popup (Squid Coins or Highrise Gold; SC greyed when unaffordable).
-- SC packs are Gold-only so their Buy goes straight to the Highrise prompt.
-- Owned permanents show a single Owned button.

--!Bind
local shopRoot       : UILuaView = nil
--!Bind
local shopTitleIcon  : Image = nil
--!Bind
local shopTitle      : UILabel = nil
--!Bind
local shopClose      : UILabel = nil
--!Bind
local shopGoldIcon   : Image = nil
--!Bind
local shopGoldLabel : UILabel = nil
--!Bind
local sectionPacks       : UILabel = nil
--!Bind
local sectionConsumables : UILabel = nil
--!Bind
local sectionPermanents  : UILabel = nil
-- SC packs
--!Bind
local sc1icon : Image = nil
--!Bind
local sc1name : UILabel = nil
--!Bind
local sc1desc : UILabel = nil
--!Bind
local sc1buy  : UILabel = nil
--!Bind
local sc2icon : Image = nil
--!Bind
local sc2name : UILabel = nil
--!Bind
local sc2desc : UILabel = nil
--!Bind
local sc2buy  : UILabel = nil
--!Bind
local sc3icon : Image = nil
--!Bind
local sc3name : UILabel = nil
--!Bind
local sc3desc : UILabel = nil
--!Bind
local sc3buy  : UILabel = nil
--!Bind
local sc4icon : Image = nil
--!Bind
local sc4name : UILabel = nil
--!Bind
local sc4desc : UILabel = nil
--!Bind
local sc4buy  : UILabel = nil
-- Consumables
--!Bind
local c1icon : Image = nil
--!Bind
local c1name : UILabel = nil
--!Bind
local c1desc : UILabel = nil
--!Bind
local c1buy  : UILabel = nil
--!Bind
local c2icon : Image = nil
--!Bind
local c2name : UILabel = nil
--!Bind
local c2desc : UILabel = nil
--!Bind
local c2buy  : UILabel = nil
-- Permanents
--!Bind
local p1icon : Image = nil
--!Bind
local p1name : UILabel = nil
--!Bind
local p1desc : UILabel = nil
--!Bind
local p1buy  : UILabel = nil
--!Bind
local p2icon : Image = nil
--!Bind
local p2name : UILabel = nil
--!Bind
local p2desc : UILabel = nil
--!Bind
local p2buy  : UILabel = nil
--!Bind
local p3icon : Image = nil
--!Bind
local p3name : UILabel = nil
--!Bind
local p3desc : UILabel = nil
--!Bind
local p3buy  : UILabel = nil
--!Bind
local p4icon : Image = nil
--!Bind
local p4name : UILabel = nil
--!Bind
local p4desc : UILabel = nil
--!Bind
local p4buy  : UILabel = nil
--!Bind
local p5icon : Image = nil
--!Bind
local p5name : UILabel = nil
--!Bind
local p5desc : UILabel = nil
--!Bind
local p5buy  : UILabel = nil
-- Payment popup. payPopup is a VisualElement so it is queried via Q(), not
-- bound (VisualElements are not bindable).
local payPopup  = nil
--!Bind
local payTitle  : UILabel = nil
--!Bind
local payChoose : UILabel = nil
--!Bind
local paySC     : UILabel = nil
--!Bind
local payGold   : UILabel = nil
--!Bind
local payCancel : UILabel = nil

-- Shop icon textures. Drag a PNG from Assets/Scripts/UI Icons into each slot in
-- the Inspector; the field name tells you which item it is.
--!SerializeField
local iconShopTitle       : Texture = nil   -- panel header icon
--!SerializeField
local iconCoin            : Texture = nil   -- the SC / gold coin
--!SerializeField
local iconPackHandful     : Texture = nil
--!SerializeField
local iconPackStack       : Texture = nil
--!SerializeField
local iconPackChest       : Texture = nil
--!SerializeField
local iconPackVault       : Texture = nil
--!SerializeField
local iconGlassSpecialist : Texture = nil
--!SerializeField
local iconFeatherWeight   : Texture = nil
--!SerializeField
local iconGlassExpert     : Texture = nil
--!SerializeField
local iconGoldMagnet      : Texture = nil
--!SerializeField
local iconIronBoots       : Texture = nil
--!SerializeField
local iconCashBoost       : Texture = nil
--!SerializeField
local iconVip             : Texture = nil

local GameEvents = require("Module_GameEvents")
local UIState    = require("Module_UIState")

-- Set an Image element's icon from a dragged-in Texture (Highrise Image type
-- has an `image : Texture` property), same pattern as the HUD / v1 UI.
local function SetImg(imgEl, tex)
    if imgEl and tex then imgEl.image = tex end
end

-- Comma formatter
local function FormatSC(n)
    local s = tostring(math.floor(n or 0))
    local result = ""
    local len = #s
    for i = 1, len do
        result = result .. s:sub(i, i)
        local remaining = len - i
        if remaining > 0 and remaining % 3 == 0 then
            result = result .. ","
        end
    end
    return result
end

-- Shop data (inlined; keep in sync with Module_ShopConfig.lua)
local SC_PACKS = {
    { id="sc_handful", icon="?", name="Handful",  desc="500 Squid Coins",          goldIwpId="gb_sc_handful", goldLabel="35g"  },
    { id="sc_stack",   icon="?", name="Stack",    desc="1,500 SC  -  +17% bonus",  goldIwpId="gb_sc_stack",   goldLabel="90g"  },
    { id="sc_pouch",   icon="?", name="Chest",    desc="5,000 SC  -  +40% bonus",  goldIwpId="gb_sc_pouch",   goldLabel="250g" },
    { id="sc_vault",   icon="?", name="Vault",    desc="12,000 SC  -  +68% bonus", goldIwpId="gb_sc_vault",   goldLabel="500g" },
}

local CONSUMABLES = {
    { id="glass_specialist", icon="?", name="Glass Specialist", desc="+10% chance the tile holds. Next 3 steps.",      scPrice=300, goldLabel="25g", goldIwpId="gb_glass_specialist" },
    { id="feather_weight",   icon="?", name="Feather Weight",   desc="20% chance to survive an unsafe tile. 2 tiles.", scPrice=600, goldLabel="40g", goldIwpId="gb_feather"           },
}

-- Ordered cheapest -> most expensive.
local PERMANENTS = {
    { id="perm_revenue_25",   icon="?",    name="Cash Boost",   desc="Permanent +25% on all Squid Coins you earn. Stacks with VIP & Gold Magnet.", scPrice=4000, scLabel="4,000", goldLabel="200g", goldIwpId="gb_25_revenue_boost" },
    { id="perm_glass_expert", icon="??", name="Glass Expert", desc="Every tile is permanently 10% more likely to hold.",        scPrice=8000,  scLabel="8,000",  goldLabel="800g",  goldIwpId="gb_perm_glass_expert" },
    { id="perm_revenue_50",   icon="??",  name="Gold Magnet",  desc="Permanent +50% on all Squid Coins you earn. Stacks with VIP.", scPrice=8000, scLabel="8,000", goldLabel="400g", goldIwpId="gb_50_revenue_boost" },
    { id="perm_vip",          icon="?",    name="VIP",          desc="Crown by your name, VIP lounge access, and +50% on all SC earned.", scPrice=12000, scLabel="12,000", goldLabel="500g", goldIwpId="viparea"          },
    { id="perm_iron_boots",   icon="??",  name="Iron Boots",   desc="Permanent 20% chance to survive any unsafe tile.",           scPrice=20000, scLabel="20,000", goldLabel="2000g", goldIwpId="gb_perm_iron_boots"   },
}

-- Element arrays
local scIcons={sc1icon,sc2icon,sc3icon,sc4icon}; local scNames={sc1name,sc2name,sc3name,sc4name}
local scDescs={sc1desc,sc2desc,sc3desc,sc4desc}; local scBuy  ={sc1buy, sc2buy, sc3buy, sc4buy }
local cIcons ={c1icon,c2icon};                   local cNames ={c1name,c2name}
local cDescs ={c1desc,c2desc};                   local cBuy   ={c1buy, c2buy}
local pIcons ={p1icon,p2icon,p3icon,p4icon,p5icon}; local pNames ={p1name,p2name,p3name,p4name,p5name}
local pDescs ={p1desc,p2desc,p3desc,p4desc,p5desc}; local pBuy   ={p1buy, p2buy, p3buy, p4buy, p5buy}

-- Parallel icon-texture arrays (order matches the item lists below)
local scTextures = { iconPackHandful, iconPackStack, iconPackChest, iconPackVault }
local cTextures  = { iconGlassSpecialist, iconFeatherWeight }
local pTextures  = { iconCashBoost, iconGlassExpert, iconGoldMagnet, iconVip, iconIronBoots }

-- State
local currentSC   = 0
local ownedPerm   = {}    -- [permId] = true
local pendingItem = nil   -- item awaiting payment-method choice

local function SetClass(lbl, cls, on) lbl:EnableInClassList(cls, on) end

-- Payment popup
local function HidePopup()
    pendingItem = nil
    payPopup:EnableInClassList("pay-popup--open", false)
end

local function ShowPopup(item)
    pendingItem = item
    payTitle:SetPrelocalizedText(item.name)
    payChoose:SetPrelocalizedText("Choose how to pay")
    paySC:SetPrelocalizedText((item.scLabel or FormatSC(item.scPrice)) .. " SC")
    payGold:SetPrelocalizedText(item.goldLabel .. " Gold")

    -- Grey out the SC option if the player cannot afford it
    SetClass(paySC, "pay-btn--disabled", currentSC < item.scPrice)

    payPopup:EnableInClassList("pay-popup--open", true)
end

-- Shop open/close
local function Open()
    shopRoot.visible = true
    HidePopup()
    GameEvents.RequestPerkSync:FireServer()
end

local function Close()
    HidePopup()
    shopRoot.visible = false
end

-- Owned-permanent sync
local function ApplyPerkSync(perks)
    for i, item in ipairs(PERMANENTS) do
        local owned = (perks[item.id] or 0) >= 1
        ownedPerm[item.id] = owned
        if pBuy[i] then
            if owned then
                pBuy[i]:SetPrelocalizedText(" Owned")
                SetClass(pBuy[i], "shop-buy--owned", true)
            else
                pBuy[i]:SetPrelocalizedText("Buy")
                SetClass(pBuy[i], "shop-buy--owned", false)
            end
        end
    end
end

-- Lifecycle
function self:ClientAwake()
    -- Note: payPopup is queried in ClientStart because Q traversal is not
    -- reliable in Awake. The popup starts hidden via its USS default.
    shopRoot.visible = false
    SetImg(shopTitleIcon, iconShopTitle)
    shopTitle:SetPrelocalizedText("Shop")
    shopClose:SetPrelocalizedText("X")
    SetImg(shopGoldIcon, iconCoin)
    shopGoldLabel:SetPrelocalizedText("- SC")
    sectionPacks:SetPrelocalizedText("SC PACKS  -  BUY WITH HIGHRISE GOLD")
    sectionConsumables:SetPrelocalizedText("CONSUMABLES")
    sectionPermanents:SetPrelocalizedText("PERMANENTS")
    payCancel:SetPrelocalizedText("Cancel")

    for i, item in ipairs(SC_PACKS) do
        SetImg(scIcons[i], scTextures[i])
        if scNames[i] then scNames[i]:SetPrelocalizedText(item.name) end
        if scDescs[i] then scDescs[i]:SetPrelocalizedText(item.desc) end
        if scBuy[i]   then scBuy[i]:SetPrelocalizedText(item.goldLabel .. " Gold") end
    end
    for i, item in ipairs(CONSUMABLES) do
        SetImg(cIcons[i], cTextures[i])
        if cNames[i] then cNames[i]:SetPrelocalizedText(item.name) end
        if cDescs[i] then cDescs[i]:SetPrelocalizedText(item.desc) end
        if cBuy[i]   then cBuy[i]:SetPrelocalizedText("Buy") end
    end
    for i, item in ipairs(PERMANENTS) do
        SetImg(pIcons[i], pTextures[i])
        if pNames[i] then pNames[i]:SetPrelocalizedText(item.name) end
        if pDescs[i] then pDescs[i]:SetPrelocalizedText(item.desc) end
        if pBuy[i]   then pBuy[i]:SetPrelocalizedText("Buy") end
    end

    UIState.Register("shop", Open, Close)
end

function self:ClientStart()
    payPopup = shopRoot:Q("payPopup")   -- VisualElement, queried not bound

    shopClose:RegisterPressCallback(Close)
    shopRoot:RegisterPressCallback(Close)
    local card = shopRoot:Q("shopCard")
    if card then card:RegisterPressCallback(function() end) end

    -- SC packs: Gold-only -> straight to the Highrise prompt
    for i, item in ipairs(SC_PACKS) do
        local it = item
        if scBuy[i] then
            scBuy[i]:RegisterPressCallback(function()
                Payments:PromptPurchase(it.goldIwpId, function(paid) end)
            end)
        end
    end

    -- Consumables: Buy -> payment popup
    for i, item in ipairs(CONSUMABLES) do
        local it = item
        if cBuy[i] then cBuy[i]:RegisterPressCallback(function() ShowPopup(it) end) end
    end

    -- Permanents: Buy -> payment popup (unless owned)
    for i, item in ipairs(PERMANENTS) do
        local it = item
        if pBuy[i] then
            pBuy[i]:RegisterPressCallback(function()
                if ownedPerm[it.id] then return end
                ShowPopup(it)
            end)
        end
    end

    -- Popup: pay with Squid Coins
    paySC:RegisterPressCallback(function()
        if not pendingItem then return end
        if currentSC < pendingItem.scPrice then return end   -- greyed; ignore
        GameEvents.ShopPurchase:FireServer(pendingItem.id)
        HidePopup()
    end)

    -- Popup: pay with Highrise Gold
    payGold:RegisterPressCallback(function()
        if not pendingItem then return end
        local iwp = pendingItem.goldIwpId
        HidePopup()
        Payments:PromptPurchase(iwp, function(paid) end)  -- server grants via PurchaseHandler
    end)

    payCancel:RegisterPressCallback(HidePopup)
    payPopup:RegisterPressCallback(HidePopup)  -- tap backdrop to dismiss
    local payCard = payPopup:Q("payCard")
    if payCard then payCard:RegisterPressCallback(function() end) end

    -- Gold balance sync
    GameEvents.GoldUpdate:Connect(function(amount)
        currentSC = amount
        shopGoldLabel:SetPrelocalizedText(FormatSC(amount) .. " SC")
        if pendingItem then
            SetClass(paySC, "pay-btn--disabled", currentSC < pendingItem.scPrice)
        end
    end)

    -- Purchase result (SC purchases)
    GameEvents.ShopPurchaseResult:Connect(function(itemId, success, newSC, usesGranted)
        if success then
            currentSC = newSC
            shopGoldLabel:SetPrelocalizedText(FormatSC(newSC) .. " SC")
        end
    end)

    -- Owned-permanent sync
    GameEvents.PerkSync:Connect(function(perks) ApplyPerkSync(perks) end)
end
