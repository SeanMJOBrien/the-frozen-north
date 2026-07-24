# Open Issues

## Bandit Outlaw displays as "Bandit" in-game

**Reported:** 2026-07-21. Hand-placed `bandit_outlaw` creatures (and possibly
other `bandit_*` types) show a nameplate of "Bandit" instead of their correct
blueprint name.

**Ruled out** (verified 2026-07-21):
- Not a source data problem — `bandit_outlaw.utc.json`'s `FirstName`
  (`id: 24586` + inline `"Bandit Outlaw"`) is identical in source, after a raw
  `nwn_gff` round-trip, and in the packed `.build/modules/TFN.mod`.
- Not the shared leftover strref — id 24586 resolves to `"Former Prisoner"`
  in `dialog.tlk` (leftover from cloning off a "Former Prisoner" quest NPC;
  21 blueprints share it, including `bandit`/`bandit_outlaw`/`bandit_mage`/
  `bandit_captain`/`bandit_leader`/`duergar_slave` and various prisoner/
  smuggler/named NPCs, all sharing Tag `m1q2_FormPris2W` too). If the engine
  preferred the strref over the inline override you'd see "Former Prisoner",
  not "Bandit" — so this isn't the active mechanism, though it's still a
  latent landmine worth cleaning up separately.
- Not a duplicate-tag `GetObjectByTag` bug — no script in `src/nss/`
  references `m1q2_FormPris2W` at all.
- The hand-placed creature record/respawn mechanism (`area_init.nss`
  records `creature_resref<N>`/position at module load;  `area_refresh.nss`
  recreates from that data on refresh) looks structurally sound and neither
  file is part of any pending change.

**Status (2026-07-22):** user will test the DM-spawn-by-resref repro above to
confirm before further work.

---

## ~~Adventurer party spawns show 5 creatures stacked at one spot~~ — closed, by design

**Reported:** 2026-07-22. Expected 1, maybe 2, adventurers per spawn location;
seeing 5 in the same spot.

**Status (2026-07-22): closed — confirmed by design, not a bug.** Kept the
investigation notes below for reference in case it resurfaces.

**Confirmed code defect** (`eve_advparty.nss:76-98`): party size is picked by
building a `jPossibilities` array of the sizes (1-5) still valid at the
current `nAdventurerHD` (each capped so no member's HD would exceed 12),
shuffling it, and taking element 0. Sizes 1-4 all have an upper-HD gate
(`nAdventurerHD+3 <= 12`, `+2 <= 12`, `<= 12`, `-1 <= 12`) but **size 5's
check only has a lower bound** (`nAdventurerHD-2 >= 3`, no upper limit) - a
deliberate choice per the code's own comment ("they'll all end up capped to
12 anyway, so no reason to check the high end for this one"). Once
`nAdventurerHD` reaches 14 (reachable via `eve_advparty.nss:58`'s escalation
loop, `while (Random(100)<30 && nAdventurerHD<14) nAdventurerHD++`), sizes
1-4 all fail their gates and size 5 is the *only* array entry left - not
more likely, but deterministic.

**Ruled out as the common-case explanation:** `area_refresh.nss:235-251`
fires the area's random event exactly once per refresh (not per-PC), so this
isn't duplicate per-player triggering. And the dominant trigger path,
`eve_wilderness.nss` (18 areas dispatch to it, all CR 4-6), starts
`nAdventurerHD` low enough that reaching HD 14 via the escalation loop is
statistically rare (~9 consecutive 30% rolls). Only 2 areas in the whole
module are high-CR enough to hit this directly by default
(`iceflow_dragon` CR 15, `ud_maker4` CR 14) - neither currently wires
`eve_advparty` as a direct area event.

**Next step:** need the specific area/zone where this was observed, to tell
whether it's the confirmed high-HD code path (matches a high-CR area) or a
separate, not-yet-found mechanism (e.g. if this happened in a CR 4-6
wilderness area, the size-5 gate isn't the explanation and something else is
going on).
