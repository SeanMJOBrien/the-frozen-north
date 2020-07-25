//::///////////////////////////////////////////////
//:: Slaad Chaos Spittle
//:: x2_s1_chaosspit
//:: Copyright (c) 2001 Bioware Corp.
//:://////////////////////////////////////////////
/*
    Creature must make a ranged touch attack to hit
    the intended target.

    Damage is 20d4 for black slaad, 10d4 for white
    slaad and hd/2 d4 for any other creature this
    spell  is assigned to

    A shifter will do his shifter level /3 d6
    points of damage

*/
//:://////////////////////////////////////////////
//:: Created By: Georg Zoeller
//:: Created On: Sept 08  , 2003
//:://////////////////////////////////////////////
/*
Patch 1.70

- critical hit damage corrected (damage was always even before)
*/

#include "70_inc_spells"
#include "x0_i0_spells"

void main()
{
    //Declare major variables
    object oTarget = GetSpellTargetObject();
    int nHD = GetHitDice(OBJECT_SELF);
    effect eVis = EffectVisualEffect(VFX_IMP_ACID_L);
    effect eVis2 = EffectVisualEffect(VFX_IMP_ACID_S);
    effect eBolt;
    int nCount;
    if (GetIsPC(OBJECT_SELF))
    {
        nCount = (GetLevelByClass(CLASS_TYPE_SHIFTER,OBJECT_SELF)/3) + 2 ;
    }
    else if (GetAppearanceType(OBJECT_SELF) == 426) // black slaad = 20d6
    {
        nCount = 20;
    }
    else if (GetAppearanceType(OBJECT_SELF) == 427) // white slaad = 10d6
    {
        nCount = 10;
    }
    else
    {
        nCount = nHD/2;
    }

    if (nCount < 1)
    {
        nCount = 1;
    }

    if (spellsIsTarget(oTarget, SPELL_TARGET_SINGLETARGET, OBJECT_SELF))
    {

        //Fire cast spell at event for the specified target
        SignalEvent(oTarget, EventSpellCastAt(OBJECT_SELF, GetSpellId()));
        //Adjust the damage based on the Reflex Save, Evasion and Improved Evasion.

        //Make a ranged touch attack
        int nTouch = TouchAttackRanged(oTarget);
        if(nTouch > 0)
        {
            int nDamage = d4(nCount*nTouch);//correct critical hit damage calculation (will enable odd values)

            //Set damage effect
            eBolt = EffectDamage(nDamage, DAMAGE_TYPE_MAGICAL);
            //Apply the VFX impact and effects
            ApplyEffectToObject(DURATION_TYPE_INSTANT, eBolt, oTarget);
            ApplyEffectToObject(DURATION_TYPE_INSTANT, eVis, oTarget);
            ApplyEffectToObject(DURATION_TYPE_INSTANT, eVis2, oTarget);
        }
    }
}
