// Test: inc_party.nss bug (debug fallback uses oMbr instead of oDev for level)
// Run this while no other PCs are within 20m of the NPC.
#include "inc_party"
#include "inc_lootselect"

void main()
{
    object oPC = GetPCSpeaker();
    SendMessageToPC(oPC, "=== inc_party: debug dev-placeholder level ===");
    SendMessageToPC(oPC, "Move away from other players, then retry if TotalSize is already > 0.");

    object oMod = GetModule();
    object oPrevDev  = GetLocalObject(oMod, "dev_lootvortex");
    int    bWasDebug = GetLocalInt(oMod, LOOT_DEBUG_ENABLED);

    // Temporarily register self as dev vortex and enable debug loot
    SetLocalObject(oMod, "dev_lootvortex", oPC);
    SetLocalInt(oMod, LOOT_DEBUG_ENABLED, 1);

    SetPartyData(OBJECT_SELF);
    int   nSize = Party.TotalSize;
    float fAvg  = Party.AverageLevel;

    // Restore
    if (GetIsObjectValid(oPrevDev))
        SetLocalObject(oMod, "dev_lootvortex", oPrevDev);
    else
        DeleteLocalObject(oMod, "dev_lootvortex");
    if (!bWasDebug)
        DeleteLocalInt(oMod, LOOT_DEBUG_ENABLED);

    int nMyLevel = GetHitDice(oPC);
    SendMessageToPC(oPC, "Your level: " + IntToString(nMyLevel));
    SendMessageToPC(oPC, "Party.TotalSize: "    + IntToString(nSize));
    SendMessageToPC(oPC, "Party.AverageLevel: " + FloatToString(fAvg, 5, 1));

    if (nSize == 0)
        SendMessageToPC(oPC, "INFO: other players in range -- move away and retry");
    else if (nSize == 1 && fAvg > 0.1)
        SendMessageToPC(oPC, "PASS: dev placeholder contributed level " + FloatToString(fAvg, 3, 1));
    else if (nSize == 1 && fAvg < 0.1)
        SendMessageToPC(oPC, "FAIL: AverageLevel is 0 -- oMbr bug still present");
}
