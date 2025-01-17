#include "inc_persist"
#include "inc_general"
#include "inc_horse"
#include "inc_nwnx"
#include "util_i_csvlists"
#include "x0_i0_position"
#include "nwnx_area"

void ApplySleepVFX(object oCreature)
{
    if (GetRacialType(oCreature) == RACIAL_TYPE_ELF) return;

    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_SLEEP), oCreature);
}

string ChooseSpawnRef(object oArea, int nTarget)
{
    string sTarget = "random"+IntToString(nTarget);

    string sList = GetLocalString(oArea, sTarget+"_list");
    string sListUnique = GetLocalString(oArea, sTarget+"_list_unique");

    int nUniqueChance = GetLocalInt(oArea, sTarget+"_unique_chance");

    if (d100() <= nUniqueChance)
    {
        return GetListItem(sListUnique, Random(CountList(sListUnique)));
    }
    else
    {
        return GetListItem(sList, Random(CountList(sList)));
    }
}

void CreateAmbush(int nTarget, object oArea, location lLocation)
{
    string sSpawnScript = GetLocalString(oArea, "random"+IntToString(nTarget)+"_spawn_script");

    int nCount = GetLocalInt(oArea, "random"+IntToString(nTarget)+"_ambush_size");
    if (nCount < 1) nCount = 2;

    int i;
    for (i = 0; i < nCount; i++)
    {
        object oEnemy = CreateObject(OBJECT_TYPE_CREATURE, ChooseSpawnRef(oArea, nTarget), lLocation, TRUE);
        SetLocalInt(oEnemy, "ambush", 1);
        if (sSpawnScript != "") ExecuteScript(sSpawnScript, oEnemy);

        DestroyObject(oEnemy, 300.0);
    }
}

void main()
{
    object oPC = GetLastPCRested();
    object oArea = GetArea(oPC);
    object oObjectLoop, oCurrentPC, oCampfire, oValidator;
    location lLocation = GetLocation(oPC);
    float fFacing = GetFacing(oPC);
    location lTarget = GenerateNewLocation(oPC, 1.5, fFacing, fFacing);
    int bRanger = FALSE;
    int bHarperScout = FALSE;
    int nAmbushRoll, nAmbushChance, nEnemyGroup;
    int nEnemyGroups = 0;
    int nHideClassChance = 0;
    int nHideChance = 10;
    float fAmbushTime;
    string sHideClass;
    string sHidePrepend = "You manage to hide away from enemies (";
    string sHideAppend = " bonus).";
    string sHide = "You manage to hide away from enemies.";
    string sSpotted = "You have been spotted by enemies!";
    int i, nSlot;
    object oItem = GetFirstItemInInventory(oPC);

    float fSize = 30.0;

    switch (GetLastRestEventType())
    {
        case REST_EVENTTYPE_REST_STARTED:

            SendDebugMessage("Event: REST_STARTED");

// prevent PC from resting when there are enemies in line of sight
            oObjectLoop = GetFirstObjectInShape(SHAPE_SPHERE, fSize, lLocation, TRUE, OBJECT_TYPE_CREATURE);
            while (GetIsObjectValid(oObjectLoop))
            {
                if (GetIsReactionTypeHostile(oPC, oObjectLoop) && !GetIsDead(oObjectLoop))
                {
                    FloatingTextStringOnCreature("You cannot rest when there are enemies nearby.", oPC, FALSE);
                    AssignCommand(oPC, ClearAllActions());
                    return;
                    break;
                }

                oObjectLoop = GetNextObjectInShape(SHAPE_SPHERE, fSize, lLocation, TRUE, OBJECT_TYPE_CREATURE);
            }

            RemoveMount(oPC);


// =======================================
// START REST AMBUSH CODE
// =======================================

// only the first 7
            for (i = 1; i < 8; i++)
            {
                if (GetLocalString(oArea, "random"+IntToString(i)) != "") nEnemyGroups++;
            }
            SendDebugMessage("pvp area: "+IntToString(NWNX_Area_GetPVPSetting(oArea)));
            if (NWNX_Area_GetPVPSetting(oArea) > 0)
            {
// only do ambushes if there are random enemy groups
                if ((GetLocalInt(oArea, "ambush") == 1) && (nEnemyGroups > 0))
                {
                    nAmbushChance = 40;
                }
                else
                {
                    nAmbushChance = 0;
                }

// loop through waypoints to see if there is a rest in progress, in which case we will use if exists
                oObjectLoop = GetFirstObjectInShape(SHAPE_SPHERE, fSize, lLocation, FALSE, OBJECT_TYPE_PLACEABLE);
                while (GetIsObjectValid(oObjectLoop))
                {
                    if (GetTag(oObjectLoop) == "_campfire")
                    {
                        SendDebugMessage("oCampfire found, rest in progress.");
                        oCampfire = oObjectLoop;
                        break;
                    }

                    oObjectLoop = GetNextObjectInShape(SHAPE_SPHERE, fSize, lLocation, FALSE, OBJECT_TYPE_PLACEABLE);
                }

// if it doesnt exist, create a rest in progress
                if (!GetIsObjectValid(oCampfire))
                {
                   SendDebugMessage("oCampfire was not found, creating a rest in progress.");
// spawn a creature to determine if this is valid spawn point
                   oValidator = CreateObject(OBJECT_TYPE_CREATURE, "_cf_validator", lTarget);

                   oCampfire = CreateObject(OBJECT_TYPE_PLACEABLE, "_campfire", GetLocation(oValidator), FALSE, "_campfire");

                   DelayCommand(30.0, AssignCommand(oCampfire, PlayAnimation(ANIMATION_PLACEABLE_DEACTIVATE)));
                   DestroyObject(oCampfire, 60.0);

                   DestroyObject(oValidator);

// loop through PCs in the same vicinity to check if there is a ranger or harper scout
                   oCurrentPC = GetFirstPC();
                   while(oCurrentPC != OBJECT_INVALID)
                   {

// the party member must be in the same area and distance to count
                      if((GetArea(oCurrentPC) == oArea) && (GetDistanceBetween(oCurrentPC, oPC) <= fSize))
                      {
// rangers and harper scouts reduce the chance of an ambush. having both however doesn't stack
                          if (GetLevelByClass(CLASS_TYPE_RANGER, oCurrentPC) >= 1)
                          {
                                SendDebugMessage("Ranger was found in rest vicinity.");
                                bRanger = TRUE;
                          }
                          if (GetLevelByClass(CLASS_TYPE_HARPER, oCurrentPC) >= 1)
                          {
                                SendDebugMessage("Harper Scout was found in rest vicinity.");
                                bHarperScout = TRUE;
                          }
                      }
                      oCurrentPC = GetNextPC();
                    }

                    if (bRanger || bHarperScout) nHideClassChance = nAmbushChance/2;

                    nAmbushRoll = d100();

                    int bSafeRest = FALSE;
                    object oSafeRest = GetNearestObjectByTag("_safe_rest");
                    float fDistanceToSafeRest = GetDistanceBetween(oPC, oSafeRest);
                    if (GetIsObjectValid(oSafeRest) && fDistanceToSafeRest > 0.0 && fDistanceToSafeRest < 50.0)
                    {
                        bSafeRest = TRUE;
                    }
                    else if (!GetIsObjectValid(GetNearestCreature(CREATURE_TYPE_REPUTATION, REPUTATION_TYPE_ENEMY, oPC, 1, CREATURE_TYPE_IS_ALIVE, TRUE)))
                    {
                        bSafeRest = TRUE;
                    }

                    if (bSafeRest)
                    {
                        SendDebugMessage("Setting ambush chance and roll to 20 due safe rest");
                        nAmbushChance = 0;
                        nAmbushRoll = 20; // this is set so "hiding from enemies" text isnt shown
                    }

                    SendDebugMessage("Ambush roll: "+IntToString(nAmbushRoll));
                    SendDebugMessage("Ambush chance: "+IntToString(nAmbushChance));
                    SendDebugMessage("Hide chance: "+IntToString(nHideChance));
                    SendDebugMessage("Hide class chance: "+IntToString(nHideClassChance));
// 10% of the time the ambush will never trigger with a message
                    if (nAmbushRoll <= 10)
                    {
                        SetLocalInt(oCampfire, "hide", 1);
                    }
// if there is a ranger or harper scout, decrease the chance of an ambush
                    if (nAmbushRoll <= nHideChance)
                    {
                       if (bRanger && bHarperScout)
                        {
                            switch (d2())
                            {
                                case 1: sHideClass = "Ranger"; break;
                                case 2: sHideClass = "Harper Scout"; break;
                            }
                        }
                        else if (bRanger) {sHideClass = "Ranger";}
                        else if (bHarperScout) {sHideClass = "Harper Scout";}

                        SetLocalString(oCampfire, "hide_class", sHideClass);
                        DelayCommand(50.0, AssignCommand(oCampfire, PlayAnimation(ANIMATION_PLACEABLE_DEACTIVATE)));
                        DestroyObject(oCampfire, 60.0);
                    }
// otherwise, trigger an ambush
                    else if (nAmbushRoll <= nAmbushChance)
                    {
                        fAmbushTime = IntToFloat(4+d6());
                        SendDebugMessage("Ambush will be created in: "+FloatToString(fAmbushTime)+" seconds");

                        DelayCommand(fAmbushTime+1.0, AssignCommand(oCampfire, PlayAnimation(ANIMATION_PLACEABLE_DEACTIVATE)));
                        DestroyObject(oCampfire, fAmbushTime+10.0);
                        DelayCommand(fAmbushTime, CreateAmbush(Random(nEnemyGroups)+1, oArea, lLocation));
                        DelayCommand(fAmbushTime, FloatingTextStringOnCreature(sSpotted, oPC, FALSE));
                    }
                 }
                 sHideClass = GetLocalString(oCampfire, "hide_class");

                 if (GetLocalInt(oCampfire, "hide") == 1) {FloatingTextStringOnCreature(sHide, oPC, TRUE);}
                 else if ((sHideClass == "Ranger") || (sHideClass == "Harper Scout")) {FloatingTextStringOnCreature(sHidePrepend+sHideClass+sHideAppend, oPC, FALSE);}
            }
// =======================================
// END REST AMBUSH CODE
// =======================================

            ApplySleepVFX(GetAssociate(ASSOCIATE_TYPE_HENCHMAN, oPC, 1));
            ApplySleepVFX(GetAssociate(ASSOCIATE_TYPE_HENCHMAN, oPC, 2));
            ApplySleepVFX(GetAssociate(ASSOCIATE_TYPE_HENCHMAN, oPC, 3));
            ApplySleepVFX(GetAssociate(ASSOCIATE_TYPE_HENCHMAN, oPC, 4));
            ApplySleepVFX(GetAssociate(ASSOCIATE_TYPE_HENCHMAN, oPC, 5));
            ApplySleepVFX(GetAssociate(ASSOCIATE_TYPE_HENCHMAN, oPC, 6));
            ApplySleepVFX(GetAssociate(ASSOCIATE_TYPE_HENCHMAN, oPC, 7));
            ApplySleepVFX(GetAssociate(ASSOCIATE_TYPE_HENCHMAN, oPC, 8));
            ApplySleepVFX(GetAssociate(ASSOCIATE_TYPE_HENCHMAN, oPC, 9));

            ApplySleepVFX(GetAssociate(ASSOCIATE_TYPE_ANIMALCOMPANION, oPC, 1));
            ApplySleepVFX(GetAssociate(ASSOCIATE_TYPE_ANIMALCOMPANION, oPC, 2));
            ApplySleepVFX(GetAssociate(ASSOCIATE_TYPE_FAMILIAR, oPC, 1));
            ApplySleepVFX(GetAssociate(ASSOCIATE_TYPE_FAMILIAR, oPC, 2));

            ApplySleepVFX(oPC);

            DelayCommand(0.1,FadeToBlack(oPC,FADE_SPEED_FAST));
            DelayCommand(2.6, FadeFromBlack(oPC, FADE_SPEED_MEDIUM));
        break;
        case REST_EVENTTYPE_REST_FINISHED:
            //DeleteLocalInt(oPC, "invis");
            DeleteLocalInt(oPC, "gsanc");
            DeleteLocalInt(oPC, "healers_kit_cd");
            GiveHiPSFeatSafely(oPC);

            while ( oItem != OBJECT_INVALID ) {
                IPRemoveAllItemProperties(oItem,DURATION_TYPE_TEMPORARY);
                oItem = GetNextItemInInventory(oPC);
            }

            for ( nSlot = 0; nSlot < NUM_INVENTORY_SLOTS; ++nSlot )
                IPRemoveAllItemProperties(GetItemInSlot(nSlot, oPC));


            if (GetIsObjectValid(GetAssociate(ASSOCIATE_TYPE_FAMILIAR, oPC))) DecrementRemainingFeatUses(oPC, FEAT_SUMMON_FAMILIAR);
            if (GetIsObjectValid(GetAssociate(ASSOCIATE_TYPE_ANIMALCOMPANION, oPC)))  DecrementRemainingFeatUses(oPC, FEAT_ANIMAL_COMPANION);

        case REST_EVENTTYPE_REST_CANCELLED:
            StopFade(oPC);
            SavePCInfo(oPC);
            if (GetPCPublicCDKey(oPC) != "") ExportSingleCharacter(oPC);
        break;
    }

}
