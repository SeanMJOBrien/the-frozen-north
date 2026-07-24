// Test: seed_treasure.nss bug (SetItemStackSize(oNewItem) called before oNewItem is assigned)
// Checks that ammo/thrown weapon items on a chest spawned by PopulateChestWeapon
// have stack size 1 (which makes the distribution script function correctly).
// Point the NPC at an ammo-type chest to test.
void main()
{
    object oPC = GetPCSpeaker();
    SendMessageToPC(oPC, "=== seed_treasure: ammo stack size ===");

    // Look for a loot chest near the NPC
    int nNth = 1;
    object oChest = GetNearestObject(OBJECT_TYPE_PLACEABLE, OBJECT_SELF, nNth);
    while (GetIsObjectValid(oChest) && GetStringLeft(GetTag(oChest), 5) != "chest")
        oChest = GetNearestObject(OBJECT_TYPE_PLACEABLE, OBJECT_SELF, ++nNth);

    if (!GetIsObjectValid(oChest))
    {
        SendMessageToPC(oPC, "INFO: no tagged chest nearby -- place NPC next to a loot chest");
        SendMessageToPC(oPC, "Alternatively: spawn a chest with PopulateChestWeapon, open it,");
        SendMessageToPC(oPC, "and check that arrows/bolts/sling bullets appear as individual");
        SendMessageToPC(oPC, "stacks of 1 rather than one combined stack.");
        return;
    }

    int nPass = 0, nFail = 0;
    object oItem = GetFirstItemInInventory(oChest);
    while (GetIsObjectValid(oItem))
    {
        int nType = GetBaseItemType(oItem);
        if (nType == BASE_ITEM_ARROW || nType == BASE_ITEM_BOLT ||
            nType == BASE_ITEM_BULLET || nType == BASE_ITEM_DART ||
            nType == BASE_ITEM_SHURIKEN || nType == BASE_ITEM_THROWINGAXE)
        {
            int nStack = GetItemStackSize(oItem);
            if (nStack == 1)
            {
                nPass++;
            }
            else
            {
                SendMessageToPC(oPC, "FAIL: " + GetName(oItem) + " has stack=" + IntToString(nStack) + " (want 1)");
                nFail++;
            }
        }
        oItem = GetNextItemInInventory(oChest);
    }

    if (nPass == 0 && nFail == 0)
        SendMessageToPC(oPC, "INFO: no ammo/thrown items found in chest");
    else
        SendMessageToPC(oPC, "RESULT: " + IntToString(nPass) + " PASS, " + IntToString(nFail) + " FAIL");
}
