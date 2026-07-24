// Test: inc_xp.nss bug (fMultiplier parameter shadowed by local re-declaration)
#include "inc_xp"

void main()
{
    object oPC = GetPCSpeaker();
    SendMessageToPC(oPC, "=== inc_xp: fMultiplier parameter ===");

    // Create a temporary rat near the NPC — not boss/semiboss so multiplier should be the only factor
    object oTemp = CreateObject(OBJECT_TYPE_CREATURE, "rat", GetLocation(OBJECT_SELF), FALSE);

    float fBase   = GetPartyXPValue(oTemp, FALSE, 5.0, 1, 1.0);
    float fDouble = GetPartyXPValue(oTemp, FALSE, 5.0, 1, 2.0);
    DestroyObject(oTemp);

    SendMessageToPC(oPC, "XP with multiplier=1.0: " + FloatToString(fBase,   8, 3));
    SendMessageToPC(oPC, "XP with multiplier=2.0: " + FloatToString(fDouble, 8, 3));

    if (fBase > 0.0 && fabs(fDouble - fBase * 2.0) < 0.01)
        SendMessageToPC(oPC, "PASS: multiplier is respected");
    else if (fabs(fDouble - fBase) < 0.01)
        SendMessageToPC(oPC, "FAIL: multiplier ignored (both returned " + FloatToString(fBase, 6, 2) + ") — bug present");
    else
        SendMessageToPC(oPC, "UNKNOWN: base=" + FloatToString(fBase, 6, 2) + " double=" + FloatToString(fDouble, 6, 2));
}
