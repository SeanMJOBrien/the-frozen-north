#include "inc_persist"
#include "inc_general"
#include "inc_quest"
#include "inc_henchman"
#include "inc_follower"
#include "inc_horse"

void main()
{
    object oRespawner = OBJECT_SELF;

    SQLocalsPlayer_DeleteInt(oRespawner, "DEAD");
    SQLocalsPlayer_DeleteInt(oRespawner, "PETRIFIED");
    SQLocalsPlayer_DeleteInt(oRespawner, "times_died");

    DetermineDeathEffectPenalty(oRespawner);

    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectResurrection(), oRespawner);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(GetMaxHitPoints(oRespawner)), oRespawner);

    RemoveMount(oRespawner);

    location lRespawnLocation = GetLocation(GetObjectByTag("RESPAWN_NEVERWINTER"));

    object oChosenRespawn = GetObjectByTag("RESPAWN_"+SQLocalsPlayer_GetString(oRespawner, "respawn"));

    if (GetIsObjectValid(oChosenRespawn))
        lRespawnLocation = GetLocation(oChosenRespawn);

// Apply a visual effect
    effect eVisual = EffectVisualEffect(VFX_IMP_RESTORATION);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, eVisual, oRespawner);
    ApplyEffectAtLocation(DURATION_TYPE_INSTANT, eVisual, lRespawnLocation);

    effect eEffect = GetFirstEffect(oRespawner);
    while(GetIsEffectValid(eEffect))
    {
        RemoveEffect(oRespawner,eEffect);
        eEffect = GetNextEffect(oRespawner);
    }
    RemoveEffects(oRespawner);

// for sergol
    SetLocalInt(oRespawner, "NW_L_I_DIED", 1);

// Teleport back to the respawn location
    AssignCommand(oRespawner, JumpToLocation(lRespawnLocation));

     SetStandardFactionReputation(STANDARD_FACTION_COMMONER, 50, oRespawner);
     SetStandardFactionReputation(STANDARD_FACTION_MERCHANT, 50, oRespawner);
     SetStandardFactionReputation(STANDARD_FACTION_DEFENDER, 50, oRespawner);

    ExecuteScript("pc_dth_penalty", oRespawner);

    DelayCommand(1.0, SavePCInfo(oRespawner));
    if (GetPCPublicCDKey(oRespawner) != "") DelayCommand(1.1, ExportSingleCharacter(oRespawner));

// if they are respawning in the hall of justice in NW and are less than level 6, let's give them a recruit
    if (GetQuestEntry(oRespawner, "q_wailing") >= 4 && GetHitDice(oRespawner) < 6 && GetTag(GetAreaFromLocation(lRespawnLocation)) == "core_hall")
    {
        object oMilitia = CreateObject(OBJECT_TYPE_CREATURE, "militia", lRespawnLocation);
        SetFollowerMaster(oMilitia, oRespawner);
        DelayCommand(3.0, PlayVoiceChat(VOICE_CHAT_HELLO, oMilitia));
        DelayCommand(6.0, AssignCommand(oMilitia, SpeakString("Sedos sent me to assist you after you have fallen in battle. I will help you on your mission.")));
        DelayCommand(9.0, AssignCommand(oMilitia, SpeakString("There are also adventurers that might be willing to help you out in the Trade of Blades, across the bridge.")));
    }
}
