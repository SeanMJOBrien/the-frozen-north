//::///////////////////////////////////////////////
//:: Cone: Sonic
//:: NW_S1_ConeSonic
//:: Copyright (c) 2001 Bioware Corp.
//:://////////////////////////////////////////////
/*
    A cone of damage eminated from the monster.  Does
    a set amount of damage based upon the creatures HD
    and can be halved with a Reflex Save.
*/
//:://////////////////////////////////////////////
//:: Created By: Preston Watamaniuk
//:: Created On: May 11, 2001
//:://////////////////////////////////////////////
/*
Patch 1.70

- area of effect size prolonged to 11.0 to match the distance of the cone usage/visual
- wrong target check (could affect other NPCs)
- successful save reduced damage for all remaining creatures in the area of effect
- damage was the same for all creatures in AoE
- shape size wasn't correct (started with 10.0 then continued with 11.0, which
caused issues)
- DC corrected to use HD
- saving throw subtype fixed
*/

#include "70_inc_spells"
#include "x0_i0_spells"

void main()
{
    //Declare major variables
    int nHD = GetHitDice(OBJECT_SELF);
    int nDamage;
    int nDice = nHD / 3;
    int nDC = 10 + (nHD/2);
    float fDelay;
    if(nDice < 1)
    {
        nDice = 1;
    }
    nDice *= 2;

    location lTargetLocation = GetSpellTargetLocation();
    effect eCone;
    effect eVis = EffectVisualEffect(VFX_IMP_SONIC);

    object oTarget = FIX_GetFirstObjectInShape(SHAPE_SPELLCONE, 11.0, lTargetLocation, TRUE);
    //Get first target in spell area
    while(GetIsObjectValid(oTarget))
    {
        if(oTarget != OBJECT_SELF && spellsIsTarget(oTarget, SPELL_TARGET_STANDARDHOSTILE, OBJECT_SELF))
        {
            //randomize damage for each creature in AoE
            nDamage = d6(nDice);
            //Fire cast spell at event for the specified target
            SignalEvent(oTarget, EventSpellCastAt(OBJECT_SELF, SPELLABILITY_CONE_SONIC));
            //Determine effect delay
            fDelay = GetDistanceBetween(OBJECT_SELF, oTarget)/20;
            //Adjust the damage based on the Reflex Save, Evasion and Improved Evasion.
            nDamage = GetSavingThrowAdjustedDamage(nDamage, oTarget, nDC, SAVING_THROW_REFLEX, SAVING_THROW_TYPE_SONIC);

            if(nDamage > 0)
            {
                //Set damage effect
                eCone = EffectDamage(nDamage, DAMAGE_TYPE_SONIC);
                //Apply the VFX impact and effects
                DelayCommand(fDelay, ApplyEffectToObject(DURATION_TYPE_INSTANT, eVis, oTarget));
                DelayCommand(fDelay, ApplyEffectToObject(DURATION_TYPE_INSTANT, eCone, oTarget));
            }
        }
        //Get next target in spell area
        oTarget = FIX_GetNextObjectInShape(SHAPE_SPELLCONE, 11.0, lTargetLocation, TRUE);
    }
}
