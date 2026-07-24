// Helper for dlg_tst_spawn.nss — runs on the spawned creature after a delay
void main()
{
    int nXPFlag = GetLocalInt(OBJECT_SELF, "pickpocket_xp");
    object oItem = GetFirstItemInInventory(OBJECT_SELF);
    int bHasPickpocketItem = FALSE;
    while (GetIsObjectValid(oItem))
    {
        if (GetPickpocketableFlag(oItem)) bHasPickpocketItem = TRUE;
        oItem = GetNextItemInInventory(OBJECT_SELF);
    }

    object oPC = GetFirstPC();
    if (!GetIsObjectValid(oPC)) { DestroyObject(OBJECT_SELF); return; }

    SendMessageToPC(oPC, "--- ai_onspawn result ---");
    SendMessageToPC(oPC, "pickpocket_xp=" + IntToString(nXPFlag)
        + " hasPickpocketItem=" + IntToString(bHasPickpocketItem));

    if (nXPFlag == 1 && !bHasPickpocketItem)
        SendMessageToPC(oPC, "FAIL: XP flag set but no item — bug present");
    else if (nXPFlag == 0 && !bHasPickpocketItem)
        SendMessageToPC(oPC, "PASS: no item and no flag (CR-0 or no loot)");
    else if (nXPFlag == 1 && bHasPickpocketItem)
        SendMessageToPC(oPC, "PASS: XP flag set and item exists");
    else
        SendMessageToPC(oPC, "INFO: flag=0 but item exists (unusual)");

    DestroyObject(OBJECT_SELF);
}
