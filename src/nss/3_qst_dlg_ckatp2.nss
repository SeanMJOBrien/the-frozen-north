// Returns TRUE if the PC is at or past quest#: ##_<quest_name>, zero padded
#include "1_inc_quest"

int StartingConditional()
{
    object oPC = GetPCSpeaker();

    return GetIsAtQuestStage(OBJECT_SELF, oPC, 2);
}
