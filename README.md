# astudios-skating (FMRP Fork)

Skateboarding activity script for FiveM, converted for **Qbox + ox_lib + ox_inventory**.

> Forked from [apx-studios/astudios-skating](https://github.com/apx-studios/astudios-skating) — original by Aqade_#1337

## What It Does

Use a skateboard item from your inventory to place a skateboard on the ground. Mount it and ride around the city with full physics — steering, jumping, ragdoll on collision. Use the item again to toggle it off, or press E near the board to pick it up with an animation.

## Changes From Original

- **Converted to Qbox + ox_inventory** — removed QBCore/ESX dual-framework branching
- **ox_inventory server export** for item use (replaces `CreateUseableItem`)
- **ox_lib** for notifications and model/anim loading
- **Eliminated 100% duplicated client code** — single clean implementation (~295 lines, down from ~365)
- **Auto-cleanup** on player death and resource restart
- **Toggle behavior** — use item to place, use again to despawn
- **Configurable** speed and jump height via `shared/config.lua`

## Dependencies

| Resource | Required |
|----------|----------|
| [ox_lib](https://github.com/overextended/ox_lib) | Yes |
| [ox_inventory](https://github.com/overextended/ox_inventory) | Yes |
| [qbx_core](https://github.com/Qbox-project/qbx_core) | Yes |

## Installation

### 1. Add the resource
Drop `astudios-skating` into your server resources folder.

### 2. Register the item
Add to `ox_inventory/data/items.lua`:
```lua
['skateboard'] = {
    label = 'Skateboard',
    weight = 3000,
    consume = 0,
    description = 'Use to place/pickup. G - Mount/Dismount | Space - Jump | E - Pick up',
    server = { export = 'astudios-skating.skateboard' },
},
```

### 3. Add the inventory image
Copy `assets/inventory_images/skateboard.png` to `ox_inventory/web/images/skateboard.png`.

### 4. Ensure load order
In your `server.cfg`, ensure `astudios-skating` starts after its dependencies:
```cfg
ensure ox_lib
ensure ox_inventory
ensure astudios-skating
```

### 5. Restart
Restart your server (or restart `ox_inventory` then `ensure astudios-skating`).

### 6. Give yourself a skateboard
```
/giveitem [id] skateboard 1
```

## Controls

| Key | Action |
|-----|--------|
| **Use item** | Place skateboard / Toggle off |
| **G** | Mount / Dismount board |
| **W/A/S/D** | Move / Steer |
| **Space** (hold & release) | Jump (charge for height) |
| **E** | Pick up skateboard (with animation) |

## Configuration

All tuning is in `shared/config.lua`:

```lua
Config.MaxSpeedKmh = 52            -- Max speed in km/h
Config.MaxJumpHeight = 6.5         -- Jump boost (6.5 = superhuman, ~2.0 = realistic)
Config.LoseConnectionDistance = 2.0 -- Auto-dismount distance from board
```

## Preview

Original demo (mechanics are the same): https://www.youtube.com/watch?v=sTfMHY3IFZY

## Credits

- **Original script**: [Apex Studios](https://github.com/apx-studios) (Aqade_#1337)
- **Qbox/ox conversion**: FruitMob RP
