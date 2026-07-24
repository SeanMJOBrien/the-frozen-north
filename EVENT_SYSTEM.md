# The Frozen North — Event & Spawn System Architecture

A map of how this module boots, routes events, and spawns its world. Companion
to `SPAWN_SYSTEM.md` (the step-by-step recipe for adding a spawn); this
document covers the whole machine. File references are `path:line` into
`src/nss/` unless stated otherwise.

---

## 0. The three layers

```
 LAYER 1: SEEDING (offline, special server run)
    Heavy precomputation -> campaign SQLite DBs ("spawns", "treasuremaps",
    "areadistances", prettify tables). Runs once per content change.

 LAYER 2: BOOT (every server start)
    on_mod_load: validate seed DBs, register ~60 NWNX hooks, initialise every
    area (area_init), stage treasure, then open the doors to players.

 LAYER 3: RUNTIME (event-driven)
    Vanilla module/area/creature events + NWNX before/after hooks + heartbeat
    timers drive everything: the area instance cycle, spawning, combat, loot.
```

The design principle throughout: **events read data; seeding writes it.**
Expensive work happens in Layer 1 so Layer 3 handlers stay cheap.

---

## 1. Boot sequence (`on_mod_load.nss`)

`Mod_OnModLoad = on_mod_load` (module.ifo). First act: raise the NWScript
instruction limit (`on_mod_load.nss:284`) so init can't TMI.

### 1a. Seed mode

If the server name contains `SEED` (`on_mod_load.nss:291`), this is not a play
server. `SeedMonitor()` (`:131`) walks six stages, advancing whenever the
current stage sets `seed_complete`, re-checking itself every second via
`DelayCommand(1.0, SeedMonitor())`:

| Stage | Gate constant (`:24-32`) | What it does |
|---|---|---|
| 0 | `SEED_SPAWNS` | `seed_area_spawns` per area → trap spawn points into campaign DB `spawns`; sets area tag = resref |
| 1 | `SEED_TREASURES` | `seed_treasure` → placeable treasure tables |
| 2 | `SEED_SPELLBOOKS` | `seed_rand_spells` (currently off) |
| 3 | `SEED_PRETTIFY_PLACEABLES` | per-area `prettify_script` → decorative placeable positions (~40 min) |
| 4 | `SEED_TREASUREMAPS` | `seed_treasuremap` → map puzzles + NUI drawings (~4 hours) |
| 5 | `SEED_AREA_CONNECTIONS` | `InitialiseAreas()` + `PrepareAreaTransitionDB()` → area-distance graph |

Then it logs a summary and **shuts the server down** (`:275`,
`NWNX_Administration_ShutdownServer`). The resulting SQLite files ship with the
server.

### 1b. Normal boot

- Refuses to start if the spawns DB is incomplete (`:333-340`) — random
  password + delayed shutdown, so players can't join a broken world.
- Registers all NWNX event subscriptions (§3) and two runtime-only vanilla
  slots (`:683-684`): `EVENT_SCRIPT_MODULE_ON_PLAYER_GUIEVENT = on_guiselect`,
  `EVENT_SCRIPT_MODULE_ON_NUI_EVENT = on_nuievent`.
- Loads prettify placeables from DB, runs `InitialiseAreas()` → `area_init`
  for every non-`_`/non-prefab area (`:104-129`, §4), stages treasure, sets
  `treasure_ready`.
- Meanwhile the module heartbeat is `mod_check_init` (module.ifo), which
  shouts "Initializing...", and once `treasure_ready` is set restores the
  instruction limit and passwords, **swaps the module heartbeat to
  `on_mod_heartb`**, fires the "server ready" webhook, and sets
  `init_complete` (`mod_check_init.nss`). That heartbeat swap is the moment
  the module goes live.

---

## 2. Vanilla module events (module.ifo)

| Slot | Script | Responsibility |
|---|---|---|
| OnModLoad | `on_mod_load` | Boot (§1) |
| OnHeartbeat | `mod_check_init` → `on_mod_heartb` | Init gate, then the 6-second world tick (§6) |
| OnClientEnter | `on_client_ent` | Login: map pins, house pin, player init |
| OnClientLeave | `on_client_exit` | Logout saves |
| OnActivateItem | `on_item_act` | Item unique-power dispatch (§5) |
| OnAcquireItem / OnUnAcquire | `on_item_acq` / `on_pc_item_una` | Item tracking |
| OnPlayerEquip / UnEquip | `on_pc_item_equ` / `on_pc_item_une` | Equip rules |
| OnPlayerChat | `on_pc_chat` | Chat commands |
| OnPlayerDeath / Dying | `on_pc_death` / `on_pc_dying` | PC death flow |
| OnPlayerRest | `on_pc_rest` | Rest rules / rested XP |
| OnPlayerLevelUp | `on_pc_level_up` | Level-up validation |
| OnSpawnButton | `on_pc_respawn` | Respawn button |
| OnPlayerGuiEvent, OnNuiEvent | *(set at runtime, §1b)* | GUI/NUI routing |

Areas, doors, and placeables mostly **don't** use their toolset event slots —
`area_init` overwrites them at boot (§4). Creatures use the `ai_*` suite baked
into their blueprints (§5).

---

## 3. NWNX hooks: the before/after layer

Vanilla events fire *after* the engine has decided something. NWNX events fire
**before or after engine internals**, and `before` handlers can veto the
action. `on_mod_load` subscribes ~60 of them; they fall into four families:

**DM permission gates** — every DM power routes through a checker:
`dm_chk_dev` (dev server only: give item/level/XP, set stat/variable, debug
scripts), `dm_chk_limit` (bounded gold/XP/alignment), `dm_chk_goto_dev` /
`dm_chk_area_dev` (movement), `dm_never` (hard-blocked: set time/date/faction,
change difficulty), `dm_spawnb`/`dm_spawna` (audit + fix up spawned objects).
This is a *policy* layer impossible with vanilla events.

**Anti-exploit / integrity** — `on_pc_save` (character save filtering),
`on_validatea` (ELC validation + the boot-on-refresh check,
`on_validatea.nss:115`), barter end, item drop, stack decrement, unpolymorph
before/after (the polymorph save-rollback problem you'll see referenced in
`inc_persist.nss`), store buy/sell before/after.

**Gameplay extensions** — stealth enter (`on_pc_stealth`), skill use
before/after, trap set/flag/disarm/recover/enter, examine before/after
(custom examine text), spell cast before/after (`remove_invis`,
mounted-casting checks), `event_has_feat` (feat spoofing),
`on_calendar_dusk` (day/night transitions).

**Performance override** — `creature_hb_ovr` on
`NWNX_ON_RUN_EVENT_SCRIPT_BEFORE`: intercepts creature heartbeat script runs
engine-side, skipping AI for creatures that don't need a tick. With hundreds
of spawned creatures, this is a large CPU saving.

The item-event framework (`inc_itemevent.nss`) also subscribes NWNX events
dynamically per item (equip/unequip/damage/attack...) — see §5.

---

## 4. `area_init` — the boot-time transformer

Run once per area at boot (`on_mod_load.nss:104-129` → `area_init.nss`), it
converts toolset data into runtime data. Per area it:

1. **Parses encounter blueprints.** For `random1`..`random9` string vars, loads
   the named `.ute` via `TemplateToJson` and flattens its creature list into
   `randomN_list` / `randomN_list_unique` CSV locals + unique-chance int
   (`area_init.nss:139-209`). The `.ute` is pure data — never a live encounter.
2. **Counts event scripts** (`event1..event9` → `events` int, `:216-222`).
3. **Overwrites area event slots** (`:229-231`): heartbeat=`area_hb`,
   enter=`area_enter`, exit=`area_exit`. Toolset-set area events are ignored;
   per-area behavior goes in `enter_script`/`exit_script`/`init_script`/
   `refresh_script` locals instead (§7).
4. **Object sweep** (`:282+`), the heart of the "world as data" design:
   - `random<N>` marker creatures → stored spawn-point locations, then deleted
     (`:417-425`).
   - Ordinary creatures → recorded as `creature_<N>_*` resref+coords, then
     deleted (`:427-439`). Immortals and `hen_*` henchmen are left alone
     (`:336-348`). Quest/merchant NPCs get `dm_immune` and are indexed for
     questgiver highlights.
   - `plx_` placeables → recorded and deleted like creatures (`:441-456`);
     trapped/imported placeables are sanitized (traps stripped, made static).
   - Doors → plot-flagged, events forced to `door_open`/`door_close`/
     `door_failopen`/`door_unlock`/`bash_lock`, lock data recorded
     (`:371-415`).
   - `_wp_event` waypoints → tagged `<resref>WP_EVENT<N>` (`:360-365`).
   - Transitions → `connection<N>` locals (used by the area-distance seeding).

After `area_init`, the area file's contents no longer matter — the area's
locals *are* the world definition.

---

## 5. Dispatcher conventions (one slot, many handlers)

The repo leans on ExecuteScript-by-naming-convention everywhere:

| Event arrives at | Dispatches to | Convention |
|---|---|---|
| `on_nuievent` | `<windowid>_evt` | NUI window id names its handler (`on_nuievent.nss:24`); a window can override via `event_script` user data |
| `on_item_act` + `inc_itemevent` | `is_<tag>` | Item tag names its script; same script also receives equip/unequip/subscribed NWNX events with `GetCurrentItemEventType()` discriminating |
| `area_refresh` | `random<N>_spawn_script` | Per-spawn-group creature customization |
| `area_*` | `init_script`, `enter_script`, `exit_script`, `refresh_script` | Per-area hooks |
| `ai_ondeath` | per-creature `ondeath_script` local (`ai_ondeath.nss:199`) | Boss/quest death specials |
| `area_refresh` events | `event<N>` script at a `WP_EVENT` waypoint | Set-piece spawns |

Creature AI is a fixed suite on every blueprint (`bandit.utc`):
`ai_onspawn`, `ai_onheartb`, `ai_onattacked`, `ai_ondamaged`, `ai_ondeath`,
`ai_onpercep`, `ai_oncombrnd`, `ai_onconverse`, `ai_ondisturb`, `ai_onblocked`,
`ai_onrest`, `ai_onspellcast`, `ai_onuserdef` — with `SignalEvent(...,
EventUserDefined(GS_EV_*))` linking them (e.g. `ai_onspawn.nss:55` signals
`GS_EV_ON_SPAWN`).

---

## 6. Heartbeats: the world's clocks

Three tick levels, largest to smallest:

- **Module** (`on_mod_heartb`, every 6 s): party revive checks (`DoRevive`,
  `:103`), stealth XP (`:22-79`), faction resets, orphaned-henchman cleanup
  (`:270+`), the wandering boss Yesgar's 200-heartbeat spawn gate (`:391-408`),
  and staggered per-PC stat DB flushes (`:410`).
- **Area** (`area_hb`): the instance cycle. Counts heartbeats while the area
  (and its `link<N>`-declared linked areas) hold no players; at
  `REFRESH_HEARTBEAT_COUNT` it runs `area_cleanup` (destroy everything on the
  cleanup list, stamp `cleaned_time`) and clears `refresh`
  (`area_hb.nss:99-118`) so the next visitor triggers a fresh spawn.
- **Creature** (`ai_onheartb`, gated by `creature_hb_ovr`): individual AI.

---

## 7. The spawn system in one page

Full recipe with worked example: **`SPAWN_SYSTEM.md`**. The architecture:

```
 SEED  seed_area_spawns: trap points -> campaign DB     (once, seed server)

 BOOT  area_init: .ute blueprints -> list locals
                  markers/creatures/placeables -> coordinate locals (+delete)

 PLAY  first PC enters -> area_enter (:120-127) sees refresh==0
          -> area_refresh:
               placeable treasure to a gold budget        (:146-226)
               50%-chance set-piece event at a WP_EVENT   (:228-252)
               static creatures + plx_ placeables         (:256-307)
               randomN groups across spawn points,
                 60% spread evenly, uniques by difficulty,
                 15% one rare per refresh                  (:8,52-144,309-350)
          -> every creature fires ai_onspawn (cr/area_cr stamps, boss flags,
             pickpocket loot, familiar handling)
          -> everything registered via AddObjectToAreaCleanupList

 DEATH ai_ondeath -> party_credit (XP + quest/bounty credit + loot rolls,
          incl. RollForTreasureMap via the loot system)
       -> Sir Elric respawn timers (inc_respawn: 600s + d300s) can restore
          individual creatures mid-cycle without a full refresh

 RESET area_hb counts empty heartbeats -> area_cleanup -> refresh flag
       cleared -> next entry respawns everything
```

Two spawn paths outside that cycle: `on_mod_heartb`'s Yesgar (module-level
wandering boss), and DM spawns audited by `dm_spawna`/`dm_spawnb`.

---

## 8. Extension-point cheat sheet

Want to add behavior? There is almost always a hook — don't edit the core
scripts:

| You want | Set this | Runs |
|---|---|---|
| Custom logic when an area spawns | `refresh_script` (area string) | end of `area_refresh` |
| Custom logic on PC enter/exit | `enter_script` / `exit_script` (area) | end of `area_enter`/`area_exit` |
| Custom area init | `init_script` (area) | during seeding/init |
| Customize each spawned creature | `random<N>_spawn_script` (area) | per creature, staggered |
| Set-piece events | `event<N>` + `_wp_event` waypoints | per refresh, `event_chance`% |
| Special death behavior | `ondeath_script` (creature) | `ai_ondeath` |
| New activatable item | tag it `X`, write `is_X.nss` | item framework |
| New NUI window | id `Y`, write `Y_evt.nss` | `on_nuievent` |
| Rare creature for a group | `rare` var on the `.ute` | 15%/refresh |
| Block/permit a DM power | edit the `dm_chk_*` policy scripts | NWNX gates |

---

## 9. Reading order for a new developer

1. `SPAWN_SYSTEM.md`, then place one spawn group in a test area and watch the
   log through a full refresh/cleanup cycle.
2. `area_init.nss` top to bottom — it explains what the toolset data *means*.
3. `area_refresh.nss` + `area_hb.nss` + `area_cleanup.nss` — the instance cycle.
4. `on_mod_load.nss` — boot + the NWNX subscription list (skim; return as needed).
5. `ai_onspawn.nss` / `ai_ondeath.nss` / `party_credit.nss` — a creature's life.
6. `inc_itemevent.nss` header comment — the item framework's contract.

The recurring pattern to internalize: **toolset objects are compiled away at
boot; the live world is rebuilt from locals and DBs on demand; every event
handler is a thin reader with a named `_script` escape hatch.**
