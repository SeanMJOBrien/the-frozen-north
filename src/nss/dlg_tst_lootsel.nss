// Test: inc_lootselect.nss bug A (operator precedence in GetStandardLootRarityWeights)
#include "inc_lootselect"

void main()
{
    object oPC = GetPCSpeaker();
    SendMessageToPC(oPC, "=== inc_lootselect Bug A: rarity weights ===");

    json jWeapon = GetStandardLootRarityWeights(LOOT_TYPE_WEAPON_MELEE);
    json jOther  = GetStandardLootRarityWeights(LOOT_TYPE_ARMOR);

    int nWeaponCommon = JsonGetInt(JsonArrayGet(jWeapon, 1));
    int nOtherCommon  = JsonGetInt(JsonArrayGet(jOther,  1));

    SendMessageToPC(oPC, "Weapon rarity weights: " + JsonDump(jWeapon));
    SendMessageToPC(oPC, "Armor rarity weights:  " + JsonDump(jOther));

    // WEAPON_COMMON_WEIGHT = 37, OTHER_COMMON_WEIGHT = 42 — they should differ
    if (nWeaponCommon == nOtherCommon)
        SendMessageToPC(oPC, "FAIL: weapons got OTHER weights (" + IntToString(nWeaponCommon) + ") — bug still present");
    else
        SendMessageToPC(oPC, "PASS: weapon=" + IntToString(nWeaponCommon) + " other=" + IntToString(nOtherCommon));
}
