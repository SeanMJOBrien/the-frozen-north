//::///////////////////////////////////////////////
//:: Associate On Attacked
//:: NW_CH_AC5
//:: Copyright (c) 2001 Bioware Corp.
//:://////////////////////////////////////////////
/*
    If already fighting then ignore, else determine
    combat round
*/
//:://////////////////////////////////////////////
//:: Created By: Preston Watamaniuk
//:: Created On: Oct 16, 2001
//:://////////////////////////////////////////////
//:://////////////////////////////////////////////
//:: Modified By: Deva Winblood
//:: Modified On: Jan 4th, 2008
//:: Added Support for Mounted Combat Feat Support
//:://////////////////////////////////////////////

#include "x0_inc_henai"

void main()
{
    if (GetIsEnemy(GetLastAttacker()))
        SpeakString("PARTY_I_WAS_ATTACKED", TALKVOLUME_SILENT_TALK);

    if(!GetAssociateState(NW_ASC_IS_BUSY))
    {
        SetCommandable(TRUE);
        if(!GetAssociateState(NW_ASC_MODE_STAND_GROUND))
        {
            if(!GetIsObjectValid(GetAttackTarget()) && !GetIsObjectValid(GetAttemptedSpellTarget()))
            {
                if(GetIsObjectValid(GetLastAttacker()))
                {
                    if(GetAssociateState(NW_ASC_MODE_DEFEND_MASTER))
                    {
                        //1.72: TODO possible !GetIsFighting check too
                        object oTarget = GetLastAttacker(GetMaster());
                        HenchmenCombatRound(oTarget);
                    }
                    else if(!GetIsFighting(OBJECT_SELF))//1.72: fix for constant combat round re-starting when surrounded by many attackers that led to attacking sporadically or not at all
                    {
                        HenchmenCombatRound(OBJECT_INVALID);
                    }
                }
            }
            if(GetSpawnInCondition(NW_FLAG_ATTACK_EVENT))
            {
                SignalEvent(OBJECT_SELF, EventUserDefined(1005));
            }
        }
    }
}

