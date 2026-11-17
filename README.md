# whip_appearance

Clothing stores, barber shops, plastic surgery, tattoo studios and company outfit wardrobes for FiveM servers
running the [WHIP framework](https://github.com/WHIPFX/txAdmin-recipe). Everything is set up in game, uses WHIP's
Character Creator look with full controller support, and ships Director, Dungeon Mode and Scenario cards.

> **Community resource.** whip_appearance is made by the community to work with WHIP. It is not part of WHIP, it is
> not made or endorsed by WHIP's author, and WHIP's support does not cover it. Report problems in this repository's
> issues.

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [First steps](#first-steps)
- [Stores](#stores)
- [Tattoo studio](#tattoo-studio)
- [Brands: what each store sells](#brands-what-each-store-sells)
- [Custom company stores](#custom-company-stores)
- [Outfit wardrobes](#outfit-wardrobes)
- [Admin Mode](#admin-mode)
- [Director, Dungeon Mode and Scenarios](#director-dungeon-mode-and-scenarios)
- [Controls](#controls)
- [Commands and permissions](#commands-and-permissions)
- [Configuration](#configuration)
- [Database](#database)
- [How saving works](#how-saving-works)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Features

- **Four kinds of store:** clothing, barber, plastic surgery and tattoo studio, each changing only its own part of
  the look.
- **In-game setup:** store positions, names, map icons and prices are edited in `/whip` → Settings. Stores are
  dragged on the map, and any store can be hidden from the map.
- **Brands:** each clothing store sells one brand (Binco, Suburban, Ponsonbys, Discount Store), picked automatically
  from each piece's name.
- **Company stores:** a store with its own catalog, limited to jobs, on duty only, free if you want.
- **Outfit wardrobes:** company outfits worn with 1 click, a minimum rank per outfit and a "Back to my clothes" button.
- **Admin Mode** inside every store: block or restrict any category, piece, color or haircut to jobs or characters,
  turn a piece into an exclusive inventory item, and set tattoo prices in batches.
- **View buttons:** hide the clothes in the tattoo studio, and hide head props or the shirt in the barber shop.
- **Try-on animations** for each kind of piece.
- **Mask fix:** the face no longer clips through masks.
- **Director cards:** open stores, goals, disguises and company outfits in scenarios and live events.
- **Safe by design:** the server validates every look, recomputes every price and refunds when a save fails.

## Requirements

| Resource | Notes |
|---|---|
| [whip_core](https://github.com/WHIPFX/txAdmin-recipe) | WHIP 1.0 or newer |
| [oxmysql](https://github.com/WHIPFX/oxmysql) | Already installed by WHIP's recipe |

GTA V Legacy and GTA V Enhanced are both supported. No other framework, inventory or target resource is needed.

## Installation

1. Download this repository and put the folder in your `resources` directory. **The folder must be named
   `whip_appearance`** (events, permissions and settings use that name).
2. Add it to `server.cfg`, after WHIP's own lines:

   ```cfg
   ensure whip_appearance
   ```

3. Start (or restart) the server. On its first start the resource creates its database tables by itself through
   oxmysql. There is no SQL to import.
4. The console prints `[whip_appearance] loaded ... rule(s)` and `[whip_appearance] loaded ... wardrobe outfit(s)`
   when everything is ready.

To install while the server is running, type `refresh` and then `ensure whip_appearance` in the server console.
After editing `fxmanifest.lua`, always run `refresh` before `restart whip_appearance`, or the server keeps the old
manifest.

## First steps

1. **Become a store admin.** Full admins already have the `whip_appearance.admin` permission. To give it to someone
   else, use `/whip` → Player Manager. Players with WHIP's developer tools on (`/w`) count as admins too.
2. **Check the stores on the map.** 14 clothing stores, 7 barber shops, 1 clinic and 6 tattoo studios come ready at
   GTA's usual places.
3. **Open the settings:** `/whip` → Settings → **Appearance**. There you move, rename, add or remove stores, choose map
   icons and set prices.
4. **Walk into a store** and press the prompt. With the permission, an **Admin** button shows on the store screen.

## Stores

| Store | What it changes |
|---|---|
| Clothing | jackets, undershirts, arms/gloves, pants, shoes, masks, accessories, bags, vests and decals (blocked by default), hats, glasses, earrings, watches, bracelets |
| Barber | haircut, hair color, fade, beard, eyebrows, chest hair, makeup, blush, lipstick |
| Plastic Surgery | sex, heritage (face and skin), face features, eye color, blemishes, ageing and moles |
| Tattoo Studio | tattoos, per body part (get and remove) |

- Each store only changes its own part of the look. Tattoos only change in the tattoo studio.
- On a sex change, the new body's clothes and hair are picked in the clinic at no extra cost. Tattoos that do not
  exist on the new body are lost.
- The player pays in cash or, if `Config.AllowBank` is on, by bank.
- The barber shop has two view buttons, on screen only: **Remove head props** (takes off the mask, glasses and hat
  to see the hair and face) and **Hide clothes** (takes off the jacket and shirt and shows bare arms, to see the chest
  hair).
- Every store can be set to **No map icon**: it works the same, but it does not show on the map or on the Director's
  GPS. Useful for hidden or roleplay-only stores.

### Prices

Settings → Appearance → **Prices** holds one price per category of each store (for example jacket, pants, haircut,
beard, each face feature). The total is always recomputed on the server.

## Tattoo studio

- One tab per body part, each tattoo with its picture, showing only the tattoos that exist for this body.
- Clicking a tattoo adds or removes it, and the character turns to show that side.
- **Hide clothes** (on by default) shows the body without clothes, on screen only. Click it again to see the
  tattoos with the clothes on.
- Up to 40 tattoos per character (WHIP's limit).
- **Price:** each new tattoo costs its body part's price (Settings → Appearance → **Prices: Tattoo**), or the price
  set for it in Admin Mode. Each removed tattoo costs the **removal** price.

## Brands: what each store sells

Each clothing store sells one brand, taken from the start of its name:

| Brand | Style |
|---|---|
| Binco | streetwear and casual |
| Suburban | casual and smart |
| Ponsonbys | suits and fancy clothes |
| Discount Store | work and basic clothes |

A piece's brands come from words in its name (`Config.Brands.keywords`) or from the DLC pack it comes from
(`Config.Brands.collections`). Admin Mode can choose the brands of any piece by hand.

## Custom company stores

Any clothing store can become a company store. In Settings → Appearance → Stores → **Clothing Stores**, click the
store and fill in:

| Field | What it does |
|---|---|
| Own catalog | e.g. `LSPD`. The store sells **only** the pieces marked with this catalog in Admin Mode; brands are ignored |
| Jobs only | comma-separated job keys (`police, sheriff`). With a single job, the point is hidden from everyone else |
| On duty only | only players clocked on can use it |
| Free | the store charges nothing |
| No map icon | the store does not show on the map |

**Building the catalog:**

1. Enter the store (admins can always enter) and turn on **Admin**.
2. Open a piece and mark its catalog chip (e.g. **LSPD**).
3. A piece marked **only** with company catalogs leaves the regular stores. Mark its brands too to sell it in both.

Inside a company catalog, the categories blocked by default (vests and decals) are open. A category blocked in Admin
Mode stays blocked.

## Outfit wardrobes

Wardrobes let a company's members put on ready-made outfits with one click.

**Adding a wardrobe:** Settings → Appearance → **Outfit Wardrobes**: where it is, its name, the job key and whether
it is on duty only. Only players with a rank at that job see the point.

**For members:**

- **Wear with 1 click:** hovering an outfit (mouse or controller) previews it on the body. Clicking wears it, and the
  outfit becomes the character's saved clothes.
- **Back to my clothes:** the clothes worn before the first outfit are kept and come back with this button. Buying
  clothes in a store makes those the new "my clothes".
- Each outfit can require a **minimum rank**. An outfit built on a male body only shows for male characters, and the
  same for female.

**For management** (members with the job's `canManage` permission, and staff):

- **Manage outfits** → create an outfit by **building it in the store** (nothing is paid) or from **the clothes you
  are wearing**.
- Edit the name and minimum rank, replace the clothes, or delete the outfit.
- Management cannot use blocked or exclusive pieces, or pieces restricted to other jobs. Staff can.
- The outfit limit per company is in Settings → Appearance → Outfit Wardrobes (60 by default).
- Staff can open any company's wardrobe anywhere with `/appearance_wardrobe <job>`.

## Admin Mode

Players with `whip_appearance.admin` see the **Admin** button on the store screen. The panel starts collapsed.

| Target | What you can set |
|---|---|
| Category (a whole tab) | everyone, restricted to jobs or characters, on duty only, or blocked. **Back to default** returns to `Config.CategoryDefaults` |
| Piece | the whole model or a single color; brands and company catalogs; who can buy it; or turn it into an **exclusive item** |
| Barber and clinic tab (Cut, Beard, Makeup, Face Features…) | who can change it in that store: everyone, restricted to jobs or characters, on duty only, or blocked |
| Haircut | who can get that haircut (per body); blocked haircuts disappear from the list |
| Tattoo body part | who can get tattoos there |
| Tattoos (batch) | click tattoo cards to pick them, then give them one price (empty: the body part's price) and one access rule |

**Exclusive items:** the piece becomes an inventory item with the piece's picture. Using the item puts the piece on,
and **Take the piece off** in its menu removes it. Give one to yourself from the panel, or hand them out like any
other item. Removing a tattoo is always allowed, whatever the rules.

## Director, Dungeon Mode and Scenarios

The cards are under the **Appearance** category in the Director.

| Card | What it does |
|---|---|
| Open Look Store | opens a clothing store, barber shop, clinic or tattoo studio for players wherever they are; the player or the house pays |
| Goal: Change Look | (Goals) the scenario continues when a player of the run buys in a store; optional GPS and time limit |
| Goal: Wear an Outfit | (Goals) the scenario continues when a player of the run, or every player, is wearing the outfit set in the card; optional GPS (nearest clothing store or the company's wardrobe) and time limit |
| Is Wearing Outfit? | goes Yes or No by what the players are wearing right now: the guard lets the uniform in |
| Wear Outfit | puts an outfit picked in the card on the players: a disguise that comes off when the run ends, or kept as their clothes |
| Wear Company Outfit | the same with an outfit from a company wardrobe (by name, or the first that fits) |
| Take Off Pieces | takes the chosen pieces off (mask, hat, glasses, earrings, vest, bag, accessories, watch, bracelet), for a while or for good |
| Restore Saved Look | removes disguises and pieces taken off: the saved look comes back |
| Open Outfit Wardrobe | opens a wardrobe for players wherever they are, with outfits made in the card for this mission (no job needed) or a company's outfits (by job key) |

**Mission wardrobes.** Open Outfit Wardrobe can hold its own outfits, made in the card: they exist only in that
mission, with no job behind them. Press **Pick outfit in the store**, build the outfit, press **Save outfit** and give
it a name (nothing is paid or saved). Players see those outfits in the wardrobe screen and wear one with 1 click: a
disguise that comes off when the run ends (**Back to my clothes** takes it off sooner), or kept as their clothes with
**Keep it**. A card that only has a job opens that company's wardrobe instead.

**Setting the outfit in a card.** Goal: Wear an Outfit and Is Wearing Outfit? take the outfit three ways:

- **Picked in this card:** press **Pick outfit in the store**, build the outfit and name it. An outfit fits only the
  body it was made on, so make one male and one female version to cover everyone. Any of them counts.
- **Any outfit of this mission's wardrobes:** any outfit of the Open Outfit Wardrobe cards of the same run counts.
  Build the outfits once, in the wardrobe card.
- **From a company wardrobe (job):** type the job key (e.g. `police`) and, optionally, the outfit's name. Empty name:
  any outfit of that wardrobe counts.

**What must match:** the main pieces (jacket, undershirt, pants and shoes) or every piece (masks, hats and
accessories too), and optionally the colors. Disguises put on by Wear Outfit count as worn.

**Keep it:** Open Outfit Wardrobe (mission outfits), Wear Outfit, Wear Company Outfit and Take Off Pieces have a
**Keep it** switch. Off, the change is a
disguise that comes off when the run ends. On, it is saved as the character's clothes, like clothes bought in a store.
In a builder's Test it is always a disguise.

**Dungeon Mode:** in the Object Viewer (G on a player), Dungeon Masters (`director.live`) and admins with `/w` on
get "Open Clothing Store / Barber Shop / Plastic Surgery / Tattoo Studio (free)", "Open their company Wardrobe
(free)" and "Restore saved look".

## Controls

| Action | Mouse and keyboard | Controller |
|---|---|---|
| Move between items | click | D-pad |
| Pick | click | A |
| Switch category | click the tab | LB / RB |
| Turn the character | drag, or Q / E | right stick |
| Zoom | mouse wheel | triggers |
| Pay in cash / by bank | Pay buttons | Y / X |
| Cancel | Esc | B |

Picking a clothing piece plays a try-on animation for that kind of piece.

## Commands and permissions

| Command | Who | What it does |
|---|---|---|
| `/appearance_wardrobe <job>` | staff (`whip_appearance.admin`) | opens any company's wardrobe wherever you are |
| `/appearance_anims` | developer tools on (`/w`) | checks in F8 that every try-on animation exists in this game |

| Permission | Given to | Allows |
|---|---|---|
| `whip_appearance.admin` | full admins, or anyone through the Player Manager | Admin Mode in stores, managing any wardrobe, the staff command |
| job permission `canManage` | company management (WHIP jobs) | managing their company's wardrobe outfits |

## Configuration

Most settings are edited in game in `/whip` → Settings → **Appearance** and survive updates of this resource:

| Group | Settings |
|---|---|
| Stores | positions, names, map icons and colors of every store; company store fields |
| Prices | per category of every store, tattoo body parts and tattoo removal |
| Outfit Wardrobes | wardrobe points and the outfit limit per company |

`config.lua` holds the defaults for those, plus a few values that are only set in the file:

| Key | What it does |
|---|---|
| `Config.UseRange` | how close a player must be to use a store |
| `Config.AllowBank` | lets players pay by bank |
| `Config.Camera` | camera distance and angle for each body part |
| `Config.Brands` | brand names, keywords and DLC collections used to give pieces their brands |
| `Config.MaskFix` | which masks shrink the head or keep the face |
| `Config.CategoryDefaults` | categories blocked by default (vests and decals) |
| `Config.Admin` | the admin permission and the weight of exclusive items |
| `Config.Wardrobe` | outfit limit and the job permission that manages wardrobes |

## Database

The resource creates these tables by itself on start (oxmysql, `CREATE TABLE IF NOT EXISTS`):

| Table | Holds |
|---|---|
| `whip_appearance_rules` | Admin Mode rules for pieces and colors, and exclusive items |
| `whip_appearance_categories` | Admin Mode rules for whole categories |
| `whip_appearance_tattoo_rules` | tattoo prices and access rules |
| `whip_appearance_outfits` | company wardrobe outfits |
| `whip_appearance_own` | each character's "my clothes" while wearing a company outfit |

Saved looks themselves stay where WHIP keeps them (the character's appearance).

## How saving works

WHIP has no server export to save an appearance, so a purchase works like this:

1. The server validates the requested look with WHIP's `SanitizeAppearance`, merges only the fields this store changes
   into the saved look and recomputes the price.
2. It charges the player (`ChargePlayer`) and asks the client to save through WHIP's own appearance event.
3. It checks that the character's saved appearance now matches. If it does not within 10 seconds, the player is
   refunded.

Nothing in whip_core is changed.

## Troubleshooting

| Problem | Fix |
|---|---|
| Console: `settings: ... is left off the page` | run `refresh`, then `restart whip_appearance` |
| No **Appearance** page in Settings | check the resource started after whip_core, and look for red lines in the console |
| `database setup failed` in the console | check oxmysql is running and connected; the resource needs `CREATE` and `ALTER` rights |
| Tattoos do not show or cannot be picked | restart whip_core first, then `restart whip_appearance` |
| A piece is missing from a store | it may be blocked, restricted or only in a company catalog: open Admin Mode on it |
| Animations do not play | turn on `/w` and run `/appearance_anims` to list the missing ones |
| Purchase refunded right after paying | the save did not reach the server: check F8 and the WHIP Monitor (`/whip` → System → Monitor) |

## License

whip_appearance is free software under the [GNU General Public License 3.0](LICENSE). You may use, change and share
it; if you share a changed version, share its source under the same license.

WHIP and whip_core belong to their author and are under their own license. This resource only uses WHIP through its
exports and its satellite helper and contains none of WHIP's files. "WHIP" is used here only to say what this
resource works with.
