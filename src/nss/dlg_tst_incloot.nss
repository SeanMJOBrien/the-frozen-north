// Test: inc_loot.nss bug (GetPersonalLootForPC ignores bCreateIfMissing parameter)
#include "inc_loot"

void main()
{
    object oPC = GetPCSpeaker();
    SendMessageToPC(oPC, "=== inc_loot: bCreateIfMissing parameter ===");

    // Create a temporary loot source placeable
    object oSource = CreateObject(OBJECT_TYPE_PLACEABLE, "_loot_container",
                                  GetLocation(OBJECT_SELF), FALSE);

    // Call with FALSE — should NOT create a container
    object oResult = GetPersonalLootForPC(oSource, oPC, FALSE);
    if (GetIsObjectValid(oResult))
        SendMessageToPC(oPC, "FAIL (A): container created despite bCreateIfMissing=FALSE — bug present");
    else
        SendMessageToPC(oPC, "PASS (A): no container created with bCreateIfMissing=FALSE");

    // Call with TRUE — should create a container
    oResult = GetPersonalLootForPC(oSource, oPC, TRUE);
    if (GetIsObjectValid(oResult))
        SendMessageToPC(oPC, "PASS (B): container created with bCreateIfMissing=TRUE");
    else
        SendMessageToPC(oPC, "FAIL (B): no container created with bCreateIfMissing=TRUE");

    DestroyObject(oResult);
    DestroyObject(oSource);
}
