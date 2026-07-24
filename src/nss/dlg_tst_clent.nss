// Test: on_client_ent.nss bugs A (race stored on module) and B (event scripts swapped)
void main()
{
    object oPC = GetPCSpeaker();
    object oMod = GetModule();

    SendMessageToPC(oPC, "=== on_client_ent Bug A: race storage ===");
    int nOnPC  = GetLocalInt(oPC,  "BASE_RACE_SET");
    int nOnMod = GetLocalInt(oMod, "BASE_RACE_SET");
    SendMessageToPC(oPC, "BASE_RACE_SET on PC: "     + IntToString(nOnPC)  + " (want 1)");
    SendMessageToPC(oPC, "BASE_RACE_SET on module: " + IntToString(nOnMod) + " (want 0)");

    SendMessageToPC(oPC, "=== on_client_ent Bug B: event scripts ===");
    string sMelee = GetEventScript(oPC, EVENT_SCRIPT_CREATURE_ON_MELEE_ATTACKED);
    string sSpell = GetEventScript(oPC, EVENT_SCRIPT_CREATURE_ON_SPELLCASTAT);
    SendMessageToPC(oPC, "MELEE_ATTACKED -> '" + sMelee + "' (want 'on_pc_attacked')");
    SendMessageToPC(oPC, "SPELLCASTAT   -> '" + sSpell + "' (want 'on_pc_spellcast')");

    int bPass = (nOnPC == 1 && nOnMod == 0 &&
                 sMelee == "on_pc_attacked" && sSpell == "on_pc_spellcast");
    SendMessageToPC(oPC, "RESULT: " + (bPass ? "PASS" : "FAIL"));
}
