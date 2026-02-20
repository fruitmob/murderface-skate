# murderface-skate (Qbox + ox Fork)

**Free, open-source skateboarding for FiveM** — drop in, configure, ride.

Converted for the **Qbox + ox_lib + ox_inventory** stack. 5-minute setup, zero escrow, zero dependencies you don't already have.

> Forked from [apx-studios/astudios-skating](https://github.com/apx-studios/astudios-skating) — original by Aqade_#1337

---

## Features

- **Use from inventory** — toggle on to ride, toggle off to stop. Simple.
- **Full physics** — WASD steering, charge-jump with Space, ragdoll on high-speed collisions
- **Clean integration** — ox_inventory item with tooltip controls, ox_lib notifications
- **Auto-cleanup** — board despawns on death, disconnect, or resource restart. No ghost entities.
- **Race-condition safe** — busy-lock prevents double-mount, warp timeout with abort cleanup
- **Ped-friendly** — invisible BMX has no-collision with all nearby peds (players, pets, NPCs)
- **Configurable** — speed, jump height, and controls all in one config file
- **Lightweight** — no database, no polling, no bloat

## Quick Start

**1.** Clone or download into your resources:
```
git clone https://github.com/fruitmob/murderface-skate.git
```

**2.** Add the item to `ox_inventory/data/items.lua`:
```lua
['skateboard'] = {
    label = 'Skateboard',
    weight = 3000,
    consume = 0,
    description = 'Use to place/pickup. WASD - Move | Space - Jump',
    server = { export = 'murderface-skate.skateboard' },
},
```

**3.** Copy `assets/inventory_images/skateboard.png` to `ox_inventory/web/images/skateboard.png`

**4.** Add to `server.cfg`:
```cfg
ensure murderface-skate
```

**5.** Restart, give yourself a board: `/giveitem [id] skateboard 1`

That's it. No SQL, no extra dependencies, no config rabbit holes.

---

## Controls

| Key | Action |
|-----|--------|
| **Use item** | Spawn board and ride / Dismount and despawn |
| **W/A/S/D** | Move / Steer |
| **Space** (hold & release) | Jump — hold longer for more height |

Wipe out at high speed? Board despawns automatically — just use the item again.

Controls are shown in the item tooltip when you hover over it in inventory.

## Configuration

Everything tunable lives in `shared/config.lua`:

```lua
Config.MaxSpeedKmh = 52            -- Max speed in km/h (default: 52)
Config.MaxJumpHeight = 6.5         -- Jump boost (6.5 = superhuman, ~2.0 = realistic)
```

## Dependencies

| Resource | Link |
|----------|------|
| ox_lib | [overextended/ox_lib](https://github.com/overextended/ox_lib) |
| ox_inventory | [overextended/ox_inventory](https://github.com/overextended/ox_inventory) |
| qbx_core | [Qbox-project/qbx_core](https://github.com/Qbox-project/qbx_core) |

If you're running Qbox with the ox stack, you already have everything you need.

## What Changed From the Original

- Removed QBCore/ESX dual-framework code (was 100% copy-pasted twice)
- Replaced `QBCore.Functions.CreateUseableItem` with ox_inventory server export
- Added ox_lib for notifications and asset loading
- Simplified to instant mount/dismount — use item to ride, use again to stop
- Auto-cleanup on wipeout, death, and resource restart
- Busy-lock to prevent race conditions on rapid toggle
- No-collision with all nearby peds (players, pets, NPCs)
- Warp timeout with abort cleanup to prevent infinite hangs
- Grace timer skips false ragdoll triggers while physics settle

## Preview

Original demo (core mechanics are the same): https://www.youtube.com/watch?v=sTfMHY3IFZY

## Credits

- **Original script**: [Apex Studios](https://github.com/apx-studios) (Aqade_#1337)
- **Qbox/ox conversion & enhancements**: [FruitMob RP](https://github.com/fruitmob)

## License

Same as the original — free to use and modify.
