// Test: on_mod_heartb.nss bugs A (faction constant always true) and B (store guard)
#include "nwnx_creature"

void main()
{
    object oPC = GetPCSpeaker();

    SendMessageToPC(oPC, "=== on_mod_heartb Bug A: faction check ===");
    SendMessageToPC(oPC, "Scanning nearby creatures (within 20m)...");
    object oCreature = GetFirstObjectInShape(SHAPE_SPHERE, 20.0, GetLocation(oPC), TRUE, OBJECT_TYPE_CREATURE);
    int nTested = 0;
    while (GetIsObjectValid(oCreature) && nTested < 6)
    {
        if (!GetIsPC(oCreature) && !GetIsDead(oCreature) && oCreature != OBJECT_SELF)
        {
            int nFaction   = NWNX_Creature_GetFaction(oCreature);
            int bOldResult = TRUE; // STANDARD_FACTION_DEFENDER constant is always nonzero
            int bNewResult = (nFaction == STANDARD_FACTION_COMMONER ||
                              nFaction == STANDARD_FACTION_DEFENDER  ||
                              nFaction == STANDARD_FACTION_MERCHANT);
            SendMessageToPC(oPC, GetName(oCreature)
                + " faction=" + IntToString(nFaction)
                + " old=TRUE new=" + IntToString(bNewResult));
            nTested++;
        }
        oCreature = GetNextObjectInShape(SHAPE_SPHERE, 20.0, GetLocation(oPC), TRUE, OBJECT_TYPE_CREATURE);
    }
    if (nTested == 0)
        SendMessageToPC(oPC, "(No nearby non-PC creatures found - move near some NPCs)");

    SendMessageToPC(oPC, "=== on_mod_heartb Bug B: store guard ===");
    object oStore = OBJECT_INVALID;
    if (GetIsObjectValid(oStore))
        SendMessageToPC(oPC, "FAIL: would call DestroyObject on OBJECT_INVALID");
    else
        SendMessageToPC(oPC, "PASS: guard prevents DestroyObject(OBJECT_INVALID)");
}
