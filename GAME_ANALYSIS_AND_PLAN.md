# Untold Legends: The Warrior's Code — Extended Game Analysis & Development Plan

*Comprehensive design document and implementation roadmap for a spiritual successor.*

---

## TABLE OF CONTENTS

**PART 1 — Game Analysis**
1. Overview & Market Context
2. Setting, Lore & Story Architecture
3. The Five Classes (Deep Dive)
4. Attribute System & Stat Formulas
5. Skill & Magic System (Full Trees)
6. Combat System (Mechanics, Frame Data, Formulas)
7. Shapeshifting (Changeling Form) — Full System
8. Enemy Design & Complete Bestiary
9. Boss Design — All 12 Encounters
10. Loot, Item Generation & Affix System
11. Currency, Economy & Vendor System
12. Status Effects & Crowd Control
13. World Structure & Game Flow
14. Quest System & Mission Design
15. Progression Loop & Pacing
16. Multiplayer Architecture
17. UI / UX / HUD Design
18. Audio Design Principles
19. Difficulty Curve & Tuning
20. Strengths, Weaknesses & Design Lessons

**PART 2 — Development Plan**
21. Vision & Pillars
22. Target Audience & Market Positioning
23. Technology Stack (Detailed)
24. Core Systems Architecture
25. Phase 1 — Vertical Slice (detailed)
26. Phase 2 — Core Game (detailed)
27. Phase 3 — Polish & Expansion (detailed)
28. Phase 4 — Post-Launch & Live Ops
29. Data Architecture & Schemas
30. Algorithms (Dungeon Gen, AI, Loot)
31. Code Examples & Stubs
32. File / Folder Structure
33. Testing & QA Plan
34. Performance Targets
35. Accessibility Features
36. Localization Plan
37. Risk Assessment & Mitigation
38. Marketing & Launch Strategy (Light)
39. Solo Developer Priority Order
40. Timeline Summary

---

# PART 1 — GAME ANALYSIS

---

## 1. Overview & Market Context

**Untold Legends: The Warrior's Code** (Sony Online Entertainment / A2M, March 14, 2006) is an
isometric action RPG hack-and-slash dungeon crawler for the PlayStation Portable. It is the
second entry in the Untold Legends series, improving on *Brotherhood of the Blade* (2005) with
five redesigned character classes, an upgraded combat engine, 12 boss battles, 45+ explorable
areas, 40+ monster types, and enhanced ad-hoc multiplayer.

The game sits squarely in the **Diablo lineage**: enter a dungeon, kill everything, collect
loot, level up, repeat — but tuned for short portable play sessions with snappy load times and
self-contained level chunks of 15–30 minutes.

### Competitive Landscape

| Comparable Game | Year | Platform | Why Relevant |
|-----------------|------|----------|--------------|
| Diablo II | 2000 | PC | Foundational ARPG loop |
| Champions of Norrath | 2004 | PS2 | Console-focused ARPG, multiplayer |
| Baldur's Gate: Dark Alliance | 2001 | PS2 | Console hack-and-slash |
| Untold Legends: Brotherhood of the Blade | 2005 | PSP | Direct predecessor |
| Untold Legends: Dark Kingdom | 2006 | PS3 | Series third entry |
| Phantasy Star Portable | 2008 | PSP | Portable ARPG/co-op |
| Diablo III | 2012 | PC/Console | Genre evolution reference |
| Path of Exile | 2013 | PC | Deep itemization reference |
| Diablo IV | 2023 | PC/Console | Modern ARPG benchmark |
| Vampire Survivors | 2022 | All | Modern wave-survival relative |

### Critical Reception (Original)

- **Aggregate scores:** Metacritic ~70/100. Praised for combat snap, criticized for repetition.
- **Common complaints:** Repetitive level art, shallow quests, thin story, low itemization depth.
- **Common praise:** Solid combat, class variety, shapeshifting flair, portable pacing.

These reviews are the **most valuable design data** — they identify exactly which areas a
successor must improve.

---

## 2. Setting, Lore & Story Architecture

### World

The world is a dark fantasy continent on the brink of corruption. A magical blight is spreading
from a hidden source, twisting nature and reanimating the dead. The Changeling people — an
ancient race of shapeshifters bound by the **Warrior's Code** — stand as the world's last
organized defense. The player character is a young initiate of this order.

### The Changelings

- Ancient race capable of borrowing forms from creatures they defeat.
- The shapeshifting gift is rationed by **Essence**: spiritual energy extracted from worthy
  foes.
- Society is martial, monastic, ascetic. The Monastery is the order's headquarters.
- The **Code** has tenets: defend the innocent, do not kill in cold blood, prove worth through
  martial trials, never abandon a comrade.

### Factions

| Faction | Disposition | Description |
|---------|-------------|-------------|
| The Warrior's Code (Changelings) | Player | Monastic warrior order |
| The Blighted | Hostile | Corrupted humans, beasts, and elementals |
| The Forgotten | Hostile | Undead remnants of an ancient war |
| Lizardfolk Clans | Mixed | Swamp dwellers, sometimes allies, often hostile |
| Free Cities | Neutral | Merchants, refugees, quest-givers |
| The Conclave | Mysterious | Robed mystics, possibly behind the blight |

### Three-Act Story Arc

**Act 1 — The Initiate**
- Player is sworn into the Order.
- First missions: clear corrupted outskirts, save villagers, recover stolen relics.
- Climax: discover an ancient seal has been broken in the forest.
- Boss: **Treant Lord Korgath** — corrupted forest guardian.

**Act 2 — The Descent**
- Push into ruins and underground territories.
- Investigate the Conclave's involvement.
- Subplot: ally with a Lizardfolk chief.
- Climax: uncover the true enemy is a Changeling traitor named **Veroth**.
- Boss: **Veroth, the First Betrayer** — corrupted Changeling using forbidden forms.

**Act 3 — The Forge of the World**
- Assault on the volcanic stronghold.
- Discover the source: an ancient elemental being chained beneath the world.
- Climax: choice — destroy the being (good ending) or absorb its power (dark ending, unlocks
  Hard Mode).
- Boss: **Ashar, the Primordial Flame** — multi-phase elemental titan.

### Narrative Delivery

- Voiced or text-only NPC dialogue at the Monastery
- Pre-mission briefings (still images + narration)
- In-dungeon discoveries (lore books, audio logs from murdered scholars)
- Post-mission reflection by the Monastery elder
- Optional codex unlocks as enemies are defeated

---

## 3. The Five Classes (Deep Dive)

Each class has **defined identity** through stats, abilities, animations, and even sound design.

### 3.1 Guardian — The Tank

**Lore:** Veterans of front-line defense. Wear plate armor; wield two-handed weapons or
sword-and-shield.

**Stats (Level 1 starting):**
- HP: 120 | Mana: 30
- STR: 12 | AGI: 6 | INT: 4 | STA: 10
- Move speed: 90% of base
- Attack speed: 85% of base
- Armor: high

**Weapons:** Greatswords, warhammers, battleaxes, shields, one-handed maces.

**Identity:** Slow, immovable, devastating in melee. Best class for new players. Excellent
soloist. Wants to brawl in the middle of the pack.

**Signature playstyle:** Open with Warcry → wade in → Earthquake AoE → finish stunned enemies
with charged attack → Stone Skin on incoming boss attack.

---

### 3.2 Mercenary — The All-Rounder

**Lore:** Sellswords who joined the Order for redemption. Pragmatic, adaptive, dual-wield.

**Stats (Level 1 starting):**
- HP: 90 | Mana: 50
- STR: 9 | AGI: 9 | INT: 7 | STA: 7
- Move speed: 100%
- Attack speed: 100%

**Weapons:** Dual blades, hand crossbow off-hand, throwing knives, scimitars.

**Identity:** Jack-of-all-trades. Has access to light magic AND solid melee. Best class for
versatile players. Weakest peak-output but most adaptable.

**Signature playstyle:** Bleed off-hand throws → close gap → dual-blade combo → magic finisher.

---

### 3.3 Disciple — The Mage

**Lore:** Mystic monks who shapeshifted into pure magical conduits during their training.

**Stats (Level 1 starting):**
- HP: 70 | Mana: 100
- STR: 4 | AGI: 7 | INT: 14 | STA: 5
- Move speed: 95%
- Attack speed: 90% (slow staff swings)

**Weapons:** Staves, wands, off-hand focus crystals, ritual daggers.

**Identity:** Glass cannon. Devastating AoE. Resource-management focused. Hardest class to
master; requires positioning skill.

**Signature playstyle:** Mana Shield up → Chain Lightning into pack → Fireball stragglers →
Arcane Blast to create space → repeat.

---

### 3.4 Prowler — The Assassin

**Lore:** Stealth specialists who study enemies before striking. Often outcasts.

**Stats (Level 1 starting):**
- HP: 80 | Mana: 40
- STR: 8 | AGI: 14 | INT: 5 | STA: 5
- Move speed: 115%
- Attack speed: 130%

**Weapons:** Twin daggers, claws, short swords, garrote (special).

**Identity:** Fast, deadly, fragile. Hit-and-run gameplay. Massive burst from stealth or behind.

**Signature playstyle:** Vanish → Shadow Step behind boss → Frenzy → unload combo → Vanish
again before retaliation.

---

### 3.5 Scout — The Archer

**Lore:** Forest-dwelling Changelings who specialized in ranged combat and tracking.

**Stats (Level 1 starting):**
- HP: 85 | Mana: 50
- STR: 6 | AGI: 13 | INT: 7 | STA: 6
- Move speed: 110%
- Attack speed: 105%

**Weapons:** Longbows, shortbows, crossbows, throwing axes.

**Identity:** Kiter. Wants distance, wants to position. Devastating if uninterrupted.

**Signature playstyle:** Trap chokepoint → Multishot incoming pack → Ensnare lead enemy →
Eagle Eye crit boss → kite to corner if rushed.

---

### Class Comparison Table

| Metric | Guardian | Mercenary | Disciple | Prowler | Scout |
|--------|----------|-----------|----------|---------|-------|
| HP rank | 1st | 3rd | 5th | 4th | 4th |
| Damage type | Phys | Phys+Mag | Magic | Phys | Phys |
| Range | Melee | Melee/Med | Long | Melee | Long |
| Mobility | Low | Med | Low | Very High | High |
| Difficulty | Easy | Medium | Hard | Hard | Medium |
| Co-op role | Tank | Flex | Backline DPS | Burst DPS | Backline DPS |

---

## 4. Attribute System & Stat Formulas

### Core Attributes

| Attribute | Primary Effect | Secondary Effects |
|-----------|----------------|-------------------|
| **Strength (STR)** | +1 melee damage per point | +0.5 carry weight, +0.2% physical skill scaling |
| **Agility (AGI)** | +1% attack speed per 2 points | +0.5% dodge chance, +1% ranged damage per point |
| **Intelligence (INT)** | +2 max mana per point | +1% spell damage, -0.1% skill cooldown per point |
| **Stamina (STA)** | +10 max HP per point | +0.5% HP regen, +1% poison/stun resistance |

### Derived Stats — Formulas

```
Max HP        = 50 + (STA * 10) + (Level * 8) + EquipmentHP
Max Mana      = 20 + (INT * 2) + (Level * 3) + EquipmentMana
Melee Damage  = WeaponBase * (1 + STR * 0.02) * (1 + SkillBonus)
Ranged Damage = WeaponBase * (1 + AGI * 0.025) * (1 + SkillBonus)
Spell Damage  = SpellBase * (1 + INT * 0.03) * (1 + SkillBonus)
Attack Speed  = BaseAS * (1 + AGI * 0.005)
Dodge Chance  = min(60%, AGI * 0.005)
Crit Chance   = 5% + (AGI * 0.002) + EquipmentCrit
Crit Damage   = 150% + EquipmentCritMult
HP Regen/sec  = (Max HP * 0.005) + (STA * 0.05)
Mana Regen/sec = (Max Mana * 0.01) + (INT * 0.04)
```

### Attribute Points per Level

- Base: 3 points per level
- Level 10, 20, 30, 40, 50: +1 bonus point ("milestone level")
- Level cap: 50

### XP Curve

```
XP to next level = 100 * (level ^ 1.7)

Level 1 → 2: 100 XP
Level 5 → 6: ~1,100 XP
Level 10 → 11: ~5,000 XP
Level 25 → 26: ~32,000 XP
Level 50 cap: ~330,000 XP total
```

This curve front-loads progression so early-game feels rewarding and back-loads so endgame
progression takes effort.

### Damage Reduction (Armor)

```
Damage Reduction % = Armor / (Armor + 100 + Level * 10)
```

This curve diminishes returns. At level 20, 200 armor = ~40% reduction; 400 armor = ~57%.
Caps near 75% to prevent invulnerability.

---

## 5. Skill & Magic System (Full Trees)

Each class has **12 skill categories**. Each skill has **5 tiers** of upgrades. Skills are
independently purchasable — no prerequisite gating between categories — but each tier within a
skill requires the previous tier and a minimum character level.

**Skill point economy:**
- 1 skill point per level (50 total)
- Tier 1 costs 1 point; Tier 2 costs 1; Tier 3 costs 2; Tier 4 costs 2; Tier 5 costs 3
- Full mastery of one skill: 9 points. Player cannot max every skill (12 × 9 = 108 > 50)
- Forces meaningful build choices

### 5.1 Guardian — Full Skill List

| # | Skill | Type | Effect |
|---|-------|------|--------|
| 1 | Warcry | Active | AoE buff: +20–40% damage to self & allies, 15s |
| 2 | Earthquake | Active | Ground slam, AoE knockdown, scaling damage |
| 3 | Stone Skin | Active | 30–60% damage reduction, 8s, 30s cooldown |
| 4 | Frostbite | Active | Cold AoE, slow 50%, dot |
| 5 | Salubrity | Passive | +0.5–2.5% HP regen/sec |
| 6 | Iron Will | Passive | +5–25% stun/fear resistance |
| 7 | Cleave | Active | Wide arc swing, hits up to 5 enemies |
| 8 | Shield Bash | Active | Stun 2s + small damage (requires shield) |
| 9 | Bulwark | Passive | +10–50 armor per tier |
| 10 | Last Stand | Active | At <25% HP, become invulnerable 5s, 2min CD |
| 11 | Taunt | Active | Force enemies in radius to target you, 5s |
| 12 | Avatar of War | Passive | +1–5% all damage per allied unit nearby |

### 5.2 Mercenary — Full Skill List

| # | Skill | Type | Effect |
|---|-------|------|--------|
| 1 | Dual Strike | Active | Both weapons attack simultaneously |
| 2 | Whirlwind | Active | Spinning AoE, channel up to 4s |
| 3 | Throw Knife | Active | Ranged projectile, bleed DoT |
| 4 | Parry | Active | 1s perfect block window, counter-attack |
| 5 | Ambidexterity | Passive | Off-hand damage 70% → 100% over tiers |
| 6 | Battle Trance | Active | +50% attack speed, 8s |
| 7 | Tactical Strike | Active | Guaranteed crit on next hit |
| 8 | Sidestep | Active | Short directional dodge with iframes |
| 9 | Veteran | Passive | +10–30% XP gain per tier |
| 10 | Arcane Blade | Active | Imbue weapon with elemental damage 30s |
| 11 | Adrenaline | Active | Restore 30% HP and Mana, 60s CD |
| 12 | Combat Mastery | Passive | +1–5% all damage per tier |

### 5.3 Disciple — Full Skill List

| # | Skill | Type | Effect |
|---|-------|------|--------|
| 1 | Fireball | Active | Projectile, AoE splash damage |
| 2 | Chain Lightning | Active | Bounces to 3–7 targets |
| 3 | Frost Nova | Active | Centered AoE, freeze 3s |
| 4 | Mana Shield | Active | 50–100% damage absorbed by mana |
| 5 | Summon Wisp | Active | Conjure ally that fires bolts, 60s duration |
| 6 | Teleport | Active | Short-range blink, 8s CD |
| 7 | Arcane Blast | Active | Knockback cone, 2s stun |
| 8 | Curse of Weakness | Active | -30% target damage, 12s |
| 9 | Meditation | Passive | +0.5–2.5% mana regen/sec |
| 10 | Arcane Lore | Passive | +5–25% spell damage |
| 11 | Time Warp | Active | Slow enemies 50% in zone, 6s, 60s CD |
| 12 | Pyroclasm | Active | Massive fire AoE (ultimate), 3min CD |

### 5.4 Prowler — Full Skill List

| # | Skill | Type | Effect |
|---|-------|------|--------|
| 1 | Shadow Step | Active | Teleport behind target, guaranteed crit next hit |
| 2 | Frenzy | Active | Stacking attack speed buff per kill |
| 3 | Bleed | Passive | All hits inflict 5–25% weapon-dmg DoT, 5s |
| 4 | Vanish | Active | Instant stealth, 4s, breaks aggro |
| 5 | Poison Strike | Active | Apply poison, DoT for 8s |
| 6 | Velocity | Passive | +5–25% move + attack speed |
| 7 | Backstab | Passive | +50–200% damage when hitting from behind |
| 8 | Caltrops | Active | Drop area trap, slow + damage |
| 9 | Death Mark | Active | Mark target; bonus damage from all sources |
| 10 | Twin Fang | Active | Quick two-hit combo, ignore armor |
| 11 | Smoke Bomb | Active | AoE blind 4s, escape utility |
| 12 | Reaper's Embrace | Passive | +5–25% damage per missing 10% target HP |

### 5.5 Scout — Full Skill List

| # | Skill | Type | Effect |
|---|-------|------|--------|
| 1 | Multishot | Active | Cone of 3–7 arrows |
| 2 | Snipe | Active | Charged shot, very high damage |
| 3 | Trap | Active | Place ground trap, triggers on enemy |
| 4 | Eagle Eye | Passive | +5–25% ranged crit chance |
| 5 | Ensnare | Active | Root target 3s |
| 6 | Volley | Active | Rain arrows in target area, channel |
| 7 | Smoke Arrow | Active | AoE blind |
| 8 | Falcon Companion | Active | Summon falcon, harasses enemies |
| 9 | Camouflage | Passive | Become harder to detect at distance |
| 10 | Piercing Shot | Passive | Arrows pierce through enemies |
| 11 | Hunter's Focus | Active | +50% damage to single target, 10s |
| 12 | Storm of Arrows | Active | Ultimate: massive AoE rain, 3min CD |

---

## 6. Combat System (Mechanics, Frame Data, Formulas)

### Combat Pillars

1. **Snap** — every input must trigger a visible response within 1–2 frames.
2. **Read** — enemies must telegraph attacks clearly enough that skilled players can react.
3. **Reward** — successful reads should produce Attack of Opportunity windows.
4. **Flow** — combat should string together: dodge → hit → skill → combo, with momentum.

### Attack Types & Frame Data (target 60fps)

| Attack | Startup | Active | Recovery | Cancellable Into |
|--------|---------|--------|----------|------------------|
| Light 1 | 6f | 4f | 12f | Light 2, Skill, Dodge |
| Light 2 | 8f | 5f | 14f | Light 3, Skill, Dodge |
| Light 3 (finisher) | 12f | 8f | 24f | Skill (after frame 20) |
| Heavy | 18f | 10f | 30f | Skill (after frame 25) |
| Charged | 30f charge | 12f | 32f | None |
| Dodge Roll | 4f | 16f (iframes 5–14) | 8f | Attack |

### Damage Formula

```
FinalDamage =
    BaseWeaponDamage
    * (1 + StatScaling)
    * (1 + SkillMultiplier)
    * (1 + ElementalBonus)
    * CritMultiplier
    * (1 - TargetDamageReduction)
    * (1 + Vulnerability)   // e.g. backstab, marked, stunned target

CritMultiplier  = if crit, (1.5 + EquipmentCritMult), else 1
Vulnerability   = sum of applicable multipliers (capped at +200%)
```

### Attack of Opportunity (AoO)

An AoO window opens when an enemy enters a vulnerable state:

- Knockdown (1.5s window)
- Stun (full duration window)
- Stagger (0.6s window after taking heavy hit)
- Animation lock (final 20% of enemy attack recovery)
- Back-turn (when enemy is targeting another ally)

During an AoO window, the next player attack:
- Deals +50% damage
- Auto-crits if Light/Heavy
- Triggers a unique animation (kneel-stab, executioner-swing, etc.)
- Generates 2x normal Essence on kill

This rewards aggression timing rather than just stat-checking.

### Combo Counter

A non-displayed background counter:
- Hits within 1.5s of last hit increment combo.
- Each tier of combo (5/10/20/50 hits) grants increasing damage buff (+5%/+10%/+20%/+40%).
- Breaks on taking damage or being interrupted.
- Counter visible only at higher tiers (intentional reward, not stress).

### Knockback / Pushback

Some attacks apply knockback measured in "tiles." Heavy enemies (bosses, large) have knockback
resistance:
```
ActualKnockback = AttackKnockback * (1 - TargetResistance)
```
Knockback into walls causes stagger; into hazards triggers environmental damage.

---

## 7. Shapeshifting (Changeling Form) — Full System

### Essence Resource

- Max Essence: 100 (cap can be increased via passive skill)
- Generated by killing enemies:
  - Trash: 1 Essence
  - Elite: 5–10 Essence
  - Boss: 30–50 Essence
- Lost when player dies (50% retained)
- Carried between dungeons

### Activation

- Requires minimum 25 Essence to transform.
- Duration: Essence drains at 5/sec; player chooses when to drop early.
- 30-second cooldown after dropping form.

### Form Effects

| Stat | Modifier |
|------|----------|
| Max HP | +100% |
| Damage | +75% |
| Armor | +50% |
| Move Speed | +20% |
| Skill access | Replaced by 3 monster-form abilities |
| Damage taken | -25% |

### Forms (One Per Class)

| Class | Form Name | Style | Abilities |
|-------|-----------|-------|-----------|
| Guardian | **Earth Titan** | Slow, devastating | Ground Pound, Boulder Throw, Roar (mass fear) |
| Mercenary | **Werewolf** | Bestial striker | Lunge, Howl (buff), Frenzied Mauling |
| Disciple | **Lich** | Floating caster | Soul Drain, Death Bolt, Wraith Form (phase through walls 3s) |
| Prowler | **Shadow Demon** | Teleport assassin | Shadow Burst, Phantom Strike, Consume Soul (heal on kill) |
| Scout | **Storm Harpy** | Aerial archer | Wind Slash, Tempest (AoE), Dive Strike |

### Strategic Use

- Save for boss fights or elite packs.
- Use during near-death (50% retained essence on death is significant).
- Some skills synergize: Disciple's Curse of Weakness + Lich's Death Bolt = +60% damage spike.

---

## 8. Enemy Design & Complete Bestiary

### Enemy Archetypes (AI Behavior Templates)

| Archetype | Behavior | Examples |
|-----------|----------|----------|
| **Rusher** | Charges directly, melee | Goblin Warrior, Wolf, Lizardman |
| **Tank** | Slow, high HP, melee | Cave Troll, Lava Golem |
| **Ranger** | Maintains distance, kites | Goblin Archer, Skeleton Bowman |
| **Caster** | AoE spells, stays back | Bog Shaman, Lich Apprentice |
| **Support** | Heals/buffs allies | Cult Priest, Wisp |
| **Ambusher** | Hides until proximity | Spider, Lurker |
| **Berserker** | Rages at low HP | Orc Brute, Werewolf Pup |
| **Swarmer** | Weak alone, deadly in groups | Imp, Rat Swarm |
| **Summoner** | Conjures minions | Necromancer, Witch |
| **Elite** | Buffed variant of base type | Champion Goblin, Veteran Skeleton |

### Full Bestiary by Zone

**Act 1 — Forest / Outskirts (12 enemies)**

| Name | Type | HP@L5 | Special |
|------|------|-------|---------|
| Goblin Scavenger | Rusher | 40 | Drops gold extra |
| Goblin Archer | Ranger | 35 | Burning arrow chance |
| Dire Wolf | Rusher | 55 | Pack bonus damage |
| Treant Sapling | Tank | 90 | Root attack |
| Bandit Marauder | Rusher | 50 | Steals gold on hit |
| Bandit Crossbow | Ranger | 45 | Pierce shot |
| Forest Spider | Ambusher | 30 | Poison |
| Wisp | Caster | 25 | Heals allies |
| Boar | Rusher | 70 | Charge knockdown |
| Corrupted Stag | Tank | 110 | Antler gore |
| Cultist Initiate | Caster | 40 | Curse spell |
| **Forest Witch (Elite)** | Summoner | 200 | Summons wolves |

**Act 2 — Ruins / Underground (14 enemies)**

| Name | Type | HP@L15 | Special |
|------|------|--------|---------|
| Skeleton Warrior | Rusher | 120 | Reassembles once |
| Skeleton Archer | Ranger | 100 | Bone arrows |
| Cave Troll | Tank | 280 | Regen 5%/s |
| Animated Statue | Tank | 350 | Petrify gaze |
| Crypt Spider | Ambusher | 90 | Web (root) |
| Ghoul | Rusher | 140 | Disease DoT |
| Specter | Caster | 110 | Phase through walls |
| Lich Apprentice | Caster | 150 | Frost Bolt |
| Bone Golem | Tank | 420 | Hurls bone shards |
| Cult Acolyte | Support | 95 | Group heal |
| Shadow Stalker | Ambusher | 130 | Invisible until 5m |
| Tomb Guardian | Tank | 380 | Sword + shield, blocks |
| Necromancer | Summoner | 200 | Raises 2 skeletons |
| **Ossuary Lord (Elite)** | Summoner | 600 | Mass raise undead |

**Act 3 — Volcanic / Stronghold (16 enemies)**

| Name | Type | HP@L25 | Special |
|------|------|--------|---------|
| Fire Imp | Swarmer | 80 | Suicide explosion |
| Lava Golem | Tank | 600 | Fire aura |
| Salamander | Rusher | 250 | Fire breath |
| Hellhound | Rusher | 280 | Burning bite |
| Flame Cultist | Caster | 200 | Fireball |
| Magma Elemental | Caster | 320 | Lava eruption |
| Obsidian Warrior | Tank | 550 | Black armor (high DR) |
| Brimstone Drake | Ranger | 240 | Cone of fire |
| Sulfur Bat | Swarmer | 60 | Confuse on hit |
| Volcanic Wraith | Ambusher | 220 | Burns through walls |
| Iron Cultist | Tank | 480 | Chains pull |
| Fire Witch | Summoner | 350 | Summons imps |
| Magma Spider | Ambusher | 180 | Acid web |
| Forge Master | Caster | 400 | Buffs others |
| Demon Brute | Berserker | 500 | Enrage at 40% |
| **Inferno Champion (Elite)** | Tank | 1200 | Boss-tier mini |

---

## 9. Boss Design — All 12 Encounters

Each boss has: unique lair, 2–3 phases, telegraphed mechanics, AoO windows, environmental
interaction, and a guaranteed legendary drop.

### Act 1 Bosses

**1. Korgath, the Treant Lord** (Forest, Mid-Act 1)
- Phases: 2
- Mechanics: Slam (ground crack), Root Snare (ranged), Phase 2 spawns saplings
- Lair: Forest clearing, destructible trees offer cover
- AoO window: 1.2s after slam recovery
- Drop: *Heartwood Cudgel* (legendary mace)

**2. Veshka, Witch of the Bog** (Forest/Swamp, End Act 1)
- Phases: 3
- Mechanics: Curses, summons spiders, transforms into raven for Phase 3
- Lair: Swamp altar with poison pools
- Drop: *Veshka's Hex Ring* (mana regen)

### Act 2 Bosses

**3. The Bone Sovereign** (Ruins, Early Act 2)
- Phases: 2
- Mechanics: Hurls bones, summons skeleton waves, ground-pound
- Lair: Throne room with collapsible pillars (player can drop on boss)
- Drop: *Crown of the Dead* (helm)

**4. Saargolt, the Hollow King** (Catacombs, Mid Act 2)
- Phases: 3
- Mechanics: Teleports, summons three duplicates (must hit real one), shadow beam
- Drop: *Shadowfang* (legendary sword)

**5. The Conclave Speaker** (Underground Temple, Late Act 2)
- Phases: 2
- Mechanics: Lightning storm, time stop, banishes player to mirror dimension briefly
- Drop: *Speaker's Tome* (off-hand focus)

**6. Veroth, the First Betrayer** (Inner Sanctum, End Act 2)
- Phases: 4 (he uses three Changeling forms then his true form)
- Mechanics: Cycles through Werewolf, Lich, Shadow Demon abilities, then own form
- Drop: *Code Breaker* (legendary blade)

### Act 3 Bosses

**7. The Forge Smith** (Volcanic Outskirts, Early Act 3)
- Phases: 2
- Mechanics: Hammers ground (lava cracks), summons obsidian warriors
- Drop: *Smith's Anvil* (heavy hammer)

**8. Brimscale, the Drake Mother** (Lava Caves, Mid Act 3)
- Phases: 3
- Mechanics: Flight phase (only Scout/ranged effective), fire breath, summons drakes
- Drop: *Drake Scale Armor*

**9. The Iron Lord** (Iron Fortress, Mid Act 3)
- Phases: 2
- Mechanics: Chain pull, ground stomp, calls reinforcements
- Drop: *Lord's Mantle* (shoulders / armor slot)

**10. The Twin Furies** (Twin chamber, Late Act 3)
- Phases: 2 (must kill both within 5s, else they revive each other)
- Mechanics: Cross-attacks, mirror dance
- Drop: *Twin Fury Daggers* (dual wield set)

**11. Ash, the Hollow Prophet** (Penultimate, Late Act 3)
- Phases: 3
- Mechanics: Prophecies (predicted attacks player must dodge to specific safe spots)
- Drop: *Prophet's Mask*

**12. Ashar, the Primordial Flame** (Final Boss)
- Phases: 5
- Mechanics:
  - Phase 1: humanoid form, sword combat
  - Phase 2: rises, fire AoEs, summon imps
  - Phase 3: titan form, slow ground slams
  - Phase 4: explodes, become floating heart (only spell damage)
  - Phase 5: enrage timer, must finish in 60s
- Lair: Volcanic crucible with shifting platforms
- Drop: *Heart of Ashar* (legendary, build-defining)

---

## 10. Loot, Item Generation & Affix System

### Item Tiers (Rarity)

| Tier | Color | Affixes | Drop Rate |
|------|-------|---------|-----------|
| Common | White | 0 | 60% |
| Uncommon | Green | 1–2 | 25% |
| Rare | Blue | 3–4 | 10% |
| Epic | Purple | 4–5 + 1 special | 4% |
| Legendary | Orange | Fixed unique kit | 1% |
| Set | Yellow-green | Bonus when matched | ~0.5% (boss-locked) |

### Item Slots

1. Main Weapon
2. Off-Hand (shield, second weapon, focus, quiver)
3. Helm
4. Chest Armor
5. Gloves
6. Boots
7. Belt
8. Amulet
9. Ring 1
10. Ring 2

**Note:** This is significantly expanded from the original (which had only 3 slots). This is
one of the most important improvements for build diversity.

### Affix System

**Prefix examples (offensive):**
- "Burning" — +X fire damage
- "Frozen" — chance to slow
- "Vampiric" — X% lifesteal
- "Vicious" — +X% crit damage
- "Piercing" — ignores X armor

**Suffix examples (defensive/utility):**
- "of the Bear" — +X armor
- "of Haste" — +X% attack speed
- "of the Sage" — +X mana
- "of Resistance" — +X% to one element
- "of the Phoenix" — revive once per dungeon

### Generation Algorithm

```
function GenerateItem(item_level, monster_difficulty):
    base = pick_base_type(item_level)
    rarity = roll_rarity(magic_find_bonus, monster_difficulty)

    item = {
        base: base,
        rarity: rarity,
        affixes: [],
    }

    if rarity >= UNCOMMON:
        item.affixes.append(roll_prefix(item_level))
    if rarity >= RARE:
        item.affixes.append(roll_suffix(item_level))
    if rarity == RARE:
        # Add 1-2 more affixes
        for _ in range(random(1, 2)):
            item.affixes.append(roll_random_affix(item_level))
    if rarity == EPIC:
        item.affixes.extend(roll_multiple_affixes(item_level, 4))
        item.special = roll_special_property()
    if rarity == LEGENDARY:
        item = pick_legendary_template(item_level)

    return item
```

### Magic Find Stat

A separate hidden stat that increases rare+ drop chances:
- Base 0%
- Equipment can add up to 200% combined
- Boosts rarity rolls, doesn't increase drop frequency itself

### Set Items

Sets of 3–4 items (e.g., "Guardian's Bulwark Set"). Equipping multiple pieces unlocks bonuses:
- 2 pieces: +50 armor
- 3 pieces: Stone Skin lasts 50% longer
- 4 pieces: New ability — "Aegis" (party-wide damage shield)

Sets are class-flavored but not class-locked.

---

## 11. Currency, Economy & Vendor System

### Currencies

| Currency | Source | Use |
|----------|--------|-----|
| **Gold** | All enemies, breakables, vendors | Buy gear, repair, teleport |
| **Essence** | Killed enemies | Shapeshifting fuel |
| **Soul Shards** | Bosses, rare drops | Salvage / craft (Phase 3) |
| **Honor Tokens** | Quest rewards | Cosmetics, special vendor |

### Vendor Types

| Vendor | Sells |
|--------|-------|
| **Armorer** | Helms, armor, boots, gloves, shields |
| **Weaponsmith** | All weapon types |
| **Apothecary** | Potions, antidotes, scrolls |
| **Jeweler** | Rings, amulets, gems |
| **Honor Quartermaster** | Cosmetics, dyes, mounts (cosmetic only) |
| **Forge Master** | (Phase 3) Crafting / upgrading |

### Refresh Mechanic

The original game's "leave and re-enter" stock refresh is preserved but tuned:
- Stock refreshes every 5 minutes of real time, OR after a dungeon run
- Manual refresh costs 100 gold (after the first free refresh)
- Reduces grind frustration while preserving the satisfying gamble

### Item Pricing Curve

```
Buy Price  = item_level * rarity_multiplier * base_value * 10
Sell Price = Buy Price * 0.25
```

| Rarity | Multiplier |
|--------|-----------|
| Common | 1 |
| Uncommon | 2 |
| Rare | 5 |
| Epic | 12 |
| Legendary | 30 |

### Gold Drop Tuning

Gold dropped per kill scales with:
- Enemy level (1–3 gold per level on average)
- "Gold Find" bonus from gear
- Difficulty modifier (Hard +25%, Hell +50%)

Target: a smart player should be able to afford 1–2 vendor purchases per dungeon.

---

## 12. Status Effects & Crowd Control

### Damage-Over-Time (DoT)

| Effect | Source | Tick | Duration |
|--------|--------|------|----------|
| Burn | Fire damage | Every 1s, 30% base | 5s |
| Bleed | Physical, Prowler | Every 0.5s, 15% base | 6s |
| Poison | Toxic | Every 1s, 25% base | 8s |
| Disease | Necrotic | Every 2s, 50% base, also -healing | 10s |
| Curse | Shadow | -damage, -armor | 12s |

### Crowd Control

| CC | Effect | Default Duration | Immunity After |
|----|--------|------------------|----------------|
| Stun | Cannot act | 1–3s | 8s |
| Freeze | Cannot act + brittle (+25% dmg taken) | 2s | 10s |
| Root | Cannot move | 2–4s | 6s |
| Slow | -50% movement | 4s | 0 (refreshes) |
| Knockdown | Prone | 1.5s | 6s |
| Knockback | Pushed back | Instant | None |
| Fear | Run away | 3s | 12s |
| Blind | Can't hit ranged | 4s | 8s |
| Silence | No skills | 5s | 10s |
| Petrify | Cannot act, +50% dmg taken | 2s | 15s |
| Charm | Attacks allies | 3s | 15s |

### Diminishing Returns

Repeated CC from same player on same target:
- 1st: 100% duration
- 2nd: 50% duration
- 3rd: 25% duration
- 4th+: immune for 10s

Prevents perma-stun cheese while rewarding CC variety.

### Status Stacking

Some statuses stack independently (e.g., 5 stacks of Bleed = 5x DoT). Visible as numbered
icons on enemy nameplates.

---

## 13. World Structure & Game Flow

### Hub: The Monastery

A persistent, evolving space:

**Phase 1 (Act 1 start):**
- Few NPCs, basic vendors, sparse decor

**Phase 2 (Act 2):**
- Refugees arrive, new vendors set up shop
- Tactics Hall opens (skill respec NPC)
- Library opens (lore codex)

**Phase 3 (Act 3):**
- Allied factions camp outside
- Forge opens (crafting)
- Champion's Arena unlocks (combat trials for cosmetics)

**Hub interactions:**
- Talk to Quest Giver → mission selection
- Visit any vendor
- Skill respec (costs gold, scales with level)
- Codex / Bestiary
- Stash (shared storage across characters)
- Mailbox (multiplayer items, gifts)
- Mirror (cosmetic / appearance edit)

### World Map

After Act 1 intro, the player has a parchment-style world map:
- Discovered zones glow
- Locked zones show as silhouettes
- Teleport between any unlocked zone (small gold cost or free at hub)
- Some zones reveal optional sub-zones after first clear

### Dungeon Structure

Each dungeon is composed of:
- 1 entry room (Safe Zone — last save point)
- 3–7 procedurally connected combat rooms
- 1–2 treasure rooms (off main path, optional)
- 1 mini-boss room (mid-dungeon, optional but rewarding)
- 1 boss room (gated by objective or all-rooms-cleared)
- 1 exit room (back to world map or next zone)

Layout is procedurally generated but **rooms themselves are hand-built templates**. This
balances variety with quality.

---

## 14. Quest System & Mission Design

### Quest Types

| Type | Description | Example |
|------|-------------|---------|
| **Slay** | Kill X enemies or specific boss | "Slay the Treant Lord" |
| **Fetch** | Retrieve N items | "Recover 3 Bone Relics" |
| **Escort** | Protect NPC from A to B | "Escort the Sage to the ruins" |
| **Defend** | Survive waves at a point | "Defend the shrine for 3 minutes" |
| **Race** | Reach a point before timer | "Reach the altar before the seal closes" |
| **Stealth** | Avoid detection through area | "Sneak past the guard patrols" |
| **Puzzle** | Solve environmental challenge | "Light the four braziers in order" |
| **Boss** | Defeat named foe | Most act finales |

By including **defend, race, stealth, puzzle** in addition to the original's slay/fetch/escort,
quest variety is significantly improved — directly addressing the main critique of the
original.

### Quest State Machine

```
INACTIVE → AVAILABLE → ACCEPTED → IN_PROGRESS
                                       ↓
                                 [Objectives]
                                       ↓
                                  COMPLETED → REWARDED → ARCHIVED
                                       ↓
                                     FAILED → ARCHIVED
```

### Quest Tracking

- HUD: active objective at top-right
- Map: waypoint marker
- Compass: directional indicator
- Quest log: review accepted quests

### Side Quests

15+ optional missions, unlocked by exploration:
- "The Lost Caravan" — find missing merchant in forest
- "The Hermit's Bargain" — recover his stolen books from goblins
- "Whisper of the Deep" — investigate strange voice in catacombs
- Etc.

Side quests reward Honor Tokens, cosmetics, and occasionally unique items not available
elsewhere.

---

## 15. Progression Loop & Pacing

### Macro Loop (Entire Campaign)

```
Tutorial → Act 1 (5h) → Act 2 (7h) → Act 3 (8h) → Endgame
                                                       ↓
                            New Game+ (Hard / Hell difficulties)
                                                       ↓
                            Endless Dungeons (procedural)
```

Target campaign length: **20–25 hours main story**, 50+ hours including endgame.

### Micro Loop (One Dungeon)

```
0:00  Enter dungeon from hub
0:01  First combat encounter
0:03  Find first treasure chest
0:08  Mid-dungeon checkpoint / mini-boss
0:15  Final boss encounter
0:20  Loot review, return to hub
0:22  Vendor, level up
0:25  Next dungeon
```

A run should reliably complete in **15–25 minutes**.

### Reward Cadence

| Frequency | Reward Type |
|-----------|-------------|
| Every kill | Gold, XP |
| Every 30s combat | Small loot drop |
| Every 5 min | Notable item (uncommon+) |
| Every dungeon | Level-up (early game) |
| Every dungeon | Skill point usable |
| Every act | Major story beat + epic gear |
| Every 5 levels | Visual gear upgrade noticeable |

### Difficulty Modes

| Mode | Unlock | Modifiers |
|------|--------|-----------|
| Normal | Default | Standard |
| Hard | Complete Normal | +50% HP, +30% damage, +25% gold/loot |
| Hell | Complete Hard | +200% HP, +60% damage, +50% loot, elite affixes |
| Nightmare | Complete Hell | +500% HP, +100% dmg, all enemies elite, exclusive drops |

### Endgame Content

- **Endless Dungeon** — procedural floors, increases difficulty per floor
- **Boss Rush** — back-to-back all 12 bosses
- **Daily Quest** — fixed seed, leaderboards
- **Champion's Arena** — wave survival, cosmetic rewards
- **Hidden Areas** — secret zones unlocked at high difficulty

---

## 16. Multiplayer Architecture

### Modes

1. **Local Co-op** — 2 players, split-screen, same PC, two controllers
2. **Online Co-op** — up to 4 players, dedicated server or peer-to-peer
3. **Asynchronous** — daily quest leaderboards, shared loot trades

### Networking Approach

For online co-op:
- **Authoritative host**: one player's machine runs simulation
- Clients send inputs; host syncs world state
- Suitable for small co-op (latency tolerance higher than competitive)

Alternative if budget allows: dedicated lightweight server using Godot's high-level multiplayer
API or a Node.js relay.

### Scaling

- HP per enemy: ×(1 + 0.6 * additional_players)
- Number of enemies: ×(1 + 0.3 * additional_players)
- Loot: instanced per player (no contention, no greed)
- XP: full XP to all players
- Boss HP: ×(1 + 0.8 * additional_players)

### Joinability

- Players can join in-progress sessions if host allows
- Public games shown in lobby browser
- Friend invites direct
- Mid-dungeon joining: spawn at last room cleared

---

## 17. UI / UX / HUD Design

### HUD Elements (Always Visible)

```
┌─────────────────────────────────────────┐
│ [HP|====] [MP|===] [ES|==]  [Mini-Map] │ Top bar
│                                          │
│                                          │
│                                          │
│                                          │
│             [game viewport]              │
│                                          │
│                                          │
│                                          │
│ [Q][W][E][R]  [1][2][3]  [LVL bar____]  │ Bottom bar
└─────────────────────────────────────────┘
```

- **HP bar** — red, with shield overlay when buffed
- **MP bar** — blue
- **Essence meter** — purple, pulses when full
- **Mini-map** — top-right, expandable to full
- **Skill bar** — 4 hotkeys (Q/W/E/R or LB/RB/LT/RT)
- **Item quick-slots** — 1/2/3 keys (potions, scrolls)
- **XP bar** — bottom, fills as level progresses
- **Quest tracker** — top-right under minimap

### Menus

| Menu | Triggered By | Contents |
|------|--------------|----------|
| Inventory | I or Y button | Grid, equipment slots, stat sheet |
| Skills | K | Skill tree per category, point allocation |
| Map | M | Full screen map, fast-travel |
| Quest Log | L | Active, completed, lore entries |
| Settings | Esc | Audio, graphics, controls |
| Codex | B | Bestiary, NPC bios, lore |

### UX Principles

- **One-button core combat** — primary attack is always one button
- **Hold-to-charge** — heavy attacks via hold instead of separate button
- **Radial menus** — for potion selection on controller
- **Item comparison** — hovering an item shows side-by-side stats with equipped
- **Color coding** — green stat = upgrade, red = downgrade
- **Tutorial prompts** — first-time-only popups, dismissible
- **No menu pause online** — inventory accessible without pause in multiplayer

---

## 18. Audio Design Principles

### Music

- One ambient track per major zone (5 zones × ~3 min loops)
- Combat layer overlays (intensifies during fights)
- Boss music: unique track per major boss
- Hub theme: calm, melodic, evolves with story progression

### Sound Effects

| Category | Examples | Priority |
|----------|----------|----------|
| Player attacks | Weapon swings, impacts, charged release | High |
| Player skills | Distinct per skill, magical layer | High |
| Enemy attacks | Telegraph sounds (audio tell) | Critical |
| Enemy deaths | Variety by type, satisfying | High |
| Loot pickup | Cha-ching variants per rarity | High |
| Footsteps | Different per surface | Medium |
| Ambient | Wind, fire crackle, dripping water | Medium |
| UI | Menu select, equip, buy | Low |

### Audio Tells

Each enemy attack must have a distinct **windup sound** so players can react without visual
focus. Example:
- Cave Troll roar → ground slam incoming
- Lich Apprentice incantation → frost bolt
- Skeleton Archer string-pull → arrow
- This is critical for accessibility AND combat depth.

### Voice Acting (Optional)

- Main NPC quest givers (5 voiced)
- Player class one-liners (battle cries, level-up)
- Narrator for act transitions
- Cost-saving option: text + ambient grunts only

---

## 19. Difficulty Curve & Tuning

### Player Power Growth

```
Level 1:  Power = 1.0  (baseline)
Level 10: Power ≈ 2.5
Level 25: Power ≈ 6.0
Level 50: Power ≈ 15.0 (10-15× starting)
```

### Enemy Power Curve

Normal mode enemies scale slightly behind player power:
- Player wins straight fights if equipped properly
- Boss fights should require active skill use
- Hell mode flips this: enemies slightly ahead, player must outplay

### Gear Power Multiplier

- Level 1 starter gear: +10% to base
- Level 25 rare gear: +200%
- Level 50 legendary set: +600%

This means a well-geared L50 player is ~15× starter power purely from gear, in addition to
stat growth.

### Encounter Pacing

- Trash packs: 3–6 enemies, killable in 10–20s
- Elite pack: 1 elite + 3 trash, ~45s fight
- Mini-boss: ~90s
- Final boss: 3–5 minutes
- Total active combat per dungeon: ~12 minutes out of 20

### Death Penalty

- Lose 10% gold carried
- Lose 50% accumulated Essence
- Respawn at last checkpoint (start of room) — not full restart
- No XP loss (avoids punishment spiral)

This is forgiving by ARPG standards. Punishing-mode optional for Hell+.

---

## 20. Strengths, Weaknesses & Design Lessons

### What the Original Did Well

1. Tight, immediate combat
2. Shapeshifting "panic button" mechanic
3. Class identity through visual + animation differences
4. Portable session pacing
5. Merchant refresh as informal farming
6. Attack of Opportunity rewarding timing reads
7. Item drops felt rewarding moment-to-moment

### What the Original Did Poorly (Things to FIX in Successor)

| Issue | Solution |
|-------|----------|
| Visual repetition across dungeons | More biome variety, modular tilesets, palette shifts per sub-zone |
| Shallow quest variety | 8 quest types instead of 3 |
| Only 3 equipment slots | 10 equipment slots |
| No crafting / itemization depth | Affix system + Forge + Set items |
| Thin story | Stronger writing, voiced cinematics, branching ending |
| Static hub | Evolving Monastery that visually changes per act |
| Flat mid-game difficulty | Active difficulty scaling per zone, optional elite affixes |
| No endgame | Endless Dungeon, Boss Rush, Daily, Arena |
| No build flexibility | Skill respec NPC, more skills per class |
| Limited multiplayer | Online + local, friends list, persistent stash |

---

---

# PART 2 — DEVELOPMENT PLAN

---

## 21. Vision & Pillars

### Vision Statement

> Build a modern spiritual successor to *Untold Legends: The Warrior's Code* — a fast-paced
> isometric action RPG with deep character builds, a satisfying loot loop, transformative
> shapeshifting combat, and bite-sized dungeon sessions that respect the player's time.

### Pillars (Non-Negotiables)

1. **Combat Snap** — every input feels responsive within 2 frames.
2. **Build Depth** — meaningful choices, viable diversity, no single dominant build.
3. **Loot Joy** — every drop has a chance of being exciting; new gear feels new.
4. **Session Respect** — 20-minute dungeons; quit anytime; save anytime in hub.
5. **Class Identity** — five classes play *completely* differently, not reskins.
6. **Co-op First-Class** — multiplayer is designed in, not bolted on.

### Anti-Pillars (What We Will NOT Do)

- No microtransactions for gameplay advantage
- No always-online requirement
- No grind for grind's sake (Diablo Immortal-style)
- No procedural-only content — hand-crafted rooms behind procedural layouts
- No pre-order incentives or paid betas
- No real-money trading

---

## 22. Target Audience & Market Positioning

### Audience

- **Primary:** ARPG fans (Diablo, Path of Exile, Last Epoch players)
- **Secondary:** Souls-lite fans seeking less punishing pace
- **Tertiary:** Co-op couch players seeking longer-form game
- **Age:** 18–45, predominantly 25–40
- **Platform:** PC primary (Steam), Switch/PSP-spiritual port secondary

### Differentiation

| Competitor | Their Strength | Our Counter |
|-----------|----------------|-------------|
| Diablo IV | AAA polish | Niche, focused, no live-service treadmill |
| Path of Exile | Build complexity | More approachable, faster moment-to-moment |
| Last Epoch | Skill mod system | Stronger narrative, distinct classes |
| Vampire Survivors | Wave survival | Deep itemization, persistent character |

### Positioning Statement

*"For ARPG players who miss the focused, hand-crafted feel of Diablo II and Champions of
Norrath, this is a 20-hour campaign with deep classes, transformative shapeshifting, and
satisfying loot — without the live-service treadmill."*

---

## 23. Technology Stack (Detailed)

### Engine Choice: Godot 4

**Why Godot:**
- Free and open-source (no royalties)
- Native isometric / 2D support (TileMap, Y-sort, Light2D)
- GDScript fast iteration, similar enough to Python
- C# option for performance-critical code
- Built-in multiplayer API (high-level)
- Cross-platform export (Windows, Mac, Linux, mobile)
- Solid community, free assets, free tutorials

**Alternatives considered:**
- Unity: solid but licensing concerns since 2023 fiasco
- Unreal: overkill for 2D ARPG
- Custom Python+Pygame: too much foundational work
- Bevy (Rust): exciting but immature for production

### Language Strategy

- **Primary: GDScript** for game logic, scenes, UI
- **Secondary: C#** for hot loops (damage calc, pathfinding) if needed
- **No: rust/wasm/etc.** — adds complexity without proportional benefit

### Key Libraries / Plugins

| Need | Solution |
|------|----------|
| Pathfinding | Godot built-in AStarGrid2D |
| Behavior trees (AI) | LimboAI plugin (free) |
| Save/load | Custom + Godot Resource serialization |
| Dialogue | Dialogic plugin (free) |
| Visual scripting (designer-friendly) | Native node graph |
| Particle effects | GPUParticles2D built-in |
| Lighting | Light2D built-in |

### Asset Pipeline

- **Sprites:** Aseprite for pixel art OR Spine for skeletal animation
- **Audio:** REAPER or Audacity, Bfxr for placeholder SFX, Bosca Ceoil for music
- **Source control:** Git + Git LFS for binaries
- **Asset organization:** strict folder hierarchy enforced by lint

### Build & Distribution

- Steam Pipe for Steam
- Itch.io for direct
- GOG potentially post-launch
- CI: GitHub Actions for automated builds per push

---

## 24. Core Systems Architecture

```
┌──────────────────────────────────────────────────────┐
│                      GAME ROOT                        │
└──────────────────────────────────────────────────────┘
              │
    ┌─────────┼──────────┬─────────┬──────────┬───────────┐
    │         │          │         │          │           │
  World    Player     Combat    Systems    UI         Multi
    │         │          │         │          │           │
    ├─Dungeon │          ├─Damage  ├─Loot    ├─HUD       ├─Lobby
    ├─HubTown ├─Class    ├─HitDet  ├─Quest   ├─Inv       ├─NetSync
    ├─WorldMap├─Attr     ├─CCMgr   ├─Save    ├─Map       └─Replicate
    └─Camera  ├─Skill    ├─AoO     ├─Audio   ├─Menu
              ├─Shape    └─Status  ├─Settings└─Codex
              ├─Inv               └─Codex
              └─Stats
```

### System Responsibilities

- **PlayerController** — input → movement, attack triggers
- **AttributeSystem** — stat calculation, derived values
- **SkillSystem** — skill cooldowns, mana costs, skill execution
- **ShapeShiftSystem** — Essence mgmt, transformation, form abilities
- **CombatManager** — damage calc, hit registration, AoO detection
- **EnemyAI** — state machine + behavior tree per archetype
- **LootSystem** — drop tables, item generation, magic find
- **QuestSystem** — quest state, objectives, rewards
- **DungeonGenerator** — procedural assembly from templates
- **SaveSystem** — serialize/deserialize state to JSON or Resource
- **AudioManager** — music transitions, SFX pooling
- **MultiplayerManager** — host/client, replication, sync

### Communication Patterns

- **Signals (events)** for loose coupling — player.died → UIManager.showDeathScreen
- **Singletons (autoloads)** for global state — GameState, AudioManager, SaveSystem
- **Direct refs** only between parent-child in scene tree
- **No god objects** — each system owns its data, exposes API

---

## 25. Phase 1 — Vertical Slice (Weeks 1–6, Detailed)

**Goal:** One playable class (Guardian), one hand-crafted dungeon, complete combat loop,
saveable character. This is the "is the game fun?" test.

### Week 1 — Foundation

**Day 1–2: Project setup**
- Create Godot 4 project
- Initialize Git repo with LFS
- Set up folder structure (per Section 32)
- Configure project: window size, default rendering settings
- Add placeholder character sprite

**Day 3–5: Movement & camera**
- Implement isometric tile grid (or top-down 2D, decide based on art)
- Player CharacterBody2D with 8-directional movement
- Camera follows player smoothly
- Tilemap test scene with collision walls
- Input remapping system

**Deliverable:** Walk around an empty room, hit walls.

### Week 2 — Combat Core

**Day 1–3: Basic attack**
- Light attack: animation, hitbox spawn, damage application
- 3-hit combo chain with input timing windows
- Heavy attack with windup
- Combo counter (internal, no UI yet)

**Day 4–5: Defense**
- Dodge roll with iframes (4f startup, 10f iframes, 8f recovery)
- Block button (Guardian only, reduces damage)
- Stagger animation when hit

**Day 6–7: Hit detection**
- HitBox vs HurtBox node setup
- Damage source attribution (for combos, killcam)
- Floating damage numbers (placeholder text)

**Deliverable:** Attack a training dummy. Combos work. Dodging works.

### Week 3 — First Enemy

**Day 1–2: Basic enemy**
- BaseEnemy class with HP, damage, speed
- Sprite + animation (placeholder)
- State machine: Idle → Patrol → Aggro → Attack → Death

**Day 3–4: AI behaviors**
- Vision cone / aggro range detection
- Pathfinding to player using AStarGrid2D
- Melee attack with telegraph (windup particle)

**Day 5: Death & drops**
- Death animation, despawn
- Drop gold pickup on death
- Player picks up gold (auto-vacuum within radius)

**Day 6–7: HUD basics**
- Health bar (player)
- Mana bar
- Gold counter
- Damage numbers polish

**Deliverable:** Fight a melee enemy, kill it, collect gold.

### Week 4 — Guardian Class

**Day 1–2: Attribute system**
- STR/AGI/INT/STA stats
- Derived stat calculator
- Level + XP system
- Level-up flow: XP threshold → +3 attribute points

**Day 3–4: Skill system foundation**
- Skill base class
- Cooldown manager
- Mana cost validation
- Skill hotbar UI (4 slots)

**Day 5–7: Guardian's 3 starter skills**
- Earthquake: AoE ground slam, knockdown, 8s CD
- Warcry: self+ally buff (+20% damage 15s), 30s CD
- Frostbite: cone of cold, slow + DoT, 12s CD
- Each skill: animation, particle effect, sound (placeholder)

**Deliverable:** Level up, allocate stats, use 3 skills, feel the Guardian's identity.

### Week 5 — First Dungeon

**Day 1–2: Dungeon assembly**
- Hand-build one dungeon map (4–5 rooms + boss)
- Spawn enemies on room entry
- Fog of war shader (reveals as explored)

**Day 3–4: Minimap**
- Top-right UI showing explored tiles
- Player + enemy icons
- Boss icon when seen

**Day 5–6: Boss enemy**
- Boss BaseEnemy subclass
- 2-phase behavior (HP threshold transition)
- Big HP bar at top of screen during fight
- Special drop on death

**Day 7: Loot system stub**
- Define Item resource
- Drop random item on enemy death (placeholder)
- Inventory grid UI
- Equip/unequip from inventory

**Deliverable:** Complete a full dungeon run, fight boss, equip loot.

### Week 6 — Save System & Polish

**Day 1–2: Save/load**
- Save game state (character, inventory, stats) to file
- Load on game start
- Main menu: New Game / Continue

**Day 3–4: First testers**
- Build to executable
- Recruit 2–3 testers
- Collect feedback, identify pain points

**Day 5–7: Fixes & juice**
- Address top 3 tester complaints
- Add screen shake on heavy hits
- Add hit-stop (2-frame pause on impact)
- Polish animation timing

**Phase 1 DELIVERABLE:** Playable vertical slice. Show this to anyone considering investing
time or money in the project. If this isn't fun, redesign before continuing.

---

## 26. Phase 2 — Core Game (Weeks 7–18, Detailed)

Goal: Complete game, all classes, all systems, full campaign, beatable start-to-finish.

### Week 7–8 — All 5 Classes

For each of Mercenary, Disciple, Prowler, Scout:
- Class sprite + animations (placeholder OK)
- Starting stats per Section 3
- 3 starter active skills + 1 passive
- Distinct weapon types per class
- Class selection screen

**Deliverable:** Five distinct classes playable from start.

### Week 9 — Shapeshifting

- Essence resource implementation
- Essence pickup particles on enemy death
- Essence meter on HUD
- Transformation flow: button press → animation → swap to monster form
- Per-class form (5 forms, 3 abilities each)
- Form duration timer, drain rate
- Visual transformation effect

**Deliverable:** Press a button, become a monster, feel powerful.

### Week 10–11 — Procedural Dungeon Generator

(Algorithm in Section 30)
- Define 30+ room templates (small/medium/large, combat/treasure/empty/trap)
- Implement room connection graph (depth-first generation)
- Validate playability (start reachable from end)
- Spawn enemies per room (based on dungeon level)
- Place treasure rooms (off main path)
- Place boss room (terminal)
- Lighting: each room has Light2D for atmosphere
- Tile theming: forest/ruins/swamp/volcanic palettes

**Deliverable:** Infinite playable dungeon variation.

### Week 12–13 — Enemy Roster (40+ types)

For each enemy:
- Sprite + animations (idle, walk, attack, death)
- AI archetype assignment (from Section 8)
- Stats per zone level
- Drop table
- Audio tell for telegraphed attacks

**Boss design** (12 bosses, see Section 9):
- Custom AI per boss
- Phase transition logic
- Unique room layout
- Cinematic intro (camera pan + name card)
- Guaranteed legendary drop

**Deliverable:** Full bestiary deployed across all biomes.

### Week 14 — Loot & Item Generation

- Implement affix system (50+ prefixes, 50+ suffixes)
- Item rarity rolls
- Magic Find stat
- 10 equipment slots
- Item comparison tooltip (side-by-side stats)
- Set items (3 sets initially)
- 20+ legendary items defined

**Deliverable:** Diverse, build-defining loot.

### Week 15 — Vendor & Economy

- 4 vendor types (Armorer, Weaponsmith, Apothecary, Jeweler)
- Vendor stock generation (level-appropriate)
- Buy/sell UI
- Refresh mechanic (5min real-time or after dungeon)
- Gold cost balancing
- Stash (shared cross-character storage)

**Deliverable:** Functioning economy.

### Week 16 — Hub Town & Quest System

- Monastery hub map
- 8 NPCs with dialogue trees (use Dialogic plugin)
- Quest system implementation (state machine per Section 14)
- 8 quest types implemented
- Quest log UI
- Map markers and compass
- World map with fast travel

**Deliverable:** Players can navigate world, accept missions, return to hub.

### Week 17 — Full Campaign Content

- Act 1: 5 dungeons + 2 bosses + main story quests
- Act 2: 5 dungeons + 3 bosses + faction subplot
- Act 3: 5 dungeons + 3 bosses + final boss
- Story dialogue written and integrated
- Act transition cutscenes (static art + narration)
- Credits screen
- New Game+ mode

**Deliverable:** Full game completable end-to-end.

### Week 18 — Multiplayer (Local Co-op)

- Split-screen for 2 players
- Two controller input
- Separate HUDs
- Difficulty scaling per Section 16
- Loot instancing

(Online multiplayer pushed to Phase 3 if time-tight.)

**Phase 2 DELIVERABLE:** Full game. All five classes. Complete campaign. Co-op. Save/load.
Difficulty modes. Endgame stub.

---

## 27. Phase 3 — Polish & Expansion (Weeks 19–26, Detailed)

### Week 19–20 — Audio Pass

- Replace all placeholder SFX with final
- Compose 5 zone music tracks + 4 boss tracks + hub theme
- Implement adaptive music (combat layer)
- All audio tells final
- Voice acting (if budget allows) or polished text + grunts
- Audio mixer: balance music/SFX/UI

### Week 21 — Visual Polish

- Particle effects pass: every skill, every elemental hit
- Lighting polish per zone
- Boss intro cinematics
- Death animations and ragdoll
- Screen shake intensity tuning
- Hit-stop timing
- Camera juice (subtle zoom on heavy hits)
- UI animation (slides, fades)

### Week 22 — Balance Pass

- All classes: time to clear standard dungeon should be ±15% of each other
- All skills: usage rate analysis; underused skills get buffs
- Loot rate: tester reports of "haven't seen an upgrade in N runs" → adjust
- Boss difficulty: ~60% first-attempt success target on Normal
- Gold economy: average player should afford 1–2 vendor items per dungeon

### Week 23 — QoL Features

- Auto-pickup gold + commons
- Smart auto-equip (toggle)
- Quick-compare overlay (hold key)
- Full keybind remapping
- Settings menu complete (graphics, audio, gameplay, accessibility)
- Pause-anywhere in single player
- Pause menu in hub for multiplayer

### Week 24 — Online Co-op

- Implement Godot HighLevelMultiplayer
- Lobby browser
- Friend invite via Steam
- State replication (player position, HP, skills)
- Loot instancing online
- Sync state on join mid-dungeon
- Latency mitigation: client prediction for movement

### Week 25 — Endgame Content

- Endless Dungeon mode (procedural floors, scaling difficulty)
- Boss Rush mode
- Daily Quest (fixed seed)
- Champion's Arena (wave defense)
- Achievement system (Steam achievements)
- Cosmetic vendor (Honor Tokens)

### Week 26 — Final Polish & Launch Prep

- Bug bash: full QA pass
- Performance optimization (60fps min, 144fps target on mid-PC)
- Localization (English, Spanish, French, German, Japanese, Simplified Chinese)
- Steam page setup
- Trailer cut
- Press kit
- Launch day patch prepared

**Phase 3 DELIVERABLE:** Shippable game.

---

## 28. Phase 4 — Post-Launch & Live Ops

Not a full development phase, but a 6–12 month plan for keeping the community engaged.

### Month 1 — Stabilization

- Launch day patch
- Hotfixes for top community issues
- Daily community engagement (Discord, Steam forums)

### Month 2–3 — First Content Patch

- 1 new endless dungeon mode variant
- 2 new bosses (revisits, harder versions)
- New legendary items
- Quality-of-life from community feedback

### Month 6 — First Expansion ("DLC 1")

- New class (6th class — proposal: **Berserker**, dual-axe, rage mechanic)
- New zone (Frozen North)
- 10+ hour story extension
- Higher level cap (50 → 70)
- Priced at $9.99–$14.99

### Month 12 — Major Update

- New game mode (PvP arena?)
- Seasonal content
- Mod tools / Steam Workshop support

### Live Service Principles

- Never charge for power
- Never gate gameplay behind grinding
- Cosmetics only for paid additions to free updates
- Listen to top community votes for next content

---

## 29. Data Architecture & Schemas

### Character Schema

```gdscript
class_name Character
extends Resource

@export var character_name: String
@export var class_type: ClassType  # enum
@export var level: int = 1
@export var xp: int = 0
@export var attributes: Dictionary = {
    "strength": 10,
    "agility": 10,
    "intelligence": 10,
    "stamina": 10
}
@export var unspent_attr_points: int = 0
@export var unspent_skill_points: int = 0
@export var skills: Dictionary = {}  # skill_id → tier
@export var equipment: Dictionary = {}  # slot → Item ref
@export var inventory: Array[Item] = []
@export var stash: Array[Item] = []
@export var gold: int = 0
@export var essence: float = 0.0
@export var honor_tokens: int = 0
@export var soul_shards: int = 0
@export var current_hp: float = 100.0
@export var current_mana: float = 50.0
@export var quests_active: Array[String] = []
@export var quests_completed: Array[String] = []
@export var zones_unlocked: Array[String] = []
@export var bestiary_discovered: Array[String] = []
@export var play_time_seconds: float = 0.0
```

### Item Schema

```gdscript
class_name Item
extends Resource

@export var item_id: String
@export var display_name: String
@export var item_type: ItemType  # enum: Weapon, Armor, Ring, etc.
@export var slot: EquipSlot
@export var rarity: Rarity
@export var level_req: int
@export var base_stats: Dictionary = {}  # damage, armor, etc.
@export var affixes: Array[Affix] = []
@export var element: Element = Element.NONE
@export var set_id: String = ""  # blank if not a set item
@export var legendary_id: String = ""  # blank if not legendary
@export var icon: Texture2D
@export var description: String
@export var sell_value: int
@export var buy_value: int
```

### Affix Schema

```gdscript
class_name Affix
extends Resource

@export var affix_id: String
@export var display_text: String  # e.g., "of the Bear"
@export var is_prefix: bool
@export var stat_modifications: Dictionary = {}  # stat_name → value
@export var special_effect: String = ""  # e.g., "lifesteal_3"
@export var tier: int  # 1-5, affects roll range
```

### Enemy Schema

```gdscript
class_name EnemyData
extends Resource

@export var enemy_id: String
@export var display_name: String
@export var archetype: Archetype  # enum
@export var base_hp: float
@export var base_damage: float
@export var move_speed: float
@export var attack_speed: float
@export var armor: float
@export var resistances: Dictionary = {}  # element → %
@export var ai_behavior: String  # behavior tree ID
@export var sprite: SpriteFrames
@export var sounds: Dictionary = {}  # attack, death, idle
@export var drop_table: DropTable
@export var essence_value: float
@export var xp_value: int
```

### Drop Table Schema

```gdscript
class_name DropTable
extends Resource

@export var gold_min: int
@export var gold_max: int
@export var item_drop_chance: float  # 0.0–1.0
@export var rarity_weights: Dictionary = {
    "common": 60,
    "uncommon": 25,
    "rare": 10,
    "epic": 4,
    "legendary": 1
}
@export var guaranteed_drops: Array[String] = []  # item_ids
```

### Dungeon Schema

```gdscript
class_name DungeonData
extends Resource

@export var zone_id: String
@export var display_name: String
@export var theme: Theme  # enum
@export var level_range: Vector2i
@export var room_count_min: int = 4
@export var room_count_max: int = 8
@export var enemy_pool: Array[String] = []  # enemy_ids
@export var boss_id: String = ""
@export var objectives: Array[Objective] = []
@export var music_track: AudioStream
@export var ambient_sound: AudioStream
@export var tileset: TileSet
```

### Save File Format

```json
{
    "version": "1.0.0",
    "character": { /* Character Schema */ },
    "world_state": {
        "current_zone": "monastery_hub",
        "quests": { /* state machine snapshots */ },
        "hub_state": "act2_arrival",
        "vendors_refreshed_at": 1735689600
    },
    "settings": {
        "music_volume": 0.8,
        "sfx_volume": 1.0,
        "controls": { /* keybindings */ }
    },
    "statistics": {
        "monsters_killed": 1247,
        "bosses_defeated": 8,
        "deaths": 23,
        "gold_earned_total": 45678,
        "items_collected": 412
    }
}
```

---

## 30. Algorithms (Dungeon Gen, AI, Loot)

### Dungeon Generation Algorithm

```
function GenerateDungeon(zone_id, level):
    rooms = []
    spawn_room = pick_room_template(type=ENTRY)
    rooms.append(spawn_room)

    target_count = random(4, 8)
    while len(rooms) < target_count:
        last = rooms[-1]
        next_template = pick_room_template(
            type=COMBAT,
            difficulty=level_to_difficulty(level)
        )
        connect(last, next_template, direction=pick_random_unused_exit(last))
        rooms.append(next_template)

    # Branch out for treasure rooms
    for _ in range(random(1, 2)):
        parent = random.choice(rooms[1:-1])
        treasure = pick_room_template(type=TREASURE)
        connect(parent, treasure, direction=pick_random_unused_exit(parent))
        rooms.append(treasure)

    # Add mini-boss room (50% chance)
    if random() < 0.5:
        miniboss = pick_room_template(type=MINIBOSS)
        insert_in_middle(rooms, miniboss)

    # Add boss room at end
    boss_room = pick_room_template(type=BOSS, boss_id=zone.boss)
    connect(rooms[-1], boss_room)
    rooms.append(boss_room)

    # Populate
    for room in rooms:
        spawn_enemies(room, zone.enemy_pool, level)
        place_loot_containers(room)
        place_traps(room, density=zone.trap_density)
        if room.type == TREASURE:
            place_treasure_chest(room)

    validate_playability(rooms)  # ensures spawn → boss is reachable
    return rooms
```

### AI Behavior Tree (Example: Melee Rusher)

```
Selector (root)
├── IsDead? → Sequence: PlayDeathAnim → Despawn
├── IsStunned? → Wait
├── CanSeePlayer?
│   └── Sequence:
│       ├── DistanceToPlayer < AttackRange?
│       │   └── Sequence: TelegraphAttack(0.5s) → ExecuteAttack → Cooldown(1s)
│       └── MoveToward(Player)
└── Idle / Patrol
    └── Sequence: PickRandomPoint → MoveTo → Wait(2s) → Repeat
```

### Loot Generation Algorithm

```
function GenerateLoot(monster, player):
    drops = []

    # Always drop gold
    gold = random(monster.gold_min, monster.gold_max)
    gold *= 1.0 + player.gold_find_bonus
    drops.append(GoldPile(gold))

    # Roll for item drop
    drop_roll = random()
    if drop_roll > monster.item_drop_chance:
        return drops

    # Determine rarity
    rarity = roll_rarity(
        weights=monster.rarity_weights,
        magic_find=player.magic_find
    )

    # Determine item base
    base = pick_from_pool(
        level_range=[monster.level - 2, monster.level + 2],
        weight_by_player_class=true  # higher chance for relevant items
    )

    # Generate full item
    item = Item.new(base)
    item.rarity = rarity
    item.affixes = generate_affixes(item_level=monster.level, count=rarity_to_affix_count(rarity))

    if rarity == LEGENDARY:
        item = upgrade_to_legendary(item)
    if rarity == EPIC:
        item.special = roll_special_property()

    drops.append(item)

    # Bosses guaranteed extra drops
    if monster.is_boss:
        for guaranteed_id in monster.guaranteed_drops:
            drops.append(create_item(guaranteed_id))

    # Essence drop (independent)
    if monster.essence_value > 0:
        drops.append(EssencePickup(monster.essence_value))

    return drops
```

### Pathfinding

Use Godot's built-in `AStarGrid2D`:
```gdscript
var grid: AStarGrid2D = AStarGrid2D.new()
grid.region = Rect2i(0, 0, map_width, map_height)
grid.cell_size = Vector2(32, 32)
grid.update()

for tile in obstacle_tiles:
    grid.set_point_solid(tile)

var path = grid.get_id_path(start_tile, goal_tile)
```

For large rooms with many enemies, batch pathfinding updates (don't recompute every frame).

---

## 31. Code Examples & Stubs

### Player Controller (GDScript)

```gdscript
class_name PlayerController
extends CharacterBody2D

@export var attribute_system: AttributeSystem
@export var skill_system: SkillSystem
@export var combat_handler: CombatHandler

var move_speed: float = 200.0
var attack_input_buffered: bool = false
var combo_state: int = 0

func _physics_process(delta):
    handle_movement(delta)
    handle_input(delta)

func handle_movement(delta):
    var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = direction * move_speed * attribute_system.move_speed_multiplier()
    move_and_slide()

func handle_input(delta):
    if Input.is_action_just_pressed("attack_light"):
        try_light_attack()
    if Input.is_action_just_pressed("attack_heavy"):
        try_heavy_attack()
    if Input.is_action_just_pressed("dodge"):
        dodge_roll()
    for i in range(4):
        if Input.is_action_just_pressed("skill_%d" % (i+1)):
            skill_system.use_skill_slot(i)

func try_light_attack():
    if can_attack():
        combat_handler.execute_attack(AttackType.LIGHT, combo_state)
        combo_state = (combo_state + 1) % 3
```

### Damage Calculator (GDScript)

```gdscript
class_name DamageCalculator
extends Node

static func calculate(
    attacker: Character,
    target: Enemy,
    base_damage: float,
    attack_type: AttackType,
    is_crit: bool = false
) -> float:
    var damage = base_damage

    # Stat scaling
    match attack_type:
        AttackType.MELEE:
            damage *= 1.0 + attacker.strength * 0.02
        AttackType.RANGED:
            damage *= 1.0 + attacker.agility * 0.025
        AttackType.SPELL:
            damage *= 1.0 + attacker.intelligence * 0.03

    # Elemental bonus
    damage *= 1.0 + attacker.elemental_bonus(attack_type)

    # Crit
    if is_crit:
        damage *= 1.5 + attacker.crit_damage_multiplier

    # Target damage reduction
    var dr = target.armor / (target.armor + 100 + target.level * 10)
    damage *= 1.0 - min(dr, 0.75)

    # Vulnerability (backstab, stunned, marked)
    if target.is_vulnerable_to(attacker):
        damage *= 1.0 + attacker.vulnerability_bonus(target)

    # Element resistance
    damage *= 1.0 - target.resistance_to(attacker.current_element)

    return max(1, damage)  # minimum 1 damage
```

### Skill Definition (Resource)

```gdscript
class_name Skill
extends Resource

@export var skill_id: String
@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var mana_cost: float
@export var cooldown: float
@export var base_damage: float
@export var damage_scaling: Dictionary = {}  # stat_name → coefficient
@export var animation_name: String
@export var effect_scene: PackedScene  # particle/AOE effect
@export var tiers: Array[Resource] = []  # SkillTier resources

func execute(caster: Character, target_position: Vector2):
    if caster.current_mana < mana_cost:
        return false
    caster.current_mana -= mana_cost
    var effect = effect_scene.instantiate()
    effect.position = target_position
    effect.damage = base_damage * calculate_scaling(caster)
    caster.get_parent().add_child(effect)
    return true
```

### Enemy AI State Machine (GDScript)

```gdscript
class_name EnemyAI
extends Node

enum State { IDLE, PATROL, AGGRO, ATTACK, STUN, DEAD }

var current_state: State = State.IDLE
var enemy: BaseEnemy
var player: PlayerController
var aggro_range: float = 200.0
var attack_range: float = 50.0
var attack_cooldown: float = 0.0

func _physics_process(delta):
    attack_cooldown = max(0, attack_cooldown - delta)
    match current_state:
        State.IDLE: do_idle(delta)
        State.PATROL: do_patrol(delta)
        State.AGGRO: do_aggro(delta)
        State.ATTACK: do_attack(delta)

func do_idle(delta):
    if can_see_player():
        change_state(State.AGGRO)

func do_aggro(delta):
    if not can_see_player():
        change_state(State.PATROL)
        return
    var dist = enemy.position.distance_to(player.position)
    if dist <= attack_range and attack_cooldown <= 0:
        change_state(State.ATTACK)
    else:
        move_toward(player.position, delta)

func do_attack(delta):
    enemy.play_attack_animation()
    await enemy.attack_telegraph_done
    if enemy.position.distance_to(player.position) <= attack_range:
        player.take_damage(enemy.attack_damage)
    attack_cooldown = 1.5
    change_state(State.AGGRO)
```

---

## 32. File / Folder Structure

```
dungeon_crawler/
├── project.godot
├── icon.svg
├── README.md
├── CHANGELOG.md
├── LICENSE
├── .gitignore
├── .gitattributes (Git LFS rules)
│
├── assets/
│   ├── sprites/
│   │   ├── characters/
│   │   │   ├── guardian/
│   │   │   ├── mercenary/
│   │   │   ├── disciple/
│   │   │   ├── prowler/
│   │   │   ├── scout/
│   │   │   └── shapes/      # changeling forms
│   │   ├── enemies/
│   │   │   ├── forest/
│   │   │   ├── ruins/
│   │   │   ├── swamp/
│   │   │   └── volcanic/
│   │   ├── bosses/
│   │   ├── tiles/
│   │   │   ├── forest_tileset.tres
│   │   │   ├── ruins_tileset.tres
│   │   │   ├── swamp_tileset.tres
│   │   │   ├── volcanic_tileset.tres
│   │   │   └── monastery_tileset.tres
│   │   ├── ui/
│   │   ├── items/
│   │   └── effects/
│   ├── audio/
│   │   ├── sfx/
│   │   │   ├── combat/
│   │   │   ├── skills/
│   │   │   ├── ui/
│   │   │   └── ambient/
│   │   └── music/
│   ├── fonts/
│   └── shaders/
│
├── scenes/
│   ├── main_menu/
│   │   ├── MainMenu.tscn
│   │   ├── CharacterCreation.tscn
│   │   └── ClassSelect.tscn
│   ├── player/
│   │   ├── Player.tscn
│   │   └── classes/
│   │       ├── Guardian.tscn
│   │       ├── Mercenary.tscn
│   │       ├── Disciple.tscn
│   │       ├── Prowler.tscn
│   │       └── Scout.tscn
│   ├── enemies/
│   │   ├── BaseEnemy.tscn
│   │   ├── BaseBoss.tscn
│   │   └── bestiary/        # one .tscn per enemy
│   ├── world/
│   │   ├── DungeonGenerator.tscn
│   │   ├── HubTown.tscn
│   │   ├── WorldMap.tscn
│   │   └── rooms/           # room templates
│   ├── ui/
│   │   ├── HUD.tscn
│   │   ├── Inventory.tscn
│   │   ├── SkillBar.tscn
│   │   ├── QuestLog.tscn
│   │   ├── Vendor.tscn
│   │   ├── Map.tscn
│   │   └── Settings.tscn
│   └── effects/
│       ├── DamageNumber.tscn
│       ├── HitEffect.tscn
│       └── LootDrop.tscn
│
├── scripts/
│   ├── autoload/            # singletons
│   │   ├── GameState.gd
│   │   ├── AudioManager.gd
│   │   ├── SaveSystem.gd
│   │   ├── EventBus.gd
│   │   └── Localization.gd
│   ├── player/
│   ├── enemies/
│   ├── combat/
│   ├── systems/
│   ├── world/
│   ├── ui/
│   ├── multiplayer/
│   └── utils/
│
├── data/                    # JSON or .tres resource files
│   ├── items/
│   │   ├── weapons.tres
│   │   ├── armor.tres
│   │   └── legendaries.tres
│   ├── skills/
│   ├── enemies/
│   ├── bosses/
│   ├── quests/
│   ├── zones/
│   ├── affixes/
│   └── localization/
│       ├── en.csv
│       ├── es.csv
│       ├── fr.csv
│       ├── de.csv
│       ├── ja.csv
│       └── zh_CN.csv
│
├── docs/
│   ├── GAME_ANALYSIS_AND_PLAN.md  (this file)
│   ├── ARCHITECTURE.md
│   ├── CONTRIBUTING.md
│   ├── DESIGN_DECISIONS.md
│   └── api/                 # auto-generated docs
│
├── tests/
│   ├── unit/
│   ├── integration/
│   └── playtest_notes/
│
└── builds/
    ├── windows/
    ├── linux/
    └── mac/
```

---

## 33. Testing & QA Plan

### Test Categories

| Type | Frequency | Tools |
|------|-----------|-------|
| **Unit tests** | Per commit | GUT (Godot Unit Test) |
| **Integration tests** | Per feature | Custom scenes |
| **Smoke tests** | Per build | Manual checklist |
| **Playtests** | Weekly (Phase 2+) | Live testers |
| **Stress tests** | Per milestone | Bots simulating 500+ enemies |
| **Multiplayer tests** | Phase 3 | Internal team play |
| **Localization tests** | Pre-launch | Native speakers |
| **Accessibility tests** | Phase 3 | Real users with disabilities |

### Unit Test Examples

```gdscript
# tests/unit/test_damage_calculator.gd
extends GutTest

func test_basic_damage():
    var attacker = mock_character(strength=20)
    var target = mock_enemy(armor=0, level=1)
    var damage = DamageCalculator.calculate(attacker, target, 10, AttackType.MELEE)
    assert_eq(damage, 14, "20 STR should give 40% melee bonus = 14 dmg")

func test_crit_damage():
    var attacker = mock_character(strength=0, crit_damage_multiplier=0.5)
    var target = mock_enemy(armor=0, level=1)
    var damage = DamageCalculator.calculate(attacker, target, 10, AttackType.MELEE, true)
    assert_eq(damage, 20, "Crit: 10 * (1.5 + 0.5) = 20")

func test_armor_reduction():
    var attacker = mock_character()
    var target = mock_enemy(armor=100, level=10)
    var damage = DamageCalculator.calculate(attacker, target, 100, AttackType.MELEE)
    # DR = 100 / (100 + 100 + 100) = 0.33
    # damage = 100 * (1 - 0.33) ≈ 67
    assert_almost_eq(damage, 67, 1)
```

### Playtest Protocol

Each weekly playtest:
1. Tester gets fresh build
2. Plays for 60–90 minutes
3. Records video + thinking aloud
4. Post-session structured interview (10 questions)
5. Top 3 issues → backlog
6. Critical bugs → hotfix within 24h

### Bug Triage

| Severity | Definition | Response |
|----------|-----------|----------|
| Critical | Crash, save corruption, blocks progression | Same day |
| High | Major feature broken, common path | Within 3 days |
| Medium | Annoying but workaround exists | Next milestone |
| Low | Cosmetic, edge case | Backlog |

### Pre-Launch Checklist

- [ ] All quests completable
- [ ] All bosses defeatable on Normal
- [ ] All five classes can clear campaign
- [ ] Save/load works across all states
- [ ] Multiplayer sync stable over 30min
- [ ] No memory leaks over 4h play session
- [ ] 60 FPS minimum on target hardware
- [ ] All 6 languages reviewed
- [ ] Achievements all unlockable
- [ ] Steam page approved
- [ ] Press kit distributed
- [ ] Launch trailer published

---

## 34. Performance Targets

| Hardware | Target | Resolution | Frame Rate |
|----------|--------|------------|------------|
| Min-spec PC (Intel HD 4000 era) | Playable | 720p | 30 fps |
| Recommended PC | Smooth | 1080p | 60 fps |
| Mid-range PC | Comfortable | 1440p | 60–144 fps |
| High-end PC | No bottleneck | 4K | 144 fps |
| Steam Deck | Native target | 720p | 60 fps |
| Switch (if ported) | Stable | 720p docked, 540p handheld | 30 fps |

### Optimization Priorities

1. **Profile early, profile often** — Godot's built-in profiler
2. **Object pooling** for projectiles, particles, damage numbers, enemy corpses
3. **Sprite batching** — texture atlas per zone
4. **Pathfinding throttling** — pathfind ≤5 enemies per frame; queue rest
5. **Off-screen culling** — disable AI for enemies outside camera + 200px
6. **Particle limits** — cap concurrent particles per zone
7. **Save async** — never block the main thread on save

### Memory Targets

- Idle hub: < 500 MB
- Active dungeon: < 1.5 GB
- Peak (boss + co-op + max effects): < 2.5 GB

---

## 35. Accessibility Features

These should be built in from Phase 1, not bolted on at the end.

### Visual

- [ ] Colorblind modes (Protanopia, Deuteranopia, Tritanopia)
- [ ] UI scale 50%–200%
- [ ] Subtitle / text size configurable
- [ ] High-contrast mode
- [ ] Damage number readability (option: large text)
- [ ] Boss telegraph high-visibility option (bright outlines)

### Audio

- [ ] Audio-only telegraph mode (every enemy attack has distinct sound)
- [ ] Subtitles for all voiced/audio content
- [ ] Visual indicator for off-screen audio cues
- [ ] Separate volume sliders: music/SFX/voice/UI/ambient

### Input

- [ ] Full keybind remapping
- [ ] Controller remapping
- [ ] Hold-to-toggle conversion (e.g., hold-to-sprint → toggle-sprint)
- [ ] Aim assist (subtle, optional)
- [ ] One-handed control mode
- [ ] Reduce input precision requirements (combo windows tunable)

### Cognitive

- [ ] Difficulty modes (including a "Story" mode below Normal)
- [ ] Pause anywhere in single player
- [ ] Quest objectives always visible
- [ ] Map markers always visible
- [ ] Skip cutscenes
- [ ] Skip text option
- [ ] Auto-loot toggle (no need to press button)

### Motion

- [ ] Reduce screen shake slider (0–100%)
- [ ] Reduce flashing effects
- [ ] Disable camera bob

---

## 36. Localization Plan

### Initial Languages (Launch)

1. **English** (primary)
2. **Spanish** (Latin America + Spain)
3. **French**
4. **German**
5. **Japanese**
6. **Simplified Chinese**

### Post-Launch Languages

- Brazilian Portuguese
- Russian
- Korean
- Italian
- Polish
- Traditional Chinese

### Localization Architecture

- All user-facing text stored in CSV: `data/localization/<lang>.csv`
- Key-based lookup: `tr("QUEST_ACT1_TITLE")`
- Pluralization rules per language
- Date/number formatting
- Right-to-left support deferred (Arabic, Hebrew) unless requested

### Estimated Text Volume

- Quest dialogue: ~10,000 words
- Item names + descriptions: ~5,000 words
- UI strings: ~2,000 words
- Tooltips: ~3,000 words
- **Total ~20,000 words** per language

At industry rate ($0.10–0.20/word), localization = $2,000–4,000 per language.

---

## 37. Risk Assessment & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Scope creep | High | High | Hard cut content beyond Phase 3 deliverables; backlog only |
| Solo dev burnout | High | Critical | 10–15 hr/week cap; mandatory weekly rest; community engagement for morale |
| Multiplayer netcode issues | Medium | High | Build local co-op first (no netcode), defer online to Phase 3 |
| Art bottleneck | High | High | Use Kenney + free assets initially; commission later in chunks |
| Combat doesn't feel good | Low-Med | Critical | Vertical slice in Phase 1; if not fun, redesign immediately |
| Engine limitations (Godot) | Low | Medium | Backup plan: port to Unity if Godot blocks at scale |
| Save corruption bugs | Medium | Critical | Multiple save slots, atomic writes, version migrations |
| Performance issues at scale | Medium | High | Profile from week 1; budget targets per system |
| Genre saturation | High | Medium | Lean into PSP-era nostalgia + portable pacing as USP |
| Launch bug crisis | Medium | High | Pre-launch internal launch (1 week before public) |
| Negative reviews killing momentum | Medium | High | Community-build pre-launch; closed beta; influencer outreach |
| Competing game launches | Low | Medium | Watch Steam upcoming list; pick a launch window without major ARPGs |

### Contingency Plans

**If Phase 1 isn't fun:**
- Pause, redesign combat from scratch
- Steal more from references (Hades, Diablo IV)
- Consider scope reduction (3 classes instead of 5)

**If solo timeline slips:**
- Cut Phase 3 multiplayer
- Cut Phase 3 crafting
- Cut Act 3 to a tighter 3-dungeon climax
- Launch as "Episode 1" with continued development

**If technical scope exceeds skill:**
- Hire contractor for specific subsystems
- Use Godot Asset Store plugins for non-core features

---

## 38. Marketing & Launch Strategy (Light)

### Pre-Launch (Months -6 to 0)

- **Devlog**: weekly blog posts and YouTube updates from Week 8
- **Discord community**: open from Week 12
- **Twitter / X**: daily GIFs of progress
- **Reddit**: post in r/ARPG, r/Godot, r/IndieDev monthly with substantial updates
- **Closed beta**: 100 invitees from Discord, 4 weeks before launch
- **Open demo**: Steam Next Fest entry (free demo of Phase 1 slice)
- **Influencer outreach**: 20 mid-tier YouTubers, free keys
- **Press kit**: screenshots, GIFs, fact sheet, available from launch -2 months

### Launch

- Steam release
- Discount: 10% launch week
- Day-1 patch ready
- Discord mods active
- Streamer codes sent
- Reddit AMA day 2
- Twitter thread daily during launch week

### Post-Launch (Months 1–3)

- Weekly patches for top issues
- Free content update at month 3 (new dungeon, new boss)
- Steam summer/winter sale participation
- Continued devlogs ("the future of [GAME NAME]")

### Pricing

- Base game: $19.99 (premium indie tier)
- DLC 1 (Berserker class + Frozen North): $9.99
- DLC 2 (Endgame expansion): $14.99
- Soundtrack: $4.99
- Total value over 2 years: ~$45 — high but acceptable for genre

---

## 39. Solo Developer Priority Order

If working alone, follow this strict order. Each step makes the prior ones more fun to test
and validate:

```
1.  Movement + camera                    → "I can move"
2.  Light attack + hit detection         → "I can hit things"
3.  One enemy with HP + death            → "I can kill things"
4.  HP/MP bars + floating damage         → "I can see my impact"
5.  XP + level up + attribute allocation → "I'm progressing"
6.  One handcrafted dungeon              → "I have a destination"
7.  Equipment slots + loot drops         → "I'm being rewarded"
8.  Vendor + gold economy                → "I have meta progression"
9.  3 skills for Guardian                → "I have build identity"
10. Save/load                            → "My progress persists"
11. Shapeshifting                        → "I have a signature mechanic"
12. All 5 classes                        → "Players have variety"
13. Procedural dungeon generation        → "Replayability"
14. Full enemy roster                    → "Combat variety"
15. Boss design (all 12)                 → "Memorable encounters"
16. Quest system                         → "Narrative pull"
17. Hub town                             → "Anchor location"
18. Multiplayer (local first)            → "Couch co-op"
19. Polish: audio, particles, screen     → "Game feels alive"
20. Endgame: Endless, Boss Rush, Daily   → "Long-term hooks"
21. Online multiplayer                   → "Friends together"
22. Accessibility pass                   → "Welcome everyone"
23. Localization                         → "Welcome the world"
24. Launch                               → "Ship it"
```

**Never skip a step.** Each must be functional before moving on. If step 4 (impact feedback)
feels weak, fixing step 11 (shapeshifting) won't save the game.

---

## 40. Timeline Summary

| Phase | Duration | Weekly Hours | Total Hours | Deliverable |
|-------|----------|--------------|-------------|-------------|
| Phase 0 — Pre-prod | 2 weeks | 10 | 20 | Design doc finalized (this doc) |
| Phase 1 — Slice | 6 weeks | 15 | 90 | Vertical slice playable |
| Phase 2 — Core | 12 weeks | 15 | 180 | Full game beatable |
| Phase 3 — Polish | 8 weeks | 15 | 120 | Shippable |
| Phase 4 — Launch | 2 weeks | 20 | 40 | Released |
| **Total to launch** | **30 weeks (~7 months)** | | **~450 hours** | Released game |

**With a 2-person team:** ~16 weeks (~4 months).
**Full-time solo (40 hr/week):** ~12 weeks (~3 months) — aggressive but possible.

### Buffer Recommendation

Add **30% buffer** to all estimates for solo dev. Realistic launch: **9–10 months** from
design-doc finalization.

### Long-Term Vision (2+ years post-launch)

- DLC 1: New class + zone (month 6)
- DLC 2: Major expansion (month 12)
- DLC 3: Multiplayer expansion (month 18)
- Sequel: design begins month 18, launch month 36

---

# APPENDICES

## A. Glossary

| Term | Meaning |
|------|---------|
| **AoO** | Attack of Opportunity — bonus damage window on vulnerable enemies |
| **CC** | Crowd Control — stun, root, slow, etc. |
| **DoT** | Damage over Time — burn, bleed, poison ticks |
| **DR** | Damage Reduction — % of damage mitigated by armor |
| **Magic Find** | Stat increasing rare+ drop chances |
| **Essence** | Resource for Changeling transformation |
| **Affix** | Prefix or suffix on an item adding properties |
| **Set Item** | Item belonging to a multi-piece set with bonuses |
| **Telegraph** | Visual/audio cue before an enemy attack |
| **iframe** | Invincibility frame, no damage taken |
| **Tile** | One grid square (~32×32 pixels) |
| **Aggro** | Aggression / target lock-on |
| **Mob** | Mobile entity (an enemy) |
| **Trash** | Common low-tier enemies |
| **Elite** | Stronger named/buffed variant |
| **Boss** | Story-significant high-HP encounter |
| **Build** | Combination of class, attributes, skills, gear |

## B. Reference Bibliography

- *Untold Legends: The Warrior's Code* (2006), Sony Online Entertainment
- *Diablo II* (2000), Blizzard
- *Champions of Norrath* (2004), Snowblind Studios
- *Hades* (2020), Supergiant — combat juice reference
- *Path of Exile* (2013), Grinding Gear — affix system reference
- *Last Epoch* (2024), Eleventh Hour — skill mod reference
- "Game Programming Patterns" — Robert Nystrom (free online)
- "The Art of Game Design" — Jesse Schell
- Godot 4 official documentation
- ARPG subreddit playtesting threads (community feedback patterns)

## C. Glossary of Internal Terms

- **The Order** — the Warrior's Code Changeling order (faction)
- **Essence** — shapeshifting resource (NOT general magic energy)
- **Form** — the monster the player transforms into
- **The Code** — the warrior tenets the player swears to
- **The Blight** — the corruption antagonist

## D. Open Questions for Designer

1. Pixel art vs hand-drawn vs 3D-rendered-as-2D? (Affects timeline by months.)
2. Voice acting budget — full, partial, or none?
3. Procedural dungeons vs hand-crafted vs hybrid (current plan)?
4. Single-player only at launch vs co-op at launch?
5. PC only vs Switch port from day 1?
6. Story-heavy or gameplay-first vibe?
7. PSP-era aesthetic homage or modern-pixel-art look?

---

*Document version: 2.0 (extended)*
*Last updated: 2026-05-20*
*Compiled from: Wikipedia, GameFAQs, GameSpot, RPGFan, Pocket Gamer, Giant Bomb, Neoseeker,*
*and developer-side analysis informed by Diablo, PoE, Hades, Last Epoch, and Vampire Survivors*
*as comparative references.*
