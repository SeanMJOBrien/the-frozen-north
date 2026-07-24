# Creating Spawns in The Frozen North — A Practical Guide

How to add a new creature spawn to this module, and how the machinery behind it
works. Written for someone new to the codebase (companion to
`EVENTS_AND_SPAWNING.md` in the tfn-treasuremap package, which covers the
general event/spawn concepts).

The most important thing to understand first:

> **In this module you almost never place a "live" creature in the toolset.**
> Spawns are *data*: variables on the area plus invisible marker objects.
> Scripts read that data and create the actual creatures at play time, every
> time the area "refreshes."

---

## 1. The area lifecycle (why spawns are data)

Every area behaves like an instance that resets itself. The cycle:

```
 MODULE STARTS
   on_mod_load ─▶ area_init runs once per area
      ├─ parses your encounter blueprints (.ute) into area local variables
      ├─ converts marker creatures into stored spawn-point locations
      ├─ records hand-placed creatures/placeables as coordinates, then DELETES them
      └─ wires the area's OnEnter/OnExit/OnHeartbeat scripts

 FIRST PLAYER ENTERS
   area_enter ─▶ sees no "refresh" flag ─▶ ExecuteScript("area_refresh")
      └─ area_refresh SPAWNS everything from the stored data,
         registering each object on the area's cleanup list

 PLAYERS LEAVE
   area_hb (heartbeat) counts down while the area (and linked areas) are empty
      └─ after enough beats ─▶ area_cleanup destroys everything on the
         cleanup list and clears the "refresh" flag

 NEXT PLAYER ENTERS  ─▶  fresh spawns again (repeat forever)
```

Key files: `src/nss/area_init.nss`, `src/nss/area_enter.nss:120-127`,
`src/nss/area_refresh.nss`, `src/nss/area_hb.nss`, `src/nss/area_cleanup.nss`.

So "creating a spawn" means **feeding the right data to `area_init` and
`area_refresh`** — not scripting anything, in the common case.

---

## 2. The main way: random encounter spawns

This is the system behind nearly every hostile spawn in the module. Each area
supports up to **nine independent spawn groups**, named `random1` … `random9`.
A group is defined by three things:

### Step 1 — an encounter blueprint (.ute) says WHAT spawns

Encounter blueprints live in `src/ute/` (128 of them — copy an existing one).
The system reads them with `TemplateToJson` in `area_init.nss:143` and uses:

- **Creature list** — the possible creature resrefs for this group.
  - Creatures with **Single Spawn** checked go on the *unique* list — spice
    mixed in occasionally (leaders, mages, dogs...).
  - Unchecked creatures form the *common* list — the rank and file.
- **Difficulty** — sets how often a unique is picked instead of a common
  creature: Very Easy 5% → Impossible 25% (`area_init.nss:155-162`).
- **Variable `rare` (string)** on the blueprint — resref of a special "rare"
  creature (see §5).

Example, `src/ute/bandit_moderate.ute.json`: commons = `bandit`; uniques =
`bandit_dog`, `bandit_fighter`, `bandit_mage`; `rare = bandit_leader`;
difficulty Hard (20% unique chance).

The blueprint is **never used as a real encounter trigger** — it's just a
convenient data container the toolset can edit.

### Step 2 — variables on the area say HOW MANY

Open the area's properties → Advanced → Variables and set:

| Variable | Type | Meaning |
|---|---|---|
| `random1` | string | resref of the .ute blueprint (e.g. `bandit_moderate`) |
| `random1_spawns` | int | how many creatures to spawn (actual count is this + up to 25% extra, `area_refresh.nss:61`) |
| `cr` | int | **required** — the area's challenge rating; drives loot, XP, treasure maps |
| `random1_spawn_script` | string | *optional* — script run on each spawned creature, staggered 0.3 s apart |

Real example (`src/git/bandit_cave.git.json`):
`random1 = bugbear_moderate`, `random1_spawns = 15`, `cr = 7`.

For a second group in the same area, repeat with `random2`, `random2_spawns`, …

### Step 3 — marker creatures say WHERE

In the toolset, place the palette creature whose **resref is the group name**
(`random1`, `random2`, … — blueprints in `src/utc/random1.utc.json` etc.)
wherever that group may spawn. Scatter as many as you like.

At module load, `area_init.nss:417-425` finds each marker by its resref
prefix, stores its location as `random<N>_spawn_point<M>` on the area, counts
them into `random<N>_spawn_point_total`, and **deletes the marker**. Players
never see them.

At refresh, `area_refresh.nss:52-144` distributes the group across those
points: ~60% spread evenly, the rest at random points, every creature facing a
random direction. This spreading exists because clustered spawns made areas
"way harder than whoever designed the area intended" (comment at line 64).

**That's it.** Blueprint + two variables + markers = a working spawn.

---

## 3. Hand-placed (static) spawns

Sometimes you want *this exact creature standing exactly here* (a guard, a
merchant, a boss). Just place the creature normally in the toolset. What
happens depends on the creature:

- **Normal creatures** — `area_init.nss:427-439` records the resref, position,
  and facing into `creature_<N>_*` locals, then deletes the instance.
  `area_refresh.nss:256-284` respawns it *at that exact spot* on every refresh.
  You get a fresh copy each cycle (dead ones return).
- **Immortal-flagged creatures** (and `hen_*` henchmen) — skipped entirely
  (`area_init.nss:336-348`). They are placed once and persist; use for
  merchants and quest NPCs that must never reset. Quest/merchant NPCs with
  plot/immortal also get `dm_immune` set.
- **Placeables with resref prefix `plx_`** — same record-and-respawn treatment
  as creatures (`area_init.nss:441-456`); use for barrels, crates, etc. that
  should reappear each refresh.

---

## 4. Event spawns (occasional set-pieces)

An area can host random one-off "events" — ambushes, ghost scenes, whatever a
script does:

1. Place waypoints with resref **`_wp_event`** at candidate locations
   (`src/utw/_wp_event.utw.json`). `area_init.nss:360-365` tags them
   `<arearesref>WP_EVENT<N>`.
2. On the area, set string variables `event1` … `event9` = script names, and
   optionally `event_chance` (int, default 50).
3. On each refresh (`area_refresh.nss:228-252`), there is an `event_chance`%
   roll; on success one random event script runs with a random event waypoint
   as `OBJECT_SELF`. Your event script spawns whatever it wants there — see
   `spawn_brokenfang.nss`, `spawn_giantraven.nss` for examples. Remember to
   `AddObjectToAreaCleanupList()` anything you create.

---

## 5. Rares — the 15% treat

Each refresh has a **15%** chance (`CHANCE_OF_RARE_SPAWN`,
`area_refresh.nss:8`) to spawn exactly one *rare*: the system collects every
group whose .ute has a `rare` variable, picks one group, and substitutes the
rare's resref at one random spawn point (`area_refresh.nss:93-98,309-350`).
Rares typically carry better loot and tie into the bestiary. To give your new
group a rare, just set the `rare` variable on its .ute blueprint.

---

## 6. What happens to each spawned creature

Every creature spawns with its OnSpawn event = `ai_onspawn.nss` (set on the
creature blueprint). It runs *per creature, at spawn time* and:

- stamps `cr` (own challenge rating) and `area_cr` (the area's `cr`) locals —
  these drive loot tier selection, XP, and treasure-map drop rolls;
- signals the user-defined spawn event for custom AI;
- handles specials via creature locals: `boss` / `semiboss` (better loot, map
  drop multipliers), `familiar`, pickpocketable loot, key copying, etc.

And every spawned thing is registered with
`AddObjectToAreaCleanupList(oArea, oObject)` (`inc_area.nss`) so
`area_cleanup` can erase it when the area resets. **If you write a custom
spawn script and forget this call, your creatures leak** — they survive
refresh and pile up forever.

---

## 7. Worked example: add a wolf pack to a new area

Goal: a forest area with ~12 wolves, occasionally a dire wolf, rarely a
legendary white wolf.

1. **Encounter blueprint.** Copy `wolf.ute` (or make one): commons = `wolf`;
   unique (Single Spawn ✓) = `direwolf`; difficulty Normal; add variable
   `rare` = `wolf_white` (string). Save as resref `wolf_forest`.
2. **Area variables** (area properties → Variables):
   - `cr` (int) = `4`
   - `random1` (string) = `wolf_forest`
   - `random1_spawns` (int) = `12`
3. **Markers.** Place 6–10 creatures with resref `random1` around the woods —
   dens, clearings, path bends. More markers = better spread.
4. *(Optional)* `random1_spawn_script` (string) = a script to customise each
   wolf as it spawns:

```c
// wolf_spawn.nss - runs once per spawned wolf, OBJECT_SELF = the wolf
void main()
{
    // 1 in 20 wolves is scarred and slightly tougher
    if (d20() == 20)
    {
        SetName(OBJECT_SELF, "Scarred " + GetName(OBJECT_SELF));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                            EffectTemporaryHitpoints(10), OBJECT_SELF);
    }
}
```

5. **Test.** Start the dev server, enter the area (first entry triggers the
   refresh), check the server log — `area_refresh` and `SendDebugMessage`
   lines report spawn counts. Leave the area empty and wait (or use
   `dev_refresh`) to watch the cleanup/respawn cycle.

---

## 8. Variable reference (area, unless noted)

| Variable | Type | Purpose |
|---|---|---|
| `cr` | int | Area challenge rating. Required for loot/XP/maps. |
| `random<N>` | string | .ute resref for spawn group N (1–9). |
| `random<N>_spawns` | int | Base creature count for the group. |
| `random<N>_spawn_script` | string | Optional per-creature script at spawn. |
| `event<N>` | string | Event script names (1–9). |
| `event_chance` | int | % chance per refresh of an event (default 50). |
| `trapped` | int | 1 = seed random trap locations for the area. |
| `init_script` / `enter_script` / `exit_script` / `refresh_script` | string | Area-specific hooks run by init/enter/exit/refresh. |
| on the .ute: `rare` | string | Resref of the group's rare creature. |
| on a creature: `boss`, `semiboss` | int | Loot/XP/map-drop tier flags. |
| on a creature: `skip` | int | 1 = area_init ignores this object entirely. |

---

## 9. Pitfalls

- **`random1` set but nothing spawns** → you forgot `random1_spawns` (count
  defaults to 0, `area_refresh.nss:59-60`) or placed no `random1` markers
  (spawn-point total 0 skips the group, `area_refresh.nss:340-341`).
- **Forgot `cr` on the area** → spawns appear but loot/XP/treasure systems
  misbehave; treasure maps ignore the area entirely.
- **Marker resref, not tag.** `area_init` matches markers by **resref**
  (`random` + digit). Renaming the *tag* of some other creature does nothing.
- **Testing edits without restarting** — `area_init` runs at module load.
  Variable/marker changes need a server restart (spawn *counts* on an already
  running server only need the area to refresh).
- **Immortal creatures never reset.** If your "boss" is immortal-flagged,
  it's a permanent fixture, not a spawn.
- **Custom event/spawn scripts must call `AddObjectToAreaCleanupList`** or
  their objects survive every refresh and accumulate.
- **Don't hand-place live monsters** expecting them to respawn where you dropped
  them *and* wander — they respawn at the recorded spot each refresh, exactly
  (see the facing note in `inc_area.nss:39-45`).
