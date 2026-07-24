// Test: ai_onspawn.nss bug (pickpocket_xp set even when SelectLootItemFromACR returns INVALID)
// Spawns a creature in an area with cr=0 so loot returns OBJECT_INVALID
void main()
{
    object oPC = GetPCSpeaker();
    SendMessageToPC(oPC, "=== ai_onspawn: pickpocket item validity ===");

    object oArea = GetArea(OBJECT_SELF);
    int nCR = GetLocalInt(oArea, "cr");
    SendMessageToPC(oPC, "Area CR: " + IntToString(nCR));

    if (nCR > 0)
    {
        SendMessageToPC(oPC, "INFO: Area has CR " + IntToString(nCR) + ".");
        SendMessageToPC(oPC, "Move to a CR-0 area for a clean test (loot returns INVALID).");
        SendMessageToPC(oPC, "Alternatively, check that any spawned creature without a valid");
        SendMessageToPC(oPC, "pickpocket item does NOT have pickpocket_xp=1.");
    }

    // Spawn a goblin (has pickpocket spawn logic via ai_onspawn)
    location lLoc = GetLocation(OBJECT_SELF);
    object oCreature = CreateObject(OBJECT_TYPE_CREATURE, "goblin", lLoc, FALSE);

    if (!GetIsObjectValid(oCreature))
    {
        SendMessageToPC(oPC, "SKIP: could not spawn 'goblin'");
        return;
    }

    // Give the spawn event a moment to fire
    DelayCommand(1.0, ExecuteScript("dlg_tst_spawnchk", oCreature));
    SendMessageToPC(oPC, "Spawned goblin — checking in 1 second...");
}
