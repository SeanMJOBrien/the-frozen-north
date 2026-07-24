# Changes Pending Since Last Commit — Summary & Test Plan

**Last commit:** `9e66db1b`, 2025-10-06 (~10 months ago). Nothing has been
committed since — everything below is **uncommitted working-tree state**,
verified against `git diff`/`git status` on 2026-07-21. There is no other
history to draw from; this file *is* "the last 3 months" (and then some).

---

## 0. Read this first: your two bug reports

### "Bandit Thug is still 100% dwarf"

Confirmed why: the fix (below, §2.14) was compiled and packed into
`.build/modules/TFN.mod` in *this* working copy
(`/home/qlippoth/git/the-frozen-north`), but that build was never deployed
anywhere. The two currently-running NWN containers are:

| Container | Mounted from | Is this our module? |
|---|---|---|
| `build_tfn-server-dev_1` | `/home/qlippoth/git/dwarfgve3/.build` | **No** — different project (DwarfStory/gve3), name collision only |
| `server_tfn-server_1` | `/home/tfn/the-frozen-north/server` | Possibly — but a **separate checkout**, owned by a different user (`tfn`); this session has no read access to confirm what it's running |

So whatever you tested against was not running the new build. **This
repo's own dev server (`linux_run_server_dev.sh`) isn't currently running
at all.** To test the race fix, you need to either start that dev server
from this checkout, or get the freshly-built `.mod` (or this source tree)
onto whatever `/home/tfn/the-frozen-north/server` actually runs — I can't
reach that path to do it for you.

### "Bandits are no longer Bandit Outlaws, only Bandits"

I could not find a cause for this in the source. Checked:

- `bandit_outlaw.utc.json` blueprint — present, unchanged from HEAD.
- Hand-placed `bandit_outlaw` instances in `nw_northeastroad.git.json`,
  `nw_river.git.json`, `pl_southroad.git.json` — present, identical between
  HEAD and the working tree (byte-for-byte same reference count).
- `bandit_strong.ute.json` encounter table listing `bandit_outlaw` — present,
  unchanged.
- Every `.nss` diff touching bandits (`rand_bandit.nss`, `ai_onspawn.nss`) —
  neither sets or clears any Name/Tag/ResRef field; `rand_bandit.nss`'s new
  race call runs on race only (see §2.14).

Since the fix was never deployed (see above), this can't be something *I*
caused either. Most likely explanation given the deployment confusion above:
whatever you're actually testing against is running a **different build**
than this source tree — possibly older, possibly a different checkout
entirely. Before I can chase this further I need to know: **which server
were you actually connected to when you saw plain "Bandit"** — the
`/home/tfn/...` one, or something else? That'll tell us whether to compare
its installed `.mod` against this source, or look elsewhere.

---

## 1. New dev tooling (not gameplay-affecting)

A "Bug Tester" dev NPC + conversation + 13 verification scripts were added to
manually confirm the fixes in §2, in-game, without a unit-test framework.
Full details already written up in `BUGFIX_TESTING.md` — this section is
just the file inventory:

| File | Purpose |
|---|---|
| `src/utc/dev_bugtest.utc.json` | The NPC blueprint (tag/resref `dev_bugtest`) |
| `src/dlg/dev_bugtest.dlg.json` | Its conversation (13 test options + exit) |
| `src/nss/dlg_tst_*.nss` (13 files) | One verification script per fix |
| `BUGFIX_TESTING.md` | Full walkthrough: setup, prerequisites, pass/fail criteria per test |
| `SPAWN_SYSTEM.md` | Reference doc: how the area/encounter/spawn system works (unrelated to the bugfixes; written as onboarding material) |
| `EVENT_SYSTEM.md` | Reference doc: module boot/event architecture (same — onboarding material) |

These are dev-only and explicitly flagged in `BUGFIX_TESTING.md` to be kept
out of shipped areas / dropped before a release build.

---

## 2. Gameplay-affecting fixes (14 total)

Numbers 1–13 are exactly as documented in `BUGFIX_TESTING.md` (see that file
for full detail, prerequisites, and exact pass/fail criteria per test) —
summarized here for completeness. **#14 is new this session, not yet in
that document.**

| # | File | Bug | Fix |
|---|---|---|---|
| 1 | `on_client_ent.nss` | Race stored on module (shared across all PCs) instead of the entering PC; `ON_MELEE_ATTACKED`/`ON_SPELLCASTAT` handlers swapped | Store on `oPC`; un-swap handlers |
| 2 | `on_mod_heartb.nss` | `if (STANDARD_FACTION_DEFENDER)` always true — every creature treated as friendly for revive logic; `DestroyObject` called on possibly-invalid store | Compare faction properly; guard with `GetIsObjectValid()` |
| 3 | `70_mod_polymorph.nss` | Item ability bonuses computed from base struct each slot instead of running total — only the last equipped item's bonus applied | Chain from the running total |
| 4 | `inc_lootselect.nss` | `nLootType & (MELEE+RANGE) > 0` — operator precedence bug, evaluates as `nLootType & 1` | Parenthesized correctly |
| 5 | `pptreas_open.nss` | Pickpocket-chest quantity rolls reversed — ~76% of opens gave 4 items, "2" and "3" outcomes unreachable | Rewritten as nested `roll <= chance` |
| 6 | `inc_xp.nss` | `GetPartyXPValue()`'s `fMultiplier` param shadowed by a local re-declaration — custom multipliers always silently became 1.0 | Removed the shadowing re-declaration |
| 7 | `inc_adventurer.nss` | `SelectAdventurerPath()` weighted-random walk biased (wrong loop boundary) — skewed which class path got picked | Subtract-then-break-on-negative, matching the already-correct sibling function |
| 8 | `seed_treasure.nss` | Stack size set on stale/wrong item reference (`oNewItem` vs `oNewItemStaging`) | Set size on the correct staging object |
| 9 | `inc_loot.nss` | `bCreateIfMissing=FALSE` ignored — loot containers created as a side effect of read-only queries | Gated creation on the parameter |
| 10 | `inc_treasuremap.nss` | SQL used `<=` instead of `=` on puzzle id (wrong row matched); dig-message `if` should've been `else if` | Fixed comparison; fixed branch |
| 11 | `inc_party.nss` | Dev loot-debug path read level from the wrong (invalid) object, dragging party-average-level math to 0 | Read from the correct object |
| 12 | `j_ai_ondeath.nss` | Floating text called against an invalid master object when a henchman-AI creature has no master | Guarded with `GetIsObjectValid()` |
| 13 | `ai_onspawn.nss` | Pickpocket flag/XP set even when no lootable item was actually generated | Wrapped in `GetIsObjectValid(oItem)` |
| 14 | `rand_bandit.nss` | **New.** Every `bandit_*` blueprint kept a static, blueprint-baked `Race` — never randomized. `bandit_fighter` ("Bandit Thug") happened to be baked Dwarf, so it was Dwarf 100% of the time; `bandit`/`bandit_captain`/`bandit_leader`/`bandit_outlaw` were always Human, `bandit_mage` always Elf | Added a call to the existing `RandomiseCreatureRacialType()` helper, gated to `bandit*` resrefs (excludes `duergar_slave`, which shares this script but isn't a bandit) — uniform 1-in-7 per race |

Plus 6 more fixes not wired into the Bug Tester dialog (manual/compile-only
verification — see `BUGFIX_TESTING.md`'s second table): `70_inc_itemprop.nss`
(negative save penalties passed a negative into a function expecting
magnitude), `enter_maker4.nss` (inverted trap-respawn condition),
`refresh_maker2.nss` (traps all spawned at one waypoint instead of their own),
`inc_treasuremap.nss` dig-message branch (counted above), `is_spectreclaw.nss`
and `mer_ravyn.nss` (unused-variable cleanup, no behavior change).

---

## 3. What you need to do to test all of this

### 3.1 Build

From `/home/qlippoth/git/the-frozen-north`:

```sh
./tools/linux/nasher/nasher pack -y \
  --erfUtil:"$PWD/tools/linux/neverwinter/nwn_erf" \
  --gffUtil:"$PWD/tools/linux/neverwinter/nwn_gff" \
  --tlkUtil:"$PWD/tools/linux/neverwinter/nwn_tlk" \
  --nssCompiler:"$PWD/tools/linux/nwnsc/nwnsc" \
  --nssFlags:"-lowqey -i $PWD/.build/include-shims -i $PWD/nwn-base-scripts"
```

This is what I ran this session; it produced `.build/modules/TFN.mod`
(2110 scripts compiled clean). `.build/` is gitignored, so this is safe to
re-run any time and doesn't touch git state.

Note: `linux_nasher_install.sh` (the repo's own full-install script) also
works but additionally **wipes and reseeds every campaign database**
(spawns/treasures/tmapsolutions/etc.) and deletes `.build/modules` first —
don't run it if you have live seeded data in `.build/database` you want to
keep. The `nasher pack` invocation above only rebuilds the module.

### 3.2 Deploy — the part I can't do for you

Figure out which of these matches how you actually test, then get the new
`.build/modules/TFN.mod` (or this whole source tree) there:

- **This checkout's own dev server** — `./linux_run_server_dev.sh` (brings up
  `docker-compose-dev.yml` from `.build/`). Nothing is running from this
  checkout right now, so this is the easy path if it's how you normally test.
- **The `/home/tfn/the-frozen-north/server` deployment** — separate user
  account, this session has no read/write access to it. If that's your test
  target, you (or whoever manages that account) need to sync this source
  and rebuild there, or copy the `.mod` over.

### 3.3 Run the Bug Tester

Once a server with this build is up:

1. Log in as DM, `dm_spawncreature dev_bugtest` (or spawn via DM creator).
2. Talk to him — 13 dialog options, each runs one test and prints
   `PASS`/`FAIL` (or in one case, a log-only check — see `BUGFIX_TESTING.md`
   §12 for the exact criterion). Some tests have placement prerequisites
   (noted per-test in that file); a town area near NPCs of mixed factions,
   next to a seeded ammo chest, with no other PCs within 20 m, satisfies
   most of them at once.

### 3.4 Test #14 (the race fix) specifically

Not wired into the Bug Tester dialog yet (it postdates that doc). To check
by hand: spawn several `bandit_fighter` (or any `bandit*`) instances — e.g.
`dm_spawncreature bandit_fighter` repeated 15–20 times — and confirm race
varies (roughly even split across Dwarf/Elf/Gnome/HalfElf/HalfOrc/Halfling/
Human) instead of 100% one race. `duergar_slave` should be unaffected (still
whatever its blueprint says).

### 3.5 The still-open "Bandit Outlaw" question

Once you've confirmed *which* server/build you were actually looking at, we
can compare its installed `.mod` against this source (extract the shipped
`rand_bandit.ncs`/`ai_onspawn.ncs`/relevant `.ute`/`.git` and diff, per the
"stale build artifact" pattern) to find where the discrepancy actually is.
