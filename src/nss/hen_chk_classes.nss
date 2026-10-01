#include "inc_webhook"
#include "inc_ctoken"

int StartingConditional()
{
    SetCustomToken(CTOKEN_HENCHMAN_CLASSES, GetClassesAndLevels(OBJECT_SELF));
    return TRUE;
}
