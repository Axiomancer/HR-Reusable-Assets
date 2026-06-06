# Activity Feed for Highrise Studio

A plug-and-play live event log for any Highrise world. Each entry shows a small
PNG icon alongside a line of text. Entries expire automatically and the feed
scrolls so only the most recent five are visible at any time.

---

## What is included

| File | Purpose |
|---|---|
| `UI_ActivityFeed.lua` | The UI script — attach this to a UI GameObject |
| `UI_ActivityFeed.uxml` | The layout file — linked to the UI script |
| `UI_ActivityFeed.uss` | The stylesheet — controls colours, sizing, position |
| `Module_FeedEvents.lua` | The event bus — lets your server fire feed messages |
| `Server_FeedDemo.lua` | Optional demo script — fires example messages on a timer so you can see the feed working immediately. Remove before shipping. |

---

## What it looks like

- Sits in the **bottom-left** of the screen, above the chat bar
- Up to **5 rows** visible at once (oldest drops off the top when a new one arrives)
- Each row is a **small icon + text pill** with a subtle dark background
- The newest entry gets a brighter highlight
- Entries **auto-expire** after 8 seconds (configurable)

---

## Setup in Highrise Studio (Unity)

### Step 1 — Import the files

1. Open your Highrise Studio project in Unity.
2. Drag all four files into your `Assets/Scripts/` folder (or a subfolder of your choice).
   Unity will import them automatically.

### Step 2 — Create GameObjects for the scripts

Every Lua script in Highrise Studio — including modules — must be assigned to a
GameObject in your scene.

1. In the **Hierarchy**, right-click and choose `Create Empty`. Name it `ActivityFeed`.
2. With it selected, go to the **Inspector** and add the **Lua Script** component.
   Assign `UI_ActivityFeed.lua` to it. Unity will automatically link
   `UI_ActivityFeed.uxml` because it shares the same filename.
3. Right-click the Hierarchy again, `Create Empty`, name it `FeedEvents`.
4. Add a **Lua Script** component and assign `Module_FeedEvents.lua` to it.

Both GameObjects need to be active in the scene at runtime.

### Step 3 — Assign icon textures

1. Select the `ActivityFeed` GameObject.
2. In the Inspector you will see a list of serialized texture slots:
   - `Icon Default`
   - `Icon Join`
   - `Icon Alert`
   - `Icon Star`
   - `Icon Coin`
   - `Icon Shield`
3. Drag a PNG file into each slot. See the **Icons** section below for where
   to find free icons.
4. If you leave a slot empty, that key falls back to `Icon Default`.
   Always fill `Icon Default` so there is always something to show.


## Firing messages from your server script

In any `--!Type(Server)` script:

```lua
local FeedEvents = require("Module_FeedEvents")

-- Basic usage: iconKey + message
FeedEvents.ActivityLog:FireAllClients("join", "PlayerName joined the world")
FeedEvents.ActivityLog:FireAllClients("coin", "PlayerName earned 100 coins")
FeedEvents.ActivityLog:FireAllClients("star", "PlayerName reached the finish line!")
FeedEvents.ActivityLog:FireAllClients("alert", "New round starting in 10 seconds")
FeedEvents.ActivityLog:FireAllClients("shield", "PlayerName was removed by staff")

-- Wire it to Highrise player events
server.PlayerConnected:Connect(function(player)
    FeedEvents.ActivityLog:FireAllClients("join", player.name .. " joined")
end)

server.PlayerDisconnected:Connect(function(player)
    FeedEvents.ActivityLog:FireAllClients("join", player.name .. " left")
end)
```

The `iconKey` string must exactly match one of the keys in the `ICON_MAP` table
inside `UI_ActivityFeed.lua` (case-sensitive). Unrecognised keys fall back to
`Icon Default`.

---

## Adding your own icon keys

The feed is not limited to the default keys. To add a new one:

### 1. Add a serialized texture slot in `UI_ActivityFeed.lua`

Find the `-- Icon slots` section near the top of the file and add a new line:

```lua
--!SerializeField
local iconMyEvent : Texture = nil   -- "myevent"
```

### 2. Map the key in ClientStart

Scroll down to the `ICON_MAP` table inside `self:ClientStart()` and add your key:

```lua
ICON_MAP = {
    join    = iconJoin,
    alert   = iconAlert,
    star    = iconStar,
    coin    = iconCoin,
    shield  = iconShield,
    myevent = iconMyEvent,   -- add this line
}
```

### 3. Assign the texture in the Inspector

Save the script. Unity will show your new `Icon My Event` slot in the Inspector.
Drag a PNG into it.

### 4. Fire it from your server

```lua
FeedEvents.ActivityLog:FireAllClients("myevent", "Something happened!")
```

---

## Changing the entry lifetime and row count

Open `UI_ActivityFeed.lua` and edit the two constants near the top of the file:

```lua
local MAX_ENTRIES = 5    -- max rows visible at once (also controls how many
                         -- feed1/feed2/.../feedN rows exist in the UXML)
local LIFETIME    = 8    -- seconds before an entry disappears
```

If you increase `MAX_ENTRIES` beyond 5 you also need to:
1. Add matching rows in `UI_ActivityFeed.uxml` (copy an existing `feed5row` block
   and increment the number).
2. Add matching `--!Bind` pairs in `UI_ActivityFeed.lua` for the new label and icon.

---

## Customising the appearance (USS)

Open `UI_ActivityFeed.uss` to change colours, sizing, position and spacing.
Key classes:

| Class | What it controls |
|---|---|
| `.feed-root` | Overall position on screen. Change `padding-left` and `padding-bottom` to move the feed. |
| `.feed-row` | Background, border-radius and padding of each pill. |
| `.feed-row--new` | Highlight colour for the most recently added entry. |
| `.feed-icon` | Size of the icon. Default 14x14px. Increase for larger icons. |
| `.feed-entry` | Font size and text colour. |

### Moving the feed

By default the feed sits bottom-left. To move it to the bottom-right:

```css
.feed-root {
    align-items: flex-end;    /* right-align rows */
    padding-right: 16px;
    padding-left: 0;
}
```

To move it to the top-left:

```css
.feed-root {
    justify-content: flex-start;  /* top of screen */
    padding-top: 90px;            /* clear any top HUD */
    padding-bottom: 0;
}
```

---

## Icons

### Recommended size

Export icons at **64x64 px** or **128x128 px**. The feed renders them at 14x14 px
by default (set in USS), so smaller source files work fine. Larger sources also
work — Highrise scales them down automatically.

### Format

Use **PNG with transparency**. The icon sits on the dark pill background so a
transparent background blends cleanly. White or light-coloured icons read best
against the dark row colour.

### Where to get free icons

**Flaticon** — [flaticon.com](https://www.flaticon.com)
- Search for what you need (e.g. "trophy", "crown", "shield", "coin")
- Use the filter `Free` to limit results
- Download as **PNG**, choose **64px**
- Free icons require attribution in your world description or credits screen
- A Flaticon Premium subscription removes the attribution requirement

**Icons8** — [icons8.com](https://icons8.com)
- Large free library, good for game UI
- Download PNG at any size
- Free tier requires a link back; paid tier removes this

**SVG Repo** — [svgrepo.com](https://www.svgrepo.com)
- Entirely free, no attribution required
- Download as SVG then convert to PNG using a free tool like
  [cloudconvert.com](https://cloudconvert.com) at 64x64 px

**Game-Icons.net** — [game-icons.net](https://game-icons.net)
- Purpose-built for games, all free under CC BY 3.0
- White icons on transparent backgrounds — perfect for this feed
- Download as PNG, set size to 64

### Tips

- Stick to a consistent icon style across all your keys (all flat, all outlined,
  all filled) so the feed looks cohesive
- White or near-white icons work best on the default dark pill background
- If you use coloured icons, consider making the pill slightly more transparent
  in the USS so the colours do not clash

---

## Troubleshooting

**Feed does not appear**
- Check that the `ActivityFeed` GameObject is active in the Hierarchy
- Check that `UI_ActivityFeed.uxml` is in the same folder as `UI_ActivityFeed.lua`
- Open the Console and look for bind errors — they usually mean a name mismatch
  between a `--!Bind` variable and a `name=` attribute in the UXML

**Icon slot appears in Inspector but shows no image after dragging**
- Make sure the PNG is inside the `Assets/` folder of your project
- Try reimporting the texture (right-click > Reimport in the Project window)

**Messages fire but no entry appears**
- Confirm `Module_FeedEvents.lua` is in your project
- Confirm the `iconKey` string matches exactly (case-sensitive) what is in `ICON_MAP`
- Check the Console for Lua errors in `UI_ActivityFeed.lua`

**Old entries never disappear**
- `os.time()` is required for expiry. If your world runs in an environment where
  `os.time()` always returns 0, entries will not expire. Increase `LIFETIME` as
  a workaround or remove the expiry timer entirely and manage entries manually.
