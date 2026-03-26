# Tower Defense — Game Design Spec

## Overview

A **defense strategy game** built with **Godot 4.x + GDScript**. The player deploys troops on an open battlefield to defend their base against waves of enemies. Top-down perspective, cartoon art style, campaign progression with unlockable units.

**Core fantasy:** You're a commander deploying troops to hold the line against increasingly dangerous enemy waves. Every unit placement is a tactical decision.

## Technology

- **Engine:** Godot 4.x
- **Language:** GDScript
- **Platform:** Desktop (Windows/macOS/Linux)
- **Resolution:** 1920x1080 base, scalable

## Core Gameplay

### Battlefield

- **Top-down view** — the camera looks down at the field from above
- **Open field** — no lanes or fixed paths. Troops and enemies move freely in 2D space
- **Base on the left** — a fortified structure the player must protect
- **Enemies enter from the right** — from varying positions along the right edge
- **Deployment zone** — the leftmost 25% of the battlefield (after the base). Troops can only be placed within this area. Highlighted with a subtle dashed border during troop placement
- **Terrain features** — rocks, trees, and bushes act as obstacles that block movement, creating natural chokepoints and tactical positioning opportunities

### Resources

| Resource | Generation | Usage |
|----------|-----------|-------|
| **Gold** | Passive: 5 gold/sec + bounty on enemy kill | Basic troops (Soldier, Archer) |
| **Gems** | Awarded on wave completion + rare enemy drops | Advanced troops (Mage) |

**Gold bounties per enemy type:** Goblin: 5, Orc: 15, Goblin Archer: 10.

Gold passive rate and starting resources are configurable per level in the level data file. Default starting resources: 100 Gold, 0 Gems.

Gold provides a constant flow so the player always has options. Gems are scarce to force strategic decisions about when to deploy advanced units.

### Troops (V1)

Units are deployed by selecting a troop type from the bottom bar, then clicking a position within the deployment zone. Once placed, troops act autonomously.

| Troop | Cost | HP | Damage | Attack Speed | Move Speed | Range | Behavior |
|-------|------|-----|--------|-------------|------------|-------|----------|
| **Soldier** | 30 Gold | 100 | 10 | 1.0s | 80 | 30 (melee) | Advances toward nearest enemy, engages in close combat. |
| **Archer** | 50 Gold | 50 | 8 | 0.8s | 60 | 200 | Advances until within firing range, then stops and attacks nearest enemy. |
| **Mage** | 2 Gems | 40 | 15 (AoE r=60) | 1.5s | 50 | 180 | Advances slightly, then attacks from range with area-of-effect spells. |

All stats are starting values subject to balance tuning. Speeds are in pixels/sec. Range and AoE radius in pixels.

**Unlock progression:**
- Level 1: Soldier only
- Level 2: Soldier + Archer
- Level 3+: Soldier + Archer + Mage

### Enemies (V1)

| Enemy | HP | Damage | Attack Speed | Move Speed | Range | Base Damage | Bounty |
|-------|----|--------|-------------|------------|-------|-------------|--------|
| **Goblin** | 40 | 5 | 1.0s | 120 | 30 (melee) | 10 | 5 Gold |
| **Orc** | 150 | 12 | 1.5s | 50 | 30 (melee) | 30 | 15 Gold |
| **Goblin Archer** | 60 | 7 | 1.0s | 80 | 150 | 10 | 10 Gold |

All stats are starting values subject to balance tuning.

All enemies advance toward the player's base (left side). When an enemy reaches the base, it deals its **Base Damage** as a one-time hit, then is removed from the field.

### Unit AI (Autonomous Behavior)

- **Soldiers:** Move toward the nearest enemy. When within melee range (30px), stop and attack. If the target dies, find the next nearest enemy.
- **Archers:** Move toward the nearest enemy until within firing range (200px). Stop and shoot. Prioritize closest target. If all enemies move out of range, advance to close the gap.
- **Mages:** Similar to archers but with area damage. Target the enemy position that maximizes enemies within the AoE radius (60px). If no cluster, target the nearest enemy.
- **All enemies:** Move toward the base (left). If a player troop enters within 80px of the enemy, the enemy engages that troop instead of continuing toward the base. Resumes moving toward the base if the troop dies.

### Unit Collision

Units have CharacterBody2D collision. Player troops and enemies block each other — they cannot pass through one another. This means soldiers effectively form a wall that enemies must fight through. Allies can overlap with each other to avoid pathfinding gridlock.

### Wave System

Each level consists of multiple waves. Between waves there is a **5-second pause** for the player to deploy new troops. Surviving troops persist between waves — they stay on the field where they are. Troops cannot be moved or recalled once placed (no repositioning in V1).

**Wave flow within a level:**
1. Wave announcement — "Wave 2 — 8 enemies" banner
2. Enemies spawn from the right edge at various positions
3. Player deploys troops in real-time during combat
4. All enemies in the wave are eliminated → brief pause
5. Resource bonus awarded
6. Next wave begins
7. After final wave is cleared → level complete

**Wave data format (JSON/Resource):**
```json
{
  "level_name": "Dark Forest",
  "base_hp": 100,
  "starting_resources": {"gold": 100, "gems": 0},
  "gold_per_second": 5,
  "available_troops": ["soldier", "archer"],
  "waves": [
    {
      "enemies": [
        {"type": "goblin", "count": 5, "spawn_delay": 1.0, "spawn_y_range": [0.2, 0.8]},
        {"type": "orc", "count": 1, "spawn_delay": 3.0, "spawn_y_range": [0.4, 0.6]}
      ],
      "reward": {"gold": 50, "gems": 1}
    }
  ]
}
```

### Win/Lose Conditions

- **Victory:** Survive all waves in the level (all enemies eliminated)
- **Defeat:** Base HP reaches 0. Base HP defaults to 100, configurable per level in the level data file.

## Campaign Structure

- **Level select screen** — linear map with nodes per level
- Completed levels shown in green, next available level highlighted, rest locked
- Each level has a unique battlefield layout (different terrain features) and predefined waves
- V1 scope: **5 levels** with increasing difficulty
  - Level 1: Tutorial — only goblins, only soldiers
  - Level 2: Introduces archers (player) and orc enemies
  - Level 3: Introduces mage, goblin archers appear
  - Level 4: Mixed enemy compositions, tighter resource economy
  - Level 5: Large waves, all enemy types, demanding positioning

## Screens

| Screen | Description |
|--------|-------------|
| **Main Menu** | Game logo, "Play" button, "Quit" button |
| **Level Select** | Linear campaign map with level nodes |
| **Battle** | Main gameplay — battlefield + HUD |
| **Level Result** | Victory: "Level Complete!" + rewards + next level button. Defeat: "Defeat" + retry button |

## HUD Layout (Battle Screen)

- **Top bar:** Gold count (left), Gems count (left), Level name (center), Wave counter (right)
- **Bottom bar:** Troop deployment buttons with cost labels, locked troops shown with lock icon, speed controls (1x/2x), pause button
- **In-field:** Base HP bar on the base structure, enemy HP bars above enemies, wave announcement banners

### Speed Controls

- **1x** — normal game speed (default)
- **2x** — doubles the simulation speed (all movement, attack timers, spawn timers, gold generation run at 2x)
- **Pause** — freezes the simulation. The player can still select troops and plan, but cannot deploy during pause.
- The player can deploy troops during 1x and 2x speeds.

### Save System

Campaign progress (completed levels, unlocked troops) is saved to a local file via Godot's `user://` directory using a simple JSON format. Progress is saved automatically after completing or failing a level. No manual save/load UI needed for V1.

## Architecture (Godot)

### Scene Tree

```
Main (Node)
├── GameManager (Autoload Singleton)
│   - Global state: resources, current level, unlocked troops, campaign progress
│
├── BattleScene
│   ├── Battlefield (Node2D)
│   │   ├── Background (terrain, grass, decorations)
│   │   ├── Obstacles (rocks, trees — StaticBody2D with collision)
│   │   ├── Base (player's base — Area2D for enemy detection)
│   │   ├── DeploymentZone (Area2D — valid placement area)
│   │   ├── PlayerUnits (Node2D container)
│   │   ├── EnemyUnits (Node2D container)
│   │   └── Projectiles (Node2D container)
│   ├── HUD (CanvasLayer)
│   │   ├── TopBar (resources, level info, wave counter)
│   │   ├── BottomBar (troop buttons, speed controls)
│   │   └── WaveBanner (announcement overlay)
│   └── WaveManager (Node — controls wave timing and spawning)
│
├── LevelSelectScene
│   └── LevelMap (level nodes, progression state)
│
└── MainMenuScene
```

### Reusable Entity Scenes

- `BaseUnit.tscn` — shared base: HP, movement, attack stats, death handling
  - `Soldier.tscn` — extends BaseUnit, melee behavior
  - `Archer.tscn` — extends BaseUnit, ranged behavior
  - `Mage.tscn` — extends BaseUnit, area attack behavior
- `BaseEnemy.tscn` — shared base: HP, movement toward base, damage-on-arrival
  - `Goblin.tscn` — extends BaseEnemy, fast/fragile
  - `Orc.tscn` — extends BaseEnemy, slow/tanky
  - `GoblinArcher.tscn` — extends BaseEnemy, ranged behavior

### Communication (Signals)

- `WaveManager`: emits `wave_started(wave_number)`, `wave_completed(wave_number)`, `all_waves_cleared`
- Units: emit `unit_died(unit)`, `unit_attacked(target, damage)`
- `Base`: emits `base_damaged(amount)`, `base_destroyed`
- `GameManager` listens to coordinate state updates (resources, progression)

### Level Data

Levels are defined as Godot Resources or JSON files, not hardcoded. Each level specifies:
- Battlefield layout (terrain features, obstacle positions)
- Wave composition (enemy types, counts, timing, spawn positions)
- Available troops
- Starting resources
- Wave rewards

## Future Enhancements (Post-V1)

These are explicitly **out of scope** for V1 but noted for future consideration:

- Troop upgrades (level up individual troop types)
- Special abilities (cooldown-based powers like bomb, heal)
- Boss enemies at end of levels
- Star/scoring system (1-3 stars per level)
- More troop types and enemy types
- Sound effects and music
- Particle effects for attacks and deaths
