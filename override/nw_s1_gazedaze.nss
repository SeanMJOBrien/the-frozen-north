//::///////////////////////////////////////////////
//:: Gaze: Daze
//:: NW_S1_GazeDaze
//:: Copyright (c) 2001 Bioware Corp.
//:://////////////////////////////////////////////
/*
    Cone shape that affects all within the AoE if they
    fail a Will Save.
*/
//:://////////////////////////////////////////////
//:: Created By: Preston Watamaniuk
//:: Created On: May 11, 2001
//:://////////////////////////////////////////////
/*
Patch 1.71

- blinded/sightless creatures are not affected anymore
- wrong target check (could affect other NPCs)
- wrong duration calculation (cumulative for each target in AoE)
*/

#include "70_inc_spells"
#include "x0_i0_spells"

void main()
{
    if(GZCanNotUseGazeAttackCheck(OBJECT_SELF))
    {
        return;
    }

    //Declare major variables
    int nHD = GetHitDice(OBJECT_SELF);
    int nDuration = 1 + (nHD / 3);
    int nDC = 10 + (nHD/2);
    location lTargetLocation = GetSpellTargetLocation();
    object oTarget;
    effect eGaze = EffectDazed();
    effect eVis = EffectVisualEffect(VFX_IMP_DAZED_S);
    effect eDur = EffectVisualEffect(VFX_DUR_CESSATE_NEGATIVE);
    effect eVisDur = EffectVisualEffect(VFX_DUR_MIND_AFFECTING_DISABLED);

    effect eLink = EffectLinkEffects(eGaze, eVisDur);
    eLink = EffectLinkEffects(eLink, eDur);
    //Get first target in spell area
    oTarget = FIX_GetFirstObjectInShape(SHAPE_SPELLCONE, 11.0, lTargetLocation, TRUE);
    int scaledDuration;
    while(GetIsObjectValid(oTarget))
    {
        if(oTarget != OBJECT_SELF && spellsIsTarget(oTarget, SPELL_TARGET_STANDARDHOSTILE, OBJECT_SELF))
        {
            //Fire cast spell at event for the specified target
            SignalEvent(oTarget, EventSpellCastAt(OBJECT_SELF, SPELLABILITY_GAZE_DAZE));
            //Determine effect delay
            float fDelay = GetDistanceBetween(OBJECT_SELF, oTarget)/20;
            if(GetIsAbleToSee(oTarget) && !MySavingThrow(SAVING_THROW_WILL, oTarget, nDC, SAVING_THROW_TYPE_MIND_SPELLS, OBJECT_SELF, fDelay))
            {
                scaledDuration = GetScaledDuration(nDuration, oTarget);
                //Apply the VFX impact and effects
                DelayCommand(fDelay, ApplyEffectToObject(DURATION_TYPE_INSTANT, eVis, oTarget));
                DelayCommand(fDelay, ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eLink, oTarget, RoundsToSeconds(scaledDuration)));
            }
        }
        //Get next target in spell area
        oTarget = FIX_GetNextObjectInShape(SHAPE_SPELLCONE, 11.0, lTargetLocation, TRUE);
    }
}
