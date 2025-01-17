//::///////////////////////////////////////////////
//:: Default community patch OnAcquire module event script
//:: 70_mod_def_aqu
//:: Copyright (c) 2001 Bioware Corp.
//:://////////////////////////////////////////////
/*
The 70_mod_def_* scripts are a new feature of nwn(c)x_patch plugin and will fire
just before normal module events. Note, that this script will run only if game
is loaded via NWNX or NWNCX and Community Patch plugin!

The purpose of this is to automatically enforce fixes/features that requires changes
in module events in any module player will play. Also, PW builders no longer needs
to merge scripts to get these functionalities.

If you are a builder you can reuse these events for your own purposes too. With
this feature, you can make a system like 3.5 ruleset which will work in any module
as long player is using patch 1.72 + NWNCX + nwncx_patch plugin.

Note: community patch doesn't include scripts for all these events, but only for
a few. You can create a script with specified name for other events. There was
just no point of including a script which will do nothing. So here is a list:
OnAcquireItem       - 70_mod_def_aqu
OnActivateItem      - 70_mod_def_act
OnClientEnter       - 70_mod_def_enter
OnClientLeave       - 70_mod_def_leave
OnCutsceneAbort     - 70_mod_def_abort
OnHeartbeat         - not running extra script
OnModuleLoad        - 70_mod_def_load
OnPlayerChat        - 70_mod_def_chat
OnPlayerDeath       - 70_mod_def_death
OnPlayerDying       - 70_mod_def_dying
OnPlayerEquipItem   - 70_mod_def_equ
OnPlayerLevelUp     - 70_mod_def_lvup
OnPlayerRespawn     - 70_mod_def_resp
OnPlayerRest        - 70_mod_def_rest
OnPlayerUnEquipItem - 70_mod_def_unequ
OnUnAcquireItem     - 70_mod_def_unaqu
OnUserDefined       - 70_mod_def_user

It is also possible to bypass the original script, use this command:
SetLocalInt(OBJECT_SELF,"BYPASS_EVENT",1);
This should be used wisely as you don't know what is original module event script
doing so, do this only if running original event has no longer sense.
*/
//:://////////////////////////////////////////////
//:: Created By: Shadooow for Community Patch 1.72
//:: Created On: 31-05-2017
//:://////////////////////////////////////////////

#include "x0_i0_spells"
#include "70_inc_itemprop"
#include "inc_quest"

void main()
{
    object oPC = GetModuleItemAcquiredBy();
    object oItem = GetModuleItemAcquired();
    object oOwner = GetModuleItemAcquiredFrom();
    int nStackSize =GetModuleItemAcquiredStackSize();

    if (GetTag(oItem) == "quest")
    {
        AdvanceQuest(oItem, oPC, 1);
        DestroyObject(oItem);
        return;
    }

    ExecuteScript("remove_invis", oPC);

    DeleteLocalInt(oItem, "destroy_count");

    //1.71: craft dupe fix
    if(GetLocalInt(oItem,"DUPLICATED_ITEM") == TRUE)
    {
       DestroyObject(oItem);
       return;
    }
     //1.72: support for OC henchman inventory across levelling
    if(GetAssociateType(oPC) == ASSOCIATE_TYPE_HENCHMAN && !GetLocalInt(oItem,"70_MY_ORIGINAL_POSSESSION") && oOwner == GetMaster(oPC))
    {
        SetLocalInt(oItem,"70_ACQUIRED_FROM_MASTER",TRUE);
    }

    //Now execute original script
    string sScript = GetLocalString(OBJECT_SELF,"EVENT_SCRIPT_MODULE_ON_ACQUIRE_ITEM");
    if(sScript != "")
    {
        ExecuteScript(sScript,OBJECT_SELF);
    }
}
