#include "inc_debug"

// OnUsed for the Spellbook Test Lever (pla_spellbktest / tag SpellbookTestLever).
// Spawns/re-rolls the 4 Dev Random caster NPCs next to the lever, each getting a
// freshly rolled random spellbook via their existing rand_test.nss spawn script.
// Requires seed_rand_spells.nss to already have been run once on this server so
// the campaign DB has seeded books to draw from - otherwise casters spawn with
// empty spellbooks while rand_test.nss's own retry/backfill logic keeps failing.

void SpawnTestCaster(string sResRef, object oArea, vector vBase, float fOffsetX, float fOffsetY, int nSlot)
{
    object oOld = GetLocalObject(OBJECT_SELF, "spellbook_test_" + IntToString(nSlot));
    if (GetIsObjectValid(oOld)) DestroyObject(oOld);

    vector vSpawn = vBase;
    vSpawn.x += fOffsetX;
    vSpawn.y += fOffsetY;
    location lSpawn = Location(oArea, vSpawn, 0.0);
    object oNew = CreateObject(OBJECT_TYPE_CREATURE, sResRef, lSpawn);
    SetLocalObject(OBJECT_SELF, "spellbook_test_" + IntToString(nSlot), oNew);
}

void main()
{
    object oPC = GetLastUsedBy();

    if (!GetIsDevServer())
    {
        SendMessageToPC(oPC, "The Spellbook Test Lever only works on the dev server.");
        return;
    }

    PlayAnimation(ANIMATION_PLACEABLE_ACTIVATE);

    location lHere = GetLocation(OBJECT_SELF);
    object oArea = GetAreaFromLocation(lHere);
    vector vBase = GetPositionFromLocation(lHere);

    SpawnTestCaster("testrandomcreatu", oArea, vBase, 3.0, -3.0, 0); // Dev Random Wizard
    SpawnTestCaster("testrandomcre001", oArea, vBase, 3.0, -1.0, 1); // Dev Random Sorc
    SpawnTestCaster("devrandomcleric",  oArea, vBase, 3.0,  1.0, 2); // Dev Random Cleric
    SpawnTestCaster("devrandomdruid",   oArea, vBase, 3.0,  3.0, 3); // Dev Random Druid

    SendMessageToPC(oPC, "Fresh Wizard, Sorcerer, Cleric, and Druid test casters spawned nearby, each with a newly rolled random spellbook. Pull again for a new roll.");
}
