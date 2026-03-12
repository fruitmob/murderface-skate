# astudios-skating (Qbox + ox Fork)

**Free, open-source skateboarding for FiveM** — drop in, configure, ride.

Converted for the **Qbox + ox_lib + ox_inventory** stack. 5-minute setup, zero escrow, zero dependencies you don't already have.

> Forked from [apx-studios/astudios-skating](https://github.com/apx-studios/astudios-skating) — original by Aqade_#1337

---

## Features

- **Use from inventory** — use item to ride, use again to dismount. Simple toggle.
- **Full physics** — WASD steering, charge-jump with Space, ragdoll on high-speed collisions
- **Clean integration** — ox_inventory client export, ox_lib notifications
- **Auto-cleanup** — board despawns on death, disconnect, or resource restart. No ghost entities.
- **Configurable** — speed and jump height in one config file
- **Lightweight** — ~270 lines total, no database, no polling, no bloat
- **Self-contained** — skateboard prop and invisible ped models included in `stream/`

## Quick Start

**1.** Clone or download into your resources:
```
git clone https://github.com/fruitmob/astudios-skating.git
```

**2.** Add the item to `ox_inventory/data/items.lua`:
```lua
['skateboard'] = {
    label = 'Skateboard',
    weight = 1000,
    stack = false,
    close = true,
    consume = 0,
    description = 'A well-worn skateboard. WASD to move, Space to jump.',
    client = { export = 'astudios-skating.skateboard' },
},
```

**3.** Copy `assets/inventory_images/skateboard.png` to `ox_inventory/web/images/skateboard.png`

**4.** Add to `server.cfg`:
```cfg
ensure astudios-skating
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

Controls are shown via notification when you mount the board.

## Configuration

Everything tunable lives in `shared/config.lua`:

```lua
Config.MaxSpeedKmh = 52            -- Max speed in km/h (default: 52)
Config.MaxJumpHeight = 6.5         -- Jump boost (6.5 = superhuman, ~2.0 = realistic)
```

## How It Works

The skateboard uses a hidden BMX bicycle for physics, with a visible skateboard prop attached to it. An invisible ped drives the BMX while your player character is attached on top with a skating animation. This gives you full vehicle physics (momentum, gravity, collisions) while looking like you're skating.

### Models

The resource streams two models in `stream/`:
- `taymckenzienz_skateboard01.ydr` — the visible skateboard prop (by TayMcKenzieNZ)
- `p_defilied_ragdoll_01_s.ydr` — invisible driver ped

The BMX model is vanilla GTA5 and doesn't need streaming.

## Dependencies

| Resource | Link |
|----------|------|
| ox_lib | [overextended/ox_lib](https://github.com/overextended/ox_lib) |
| ox_inventory | [overextended/ox_inventory](https://github.com/overextended/ox_inventory) |

Works with Qbox (qbx_core) or any framework that uses ox_lib + ox_inventory.

## What Changed in v2.0.0

- **Fixed: item use did nothing** — switched from `server` export to `client` export (ox_inventory's `useSlot()` never initiated the server callback chain for items without a `client` table)
- **Fixed: infinite hang on invalid models** — added `IsModelValid()` pre-checks and timeouts on all model/entity loading
- **Fixed: missing skateboard model** — bundled `taymckenzienz_skateboard01.ydr` in `stream/` (the original conversion never included a skateboard prop)
- **Cleaned up** — removed debug prints, simplified server script
- Self-contained: no longer depends on external resources for the skateboard prop model

## Preview

Original demo (core mechanics are the same): https://www.youtube.com/watch?v=sTfMHY3IFZY

## Credits

- **Original script**: [Apex Studios](https://github.com/apx-studios) (Aqade_#1337)
- **Skateboard model**: [TayMcKenzieNZ](https://github.com/TayMcKenzieNZ)
- **Qbox/ox conversion + v2.0 fixes**: [FruitMob RP](https://github.com/fruitmob)

## License

Same as the original — free to use and modify.
