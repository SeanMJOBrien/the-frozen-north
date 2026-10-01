// Test: party_credit.nss bug (bDestroyed derived from hit points only)
// A death effect -- an engine coup de grace on a sleeping target, finger of death,
// implosion, ... -- kills without reducing hit points, so the corpse used to be
// treated like an intact container and no _loot_container loot bag was spawned.
// Before fix: no loot bag appears (and any quest_item is lost with it).
// After fix: a loot bag appears even though the corpse still has positive hit points.

const string TEST_RESREF = "ogre_lord"; // boss with quest_item "b_ogre_head"
const float TEST_RADIUS = 8.0;

int CountLootBags(location lLocation)
{
    int nCount = 0;
    object oTest = GetFirstObjectInShape(SHAPE_SPHERE, TEST_RADIUS, lLocation, FALSE, OBJECT_TYPE_PLACEABLE);
    while (GetIsObjectValid(oTest))
    {
        if (GetResRef(oTest) == "_loot_container") nCount++;
        oTest = GetNextObjectInShape(SHAPE_SPHERE, TEST_RADIUS, lLocation, FALSE, OBJECT_TYPE_PLACEABLE);
    }
    return nCount;
}

void ReportResult(object oPC, object oTarget, location lLocation, int nBaselineBags)
{
    int nBags = CountLootBags(lLocation) - nBaselineBags;

    if (GetIsObjectValid(oTarget))
    {
        SendMessageToPC(oPC, "Corpse hit points after death effect: "
            + IntToString(GetCurrentHitPoints(oTarget)) + " (positive is the bug's trigger)");
    }

    SendMessageToPC(oPC, "New loot bags nearby: " + IntToString(nBags));

    if (nBags > 0)
        SendMessageToPC(oPC, "PASS: loot bag spawned from a death-effect kill");
    else
        SendMessageToPC(oPC, "FAIL: no loot bag -- bDestroyed still derived from hit points only");

    if (GetIsObjectValid(oTarget)) DestroyObject(oTarget);
}

void main()
{
    object oPC = GetPCSpeaker();
    SendMessageToPC(oPC, "=== party_credit: loot bag after a death effect ===");

    location lLocation = GetLocation(OBJECT_SELF);
    int nBaselineBags = CountLootBags(lLocation);

    object oTarget = CreateObject(OBJECT_TYPE_CREATURE, TEST_RESREF, lLocation, FALSE);
    if (!GetIsObjectValid(oTarget))
    {
        SendMessageToPC(oPC, "SKIP: could not spawn '" + TEST_RESREF + "'");
        return;
    }

    // don't announce a test kill to the module's Discord webhook
    DeleteLocalInt(oTarget, "defeated_webhook");

    // ai_ondeath only awards credit for a kill the party is tied to
    SetLocalInt(oTarget, "player_tagged", 1);

    SendMessageToPC(oPC, "Spawned " + GetName(oTarget) + " with "
        + IntToString(GetCurrentHitPoints(oTarget)) + " hit points. Killing with EffectDeath...");

    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDeath(), oTarget);

    DelayCommand(1.5, ReportResult(oPC, oTarget, lLocation, nBaselineBags));
}
