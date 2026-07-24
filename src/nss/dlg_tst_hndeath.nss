// Test: j_ai_ondeath.nss bug (FloatingTextStringOnCreature with invalid master)
// Spawns a temporary henchman-resref creature with no master and kills it.
// Before fix: FloatingTextStringOnCreature called with OBJECT_INVALID.
// After fix: the call is guarded and no crash occurs.
void main()
{
    object oPC = GetPCSpeaker();
    SendMessageToPC(oPC, "=== j_ai_ondeath: masterless henchman death ===");
    SendMessageToPC(oPC, "Spawning temp henchman (hen_bim resref) with no master...");

    location lLoc = GetLocation(OBJECT_SELF);
    object oHench = CreateObject(OBJECT_TYPE_CREATURE, "hen_bim", lLoc, FALSE);

    if (!GetIsObjectValid(oHench))
    {
        SendMessageToPC(oPC, "SKIP: could not spawn 'hen_bim' (resref may not exist)");
        return;
    }

    // Confirm no master
    object oMaster = GetMaster(oHench);
    SendMessageToPC(oPC, "Master valid: " + IntToString(GetIsObjectValid(oMaster))
        + " (want 0)");

    // Kill it — this fires j_ai_ondeath (or on_death event)
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDamage(9999, DAMAGE_TYPE_DIVINE), oHench);

    SendMessageToPC(oPC, "Killed. Check server log for errors.");
    SendMessageToPC(oPC, "PASS if no error in log referencing FloatingTextStringOnCreature.");
}
