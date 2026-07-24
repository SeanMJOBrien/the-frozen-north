# Bug-Fix Testing Guide

This document describes the bug fixes currently in the working tree (18 modified
scripts) and how to verify them in-game using the **Bug Tester** dev NPC.

## The test NPC

| Piece | File |
|---|---|
| NPC blueprint (resref/tag `dev_bugtest`) | `src/utc/dev_bugtest.utc.json` |
| Conversation | `src/dlg/dev_bugtest.dlg.json` |
| Test scripts (one per dialog option) | `src/nss/dlg_tst_*.nss` |

The NPC is plot and immortal, so tests that spawn hostile creatures or apply
damage cannot kill him. He is not placed in any area — spawn him where you want
to test.

Blueprint notes (in case the NPC needs to be rebuilt or tweaked):

- Cloned from `adventurer.utc.json` (a plain human with the module's standard
  `ai_onconverse`/`ai_onspawn` event scripts), then: `TemplateResRef`, `Tag`,
  and `Conversation` all set to `dev_bugtest`; `Plot` and `IsImmortal` set
  to 1; name set to "Bug Tester".
- The adventurer's `VarTable` was **stripped** — it carried
  `heartbeat_script=fol_heartb` (follower heartbeat), which would have made
  the NPC wander after players, plus adventurer-system variables
  (`persuade_dc` etc.) that don't apply.
- The inherited TLK string refs (`id` fields on `FirstName`/`LastName`) were
  removed — a leftover strref can override the embedded name in-game.
- The JSON is in `nwn_gff`'s canonical pretty format (`-k json -p`), same as
  every other blueprint in `src/`, so nasher round-trips it without noise.

The conversation has a single NPC entry ("Welcome, developer. Select a bug fix
to test.") and 14 replies: options 1–13 each fire one `dlg_tst_*` script via
the reply's action script and loop back to the menu; option 14 exits.

### Setup

1. Build the module: `./linux_nasher_install.sh` (or the dev variant you use).
2. Start the dev server: `./linux_run_server_dev.sh`.
3. Log in as a DM (or use the DM client) and spawn the NPC by resref:
   `dm_spawncreature dev_bugtest` in the console, or via the DM creator.
4. Talk to him. Each dialog option runs one verification script and returns to
   the menu, so you can run all tests in a single conversation. Results are
   printed to your chat window as server messages — most tests print an explicit
   `PASS` / `FAIL` line.

Some tests have placement prerequisites, noted per test below. A good spot that
satisfies all of them at once: a town area with commoner/merchant NPCs nearby,
next to a seeded loot chest (weapon/ammo type), while no other PCs are within
20 m of you.

---

## Fixes covered by the dialog (options 1–13)

### 1. `on_client_ent.nss` — race stored on module + swapped event scripts

Two bugs in the client-enter handler:

- **A:** `GetHasEffect(EFFECT_TYPE_POLYMORPH)` was missing the `oPC` argument
  (so it checked the module), and `BASE_RACE` / `BASE_RACE_SET` were stored on
  `OBJECT_SELF` (the module) instead of the entering PC. Every player was
  sharing one module-wide "base race" — whichever PC logged in last.
- **B:** The `ON_MELEE_ATTACKED` event was wired to `on_pc_spellcast` and
  `ON_SPELLCASTAT` to `on_pc_attacked` — the two handlers were swapped.

**Test (option 1):** checks that `BASE_RACE_SET` is 1 on you and 0 on the
module, and that your event scripts point to the right handlers. Prints a
single combined `PASS`/`FAIL`. *Prerequisite: log in fresh (the values are set
on client-enter), and don't be polymorphed when you log in.*

### 2. `on_mod_heartb.nss` — faction check always true + unguarded store delete

- **A:** In `DoRevive()`, `if (STANDARD_FACTION_DEFENDER)` compared a nonzero
  constant instead of the creature's faction, so **every** creature counted as
  a friendly commoner/defender/merchant for the revive logic. Restored the
  intended `nFaction == ...` comparison.
- **B:** `DestroyObject(oStore)` was called even when the dead NPC had no
  merchant store (`oStore` invalid). Now guarded with `GetIsObjectValid()`.

**Test (option 2):** scans creatures within 20 m and prints each one's faction
with the old result (always TRUE) next to the new result, so you can see
non-commoner factions now correctly excluded. Bug B is asserted directly
(guard vs. `OBJECT_INVALID`). *Prerequisite: stand near a few NPCs of mixed
factions (e.g. a town with guards and hostile spawns in range) for part A to
show a contrast.*

### 3. `70_mod_polymorph.nss` — item ability bonuses didn't stack

When polymorphing with the "keep item bonuses" shifter options, each equipment
slot's bonuses were computed as `abil2 = IPGetAbilityBonuses(abil, oItem)` —
chaining from the *base* struct every time instead of the running total
(`abil2`). Only the **last** slot processed actually contributed; bonuses from
all other equipped items were lost.

**Test (option 3):** computes the correctly-chained cumulative bonus of
everything you have equipped and prints the expected Str/Dex/Con/Int/Wis/Cha
totals. Then polymorph (as a class that keeps item bonuses, e.g. druid/shifter)
and confirm your polymorphed ability scores went up by those amounts.
*Prerequisite: equip 2+ items with ability bonuses on different slots — with
the bug you'd only see one item's worth.*

### 4. `inc_lootselect.nss` — operator precedence in rarity weights

`if (nLootType & (MELEE + RANGE) > 0)` parses as `nLootType & ((MELEE+RANGE) > 0)`
in NWScript — i.e. `nLootType & 1`. Whether a weapon got weapon-specific rarity
weights depended on bit 0 of its loot type rather than the weapon bits.
Parenthesized to `(nLootType & (MELEE + RANGE)) > 0`.

(Same file also gained a guard in `SelectLootItemFixedCategories()` returning
`OBJECT_INVALID` when the chest scan finds no item — see option 13, which
exercises the downstream effect.)

**Test (option 4):** calls `GetStandardLootRarityWeights()` for a melee weapon
type and an armor type and prints both weight arrays. `PASS` when weapons get
the weapon weights (common=37) and armor gets the generic ones (common=42);
`FAIL` if both come back identical.

### 5. `pptreas_open.nss` — reversed treasure quantity rolls

The pickpocket-treasure chest rolled `d100()` and compared with `bChanceFour <= roll`
etc. — backwards. With chances 75/50/25, a roll of 80 gave **four** items and
the "two items" and "three items" branches were unreachable: ~76% of opens gave
4 items, ~24% gave 1, never 2 or 3. Rewritten as nested `roll <= chance` checks
so the intended 25/25/25/25 distribution applies.

**Test (option 5):** simulates 1000 rolls through both the old and new logic
and prints both distributions side by side. `PASS` confirms the old logic was
degenerate (~240/0/0/760) and the new one is ~250 each.

### 6. `inc_xp.nss` — XP multiplier parameter ignored

`GetPartyXPValue()` takes an `fMultiplier` parameter, but the body re-declared
`float fMultiplier = 1.0;`, shadowing it. Callers passing a custom multiplier
(event bonuses etc.) silently got 1.0. The local re-declaration is removed.

**Test (option 6):** spawns a temporary rat and calls `GetPartyXPValue()` with
multiplier 1.0 and 2.0. `PASS` when the second result is exactly double;
`FAIL` when both are equal (bug behavior).

### 7. `inc_adventurer.nss` — adventurer path selection biased

`SelectAdventurerPath()` did weighted random selection with
`while (nRandom > 0) { nRandom -= weight; i++; }`. A roll of 0 skipped the loop
entirely, and the subtract-then-increment order shifted each path's window —
path 1 was overrepresented and the last path could be chosen with the wrong
probability. Now subtracts first and breaks when the remainder goes negative,
giving each path exactly weight/total probability.

**Test (option 7):** simulates 1000 selections with weights 60/110/150 through
both algorithms and prints the two distributions (expected ~188/344/469).
`PASS` when the fixed distribution matches expectations with no out-of-range
picks.

### 8. `seed_treasure.nss` — stack size set on wrong item

In `PopulateChestWeapon()`, ammo/thrown types did `SetItemStackSize(oNewItem, 1)`
— but at that point the freshly created item is `oNewItemStaging`; `oNewItem`
is stale (or invalid). Seeded ammo kept its default stack size, which breaks
the downstream per-item distribution logic. Now sets the size on
`oNewItemStaging`.

**Test (option 8):** finds the nearest `chest*`-tagged placeable and checks
every arrow/bolt/bullet/dart/shuriken/throwing-axe in it has stack size 1.
*Prerequisite: spawn the NPC near a seeded weapon chest that contains ammo
(or follow the fallback instructions the test prints).*

### 9. `inc_loot.nss` — `bCreateIfMissing` ignored

`GetPersonalLootForPC(oSource, oPC, bCreateIfMissing=FALSE)` created a personal
loot container whenever one was missing, regardless of the parameter. Callers
that only wanted to *query* (e.g. cleanup/inspection paths) were spawning
placeables as a side effect. The create branch now requires
`bCreateIfMissing`.

**Test (option 9):** creates a temporary loot source, calls the function with
`FALSE` (expects no container) then `TRUE` (expects a container), prints
`PASS`/`FAIL` for each, and cleans up after itself.

### 10. `inc_treasuremap.nss` — SQL `<=` instead of `=` (+ message chain)

- **A:** `UseTreasureMap()` validated a map's ACR with
  `SELECT minacr FROM treasuremaps WHERE puzzleid <= @puzzleid` — matching *any*
  lower puzzle id; the row returned was effectively arbitrary. Changed to `=`.
- **B (manual):** in `DigForTreasure()`, the surface-material 9 message check
  was `if` instead of `else if`, letting it override the wooden-floor message.
  Verify by digging up a treasure on wood vs. carpet and checking the flavor
  text.

**Test (option 10):** runs both the `<=` and `=` queries for puzzleid 2 against
the live `tmapsolutions` DB and compares. `PASS` when they agree; `FAIL` when
the `<=` form returns a different (earlier) row. *Prerequisite: the campaign DB
must contain at least two puzzles with different `minacr` for a conclusive
contrast (the test says so if the DB is empty).*

### 11. `inc_party.nss` — dev placeholder level read from wrong object

In `SetPartyData()`'s loot-debug path, the dev "loot vortex" placeholder member
computed its level from `oMbr` (invalid in that branch) instead of `oDev`, so
the placeholder contributed level 0 and dragged party-average-level loot math
down. Now reads `GetXP(oDev)`.

**Test (option 11):** temporarily registers you as the dev vortex, enables the
debug flag, recomputes party data on the NPC, restores everything, and checks
that `Party.AverageLevel` reflects your level rather than 0. *Prerequisite: no
other PCs within 20 m of the NPC (the test tells you if it detected any).*

### 12. `j_ai_ondeath.nss` — floating text on invalid master

A dying henchman-AI creature always called
`FloatingTextStringOnCreature(sText, GetMaster(OBJECT_SELF))`. With no master
(dismissed, orphaned, or debug-spawned) that's a call against
`OBJECT_INVALID`, which logs errors. Now guarded with `GetIsObjectValid()`.

**Test (option 12):** spawns a masterless `hen_bim`, confirms it has no master,
and kills it with divine damage. **PASS criterion is in the server log**: no
`FloatingTextStringOnCreature` error after the kill.

### 13. `ai_onspawn.nss` — pickpocket flag set with no item

`GeneratePickpocketItem()` marked the creature `pickpocket_xp=1` and set item
flags even when `SelectLootItemFromACR()` returned `OBJECT_INVALID` (e.g. CR-0
areas / empty loot pools). Rogues could earn pickpocket XP from creatures
carrying nothing. All of it is now inside a `GetIsObjectValid(oItem)` guard.
(This pairs with the new invalid-item guard in `inc_lootselect.nss`.)

**Test (option 13):** spawns a goblin next to the NPC and, after its spawn
event runs, `dlg_tst_spawnchk` reports whether `pickpocket_xp` is consistent
with the creature actually holding a pickpocketable item — `PASS` when flag
and item agree, `FAIL` when the flag is set with no item. *Prerequisite: best
run in an area with `cr=0` (the test prints the area CR and tells you if the
area is unsuitable for the clean negative case).*

---

## Fixes not covered by the dialog (manual / compile-only)

| File | Fix | How to verify |
|---|---|---|
| `70_inc_itemprop.nss` | Negative save penalties passed a negative value to `ItemPropertyReducedSavingThrow` (and the >12 cap never applied); now uses `abs()`. | Polymorph while wearing an item with a save *penalty*; check the penalty appears correctly on the merged creature weapon (option 3's polymorph flow exercises the same code path). |
| `enter_maker4.nss` | Trap-respawn condition was inverted/incomplete: it respawned the trap when the sling *was* safely on the ground in the area, and missed the sling-carried-away case. Now respawns when the sling is missing, out of the area, or in someone's inventory. | In the Maker dungeon (area 4): leave the sling on the ground → no trap on re-entry; carry it out and return → trap respawns. |
| `refresh_maker2.nss` | Every `maker2_trap` waypoint spawned its trap at `oWPOctagon` (a leftover TMI workaround) instead of at the waypoint itself. | Trigger the Maker area-2 refresh; traps appear at each trap waypoint, not stacked on the octagon. |
| `inc_treasuremap.nss` (B) | Dig-message `if` → `else if` (see option 10 notes). | Dig treasure on a wooden floor; message should mention the plank, not the carpet. |
| `is_spectreclaw.nss` | Removed unused `nSpellID` local. | Compile only — no behavior change. |
| `mer_ravyn.nss` | Removed unused `bNonUnique` local. | Compile only — no behavior change. |

---

## Test infrastructure fixes

Three test scripts originally spawned creatures by resrefs that don't exist in
this module, which would have made those tests silently `SKIP` (or fail to
produce a corpse/spawn at all). They were corrected to real blueprints, chosen
because their event scripts match what each test needs to exercise:

| Script | Was | Now | Why this blueprint |
|---|---|---|---|
| `dlg_tst_spawn.nss` | `c_goblin` | `goblin` | Has `ScriptSpawn = ai_onspawn`, the script under test (pickpocket item logic). |
| `dlg_tst_hndeath.nss` | `hen_warrior` | `hen_bim` | Has `ScriptDeath = j_ai_ondeath`, the script under test (masterless floating text). |
| `dlg_tst_xp.nss` | `c_rat` | `rat` | Plain CR 0.5 creature with no boss/semiboss/rare flags, so `fMultiplier` is the only variable. |

The `_loot_container` placeable used by the `inc_loot` test (option 9) was
verified to exist (`src/utp/_loot_container.utp.json`) — it's the same
blueprint `GetPersonalLootForPC()` itself creates, so the test matches
production behavior.

## Verification status

- All 14 `dlg_tst_*` scripts compile clean against `nwn-base-scripts` with
  `nwnsc` (run from `src/nss/`, since `nwnsc -b` mirrors input paths):
  `../../../nwn-tools/linux/nwnsc/nwnsc -i ../../nwn-base-scripts -i . -b <out> dlg_tst_*.nss`
- `dev_bugtest.dlg.json` and `dev_bugtest.utc.json` round-trip through
  `nwn_gff` (JSON → GFF → JSON) without errors.
- The NPC, dialog, and test scripts are dev-only tooling: keep them out of
  shipped areas, and consider dropping them from release builds once the fixes
  are merged.
