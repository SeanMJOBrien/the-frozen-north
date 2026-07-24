// Test: 70_mod_polymorph.nss bug (abil chained from base instead of abil2)
// Equip several items with ability bonuses before testing.
// The script prints what each item contributes, so you can check the running total.
#include "70_inc_shifter"

void main()
{
    object oPC = GetPCSpeaker();
    SendMessageToPC(oPC, "=== 70_mod_polymorph: ability accumulation ===");
    SendMessageToPC(oPC, "Equip items with ability bonuses, polymorph, then compare totals.");

    // Compute cumulative totals by chaining IPGetAbilityBonuses correctly
    struct abilities aCumul;
    aCumul = IPGetAbilityBonuses(aCumul, GetItemInSlot(INVENTORY_SLOT_CHEST,     oPC));
    aCumul = IPGetAbilityBonuses(aCumul, GetItemInSlot(INVENTORY_SLOT_HEAD,      oPC));
    aCumul = IPGetAbilityBonuses(aCumul, GetItemInSlot(INVENTORY_SLOT_LEFTHAND,  oPC));
    aCumul = IPGetAbilityBonuses(aCumul, GetItemInSlot(INVENTORY_SLOT_NECK,      oPC));
    aCumul = IPGetAbilityBonuses(aCumul, GetItemInSlot(INVENTORY_SLOT_LEFTRING,  oPC));
    aCumul = IPGetAbilityBonuses(aCumul, GetItemInSlot(INVENTORY_SLOT_RIGHTRING, oPC));
    aCumul = IPGetAbilityBonuses(aCumul, GetItemInSlot(INVENTORY_SLOT_CLOAK,     oPC));
    aCumul = IPGetAbilityBonuses(aCumul, GetItemInSlot(INVENTORY_SLOT_BELT,      oPC));
    aCumul = IPGetAbilityBonuses(aCumul, GetItemInSlot(INVENTORY_SLOT_BOOTS,     oPC));
    aCumul = IPGetAbilityBonuses(aCumul, GetItemInSlot(INVENTORY_SLOT_ARMS,      oPC));
    aCumul = IPGetAbilityBonuses(aCumul, GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC));

    SendMessageToPC(oPC, "Expected cumulative bonus from all equipped items:");
    SendMessageToPC(oPC, "Str+" + IntToString(aCumul.Str)
        + " Dex+" + IntToString(aCumul.Dex)
        + " Con+" + IntToString(aCumul.Con)
        + " Int+" + IntToString(aCumul.Int)
        + " Wis+" + IntToString(aCumul.Wis)
        + " Cha+" + IntToString(aCumul.Cha));
    SendMessageToPC(oPC, "Polymorph and verify your ability scores increased by these amounts.");
    SendMessageToPC(oPC, "Before fix: only the LAST slot's bonus applied. After fix: all stack.");
}
