# Dungeon Crawler

A modern spiritual successor to *Untold Legends: The Warrior's Code*.
3D isometric action RPG with deep character builds, shapeshifting combat,
and tight 20-minute dungeon runs.

See [GAME_ANALYSIS_AND_PLAN.md](GAME_ANALYSIS_AND_PLAN.md) for the full design
document and development roadmap.

## Tech

- **Engine:** Godot 4.5+ (Forward+ renderer)
- **Language:** GDScript (with optional C# for hot paths later)
- **Target:** PC (Windows, Linux, Mac), Steam Deck

## Running the Project

1. Install [Godot 4.5+](https://godotengine.org/download).
2. Open the Godot editor and import this folder (`project.godot`).
3. Press **F5** (or the Play button) to run.

The default scene is `scenes/world/TestArena.tscn` — a placeholder
arena for testing movement and camera.

## Current Phase

**Phase 1 — Vertical Slice (Week 1: Foundation)**

| Status | Feature |
|--------|---------|
| Done | Project setup, autoloads (GameState, EventBus) |
| Done | 3D isometric camera (orthographic, fixed angle, smooth follow) |
| Done | Player CharacterBody3D with placeholder capsule mesh |
| Done | Camera-relative WASD movement, gravity, smooth rotation |
| Done | Dodge roll with cooldown (stub iframes) |
| Done | Attack input stubs (light/heavy, combo counter) |
| Done | Test arena: floor, walls, pillars, lighting |
| Next | Hit detection (HitBox / HurtBox nodes) |
| Next | First enemy with state machine |
| Next | Damage numbers + HP bar UI |

## Controls

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| Move | WASD | Left Stick |
| Light Attack | Left Mouse | West (X / Square) |
| Heavy Attack | Right Mouse | North (Y / Triangle) |
| Dodge | Space | South (A / Cross) |
| Skill 1 | Q | — (TBD) |
| Skill 2 | E | — |
| Skill 3 | R | — |
| Skill 4 | F | — |
| Shapeshift | X | — |
| Interact | F | — |
| Inventory | I | — |

## Folder Structure

```
.
├── project.godot              Godot project config
├── icon.svg                   Project icon
├── README.md                  This file
├── GAME_ANALYSIS_AND_PLAN.md  Full design doc + roadmap
├── assets/                    Sprites, audio, fonts (empty for now)
├── scenes/
│   ├── player/Player.tscn     Player CharacterBody3D
│   └── world/TestArena.tscn   Phase 1 test arena (main scene)
├── scripts/
│   ├── autoload/              Global singletons
│   │   ├── GameState.gd
│   │   └── EventBus.gd
│   ├── player/
│   │   └── PlayerController.gd
│   └── world/
│       └── IsometricCamera.gd
└── data/                      Item/skill/enemy resources (empty for now)
```

## Collision Layers

| Layer | Name | Purpose |
|-------|------|---------|
| 1 | World | Static geometry (floor, walls) |
| 2 | Player | Player body |
| 3 | Enemy | Enemy bodies |
| 4 | PlayerHitbox | Damage dealt by player |
| 5 | EnemyHitbox | Damage dealt by enemies |
| 6 | Interactable | NPCs, doors, chests |
| 7 | Pickup | Gold, loot, essence |

## Development Workflow

1. Open the Godot editor.
2. Run with **F5**.
3. Use **F8** to step / **F7** to stop.
4. The remote debugger and profiler are essential — use them often.
5. Commit small, focused changes.

## Roadmap Snapshot

See full plan in `GAME_ANALYSIS_AND_PLAN.md`.

- **Phase 1 (Weeks 1-6):** Vertical slice — one class, one dungeon
- **Phase 2 (Weeks 7-18):** Core game — five classes, three acts
- **Phase 3 (Weeks 19-26):** Polish, balance, co-op, endgame
